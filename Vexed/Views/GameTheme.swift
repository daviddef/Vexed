import SwiftUI

struct GameTheme {
    let isArcade: Bool
    let isKid: Bool

    // MARK: - Background
    var bgBase: Color {
        isArcade ? Color(red: 0.03, green: 0.01, blue: 0.12)
        : isKid  ? Color(red: 0.04, green: 0.04, blue: 0.10)
                 : Color(red: 0.06, green: 0.06, blue: 0.09)
    }
    var bgBreathColor: Color {
        isArcade ? Color(red: 0.38, green: 0.06, blue: 0.80)
        : isKid  ? Color(red: 0.9,  green: 0.6,  blue: 0.0)   // warm golden pulse
                 : Color(red: 0.12, green: 0.08, blue: 0.18)
    }
    var bgBreathOpacityHigh: Double { isArcade ? 0.55 : isKid ? 0.30 : 0.40 }
    var bgBreathOpacityLow: Double  { isArcade ? 0.22 : isKid ? 0.08 : 0.15 }
    /// Always show corner glows in kid mode (cheerful) and arcade mode
    var showCornerGlows: Bool { isArcade || isKid }
    /// Kid mode: yellow top-right + green bottom-left; arcade: purple + teal
    var cornerGlowColors: (topRight: Color, bottomLeft: Color) {
        isKid
            ? (Color(red: 1.0, green: 0.85, blue: 0.0),   Color(red: 0.1, green: 0.9, blue: 0.4))
            : (Color(red: 0.55, green: 0.1, blue: 0.9),   Color(red: 0.0, green: 0.7, blue: 0.8))
    }
    var cornerGlowOpacity: (topRight: Double, bottomLeft: Double) {
        isKid ? (0.28, 0.22) : (0.35, 0.22)
    }

    // MARK: - Tile face
    var consonantBase: Color {
        isArcade ? Color(red: 0.18, green: 0.10, blue: 0.30)
        : isKid  ? Color(red: 0.20, green: 0.18, blue: 0.30)   // slightly warmer/lighter
                 : Color(red: 0.165, green: 0.165, blue: 0.243)
    }
    var tileHighlightOpacity: Double { isArcade ? 0.62 : isKid ? 0.58 : 0.45 }
    var tileHighlightStop: Double    { isArcade ? 0.55 : isKid ? 0.50 : 0.40 }
    var tileShadowOpacity: Double    { isArcade ? 0.40 : 0.30 }
    var tileBorderWidth: CGFloat     { isArcade ? 2.0  : isKid ? 2.0 : 1.5 }
    var showGlossStripe: Bool        { isArcade || isKid }

    // MARK: - Score stat bar
    var scoreFont: Font {
        isArcade ? .system(size: 20, weight: .black, design: .serif)
        : isKid  ? .system(size: 22, weight: .black, design: .rounded)
                 : .system(size: 18, weight: .black, design: .monospaced)
    }
    var statLabelFont: Font {
        isArcade ? .system(size: 9, weight: .heavy, design: .serif)
        : isKid  ? .system(size: 9, weight: .black, design: .rounded)
                 : .system(size: 8, weight: .semibold)
    }
    var statLabelTracking: CGFloat { isArcade ? 1.5 : isKid ? 1.0 : 1.0 }
    var statBgOpacity: Double      { (isArcade || isKid) ? 0.18 : 0.0 }
    var statCornerRadius: CGFloat  { (isArcade || isKid) ? 10 : 0 }
    func statBgColor(for label: String) -> Color {
        switch label {
        case "SCORE":  return isKid ? Color(red: 1.0, green: 0.85, blue: 0.2) : .white
        case "WORDS":  return Color(red: 0.3, green: 0.9, blue: 1.0)
        case "FORGED": return Color(red: 0.4, green: 0.85, blue: 1.0)
        case "LOST":   return Color(red: 1.0, green: 0.35, blue: 0.35)
        case "STARS":  return Color(red: 1.0, green: 0.85, blue: 0.2)
        default:       return .white
        }
    }

    // MARK: - Word history chips
    var chipCornerRadius: CGFloat { isArcade ? 16 : isKid ? 20 : 10 }
    var chipFont: Font {
        isArcade ? .system(size: 12, weight: .black, design: .serif)
        : isKid  ? .system(size: 13, weight: .black, design: .rounded)
                 : .system(size: 11, weight: .bold,  design: .rounded)
    }
    var chipPointsFont: Font {
        isArcade ? .system(size: 10, weight: .heavy, design: .serif)
        : isKid  ? .system(size: 11, weight: .black, design: .rounded)
                 : .system(size: 10, weight: .semibold, design: .monospaced)
    }
    var chipPaddingH: CGFloat { isArcade ? 12 : isKid ? 14 : 8 }
    var chipPaddingV: CGFloat { isArcade ? 6  : isKid ? 7  : 5 }
    func chipBg(forWordLength n: Int) -> AnyShapeStyle {
        if isKid {
            if n >= 5 { return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.38, green: 0.22, blue: 0.02), Color(red: 0.26, green: 0.18, blue: 0.02)],
                startPoint: .topLeading, endPoint: .bottomTrailing)) }
            if n >= 3 { return AnyShapeStyle(Color(red: 0.08, green: 0.14, blue: 0.28)) }
            return AnyShapeStyle(Color(red: 0.0, green: 0.22, blue: 0.12))  // 2-letter: green tint
        }
        if isArcade && n >= 6 {
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.38, green: 0.22, blue: 0.02), Color(red: 0.26, green: 0.18, blue: 0.02)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        if isArcade && n >= 5 { return AnyShapeStyle(Color(red: 0.05, green: 0.10, blue: 0.28)) }
        if n >= 6 { return AnyShapeStyle(Color(red: 0.22, green: 0.18, blue: 0.04)) }
        if n >= 5 { return AnyShapeStyle(Color(red: 0.06, green: 0.12, blue: 0.22)) }
        return AnyShapeStyle(isArcade ? Color(white: 0.12) : Color(white: 0.10))
    }

    // MARK: - Toast
    var toastFont: Font {
        isArcade ? .system(size: 26, weight: .black, design: .serif)
        : isKid  ? .system(size: 30, weight: .black, design: .rounded)
                 : .system(size: 22, weight: .black, design: .rounded)
    }
    var toastPaddingH: CGFloat     { isArcade ? 30 : isKid ? 36 : 24 }
    var toastPaddingV: CGFloat     { isArcade ? 15 : isKid ? 18 : 12 }
    var toastCornerRadius: CGFloat { isArcade ? 20 : isKid ? 26 : 16 }
    var toastFill: AnyShapeStyle {
        if isKid {
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 1.0, green: 0.9, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        return isArcade
            ? AnyShapeStyle(LinearGradient(
                colors: [Color(red: 1.0, green: 0.88, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            : AnyShapeStyle(Color.yellow)
    }

    // MARK: - Forge banner
    var forgeBannerFont: Font {
        isArcade ? .system(size: 15, weight: .black, design: .serif)
        : isKid  ? .system(size: 16, weight: .black, design: .rounded)
                 : .system(size: 14, weight: .black, design: .rounded)
    }
    var forgeBannerFill: AnyShapeStyle {
        isKid
            ? AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.2, green: 0.95, blue: 0.5), Color(red: 0.0, green: 0.78, blue: 0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            : isArcade
                ? AnyShapeStyle(LinearGradient(
                    colors: [Color(red: 0.0, green: 0.85, blue: 1.0), Color(red: 0.1, green: 0.6, blue: 0.95)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                : AnyShapeStyle(Color(red: 0.3, green: 0.9, blue: 1.0))
    }
    var forgeBannerRadius: CGFloat { isArcade ? 14 : isKid ? 16 : 10 }

    // MARK: - Vanish banner
    var vanishBannerFont: Font {
        isArcade ? .system(size: 16, weight: .black, design: .serif)
        : isKid  ? .system(size: 16, weight: .black, design: .rounded)
                 : .system(size: 15, weight: .black, design: .rounded)
    }
    var vanishBannerFill: AnyShapeStyle {
        isArcade
            ? AnyShapeStyle(LinearGradient(
                colors: [Color(red: 1.0, green: 0.15, blue: 0.15), Color(red: 0.7, green: 0.05, blue: 0.05)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            : AnyShapeStyle(Color(red: 0.85, green: 0.15, blue: 0.15))
    }
    var vanishBannerRadius: CGFloat { isArcade ? 16 : 12 }

    /// Minimum word length before the big celebration fires (rainbow burst + big word)
    var celebrationMinLength: Int { isKid ? 2 : 5 }
}
