import SwiftUI

struct GameTheme {
    let style: AppTheme
    private var isFun: Bool { style == .fun }
    private var isArcade: Bool { style == .arcade }

    // MARK: - Background
    var bgBase: Color {
        switch style {
        case .arcade:  return Color(red: 0.02, green: 0.0, blue: 0.07)
        case .fun:     return Color(red: 0.68, green: 0.88, blue: 1.0)
        case .regular: return Color(red: 0.06, green: 0.06, blue: 0.09)
        }
    }
    var bgBreathColor: Color {
        switch style {
        case .arcade:  return Color(red: 1.0, green: 0.0, blue: 0.75)   // hot neon magenta pulse
        case .fun:     return Color(red: 0.55, green: 0.20, blue: 1.0)  // violet shimmer over sky blue
        case .regular: return Color(red: 0.12, green: 0.08, blue: 0.18)
        }
    }
    var bgBreathOpacityHigh: Double { isArcade ? 0.65 : isFun ? 0.20 : 0.40 }
    var bgBreathOpacityLow: Double  { isArcade ? 0.25 : isFun ? 0.05 : 0.15 }
    /// Always show corner glows in fun mode (cheerful) and arcade mode (neon)
    var showCornerGlows: Bool { isArcade || isFun }
    /// Fun: hot pink top-right + lime green bottom-left; arcade: electric cyan + neon magenta
    var cornerGlowColors: (topRight: Color, bottomLeft: Color) {
        switch style {
        case .arcade:  return (Color(red: 0.0, green: 1.0, blue: 1.0),   Color(red: 1.0, green: 0.0, blue: 0.85))
        case .fun:     return (Color(red: 1.0, green: 0.35, blue: 0.70), Color(red: 0.20, green: 0.85, blue: 0.45))
        case .regular: return (Color(red: 0.55, green: 0.1, blue: 0.9),  Color(red: 0.0,  green: 0.7,  blue: 0.8))
        }
    }
    var cornerGlowOpacity: (topRight: Double, bottomLeft: Double) {
        isArcade ? (0.65, 0.55) : isFun ? (0.55, 0.45) : (0.35, 0.22)
    }
    /// Arcade only: faint horizontal scanline overlay for CRT-cabinet flavor
    var showScanlines: Bool { isArcade }

    // MARK: - Tile face
    var consonantBase: Color {
        switch style {
        case .arcade:  return Color(red: 0.24, green: 0.02, blue: 0.42)   // deep neon purple
        case .fun:     return Color(red: 0.18, green: 0.44, blue: 0.90)   // vivid cobalt blue — white text still reads fine
        case .regular: return Color(red: 0.165, green: 0.165, blue: 0.243)
        }
    }
    /// Arcade tiles get a neon-cyan outline that glows regardless of letter type
    var neonTileBorder: Color? { isArcade ? Color(red: 0.0, green: 1.0, blue: 0.95) : nil }
    var tileHighlightOpacity: Double { isArcade ? 0.70 : isFun ? 0.65 : 0.40 }
    var tileHighlightStop: Double    { 0.28 }   // fade to clear by top 28% — keeps bevel off the letter
    var tileShadowOpacity: Double    { isArcade ? 0.45 : isFun ? 0.20 : 0.30 }
    var tileBorderWidth: CGFloat     { isArcade ? 2.5 : isFun ? 2.5 : 1.5 }
    var showGlossStripe: Bool        { isArcade || isFun }

    // MARK: - Score stat bar
    var scoreFont: Font {
        switch style {
        case .arcade:  return .system(size: 21, weight: .black, design: .monospaced)   // LED-scoreboard feel
        case .fun:     return .system(size: 22, weight: .black, design: .rounded)
        case .regular: return .system(size: 18, weight: .black, design: .monospaced)
        }
    }
    var scoreTracking: CGFloat { isArcade ? 1.5 : 0 }
    var statLabelFont: Font {
        switch style {
        case .arcade:  return .system(size: 9, weight: .heavy, design: .monospaced)
        case .fun:     return .system(size: 9, weight: .black, design: .rounded)
        case .regular: return .system(size: 8, weight: .semibold)
        }
    }
    var statLabelTracking: CGFloat { isArcade ? 2.0 : isFun ? 1.0 : 1.0 }
    var statLabelColor: Color {
        switch style {
        case .arcade:  return Color(red: 0.55, green: 0.95, blue: 1.0)
        case .fun:     return Color(red: 0.10, green: 0.25, blue: 0.50)
        case .regular: return Color(white: 0.30)
        }
    }
    var statBgOpacity: Double      { isArcade ? 0.22 : isFun ? 0.22 : 0.0 }
    var statCornerRadius: CGFloat  { (isArcade || isFun) ? 10 : 0 }
    func statBgColor(for label: String) -> Color {
        switch label {
        case "SCORE":  return isFun ? Color(red: 1.0, green: 0.85, blue: 0.2) : isArcade ? Color(red: 1.0, green: 0.0, blue: 0.85) : .white
        case "WORDS":  return isArcade ? Color(red: 0.0, green: 1.0, blue: 1.0) : Color(red: 0.3, green: 0.9, blue: 1.0)
        case "FORGED": return isArcade ? Color(red: 0.6, green: 0.3, blue: 1.0) : Color(red: 0.4, green: 0.85, blue: 1.0)
        case "LOST":   return Color(red: 1.0, green: 0.35, blue: 0.35)
        case "STARS":  return Color(red: 1.0, green: 0.85, blue: 0.2)
        default:       return .white
        }
    }

    // MARK: - Word history chips
    var chipCornerRadius: CGFloat { isArcade ? 16 : isFun ? 20 : 10 }
    var chipFont: Font {
        switch style {
        case .arcade:  return .system(size: 12, weight: .black, design: .monospaced)
        case .fun:     return .system(size: 13, weight: .black, design: .rounded)
        case .regular: return .system(size: 11, weight: .bold,  design: .rounded)
        }
    }
    var chipPointsFont: Font {
        switch style {
        case .arcade:  return .system(size: 10, weight: .heavy, design: .monospaced)
        case .fun:     return .system(size: 11, weight: .black, design: .rounded)
        case .regular: return .system(size: 10, weight: .semibold, design: .monospaced)
        }
    }
    var chipPaddingH: CGFloat { isArcade ? 13 : isFun ? 14 : 8 }
    var chipPaddingV: CGFloat { isArcade ? 6  : isFun ? 7  : 5 }
    /// Neon border stroke for arcade chips — nil elsewhere (no extra stroke)
    func chipBorder(forWordLength n: Int) -> Color? {
        guard isArcade else { return nil }
        if n >= 5 { return Color(red: 1.0, green: 0.0, blue: 0.85) }
        if n >= 4 { return Color(red: 0.0, green: 1.0, blue: 1.0) }
        return Color(red: 0.6, green: 0.3, blue: 1.0)
    }
    func chipBg(forWordLength n: Int) -> AnyShapeStyle {
        if isFun {
            if n >= 5 { return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 1.0, green: 0.55, blue: 0.05), Color(red: 0.95, green: 0.15, blue: 0.55)],
                startPoint: .topLeading, endPoint: .bottomTrailing)) }  // orange → pink
            if n >= 4 { return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.15, green: 0.75, blue: 0.35), Color(red: 0.05, green: 0.55, blue: 0.90)],
                startPoint: .topLeading, endPoint: .bottomTrailing)) }  // green → blue
            return AnyShapeStyle(Color(red: 0.20, green: 0.45, blue: 0.90).opacity(0.85))
        }
        if isArcade {
            if n >= 5 { return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.45, green: 0.0, blue: 0.35), Color(red: 0.15, green: 0.0, blue: 0.30)],
                startPoint: .topLeading, endPoint: .bottomTrailing)) }  // neon magenta glow
            if n >= 4 { return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.0, green: 0.30, blue: 0.35), Color(red: 0.0, green: 0.12, blue: 0.28)],
                startPoint: .topLeading, endPoint: .bottomTrailing)) }  // neon cyan glow
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.20, green: 0.05, blue: 0.35), Color(red: 0.10, green: 0.02, blue: 0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing))   // neon violet glow
        }
        return AnyShapeStyle(Color(white: 0.10))
    }

    // MARK: - Toast
    var toastFont: Font {
        switch style {
        case .arcade:  return .system(size: 26, weight: .black, design: .monospaced)
        case .fun:     return .system(size: 30, weight: .black, design: .rounded)
        case .regular: return .system(size: 22, weight: .black, design: .rounded)
        }
    }
    var toastPaddingH: CGFloat     { isArcade ? 30 : isFun ? 36 : 24 }
    var toastPaddingV: CGFloat     { isArcade ? 15 : isFun ? 18 : 12 }
    var toastCornerRadius: CGFloat { isArcade ? 20 : isFun ? 26 : 16 }
    var toastFill: AnyShapeStyle {
        switch style {
        case .fun:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 1.0, green: 0.9, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .arcade:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 1.0, green: 0.0, blue: 0.85), Color(red: 0.0, green: 0.9, blue: 1.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .regular:
            return AnyShapeStyle(Color.yellow)
        }
    }

    // MARK: - Forge banner
    var forgeBannerFont: Font {
        switch style {
        case .arcade:  return .system(size: 15, weight: .black, design: .monospaced)
        case .fun:     return .system(size: 16, weight: .black, design: .rounded)
        case .regular: return .system(size: 14, weight: .black, design: .rounded)
        }
    }
    var forgeBannerFill: AnyShapeStyle {
        switch style {
        case .fun:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.2, green: 0.95, blue: 0.5), Color(red: 0.0, green: 0.78, blue: 0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .arcade:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.0, green: 1.0, blue: 0.6), Color(red: 0.0, green: 0.55, blue: 1.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .regular:
            return AnyShapeStyle(Color(red: 0.3, green: 0.9, blue: 1.0))
        }
    }
    var forgeBannerRadius: CGFloat { isArcade ? 14 : isFun ? 16 : 10 }

    // MARK: - Vanish banner
    var vanishBannerFont: Font {
        switch style {
        case .arcade:  return .system(size: 16, weight: .black, design: .monospaced)
        case .fun:     return .system(size: 16, weight: .black, design: .rounded)
        case .regular: return .system(size: 15, weight: .black, design: .rounded)
        }
    }
    var vanishBannerFill: AnyShapeStyle {
        switch style {
        case .arcade:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 1.0, green: 0.0, blue: 0.3), Color(red: 1.0, green: 0.5, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        default:
            return AnyShapeStyle(Color(red: 0.85, green: 0.15, blue: 0.15))
        }
    }
    var vanishBannerRadius: CGFloat { isArcade ? 16 : 12 }
}
