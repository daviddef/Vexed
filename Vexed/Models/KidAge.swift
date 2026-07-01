import Foundation

enum KidAge: String, CaseIterable, Identifiable {
    case little      // 5–7
    case explorer    // 8–10
    case challenger  // 11+

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .little:      return "Little"
        case .explorer:    return "Explorer"
        case .challenger:  return "Challenger"
        }
    }

    var ageRange: String {
        switch self {
        case .little:      return "5–7"
        case .explorer:    return "8–10"
        case .challenger:  return "11+"
        }
    }

    var emoji: String {
        switch self {
        case .little:      return "🌟"
        case .explorer:    return "🧭"
        case .challenger:  return "⚡"
        }
    }

    var minWordLength: Int {
        switch self {
        case .little:      return 2
        case .explorer:    return 3
        case .challenger:  return 3
        }
    }

    /// 0 = use standard formula (word length − forgeMinLength). Positive = flat bonus per word.
    var flatForgeBonus: Int {
        switch self {
        case .little:      return 4
        case .explorer:    return 3
        case .challenger:  return 0
        }
    }

    /// Idle seconds before phase-1 hint (gold outline glow). 0 = no auto-hint.
    var hintDelay: Double {
        switch self {
        case .little:      return 8
        case .explorer:    return 14
        case .challenger:  return 0
        }
    }

    /// Idle seconds before phase-2 hint (tap beacon). 0 = no beacon.
    var beaconDelay: Double {
        switch self {
        case .little:      return 16
        case .explorer:    return 26
        case .challenger:  return 0
        }
    }

    var wordListName: String {
        switch self {
        case .little:      return "kid_words"
        case .explorer:    return "easy_words"
        case .challenger:  return "medium_words"
        }
    }
}
