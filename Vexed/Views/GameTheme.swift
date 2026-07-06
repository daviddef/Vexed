import SwiftUI

struct GameTheme {
    let style: AppTheme
    private var isFun: Bool { style == .fun }
    private var isArcade: Bool { style == .arcade }
    private var isLight: Bool { style == .light }
    /// Fun/Arcade/Light all lean into a decorated, chunky, playful look — Regular stays minimal.
    private var isDecorated: Bool { isFun || isArcade || isLight }

    // MARK: - Background
    var bgBase: Color {
        switch style {
        case .arcade:  return Color(red: 0.02, green: 0.0, blue: 0.07)
        case .light:   return Color(red: 0.96, green: 0.97, blue: 1.0)   // soft cool white, not clinical flat white
        case .fun:     return Color(red: 0.68, green: 0.88, blue: 1.0)
        case .regular: return Color(red: 0.06, green: 0.06, blue: 0.09)
        }
    }
    var bgBreathColor: Color {
        switch style {
        case .arcade:  return Color(red: 1.0, green: 0.0, blue: 0.75)   // hot neon magenta pulse
        case .light:   return Color(red: 0.55, green: 0.60, blue: 1.0)  // soft lavender shimmer
        case .fun:     return Color(red: 0.55, green: 0.20, blue: 1.0)  // violet shimmer over sky blue
        case .regular: return Color(red: 0.12, green: 0.08, blue: 0.18)
        }
    }
    var bgBreathOpacityHigh: Double { isArcade ? 0.65 : isLight ? 0.10 : isFun ? 0.20 : 0.40 }
    var bgBreathOpacityLow: Double  { isArcade ? 0.25 : isLight ? 0.03 : isFun ? 0.05 : 0.15 }
    /// Always show corner glows in fun/arcade (cheerful/neon); Light keeps a very soft touch
    var showCornerGlows: Bool { isArcade || isFun || isLight }
    /// Fun: hot pink top-right + lime green bottom-left; arcade: electric cyan + neon magenta;
    /// Light: soft pastel blue + pink, barely-there depth on a white board
    var cornerGlowColors: (topRight: Color, bottomLeft: Color) {
        switch style {
        case .arcade:  return (Color(red: 0.0, green: 1.0, blue: 1.0),   Color(red: 1.0, green: 0.0, blue: 0.85))
        case .light:   return (Color(red: 1.0, green: 0.75, blue: 0.55), Color(red: 0.55, green: 0.75, blue: 1.0))
        case .fun:     return (Color(red: 1.0, green: 0.35, blue: 0.70), Color(red: 0.20, green: 0.85, blue: 0.45))
        case .regular: return (Color(red: 0.55, green: 0.1, blue: 0.9),  Color(red: 0.0,  green: 0.7,  blue: 0.8))
        }
    }
    var cornerGlowOpacity: (topRight: Double, bottomLeft: Double) {
        switch style {
        case .arcade:  return (0.65, 0.55)
        case .light:   return (0.18, 0.15)
        case .fun:     return (0.55, 0.45)
        case .regular: return (0.35, 0.22)
        }
    }
    /// Arcade only: faint horizontal scanline overlay for CRT-cabinet flavor
    var showScanlines: Bool { isArcade }

    // MARK: - Tile face
    var consonantBase: Color {
        switch style {
        case .arcade:  return Color(red: 0.24, green: 0.02, blue: 0.42)   // deep neon purple
        case .light:   return Color(red: 0.20, green: 0.26, blue: 0.58)   // rich indigo — strong contrast on white
        case .fun:     return Color(red: 0.18, green: 0.44, blue: 0.90)   // vivid cobalt blue — white text still reads fine
        case .regular: return Color(red: 0.165, green: 0.165, blue: 0.243)
        }
    }
    /// Arcade tiles get a neon-cyan outline that glows regardless of letter type
    var neonTileBorder: Color? { isArcade ? Color(red: 0.0, green: 1.0, blue: 0.95) : nil }
    var tileHighlightOpacity: Double { isArcade ? 0.70 : isLight ? 0.60 : isFun ? 0.65 : 0.40 }
    var tileHighlightStop: Double    { 0.28 }   // fade to clear by top 28% — keeps bevel off the letter
    /// Light theme uses soft, shallow shadows — heavy dark drop-shadows read muddy on a white board
    var tileShadowOpacity: Double    { isArcade ? 0.45 : isLight ? 0.16 : isFun ? 0.20 : 0.30 }
    var tileBorderWidth: CGFloat     { isDecorated ? 2.5 : 1.5 }
    var showGlossStripe: Bool        { isDecorated }

    // MARK: - Score stat bar
    var scoreFont: Font {
        switch style {
        case .arcade:  return .system(size: 21, weight: .black, design: .monospaced)   // LED-scoreboard feel
        case .light:   return .system(size: 22, weight: .black, design: .rounded)
        case .fun:     return .system(size: 22, weight: .black, design: .rounded)
        case .regular: return .system(size: 18, weight: .black, design: .monospaced)
        }
    }
    var scoreTracking: CGFloat { isArcade ? 1.5 : 0 }
    var statLabelFont: Font {
        switch style {
        case .arcade:  return .system(size: 9, weight: .heavy, design: .monospaced)
        case .light:   return .system(size: 9, weight: .black, design: .rounded)
        case .fun:     return .system(size: 9, weight: .black, design: .rounded)
        case .regular: return .system(size: 8, weight: .semibold)
        }
    }
    var statLabelTracking: CGFloat { isArcade ? 2.0 : 1.0 }
    /// Dark text on a light background — same legibility fix Fun theme needed against sky-blue.
    var statLabelColor: Color {
        switch style {
        case .arcade:  return Color(red: 0.55, green: 0.95, blue: 1.0)
        case .light:   return Color(red: 0.20, green: 0.20, blue: 0.35)
        case .fun:     return Color(red: 0.10, green: 0.25, blue: 0.50)
        case .regular: return Color(white: 0.55)
        }
    }
    var statBgOpacity: Double      { isArcade ? 0.22 : isLight ? 0.16 : isFun ? 0.22 : 0.0 }
    var statCornerRadius: CGFloat  { isDecorated ? 10 : 0 }
    func statBgColor(for label: String) -> Color {
        switch label {
        case "SCORE":
            if isFun { return Color(red: 1.0, green: 0.85, blue: 0.2) }
            if isArcade { return Color(red: 1.0, green: 0.0, blue: 0.85) }
            if isLight { return Color(red: 0.95, green: 0.60, blue: 0.10) }
            return .white
        case "WORDS":  return isArcade ? Color(red: 0.0, green: 1.0, blue: 1.0) : Color(red: 0.3, green: 0.9, blue: 1.0)
        case "FORGED": return isArcade ? Color(red: 0.6, green: 0.3, blue: 1.0) : Color(red: 0.4, green: 0.85, blue: 1.0)
        case "LOST":   return Color(red: 1.0, green: 0.35, blue: 0.35)
        case "STARS":  return Color(red: 1.0, green: 0.85, blue: 0.2)
        default:       return .white
        }
    }

    // MARK: - Word history chips
    var chipCornerRadius: CGFloat { isArcade ? 16 : isDecorated ? 20 : 10 }
    var chipFont: Font {
        switch style {
        case .arcade:  return .system(size: 12, weight: .black, design: .monospaced)
        case .light:   return .system(size: 13, weight: .black, design: .rounded)
        case .fun:     return .system(size: 13, weight: .black, design: .rounded)
        case .regular: return .system(size: 11, weight: .bold,  design: .rounded)
        }
    }
    var chipPointsFont: Font {
        switch style {
        case .arcade:  return .system(size: 10, weight: .heavy, design: .monospaced)
        case .light:   return .system(size: 11, weight: .black, design: .rounded)
        case .fun:     return .system(size: 11, weight: .black, design: .rounded)
        case .regular: return .system(size: 10, weight: .semibold, design: .monospaced)
        }
    }
    var chipPaddingH: CGFloat { isArcade ? 13 : isDecorated ? 14 : 8 }
    var chipPaddingV: CGFloat { isArcade ? 6  : isDecorated ? 7  : 5 }
    /// Neon border stroke for arcade chips, subtle dark outline for Light (definition on white) — nil elsewhere
    func chipBorder(forWordLength n: Int) -> Color? {
        if isArcade {
            if n >= 5 { return Color(red: 1.0, green: 0.0, blue: 0.85) }
            if n >= 4 { return Color(red: 0.0, green: 1.0, blue: 1.0) }
            return Color(red: 0.6, green: 0.3, blue: 1.0)
        }
        if isLight {
            return Color.black.opacity(0.08)
        }
        return nil
    }
    func chipBg(forWordLength n: Int) -> AnyShapeStyle {
        if isLight {
            // Flat, saturated candy-block colors — matches a white-board puzzle aesthetic where
            // color alone (not gradient sheen) carries the "fun" read.
            if n >= 5 { return AnyShapeStyle(Color(red: 1.0, green: 0.55, blue: 0.15)) }   // orange
            if n >= 4 { return AnyShapeStyle(Color(red: 0.20, green: 0.75, blue: 0.45)) }  // green
            return AnyShapeStyle(Color(red: 0.30, green: 0.55, blue: 1.0))                 // blue
        }
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
        case .light:   return .system(size: 28, weight: .black, design: .rounded)
        case .fun:     return .system(size: 30, weight: .black, design: .rounded)
        case .regular: return .system(size: 22, weight: .black, design: .rounded)
        }
    }
    var toastPaddingH: CGFloat     { isArcade ? 30 : isDecorated ? 36 : 24 }
    var toastPaddingV: CGFloat     { isArcade ? 15 : isDecorated ? 18 : 12 }
    var toastCornerRadius: CGFloat { isArcade ? 20 : isDecorated ? 26 : 16 }
    var toastFill: AnyShapeStyle {
        switch style {
        case .light:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 1.0, green: 0.75, blue: 0.15), Color(red: 1.0, green: 0.50, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
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
        case .light:   return .system(size: 16, weight: .black, design: .rounded)
        case .fun:     return .system(size: 16, weight: .black, design: .rounded)
        case .regular: return .system(size: 14, weight: .black, design: .rounded)
        }
    }
    var forgeBannerFill: AnyShapeStyle {
        switch style {
        case .light:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.25, green: 0.85, blue: 0.55), Color(red: 0.10, green: 0.65, blue: 0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
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
    var forgeBannerRadius: CGFloat { isArcade ? 14 : isDecorated ? 16 : 10 }

    // MARK: - Vanish banner
    var vanishBannerFont: Font {
        switch style {
        case .arcade:  return .system(size: 16, weight: .black, design: .monospaced)
        case .light:   return .system(size: 16, weight: .black, design: .rounded)
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
