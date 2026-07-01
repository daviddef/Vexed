import Foundation
import Combine
import SwiftUI

struct SlideResult {
    let moved: Bool
    let vanishedPositions: [Position]
    let scoredWords: [ScoredWord]
}

struct ScoredWord {
    let word: String
    let positions: [Position]
    var points: Int { word.count * 10 + (word.count > 4 ? 20 : 0) }
}

@MainActor
final class GameEngine: ObservableObject {
    @Published var grid: [[Tile?]]
    @Published var selectedPosition: Position?
    @Published var score: Int = 0
    @Published var wordCount: Int = 0
    @Published var lostVowels: Int = 0
    @Published var lastWord: String? = nil
    @Published var flashWord: String? = nil
    @Published var gameOver: Bool = false
    @Published var log: [LogEntry] = []
    @Published var wordHistory: [(word: String, points: Int)] = []
    @Published var potentialScore: Int = 0
    @Published var peakScore: Int = 0      // max possible at game start, set once
    @Published var noWordsLeft: Bool = false
    @Published var combo: Int = 0          // consecutive word-scoring moves
    @Published var comboMultiplier: Double = 1.0  // 1.0, 1.5, 2.0, 3.0
    @Published var boardVersion: Int = 0   // increments on each reset to trigger animation
    @Published var dangerVowelColor: Color? = nil   // non-nil when a cluster of 3+ same vowel exists
    @Published var celebrationWord: String? = nil   // set to the word when 5+ letters scored
    @Published var tilesForged: Int = 0             // cumulative bonus tiles spawned by Tile Forge
    @Published var forgeMessage: String? = nil      // brief "+N tiles" banner
    @Published var availableWords: [AvailableWord] = []   // words scoreable RIGHT NOW on the board
    @Published var highlightedPositions: Set<Position>? = nil  // non-nil = dim all other tiles
    @Published var interactionTick: Int = 0  // incremented on every user action (slide/select/collect)
    @Published var hintWordId: UUID? = nil   // kid mode: ID of word to highlight as hint
    @Published var hintBeaconActive: Bool = false  // kid mode phase-2: show tap beacon

    struct AvailableWord: Identifiable {
        let id = UUID()
        let word: String
        let positions: [Position]
        var points: Int { word.count * 10 + (word.count > 4 ? 20 : 0) }
    }

    /// Cells each cardinal-direction slide would pass through. Key = direction, value = ordered path including destination.
    @Published var slidePaths: [Direction: [Position]] = [:]
    @Published var burstEvents: [BurstEvent] = []

    struct BurstEvent: Identifiable, Equatable {
        let id = UUID()
        let color: Color
    }

    var config: DifficultyConfig
    private var hintTask: Task<Void, Never>? = nil
    private var validator: WordValidator {
        let includeRare = UserDefaults.standard.bool(forKey: "includeRareWords")
        return WordValidator.forResource(config.activeWordList(includeRare: includeRare))
    }
    private var pressureTimer: AnyCancellable?

    struct LogEntry: Identifiable {
        let id = UUID()
        let message: String
        let kind: Kind
        enum Kind { case good, bad, info }
    }

    init(difficulty: Difficulty = .medium) {
        self.config = difficulty.config
        Self.applyKidOverrides(to: &self.config)
        self.grid = Self.makeGrid(rows: config.rows, cols: config.cols, validator: WordValidator.forResource(config.activeWordList(includeRare: UserDefaults.standard.bool(forKey: "includeRareWords"))))
        startPressureTimer()
        recalculatePotentialScore()
    }

    // MARK: - Kid Mode

    private var celebrationMinLength: Int {
        guard UserDefaults.standard.bool(forKey: "kidMode") else { return 5 }
        let ageRaw = UserDefaults.standard.string(forKey: "kidAge") ?? KidAge.explorer.rawValue
        switch KidAge(rawValue: ageRaw) ?? .explorer {
        case .little:      return 2
        case .explorer:    return 3
        case .challenger:  return 4
        }
    }

    static func applyKidOverrides(to config: inout DifficultyConfig) {
        guard UserDefaults.standard.bool(forKey: "kidMode") else { return }
        let ageRaw = UserDefaults.standard.string(forKey: "kidAge") ?? KidAge.explorer.rawValue
        let age = KidAge(rawValue: ageRaw) ?? .explorer
        config.minWordLength = age.minWordLength
        config.wordListName  = age.wordListName
        if age.flatForgeBonus > 0 { config.flatForgeBonus = age.flatForgeBonus }
    }

    func clearHint() {
        hintTask?.cancel()
        hintTask = nil
        hintWordId = nil
        hintBeaconActive = false
    }

    private func rescheduleHint() {
        hintTask?.cancel()
        hintWordId = nil
        hintBeaconActive = false
        guard UserDefaults.standard.bool(forKey: "kidMode") else { return }
        let ageRaw = UserDefaults.standard.string(forKey: "kidAge") ?? KidAge.explorer.rawValue
        let age = KidAge(rawValue: ageRaw) ?? .explorer
        guard age.hintDelay > 0 else { return }
        hintTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(age.hintDelay * 1_000_000_000))
            } catch { return }
            guard let self, !Task.isCancelled else { return }
            if let word = self.availableWords.randomElement() {
                self.hintWordId = word.id
            }
            guard age.beaconDelay > age.hintDelay else { return }
            do {
                try await Task.sleep(nanoseconds: UInt64((age.beaconDelay - age.hintDelay) * 1_000_000_000))
            } catch { return }
            guard !Task.isCancelled else { return }
            self.hintBeaconActive = true
        }
    }

    // MARK: - Grid Setup

    private static func makeGrid(rows: Int, cols: Int, validator: WordValidator) -> [[Tile?]] {
        // Regenerate until the board has no pre-existing words AND no 3+ same-vowel clusters.
        // With ~20% empty cells this typically resolves in 1-3 attempts.
        var attempts = 0
        while true {
            let g = generateGrid(rows: rows, cols: cols)
            attempts += 1
            let clean = !boardHasWords(g, rows: rows, cols: cols, validator: validator)
                     && !boardHasVowelCluster(g, rows: rows, cols: cols)
            if clean || attempts > 50 { return g }
        }
    }

    /// Returns true if any 3+ orthogonally-connected group of identical vowels exists.
    private static func boardHasVowelCluster(_ grid: [[Tile?]], rows: Int, cols: Int) -> Bool {
        var visited = Array(repeating: Array(repeating: false, count: cols), count: rows)
        for r in 0..<rows {
            for c in 0..<cols {
                guard let vowel = grid[r][c]?.vowel, !visited[r][c] else { continue }
                // BFS to count connected same-vowel tiles
                var queue = [(r, c)]
                var size = 0
                visited[r][c] = true
                while !queue.isEmpty {
                    let (cr, cc) = queue.removeFirst()
                    size += 1
                    for (dr, dc) in [(-1,0),(1,0),(0,-1),(0,1)] {
                        let nr = cr + dr; let nc = cc + dc
                        guard nr >= 0, nr < rows, nc >= 0, nc < cols,
                              !visited[nr][nc],
                              grid[nr][nc]?.vowel == vowel else { continue }
                        visited[nr][nc] = true
                        queue.append((nr, nc))
                    }
                }
                if size >= 3 { return true }
            }
        }
        return false
    }

    private static func generateGrid(rows: Int, cols: Int) -> [[Tile?]] {
        let consonants = "BCDFGHJKLMNPQRSTVWXYZ".map { $0 }
        let vowelChars = "AEIOU".map { $0 }

        var chars: [Character?] = []
        let total = rows * cols
        let vowelCount = total * 4 / 10
        let consonantCount = total * 4 / 10

        for _ in 0..<vowelCount { chars.append(vowelChars.randomElement()!) }
        for _ in 0..<consonantCount { chars.append(consonants.randomElement()!) }
        while chars.count < total { chars.append(nil) }
        chars.shuffle()

        var g: [[Tile?]] = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        var idx = 0
        for r in 0..<rows {
            for c in 0..<cols {
                g[r][c] = chars[idx].map { Tile(letter: $0) }
                idx += 1
            }
        }
        return g
    }

    // Returns true if any row or column contains a valid word of 3+ letters.
    private static func boardHasWords(_ grid: [[Tile?]], rows: Int, cols: Int, validator v: WordValidator) -> Bool {
        // Scan rows
        for r in 0..<rows {
            let letters = (0..<cols).compactMap { grid[r][$0]?.letter }
            if lineHasWord(letters, validator: v) { return true }
        }
        // Scan columns
        for c in 0..<cols {
            let letters = (0..<rows).compactMap { grid[$0][c]?.letter }
            if lineHasWord(letters, validator: v) { return true }
        }
        return false
    }

    private static func lineHasWord(_ letters: [Character], validator: WordValidator) -> Bool {
        guard letters.count >= 3 else { return false }
        for start in 0..<letters.count {
            guard start + 3 <= letters.count else { break }
            for end in (start + 3)...letters.count {
                let word = String(letters[start..<end])
                if validator.isValid(word) { return true }
            }
        }
        return false
    }

    // MARK: - Selection

    func select(position: Position) {
        if grid[position.row][position.col] == nil { selectedPosition = nil; slidePaths = [:]; return }
        selectedPosition = (selectedPosition == position) ? nil : position
        interactionTick += 1
        rescheduleHint()
        updateSlidePaths()
    }

    func updateSlidePaths() {
        guard let src = selectedPosition, grid[src.row][src.col] != nil else {
            slidePaths = [:]
            return
        }
        var paths: [Direction: [Position]] = [:]
        for dir in Direction.cardinal {
            var path: [Position] = []
            var pos = src
            while true {
                let next = pos.moved(dir)
                guard next.isValid(rows: config.rows, cols: config.cols),
                      grid[next.row][next.col] == nil else { break }
                path.append(next)
                pos = next
            }
            if !path.isEmpty { paths[dir] = path }
        }
        slidePaths = paths
    }

    // MARK: - Slide

    @discardableResult
    func slide(direction: Direction) -> SlideResult {
        guard let src = selectedPosition,
              grid[src.row][src.col] != nil else {
            return SlideResult(moved: false, vanishedPositions: [], scoredWords: [])
        }
        interactionTick += 1
        rescheduleHint()

        // Ice physics: glide until wall or occupied cell
        var dest = src
        while true {
            let next = dest.moved(direction)
            guard next.isValid(rows: config.rows, cols: config.cols),
                  grid[next.row][next.col] == nil else { break }
            dest = next
        }

        guard dest != src else {
            Haptics.rigid()
            addLog("Can't slide that way", .info)
            return SlideResult(moved: false, vanishedPositions: [], scoredWords: [])
        }

        withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
            grid[dest.row][dest.col] = grid[src.row][src.col]
            grid[src.row][src.col] = nil
            selectedPosition = dest
        }

        Haptics.medium()
        highlightedPositions = nil
        addLog("Slid \(grid[dest.row][dest.col]!.letter) → (\(dest.row),\(dest.col))", .info)

        slidePaths = [:]
        // Vowel vanish only — word scoring is now triggered manually by the player
        let vanished = applyVowelVanish()
        let vanishDelay = vanished.isEmpty ? 0.0 : 0.55
        DispatchQueue.main.asyncAfter(deadline: .now() + vanishDelay) { [weak self] in
            guard let self else { return }
            self.updateDangerStates()
            self.recalculatePotentialScore()
            self.updateSlidePaths()
        }
        if vanished.isEmpty {
            updateDangerStates()
            recalculatePotentialScore()
            updateSlidePaths()
        }

        return SlideResult(moved: true, vanishedPositions: vanished, scoredWords: [])
    }

    // MARK: - Vowel Vanish

    @discardableResult
    private func applyVowelVanish() -> [Position] {
        var toVanish: Set<Position> = []
        var visited: Set<Position> = []

        for r in 0..<config.rows {
            for c in 0..<config.cols {
                let pos = Position(r, c)
                guard !visited.contains(pos),
                      let tile = grid[r][c],
                      let v = tile.vowel else { continue }

                let group = floodFill(from: pos, vowel: v)
                visited.formUnion(group)
                if group.count >= 3 { toVanish.formUnion(group) }
            }
        }

        let positions = Array(toVanish)
        if !positions.isEmpty {
            // Mark vanishing animation state
            for pos in positions {
                grid[pos.row][pos.col]?.animState = .vanishing
            }
            lostVowels += positions.count
            Haptics.warning()
            if let first = positions.first, let vowel = grid[first.row][first.col]?.vowel {
                let c: Color
                switch vowel {
                case .A: c = Color(red: 0.95, green: 0.22, blue: 0.22)
                case .E: c = Color(red: 0.18, green: 0.82, blue: 0.35)
                case .I: c = Color(red: 0.15, green: 0.48, blue: 1.0)
                case .O: c = Color(red: 1.0,  green: 0.55, blue: 0.05)
                case .U: c = Color(red: 0.72, green: 0.22, blue: 0.95)
                }
                burstEvents.append(BurstEvent(color: c))
            }
            addLog("💥 \(positions.count) vowels vanished!", .bad)

            // Remove after animation delay handled by view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self else { return }
                for pos in positions { self.grid[pos.row][pos.col] = nil }
                self.updateDangerStates()
                self.recalculatePotentialScore()
            }
        }
        return positions
    }

    private func floodFill(from start: Position, vowel: Vowel) -> Set<Position> {
        var group: Set<Position> = []
        var stack = [start]
        while let pos = stack.popLast() {
            guard !group.contains(pos) else { continue }
            guard pos.isValid(rows: config.rows, cols: config.cols),
                  grid[pos.row][pos.col]?.vowel == vowel else { continue }
            group.insert(pos)
            for dir in config.adjacentDirections {
                stack.append(pos.moved(dir))
            }
        }
        return group
    }

    // MARK: - Word Scoring

    @discardableResult
    /// Player-triggered word collection. Called when the player double-taps a word chip.
    func collectWord(_ word: AvailableWord) {
        guard availableWords.contains(where: { $0.id == word.id }) else { return }
        interactionTick += 1
        rescheduleHint()

        combo += 1
        comboMultiplier = combo >= 4 ? 3.0 : combo >= 3 ? 2.0 : combo >= 2 ? 1.5 : 1.0

        for pos in word.positions { grid[pos.row][pos.col]?.animState = .scoring }
        let multiplied = Int(Double(word.points) * comboMultiplier)
        score += multiplied
        wordCount += 1
        lastWord = word.word
        wordHistory.append((word: word.word, points: multiplied))
        addLog("✨ \"\(word.word)\" +\(multiplied)pts", .good)

        Haptics.wordScore()
        flashWord = word.word
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in self?.flashWord = nil }

        if word.word.count >= celebrationMinLength {
            celebrationWord = word.word
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in self?.celebrationWord = nil }
        }

        burstEvents.append(BurstEvent(color: Color(red: 1.0, green: 0.85, blue: 0.2)))

        let forgeCount = config.forgeBonusCount(wordLength: word.word.count)

        // Remove from pending list immediately so it can't be double-collected
        availableWords.removeAll { $0.id == word.id }
        highlightedPositions = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            for pos in word.positions { self.grid[pos.row][pos.col] = nil }
            self.updateDangerStates()
            self.recalculatePotentialScore()
            if forgeCount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.spawnForgeTiles(count: forgeCount)
                }
            }
        }
    }

    private func applyWordScoring() -> [ScoredWord] {
        var found: [ScoredWord] = []

        // Scan rows
        for r in 0..<config.rows {
            let positions = (0..<config.cols).map { Position(r, $0) }
            found += scanLine(positions)
        }
        // Scan columns
        for c in 0..<config.cols {
            let positions = (0..<config.rows).map { Position($0, c) }
            found += scanLine(positions)
        }

        if found.isEmpty {
            combo = 0
            comboMultiplier = 1.0
        } else {
            combo += 1
            comboMultiplier = combo >= 4 ? 3.0 : combo >= 3 ? 2.0 : combo >= 2 ? 1.5 : 1.0
        }

        for word in found {
            for pos in word.positions { grid[pos.row][pos.col]?.animState = .scoring }
            let multiplied = Int(Double(word.points) * comboMultiplier)
            score += multiplied
            wordCount += 1
            lastWord = word.word
            wordHistory.append((word: word.word, points: multiplied))
            addLog("✨ \"\(word.word)\" +\(multiplied)pts", .good)
        }

        if !found.isEmpty {
            Haptics.wordScore()

            // Flash the word prominently before tiles vanish
            if let first = found.first {
                flashWord = first.word
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                    self?.flashWord = nil
                }
            }

            // Celebration for words meeting the length threshold (lower in Kid Mode)
            if let best = found.max(by: { $0.word.count < $1.word.count }), best.word.count >= celebrationMinLength {
                celebrationWord = best.word
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.celebrationWord = nil
                }
            }

            let burstColor = Color(red: 1.0, green: 0.85, blue: 0.2) // gold for word score
            burstEvents.append(BurstEvent(color: burstColor))
        }

        if !found.isEmpty {
            // Calculate Tile Forge bonus: extra letters beyond 3 per word
            let forgeCount = found.reduce(0) { $0 + config.forgeBonusCount(wordLength: $1.word.count) }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                for word in found {
                    for pos in word.positions { self.grid[pos.row][pos.col] = nil }
                }
                self.updateDangerStates()

                // Spawn bonus tiles after scored tiles are cleared
                if forgeCount > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                        self?.spawnForgeTiles(count: forgeCount)
                    }
                }
            }
        }
        return found
    }

    // MARK: - Tile Forge

    private func spawnForgeTiles(count: Int) {
        // Gather empty cells
        var emptyCells: [Position] = []
        for r in 0..<config.rows {
            for c in 0..<config.cols {
                if grid[r][c] == nil { emptyCells.append(Position(r, c)) }
            }
        }
        // Don't overfill — leave at least 20% empty
        let maxFill = Int(Double(config.rows * config.cols) * 0.80)
        let occupiedCount = config.rows * config.cols - emptyCells.count
        let canSpawn = min(count, max(0, maxFill - occupiedCount), emptyCells.count)
        guard canSpawn > 0 else { return }

        emptyCells.shuffle()
        let targets = Array(emptyCells.prefix(canSpawn))

        for pos in targets {
            var t = Tile(letter: randomForgeLetter())
            t.animState = .forged
            grid[pos.row][pos.col] = t
        }
        // Settle forged tiles to idle after the entry animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            for pos in targets where self.grid[pos.row][pos.col]?.animState == .forged {
                self.grid[pos.row][pos.col]?.animState = .idle
            }
        }

        tilesForged += canSpawn
        let msg = "+\(canSpawn) tile\(canSpawn == 1 ? "" : "s") forged!"
        forgeMessage = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.forgeMessage = nil
        }
        recalculatePotentialScore()
        updateDangerStates()
    }

    private func randomForgeLetter() -> Character {
        let vowels: [Character] = ["A", "E", "I", "O", "U"]
        let consonants: [Character] = "BCDFGHJKLMNPRSTVWX".map { $0 }

        // Maintain vowel/consonant balance — target ~40% vowels
        let tiles = grid.flatMap { $0 }.compactMap { $0 }
        let vowelRatio = tiles.isEmpty ? 0.4 : Double(tiles.filter { $0.vowel != nil }.count) / Double(tiles.count)
        let spawnVowel = vowelRatio < 0.40 ? true : Double.random(in: 0..<1) < 0.35

        let pool = spawnVowel ? vowels : consonants

        // Weight each letter by 1/(count+1) — letters already common on the board
        // get a much lower probability, letters absent get weight 1.0
        var freq: [Character: Int] = [:]
        for tile in tiles { freq[tile.letter, default: 0] += 1 }

        let weights = pool.map { 1.0 / Double(freq[$0, default: 0] + 1) }
        let total = weights.reduce(0, +)
        var r = Double.random(in: 0..<total)
        for (letter, weight) in zip(pool, weights) {
            r -= weight
            if r <= 0 { return letter }
        }
        return pool.last!
    }

    private func scanLine(_ positions: [Position]) -> [ScoredWord] {
        var words: [ScoredWord] = []
        var i = 0
        while i < positions.count {
            guard grid[positions[i].row][positions[i].col] != nil else { i += 1; continue }
            // Find run of non-nil tiles
            var j = i
            while j < positions.count, grid[positions[j].row][positions[j].col] != nil { j += 1 }
            let run = Array(positions[i..<j])
            // Try longest substrings first
            for start in 0..<run.count {
                for end in stride(from: run.count, through: start + config.minWordLength, by: -1) {
                    let slice = Array(run[start..<end])
                    let word = slice.compactMap { grid[$0.row][$0.col]?.letter }.map { String($0) }.joined()
                    if word.count == end - start, validator.isValid(word) {
                        words.append(ScoredWord(word: word, positions: slice))
                        // Don't overlap — skip consumed tiles
                        break
                    }
                }
            }
            i = j
        }
        return words
    }

    // MARK: - Potential Score

    func recalculatePotentialScore() {
        var total = 0
        // Scan rows
        for r in 0..<config.rows {
            let letters = (0..<config.cols).compactMap { grid[r][$0]?.letter }
            total += bestScoreForLine(letters)
        }
        // Scan columns
        for c in 0..<config.cols {
            let letters = (0..<config.rows).compactMap { grid[$0][c]?.letter }
            total += bestScoreForLine(letters)
        }
        potentialScore = total
        peakScore = max(peakScore, potentialScore)
        let tilesExist = grid.flatMap { $0 }.contains { $0 != nil }
        // Scan current words first — if any are already collectable, game is not over.
        availableWords = scanAvailableWords()
        let wasOver = noWordsLeft
        noWordsLeft = tilesExist && wordCount > 0 && !gameOver
            && availableWords.isEmpty && !anySlideCanScoreWord()
        if noWordsLeft && !wasOver { saveHighScoreIfBetter() }
    }

    private func scanAvailableWords() -> [AvailableWord] {
        var seen = Set<String>()
        var results: [AvailableWord] = []

        func scanLine(_ positions: [Position]) {
            var i = 0
            while i < positions.count {
                guard grid[positions[i].row][positions[i].col] != nil else { i += 1; continue }
                var j = i
                while j < positions.count, grid[positions[j].row][positions[j].col] != nil { j += 1 }
                let run = Array(positions[i..<j])
                for start in 0..<run.count {
                    for end in stride(from: run.count, through: start + config.minWordLength, by: -1) {
                        let slice = Array(run[start..<end])
                        let word = slice.compactMap { grid[$0.row][$0.col]?.letter }.map { String($0) }.joined()
                        if word.count == end - start, validator.isValid(word), !seen.contains(word) {
                            seen.insert(word)
                            results.append(AvailableWord(word: word, positions: slice))
                        }
                    }
                }
                i = j
            }
        }

        for r in 0..<config.rows { scanLine((0..<config.cols).map { Position(r, $0) }) }
        for c in 0..<config.cols { scanLine((0..<config.rows).map { Position($0, c) }) }
        // Longest words first (highest score potential), then alphabetically for stability
        return results.sorted {
            if $0.word.count != $1.word.count { return $0.word.count > $1.word.count }
            return $0.word < $1.word
        }
    }

    /// Returns true if at least one tile can be slid in some direction to form a valid word.
    // Returns all (src, dest) pairs for one ice-slide in the given grid.
    private func allSlides(in g: [[Tile?]]) -> [(Position, Position)] {
        var moves: [(Position, Position)] = []
        for r in 0..<config.rows {
            for c in 0..<config.cols {
                guard g[r][c] != nil else { continue }
                let src = Position(r, c)
                for dir in Direction.cardinal {
                    var dest = src
                    while true {
                        let next = dest.moved(dir)
                        guard next.isValid(rows: config.rows, cols: config.cols),
                              g[next.row][next.col] == nil else { break }
                        dest = next
                    }
                    if dest != src { moves.append((src, dest)) }
                }
            }
        }
        return moves
    }

    // Apply a single slide to a grid copy and return the result.
    private func applying(_ g: [[Tile?]], from src: Position, to dest: Position) -> [[Tile?]] {
        var g2 = g
        g2[dest.row][dest.col] = g2[src.row][src.col]
        g2[src.row][src.col] = nil
        return g2
    }

    // Check whether any contiguous run in the row or column of dest contains a valid word.
    private func gridHasWordAt(_ g: [[Tile?]], dest: Position) -> Bool {
        lineHasWordInRuns(g, row: dest.row) || lineHasWordInRuns(g, col: dest.col)
    }

    private func lineHasWordInRuns(_ g: [[Tile?]], row: Int) -> Bool {
        var run: [Character] = []
        for c in 0..<config.cols {
            if let letter = g[row][c]?.letter {
                run.append(letter)
            } else {
                if lineLettersHaveWord(run) { return true }
                run.removeAll()
            }
        }
        return lineLettersHaveWord(run)
    }

    private func lineHasWordInRuns(_ g: [[Tile?]], col: Int) -> Bool {
        var run: [Character] = []
        for r in 0..<config.rows {
            if let letter = g[r][col]?.letter {
                run.append(letter)
            } else {
                if lineLettersHaveWord(run) { return true }
                run.removeAll()
            }
        }
        return lineLettersHaveWord(run)
    }

    private func anySlideCanScoreWord() -> Bool {
        // Single-slide pass
        let slides = allSlides(in: grid)
        for (src, dest) in slides {
            let g1 = applying(grid, from: src, to: dest)
            if gridHasWordAt(g1, dest: dest) { return true }
        }
        // Two-slide lookahead: if no single slide works, try all pairs
        for (src1, dest1) in slides {
            let g1 = applying(grid, from: src1, to: dest1)
            for (src2, dest2) in allSlides(in: g1) {
                let g2 = applying(g1, from: src2, to: dest2)
                if gridHasWordAt(g2, dest: dest2) { return true }
            }
        }
        return false
    }

    private func lineLettersHaveWord(_ letters: [Character]) -> Bool {
        guard letters.count >= config.minWordLength else { return false }
        for start in 0..<letters.count {
            let maxLen = min(10, letters.count - start)
            guard maxLen >= config.minWordLength else { break }
            for len in config.minWordLength...maxLen {
                if validator.isValid(String(letters[start..<(start + len)])) { return true }
            }
        }
        return false
    }

    // Greedy scan: find non-overlapping valid words (longest first) and sum their points.
    private func bestScoreForLine(_ letters: [Character]) -> Int {
        guard letters.count >= config.minWordLength else { return 0 }
        var total = 0
        var i = 0
        while i < letters.count {
            var found = false
            for len in stride(from: min(letters.count - i, 10), through: config.minWordLength, by: -1) {
                let word = String(letters[i..<(i + len)])
                if validator.isValid(word) {
                    total += word.count * 10 + (word.count > 4 ? 20 : 0)
                    i += len
                    found = true
                    break
                }
            }
            if !found { i += 1 }
        }
        return total
    }

    // MARK: - Danger States

    func updateDangerStates() {
        for r in 0..<config.rows {
            for c in 0..<config.cols {
                guard let tile = grid[r][c], let v = tile.vowel else { continue }
                let pos = Position(r, c)
                let hasSameNeighbor = config.adjacentDirections.contains {
                    let n = pos.moved($0)
                    return n.isValid(rows: config.rows, cols: config.cols) && grid[n.row][n.col]?.vowel == v
                }
                let isInDanger = hasSameNeighbor
                if grid[r][c]?.animState == .idle || grid[r][c]?.animState == .danger {
                    grid[r][c]?.animState = isInDanger ? .danger : .idle
                }
            }
        }

        // Check for dangerous clusters (3+ same adjacent vowels)
        dangerVowelColor = nil
        outer: for r in 0..<config.rows {
            for c in 0..<config.cols {
                guard let tile = grid[r][c], let v = tile.vowel else { continue }
                var visited: Set<Position> = []
                let clusterSize = vowelClusterSize(at: Position(r, c), vowel: v, visited: &visited)
                if clusterSize >= 3 {
                    dangerVowelColor = vowelColor(v)
                    break outer
                }
            }
        }
    }

    private func vowelClusterSize(at pos: Position, vowel: Vowel, visited: inout Set<Position>) -> Int {
        guard !visited.contains(pos),
              pos.isValid(rows: config.rows, cols: config.cols),
              let tile = grid[pos.row][pos.col],
              tile.vowel == vowel else { return 0 }
        visited.insert(pos)
        return 1 +
            vowelClusterSize(at: pos.moved(.up), vowel: vowel, visited: &visited) +
            vowelClusterSize(at: pos.moved(.down), vowel: vowel, visited: &visited) +
            vowelClusterSize(at: pos.moved(.left), vowel: vowel, visited: &visited) +
            vowelClusterSize(at: pos.moved(.right), vowel: vowel, visited: &visited)
    }

    private func vowelColor(_ vowel: Vowel) -> Color {
        switch vowel {
        case .A: return Color(red: 0.95, green: 0.22, blue: 0.22)
        case .E: return Color(red: 0.18, green: 0.82, blue: 0.35)
        case .I: return Color(red: 0.15, green: 0.48, blue: 1.0)
        case .O: return Color(red: 1.0,  green: 0.55, blue: 0.05)
        case .U: return Color(red: 0.72, green: 0.22, blue: 0.95)
        }
    }

    // MARK: - Pressure (tile flow from edges on Hard/Expert)

    private func startPressureTimer() {
        // Pressure timer removed — difficulty now comes from board size and Tile Forge chain length
    }

    private func edgePositions() -> [Position] {
        var positions: [Position] = []
        for c in 0..<config.cols { positions += [Position(0, c), Position(config.rows-1, c)] }
        for r in 1..<config.rows-1 { positions += [Position(r, 0), Position(r, config.cols-1)] }
        return positions
    }

    // MARK: - End Screen Helpers

    var letterGrade: String {
        guard peakScore > 0 else { return "F" }
        let pct = Double(score) / Double(peakScore)
        switch pct {
        case 0.9...: return "S"
        case 0.75...: return "A"
        case 0.6...: return "B"
        case 0.45...: return "C"
        case 0.3...: return "D"
        default: return "F"
        }
    }

    var bestWord: String? {
        wordHistory.max(by: { $0.word.count < $1.word.count })?.word
    }

    // MARK: - Helpers

    func vowelCounts() -> [Vowel: Int] {
        var counts: [Vowel: Int] = [:]
        for v in Vowel.allCases { counts[v] = 0 }
        for r in 0..<config.rows {
            for c in 0..<config.cols {
                if let v = grid[r][c]?.vowel { counts[v, default: 0] += 1 }
            }
        }
        return counts
    }

    private func addLog(_ message: String, _ kind: LogEntry.Kind) {
        log.append(LogEntry(message: message, kind: kind))
        if log.count > 50 { log.removeFirst() }
    }

    private func saveHighScoreIfBetter() {
        let key = "highScore_\(config.wordListName)_\(config.rows)x\(config.cols)"
        let current = UserDefaults.standard.integer(forKey: key)
        if score > current {
            UserDefaults.standard.set(score, forKey: key)
        }
    }

    static func highScore(for difficulty: Difficulty) -> Int {
        let c = difficulty.config
        let key = "highScore_\(c.wordListName)_\(c.rows)x\(c.cols)"
        return UserDefaults.standard.integer(forKey: key)
    }

    func reset(difficulty: Difficulty) {
        pressureTimer?.cancel()
        config = difficulty.config
        Self.applyKidOverrides(to: &config)
        grid = Self.makeGrid(rows: config.rows, cols: config.cols, validator: WordValidator.forResource(config.activeWordList(includeRare: UserDefaults.standard.bool(forKey: "includeRareWords"))))
        selectedPosition = nil
        score = 0; wordCount = 0; lostVowels = 0
        lastWord = nil; gameOver = false; log = []; wordHistory = []
        combo = 0; comboMultiplier = 1.0
        dangerVowelColor = nil
        celebrationWord = nil
        tilesForged = 0; forgeMessage = nil
        availableWords = []; highlightedPositions = nil
        hintTask?.cancel(); hintTask = nil
        interactionTick = 0; hintWordId = nil; hintBeaconActive = false
        startPressureTimer()
        updateDangerStates()
        peakScore = 0
        noWordsLeft = false
        recalculatePotentialScore()
        boardVersion += 1
    }
}
