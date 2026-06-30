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
    /// Cells each cardinal-direction slide would pass through. Key = direction, value = ordered path including destination.
    @Published var slidePaths: [Direction: [Position]] = [:]
    @Published var burstEvents: [BurstEvent] = []

    struct BurstEvent: Identifiable, Equatable {
        let id = UUID()
        let color: Color
    }

    let config: DifficultyConfig
    private let validator = WordValidator.shared
    private var pressureTimer: AnyCancellable?

    struct LogEntry: Identifiable {
        let id = UUID()
        let message: String
        let kind: Kind
        enum Kind { case good, bad, info }
    }

    init(difficulty: Difficulty = .medium) {
        self.config = difficulty.config
        self.grid = Self.makeGrid(rows: config.rows, cols: config.cols)
        startPressureTimer()
        recalculatePotentialScore()
    }

    // MARK: - Grid Setup

    private static func makeGrid(rows: Int, cols: Int) -> [[Tile?]] {
        // Regenerate until the starting board contains no pre-existing words.
        // With ~20% empty cells this typically resolves in 1-3 attempts.
        var attempts = 0
        while true {
            let g = generateGrid(rows: rows, cols: cols)
            attempts += 1
            if !boardHasWords(g, rows: rows, cols: cols) || attempts > 50 { return g }
        }
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
    private static func boardHasWords(_ grid: [[Tile?]], rows: Int, cols: Int) -> Bool {
        let v = WordValidator.shared
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
        addLog("Slid \(grid[dest.row][dest.col]!.letter) → (\(dest.row),\(dest.col))", .info)

        slidePaths = [:]
        // Vowel vanish first, then word scoring — staggered so each phase is visible
        let vanished = applyVowelVanish()
        let vanishDelay = vanished.isEmpty ? 0.0 : 0.55
        DispatchQueue.main.asyncAfter(deadline: .now() + vanishDelay) { [weak self] in
            guard let self else { return }
            self.applyWordScoring()
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

        for word in found {
            for pos in word.positions { grid[pos.row][pos.col]?.animState = .scoring }
            score += word.points
            wordCount += 1
            lastWord = word.word
            wordHistory.append((word: word.word, points: word.points))
            addLog("✨ \"\(word.word)\" +\(word.points)pts", .good)
        }

        if !found.isEmpty {
            Haptics.success()

            // Flash the word prominently before tiles vanish
            if let first = found.first {
                flashWord = first.word
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                    self?.flashWord = nil
                }
            }

            let burstColor = Color(red: 1.0, green: 0.85, blue: 0.2) // gold for word score
            burstEvents.append(BurstEvent(color: burstColor))
        }

        if !found.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                for word in found {
                    for pos in word.positions { self.grid[pos.row][pos.col] = nil }
                }
                self.updateDangerStates()
            }
        }
        return found
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
        // Track running maximum — peakScore only rises during a game
        peakScore = max(peakScore, potentialScore)
        // Only fire noWordsLeft once words have actually been possible (peakScore > 0).
        // Fresh boards start with potentialScore == 0 by design; without this guard
        // the overlay would trigger on the very first slide.
        let tilesExist = grid.flatMap { $0 }.contains { $0 != nil }
        noWordsLeft = tilesExist && potentialScore == 0 && peakScore > 0 && !gameOver
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
    }

    // MARK: - Pressure (tile flow from edges on Hard/Expert)

    private func startPressureTimer() {
        guard config.pressureRate > 0 else { return }
        let interval = 1.0 / config.pressureRate
        pressureTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.addPressureTile() }
    }

    private func addPressureTile() {
        // Pick a random empty edge cell and fill it
        let edges = edgePositions().filter { grid[$0.row][$0.col] == nil }
        guard let pos = edges.randomElement() else { gameOver = true; return }
        let all = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { $0 }
        // Weight toward vowels slightly to keep board playable
        let pool: [Character] = Array(repeating: "AEIOU".randomElement()!, count: 3) + [all.randomElement()!]
        grid[pos.row][pos.col] = Tile(letter: pool.randomElement()!)
        updateDangerStates()
    }

    private func edgePositions() -> [Position] {
        var positions: [Position] = []
        for c in 0..<config.cols { positions += [Position(0, c), Position(config.rows-1, c)] }
        for r in 1..<config.rows-1 { positions += [Position(r, 0), Position(r, config.cols-1)] }
        return positions
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

    func reset(difficulty: Difficulty) {
        pressureTimer?.cancel()
        let cfg = difficulty.config
        grid = Self.makeGrid(rows: cfg.rows, cols: cfg.cols)
        selectedPosition = nil
        score = 0; wordCount = 0; lostVowels = 0
        lastWord = nil; gameOver = false; log = []; wordHistory = []
        startPressureTimer()
        updateDangerStates()
        peakScore = 0
        noWordsLeft = false
        recalculatePotentialScore()
    }
}
