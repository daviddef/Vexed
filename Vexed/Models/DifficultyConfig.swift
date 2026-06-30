import Foundation

enum AdjacencyMode {
    case orthogonal   // 4 directions (kids)
    case all8         // 8 directions (medium+)
}

enum Difficulty: String, CaseIterable, Identifiable {
    case kids, medium, hard, expert
    var id: String { rawValue }

    var config: DifficultyConfig {
        switch self {
        case .kids:   return DifficultyConfig(rows: 4, cols: 4, adjacency: .orthogonal, minWordLength: 3, pressureRate: 0,   dictionaryTier: .simple)
        case .medium: return DifficultyConfig(rows: 6, cols: 6, adjacency: .all8,       minWordLength: 3, pressureRate: 0,   dictionaryTier: .standard)
        case .hard:   return DifficultyConfig(rows: 8, cols: 8, adjacency: .all8,       minWordLength: 3, pressureRate: 0.3, dictionaryTier: .standard)
        case .expert: return DifficultyConfig(rows: 8, cols: 8, adjacency: .all8,       minWordLength: 4, pressureRate: 0.6, dictionaryTier: .full)
        }
    }

    var displayName: String {
        switch self {
        case .kids:   return "Kids"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        case .expert: return "Expert"
        }
    }
}

enum DictionaryTier { case simple, standard, full }

struct DifficultyConfig {
    let rows: Int
    let cols: Int
    let adjacency: AdjacencyMode
    let minWordLength: Int
    let pressureRate: Double  // new tiles per second from edges (0 = no pressure)
    let dictionaryTier: DictionaryTier

    var adjacentDirections: [Direction] {
        adjacency == .orthogonal ? Direction.cardinal : Direction.allCases
    }
}
