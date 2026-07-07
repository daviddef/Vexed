import SwiftUI

struct TileCellView: View {
    let tile: Tile?
    let isSelected: Bool
    let size: CGFloat
    var isTouching: Bool = false
    // Path glow: non-nil when this empty cell is in the slide path of the selected tile
    var pathColor: Color? = nil
    var isDestination: Bool = false
    // Ghost preview (opt-in, Adult Mode): true when sliding the selected tile here would
    // immediately complete a word — surfaces the engine's own lookahead as a visible skill aid.
    var isScoringDestination: Bool = false
    // Kid mode hint: tile glows gold while hint is active
    var isHintTile: Bool = false
    // True when this tile is part of a 3+ same-vowel cluster about to vanish
    var isCriticalDanger: Bool = false
    // True when this tile is part of the word currently previewed (tap-to-highlight, tap again to collect)
    var isWordHighlighted: Bool = false
    // Non-nil on the first tile of an available word — shows its point value in the top-left corner
    var pointsBadge: Int? = nil

    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.regular.rawValue
    private var theme: GameTheme { GameTheme(style: AppTheme(rawValue: appThemeRaw) ?? .regular) }

    @State private var vanishRotation: Double = 0
    // Forge animation: scale pops in from 0; pulse (0→1) drives color brightness & glow
    @State private var forgeScale: CGFloat = 1.0
    @State private var forgePulse: CGFloat = 0.0
    // Hint animation: pulse (0→1) drives gold brightness & glow
    @State private var hintPulse: CGFloat = 0.0
    // Critical danger animation: pulse (0→1) drives border/glow/scale for at-risk tiles
    @State private var criticalPulse: CGFloat = 0.0
    // Word-highlight animation: pulse (0→1) drives glow for the previewed word
    @State private var wordHighlightPulse: CGFloat = 0.0

    private var isForged: Bool { tile?.animState == .forged }

    var body: some View {
        ZStack {
            if let tile {
                let base = baseColor(for: tile)
                let cr = size * 0.22

                // 1. Base fill
                RoundedRectangle(cornerRadius: cr)
                    .fill(base)

                // 2. Top-light overlay (3D bevel highlight) — hidden while forged (tile is white)
                if !isForged {
                    RoundedRectangle(cornerRadius: cr)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(theme.tileHighlightOpacity), location: 0),
                                    .init(color: Color.clear, location: theme.tileHighlightStop)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                    // 3. Bottom-shadow overlay
                    RoundedRectangle(cornerRadius: cr)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.clear, location: 0.60),
                                    .init(color: Color.black.opacity(theme.tileShadowOpacity), location: 1.0)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )

                    // 4. Arcade gloss stripe — sits in the rounded top-cap, well above the letter
                    if theme.showGlossStripe {
                        Capsule()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: size * 0.40, height: size * 0.055)
                            .offset(y: -(size * 0.34))
                            .blendMode(.plusLighter)
                    }
                }

                // 5. Border
                RoundedRectangle(cornerRadius: cr)
                    .strokeBorder(
                        isSelected ? Color.white
                            : isWordHighlighted ? Color(red: 1.0, green: 0.85, blue: 0.0)
                            : (isForged ? Color(white: 0.6)
                            : isCriticalDanger ? Color(red: 1.0, green: 0.15 + criticalPulse * 0.25, blue: 0.15)
                            : isHintTile ? Color(red: 1.0, green: 0.65, blue: 0.0)
                            : theme.neonTileBorder ?? darkenedColor(base, factor: 0.65)),
                        lineWidth: isSelected ? 3.5 : isWordHighlighted ? 3.0 : isCriticalDanger ? (2.5 + criticalPulse * 2.0) : isHintTile ? 2.5 : theme.tileBorderWidth
                    )

                // 6. Outer highlight — skip when forged
                if !isSelected && !isForged {
                    RoundedRectangle(cornerRadius: cr)
                        .stroke(Color.white.opacity(theme.showGlossStripe ? 0.35 : 0.25), lineWidth: 0.75)
                }

                // 7. Arcade neon glow ring — extra outer stroke to sell the CRT/neon look
                if theme.neonTileBorder != nil && !isSelected && !isForged && !isCriticalDanger && !isHintTile {
                    RoundedRectangle(cornerRadius: cr)
                        .stroke(theme.neonTileBorder!.opacity(0.5), lineWidth: 1)
                        .blur(radius: 1.5)
                }

                // Letter — dark on forged/hint tiles, white otherwise
                Text(String(tile.letter))
                    .font(.system(size: size * 0.50, weight: .black, design: .rounded))
                    .foregroundColor((isForged || isHintTile) ? Color(white: 0.08) : .white)
                    .shadow(color: (isForged || isHintTile) ? .clear : .black.opacity(0.4), radius: 1, x: 0, y: 1)

            } else {
                // Empty cell
                RoundedRectangle(cornerRadius: size * 0.22)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundColor(pathColor != nil ? pathColor!.opacity(0.5) : Color(white: 0.30))

                if let col = pathColor {
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(col.opacity(isDestination ? 0.18 : 0.08))
                }

                if isDestination, let col = pathColor {
                    Circle()
                        .fill(col.opacity(0.7))
                        .frame(width: size * 0.18, height: size * 0.18)
                }

                // Ghost preview: this direction would score if slid — a small sparkle badge
                // so the reward is visible before committing to the move.
                if isScoringDestination {
                    Image(systemName: "sparkles")
                        .font(.system(size: size * 0.28, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.0))
                        .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.8), radius: 6, x: 0, y: 0)
                }
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isForged ? forgeScale : (isTouching ? 1.10 : scaleFor(tile?.animState)))
        .rotationEffect(.degrees(tile?.animState == .vanishing ? vanishRotation : 0))
        .opacity(tile?.animState == .vanishing ? 0 : 1)
        // White pulse glow — driven by forgePulse (CGFloat 0→1)
        .shadow(color: Color.white.opacity(forgePulse * 0.85), radius: forgePulse * 28, x: 0, y: 0)
        // Gold pulse glow — driven by hintPulse (CGFloat 0→1)
        .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(isHintTile ? hintPulse * 0.75 : 0), radius: isHintTile ? hintPulse * 22 : 0, x: 0, y: 0)
        // Red pulse glow for tiles about to vanish (3+ same-vowel cluster) — driven by criticalPulse (CGFloat 0→1)
        .shadow(color: Color(red: 1.0, green: 0.1, blue: 0.1).opacity(isCriticalDanger ? 0.4 + criticalPulse * 0.5 : 0),
                radius: isCriticalDanger ? 10 + criticalPulse * 16 : 0, x: 0, y: 0)
        .scaleEffect(isCriticalDanger ? 1.0 + criticalPulse * 0.06 : 1.0)
        // Bright yellow glow for the previewed word — driven by wordHighlightPulse (CGFloat 0→1)
        .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.0).opacity(isWordHighlighted ? 0.55 + wordHighlightPulse * 0.3 : 0),
                radius: isWordHighlighted ? 12 + wordHighlightPulse * 8 : 0, x: 0, y: 0)
        .overlay(alignment: .topLeading) {
            if let pts = pointsBadge, tile != nil {
                Text("+\(pts)")
                    .font(.system(size: max(8, size * 0.15), weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.0))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 4))
                    .padding(3)
                    .allowsHitTesting(false)
            }
        }
        // Ambient neon glow — arcade theme only
        .shadow(color: (theme.neonTileBorder ?? .clear).opacity(!isSelected && !isCriticalDanger && !isHintTile ? 0.45 : 0), radius: 6, x: 0, y: 0)
        .shadow(color: dropShadowColor, radius: 8, x: 0, y: 5)
        .shadow(color: isTouching ? touchGlowColor : dangerGlowColor,
                radius: isTouching ? 18 : (isDanger ? 14 : 0))
        .shadow(color: pathColor?.opacity(isDestination ? 0.85 : 0.45) ?? .clear,
                radius: isDestination ? 12 : 6, x: 0, y: 0)
        .rotation3DEffect(
            .degrees(tile != nil && isSelected ? -8 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.4
        )
        .scaleEffect(tile != nil && isSelected ? 1.08 : 1.0)
        .shadow(
            color: tile != nil && isSelected ? baseColor(for: tile!).opacity(0.7) : .clear,
            radius: tile != nil && isSelected ? 20 : 0,
            x: 0, y: tile != nil && isSelected ? 8 : 0
        )
        .animation(.spring(response: 0.18, dampingFraction: 0.55), value: isSelected)
        .animation(.spring(response: 0.12, dampingFraction: 0.55), value: isTouching)
        .animation(.easeInOut(duration: 0.25), value: pathColor != nil)
        // Springy pop instead of flat ease — impact moments (score/vanish) read punchier with a
        // touch of overshoot than a linear-feeling ease curve.
        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: tile?.animState)
        .onAppear {
            if isHintTile {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    hintPulse = 1.0
                }
            }
            if isCriticalDanger {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                    criticalPulse = 1.0
                }
            }
            if isWordHighlighted {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    wordHighlightPulse = 1.0
                }
            }
        }
        .onChange(of: isCriticalDanger) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                    criticalPulse = 1.0
                }
            } else {
                withAnimation(.easeOut(duration: 0.25)) {
                    criticalPulse = 0.0
                }
            }
        }
        .onChange(of: isWordHighlighted) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    wordHighlightPulse = 1.0
                }
            } else {
                withAnimation(.easeOut(duration: 0.25)) {
                    wordHighlightPulse = 0.0
                }
            }
        }
        .onChange(of: isHintTile) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    hintPulse = 1.0
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    hintPulse = 0.0
                }
            }
        }
        .onChange(of: tile) { oldTile, newTile in
            // Forged tile entry: nil → .forged
            if oldTile == nil, let newTile, newTile.animState == .forged {
                // Snap both to zero immediately (disabling animations prevents the implicit
                // .easeInOut from catching these resets and animating them)
                var tx = Transaction()
                tx.disablesAnimations = true
                withTransaction(tx) {
                    forgeScale = 0.0
                    forgePulse = 0.0
                }
                // Spring scale from 0 → 1 (overshoot gives the pop-in feel)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.35)) {
                    forgeScale = 1.0
                }
                // Pulse brightness: ramp up and repeat for the full forged duration
                withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                    forgePulse = 1.0
                }
            }
            // Forged state cleared → settle pulse back to 0
            if oldTile?.animState == .forged, newTile?.animState != .forged {
                withAnimation(.easeOut(duration: 0.5)) {
                    forgePulse = 0.0
                }
            }
            // Vanish rotation
            if newTile?.animState == .vanishing {
                withAnimation(.easeIn(duration: 0.3)) {
                    vanishRotation = Bool.random() ? 18 : -18
                }
            } else if newTile == nil || newTile?.animState != .vanishing {
                vanishRotation = 0
            }
        }
    }

    // MARK: - Base colors

    private func baseColor(for tile: Tile) -> Color {
        // Forged tiles are white, pulsing brighter with forgePulse (0→1 CGFloat)
        if tile.animState == .forged {
            return Color(white: 0.85 + forgePulse * 0.15)
        }
        // Hint tiles pulse between deep gold and bright amber
        if isHintTile {
            return Color(red: 1.0, green: 0.60 + hintPulse * 0.20, blue: 0.0 + hintPulse * 0.08)
        }
        switch tile.type {
        case .consonant:
            return theme.consonantBase
        case .vowel(.A):
            return Color(red: 0.95, green: 0.22, blue: 0.22)
        case .vowel(.E):
            return Color(red: 0.18, green: 0.82, blue: 0.35)
        case .vowel(.I):
            return Color(red: 0.15, green: 0.48, blue: 1.0)
        case .vowel(.O):
            return Color(red: 1.0,  green: 0.55, blue: 0.05)
        case .vowel(.U):
            return Color(red: 0.72, green: 0.22, blue: 0.95)
        }
    }

    private func darkenedColor(_ color: Color, factor: Double) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(red: Double(r) * factor, green: Double(g) * factor, blue: Double(b) * factor)
    }

    // MARK: - Shadows & glows

    private var dropShadowColor: Color {
        guard let tile else { return .clear }
        return baseColor(for: tile).opacity(0.55)
    }

    private var isDanger: Bool { tile?.animState == .danger }

    private var touchGlowColor: Color {
        Color(red: 1.0, green: 0.95, blue: 0.5).opacity(0.9)
    }

    private var dangerGlowColor: Color {
        guard isDanger, let tile, let v = tile.vowel else { return .clear }
        switch v {
        case .A: return Color(red: 1.0, green: 0.2, blue: 0.2)
        case .E: return Color(red: 0.2, green: 1.0, blue: 0.3)
        case .I: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .O: return Color(red: 1.0, green: 0.6, blue: 0.1)
        case .U: return Color(red: 0.8, green: 0.2, blue: 1.0)
        }
    }

    private func scaleFor(_ state: TileAnimState?) -> CGFloat {
        switch state {
        case .selected:   return 1.10
        case .vanishing:  return 0.05
        case .scoring:    return 1.15
        default:          return 1.0
        }
    }
}
