import Foundation

enum AdjacencyMode {
    case orthogonal   // 4 directions (kids)
    case all8         // 8 directions (medium+)
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy, medium, hard
    var id: String { rawValue }

    var config: DifficultyConfig {
        switch self {
        // forgeMinLength/forgeMaxTiles → tiles = min(max, max(0, wordLen − min))
        // Easy:   3→+1, 4→+2, 5+→+3  (small board, generous replenishment)
        // Medium: 3→0,  4→+1, 5→+2, 6+→+3
        // Hard:   4→+1, 5→+2, 6+→+2  (min word 4 letters, capped at 2)
        case .easy:   return DifficultyConfig(rows: 5,  cols: 5,  adjacency: .orthogonal, minWordLength: 3, wordListName: "easy_words", forgeMinLength: 2, forgeMaxTiles: 3)
        case .medium: return DifficultyConfig(rows: 7,  cols: 7,  adjacency: .orthogonal, minWordLength: 3, wordListName: "words",       forgeMinLength: 3, forgeMaxTiles: 3)
        case .hard:   return DifficultyConfig(rows: 10, cols: 10, adjacency: .orthogonal, minWordLength: 4, wordListName: "dictionary",   forgeMinLength: 3, forgeMaxTiles: 2)
        }
    }

    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }

    var description: String {
        switch self {
        case .easy:   return "5×5 · Learn the ropes"
        case .medium: return "7×7 · The sweet spot"
        case .hard:   return "10×10 · Chain or perish"
        }
    }
}

struct DifficultyConfig {
    let rows: Int
    let cols: Int
    let adjacency: AdjacencyMode
    let minWordLength: Int
    let wordListName: String
    /// Forge curve: tiles awarded = min(forgeMaxTiles, max(0, wordLength − forgeMinLength))
    let forgeMinLength: Int
    let forgeMaxTiles: Int

    var adjacentDirections: [Direction] { Direction.cardinal }

    func forgeBonusCount(wordLength: Int) -> Int {
        min(forgeMaxTiles, max(0, wordLength - forgeMinLength))
    }
}
