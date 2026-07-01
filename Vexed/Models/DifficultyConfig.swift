import Foundation
import UIKit

enum AdjacencyMode {
    case orthogonal   // 4 directions (kids)
    case all8         // 8 directions (medium+)
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy, medium, hard, fill
    var id: String { rawValue }

    var config: DifficultyConfig {
        switch self {
        // Forge tiles = max(0, wordLength − forgeMinLength), uncapped and increasing.
        case .easy:   return DifficultyConfig(rows: 5,  cols: 5,  adjacency: .orthogonal, minWordLength: 3, wordListName: "easy_words",   wordListNameFull: "easy_words", forgeMinLength: 1)
        case .medium: return DifficultyConfig(rows: 7,  cols: 7,  adjacency: .orthogonal, minWordLength: 3, wordListName: "medium_words", wordListNameFull: "words",       forgeMinLength: 2)
        case .hard:   return DifficultyConfig.hardConfig()
        case .fill:   return DifficultyConfig.fillConfig()
        }
    }

    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        case .fill:   return "Fill"
        }
    }

    /// Label used in kid mode (hides Hard; renames boards by size)
    var kidDisplayName: String {
        switch self {
        case .easy:   return "Small"
        case .medium: return "Medium"
        case .fill:   return "Full"
        case .hard:   return "Hard"   // not shown in kid mode, but needs a value
        }
    }

    /// Human-readable description shown below the splash difficulty pill in kid mode
    var kidDescription: String {
        switch self {
        case .easy:   return "5×5 · Short words welcome"
        case .medium: return "7×7 · Growing challenge"
        case .fill:   return "\(DifficultyConfig.fillConfig().cols)×screen · Packed & playful"
        case .hard:   return description
        }
    }

    var description: String {
        let c = DifficultyConfig.fillConfig()
        switch self {
        case .easy:   return "5×5 · Learn the ropes"
        case .medium: return "7×7 · The sweet spot"
        case .hard:   return "9×\(DifficultyConfig.hardConfig().rows) · Chain or perish"
        case .fill:   return "\(c.cols)×\(c.rows) · Pack the screen"
        }
    }
}

struct DifficultyConfig {
    let rows: Int
    let cols: Int
    let adjacency: AdjacencyMode
    var minWordLength: Int
    var wordListName: String       // default (clean, no archaic/rare words)
    let wordListNameFull: String   // when "include rare words" toggle is on
    /// Forge tiles = max(0, wordLength − forgeMinLength), uncapped.
    let forgeMinLength: Int
    /// If > 0, forge bonus is this flat value instead of the length formula.
    var flatForgeBonus: Int = 0

    func activeWordList(includeRare: Bool) -> String {
        includeRare ? wordListNameFull : wordListName
    }

    var adjacentDirections: [Direction] { Direction.cardinal }

    func forgeBonusCount(wordLength: Int) -> Int {
        flatForgeBonus > 0 ? flatForgeBonus : max(0, wordLength - forgeMinLength)
    }

    /// Computes a screen-filling config for Hard: 9-col minimum, 4-letter min, forge-3.
    /// Columns scale with screen width to keep tiles near a target size (~46pt).
    static func hardConfig() -> DifficultyConfig {
        let screen = UIScreen.main.bounds
        let gap: CGFloat     = 6
        let gridPad: CGFloat = 10
        let gamePad: CGFloat = 10
        let availW = screen.width - gamePad * 2

        let targetTileW: CGFloat = 46
        let rawCols = Int(floor((availW - gridPad * 2 + gap) / (targetTileW + gap)))
        let cols = max(9, min(18, rawCols))
        let tileW = (availW - gridPad * 2 - gap * CGFloat(cols - 1)) / CGFloat(cols)

        let nonGrid: CGFloat = 226
        let safeBottom = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom) ?? 34
        let availH = screen.height - nonGrid - safeBottom

        let rows = max(9, Int(floor((availH - gridPad * 2 + gap) / (tileW + gap))))

        return DifficultyConfig(
            rows: rows, cols: cols,
            adjacency: .orthogonal,
            minWordLength: 4,
            wordListName: "medium_words",
            wordListNameFull: "dictionary",
            forgeMinLength: 3
        )
    }

    /// Computes a grid config that fills the screen.
    /// Columns scale with screen width to keep tiles near a target size (~56pt),
    /// so iPad gets more columns + more rows rather than giant sparse tiles.
    static func fillConfig() -> DifficultyConfig {
        let screen = UIScreen.main.bounds
        let gap: CGFloat     = 6
        let gridPad: CGFloat = 10
        let gamePad: CGFloat = 10
        let availW = screen.width - gamePad * 2

        // Derive columns so tiles stay close to targetTileW across all device sizes
        let targetTileW: CGFloat = 56
        let rawCols = Int(floor((availW - gridPad * 2 + gap) / (targetTileW + gap)))
        let cols = max(7, min(16, rawCols))
        let tileW = (availW - gridPad * 2 - gap * CGFloat(cols - 1)) / CGFloat(cols)

        // Non-grid UI: top bar + vowel radar + footer + bottom safe area
        let nonGrid: CGFloat = 226
        let safeBottom = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom) ?? 34
        let availH = screen.height - nonGrid - safeBottom

        let rows = max(7, Int(floor((availH - gridPad * 2 + gap) / (tileW + gap))))

        return DifficultyConfig(
            rows: rows, cols: cols,
            adjacency: .orthogonal,
            minWordLength: 3,
            wordListName: "medium_words",
            wordListNameFull: "dictionary",
            forgeMinLength: 2
        )
    }
}
