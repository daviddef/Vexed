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
        case .easy:   return DifficultyConfig(rows: 5, cols: 5, adjacency: .orthogonal, minWordLength: 3)
        case .medium: return DifficultyConfig(rows: 7, cols: 7, adjacency: .orthogonal, minWordLength: 3)
        case .hard:   return DifficultyConfig(rows: 9, cols: 9, adjacency: .orthogonal, minWordLength: 3)
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
        case .hard:   return "9×9 · Chain or perish"
        }
    }
}

struct DifficultyConfig {
    let rows: Int
    let cols: Int
    let adjacency: AdjacencyMode
    let minWordLength: Int

    var adjacentDirections: [Direction] { Direction.cardinal }

    /// Bonus tiles awarded per word based on letter count beyond 3.
    /// 3 letters = 0, 4 = 1, 5 = 2, 6+ = 3 (capped).
    static func forgeBonusCount(wordLength: Int) -> Int {
        min(3, max(0, wordLength - 3))
    }
}
