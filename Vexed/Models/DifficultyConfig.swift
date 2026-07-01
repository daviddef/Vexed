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
        // Forge tiles = max(0, wordLength − forgeMinLength), uncapped and increasing.
        // Each difficulty step raises the threshold by 1 letter:
        //   Easy   (min=1): 3→+2, 4→+3, 5→+4, 6→+5 …
        //   Medium (min=2): 3→+1, 4→+2, 5→+3, 6→+4, 7→+5 …
        //   Hard   (min=3): 4→+1, 5→+2, 6→+3, 7→+4 … (min word length 4)
        case .easy:   return DifficultyConfig(rows: 5,  cols: 5,  adjacency: .orthogonal, minWordLength: 3, wordListName: "easy_words", forgeMinLength: 1)
        case .medium: return DifficultyConfig(rows: 7,  cols: 7,  adjacency: .orthogonal, minWordLength: 3, wordListName: "words",       forgeMinLength: 2)
        case .hard:   return DifficultyConfig(rows: 10, cols: 10, adjacency: .orthogonal, minWordLength: 4, wordListName: "dictionary",   forgeMinLength: 3)
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
    /// Forge tiles = max(0, wordLength − forgeMinLength), uncapped.
    let forgeMinLength: Int

    var adjacentDirections: [Direction] { Direction.cardinal }

    func forgeBonusCount(wordLength: Int) -> Int {
        max(0, wordLength - forgeMinLength)
    }
}
