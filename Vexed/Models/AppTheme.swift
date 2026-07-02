import SwiftUI

/// Visual theme — independent from game Mode (Kid/Adult). Mode picks difficulty & assistance;
/// Theme picks the look. Kid mode defaults to `.fun`, Adult mode defaults to `.regular`, but once
/// the player explicitly picks a theme it sticks regardless of mode (see `themeIsUserSet` in GameView).
enum AppTheme: String, CaseIterable, Identifiable {
    case regular
    case fun
    case arcade

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .regular: return "Regular"
        case .fun:     return "Fun"
        case .arcade:  return "Arcade"
        }
    }

    var subtitle: String {
        switch self {
        case .regular: return "Clean dark look\nfocused gameplay"
        case .fun:     return "Bright & bouncy\nrainbow colours"
        case .arcade:  return "Neon lights\nretro cabinet vibes"
        }
    }

    var icon: String {
        switch self {
        case .regular: return "moon.stars.fill"
        case .fun:     return "sun.max.fill"
        case .arcade:  return "gamecontroller.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .regular: return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .fun:     return Color(red: 1.0, green: 0.55, blue: 0.75)
        case .arcade:  return Color(red: 0.0, green: 1.0, blue: 0.9)
        }
    }
}
