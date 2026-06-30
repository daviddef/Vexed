import Foundation
import Combine

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
    @Published var gameOver: Bool = false
    @Published var log: [LogEntry] = []

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
    }

    // MARK: - Grid Setup

    private static func makeGrid(rows: Int, cols: Int) -> [[Tile?]] {
        let consonants = "BCDFGHJKLMNPQRSTVWXYZ".map { $0 }
        let vowelChars = "AEIOU".map { $0 }

        // Seed: ~40% vowels, 40% consonants, 20% empty
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

    // MARK: - Selection

    func select(position: Position) {
        if grid[position.row][position.col] == nil { selectedPosition = nil; return }
        selectedPosition = (selectedPosition == position) ? nil : position
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
            addLog("Can't slide that way", .info)
            return SlideResult(moved: false, vanishedPositions: [], scoredWords: [])
        }

        grid[dest.row][dest.col] = grid[src.row][src.col]
        grid[src.row][src.col] = nil
        selectedPosition = dest

        addLog("Slid \(grid[dest.row][dest.col]!.letter) → (\(dest.row),\(dest.col))", .info)

        let vanished = applyVowelVanish()
        let words = applyWordScoring()
        updateDangerStates()

        return SlideResult(moved: true, vanishedPositions: vanished, scoredWords: words)
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
            addLog("💥 \(positions.count) vowels vanished!", .bad)

            // Remove after animation delay handled by view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self else { return }
                for pos in positions { self.grid[pos.row][pos.col] = nil }
                self.updateDangerStates()
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
            addLog("✨ \"\(word.word)\" +\(word.points)pts", .good)
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
        lastWord = nil; gameOver = false; log = []
        startPressureTimer()
        updateDangerStates()
    }
}
