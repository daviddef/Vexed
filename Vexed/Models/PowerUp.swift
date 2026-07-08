import Foundation

enum PowerUpKind: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case bomb
    case reveal

    var title: String {
        switch self {
        case .bomb: return "Bomb"
        case .reveal: return "Reveal"
        }
    }

    var subtitle: String {
        switch self {
        case .bomb: return "Remove one tile from the board"
        case .reveal: return "Instantly highlight a scoreable word"
        }
    }

    var emoji: String {
        switch self {
        case .bomb: return "💣"
        case .reveal: return "🔍"
        }
    }

    /// Charges granted per rewarded-ad watch.
    var rewardAmount: Int { 3 }
}
