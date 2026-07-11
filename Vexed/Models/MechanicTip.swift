import Foundation

/// A one-time contextual explanation shown the first time a mechanic actually appears in live
/// play. Follows the onboarding research's headline principle — progressive disclosure: teach one
/// mechanic at a time, in-context, at the moment it becomes relevant, rather than dumping
/// everything in an up-front tutorial. Each tip fires at most once per install (tracked in
/// UserDefaults), and only one shows at a time (see `GameEngine.offerTip`).
enum MechanicTip: String, CaseIterable, Identifiable {
    case forge
    case locked
    case multiplier
    case combo
    case doublePlay

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .forge:      return "🔨"
        case .locked:     return "🔒"
        case .multiplier: return "⭐️"
        case .combo:      return "🔥"
        case .doublePlay: return "⚡️"
        }
    }

    var title: String {
        switch self {
        case .forge:      return "Tile Forge"
        case .locked:     return "Locked Tile"
        case .multiplier: return "Multiplier Tile"
        case .combo:      return "Combo!"
        case .doublePlay: return "Double Play"
        }
    }

    var body: String {
        switch self {
        case .forge:      return "Scoring longer words forges fresh bonus tiles onto the board."
        case .locked:     return "This tile can't join a word yet — slide a tile next to it twice to free it."
        case .multiplier: return "Score a word through this star tile to double its points."
        case .combo:      return "Score on back-to-back moves to build a combo — up to ×3 points."
        case .doublePlay: return "You collected a row and column word at once — bonus points!"
        }
    }

    private var seenKey: String { "mechanicTipSeen.\(rawValue)" }
    var hasBeenSeen: Bool { UserDefaults.standard.bool(forKey: seenKey) }
    func markSeen() { UserDefaults.standard.set(true, forKey: seenKey) }

    /// Test/debug helper — clears all first-encounter flags so tips fire again.
    static func resetAllSeen() {
        for tip in MechanicTip.allCases {
            UserDefaults.standard.removeObject(forKey: "mechanicTipSeen.\(tip.rawValue)")
        }
    }
}
