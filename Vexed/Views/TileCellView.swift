import SwiftUI

struct TileCellView: View {
    let tile: Tile?
    let isSelected: Bool
    let size: CGFloat
    var isTouching: Bool = false
    // Path glow: non-nil when this empty cell is in the slide path of the selected tile
    var pathColor: Color? = nil
    var isDestination: Bool = false

    @State private var vanishRotation: Double = 0

    var body: some View {
        ZStack {
            if let tile {
                let base = baseColor(for: tile)
                let cr = size * 0.22

                // 1. Base fill
                RoundedRectangle(cornerRadius: cr)
                    .fill(base)

                // 2. Top-light overlay (3D bevel highlight)
                RoundedRectangle(cornerRadius: cr)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.45), location: 0),
                                .init(color: Color.clear, location: 0.40)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                // 3. Bottom-shadow overlay (3D bevel shadow)
                RoundedRectangle(cornerRadius: cr)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.clear, location: 0.60),
                                .init(color: Color.black.opacity(0.30), location: 1.0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                // 4. Border: selected = white, else darkened inner border
                RoundedRectangle(cornerRadius: cr)
                    .strokeBorder(
                        isSelected ? Color.white : darkenedColor(base, factor: 0.65),
                        lineWidth: isSelected ? 3.5 : 1.5
                    )

                // 5. Outer highlight stroke (white top shimmer)
                if !isSelected {
                    RoundedRectangle(cornerRadius: cr)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.75)
                }

                // Letter
                Text(String(tile.letter))
                    .font(.system(size: size * 0.50, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1, x: 0, y: 1)

            } else {
                // Empty cell: barely visible dashed grid structure
                RoundedRectangle(cornerRadius: size * 0.22)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .foregroundColor(pathColor != nil ? pathColor!.opacity(0.5) : Color(white: 0.30))

                // Path fill tint
                if let col = pathColor {
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(col.opacity(isDestination ? 0.18 : 0.08))
                }

                // Destination arrow dot
                if isDestination, let col = pathColor {
                    Circle()
                        .fill(col.opacity(0.7))
                        .frame(width: size * 0.18, height: size * 0.18)
                }
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isTouching ? 1.10 : scaleFor(tile?.animState))
        .rotationEffect(.degrees(tile?.animState == .vanishing ? vanishRotation : 0))
        .opacity(tile?.animState == .vanishing ? 0 : 1)
        .shadow(color: dropShadowColor, radius: 8, x: 0, y: 5)
        .shadow(color: isTouching ? touchGlowColor : dangerGlowColor,
                radius: isTouching ? 18 : (isDanger ? 14 : 0))
        // Path glow on the outer border of path / destination cells
        .shadow(color: pathColor?.opacity(isDestination ? 0.85 : 0.45) ?? .clear,
                radius: isDestination ? 12 : 6, x: 0, y: 0)
        .animation(.spring(response: 0.18, dampingFraction: 0.55), value: isSelected)
        .animation(.spring(response: 0.12, dampingFraction: 0.55), value: isTouching)
        .animation(.easeInOut(duration: 0.25), value: pathColor != nil)
        .animation(.easeInOut(duration: 0.35), value: tile?.animState)
        .onChange(of: tile?.animState) { _, newState in
            if newState == .vanishing {
                withAnimation(.easeIn(duration: 0.3)) {
                    vanishRotation = Bool.random() ? 18 : -18
                }
            } else {
                vanishRotation = 0
            }
        }
    }

    // MARK: - Base colors (bright Block Blast style)

    private func baseColor(for tile: Tile) -> Color {
        switch tile.type {
        case .consonant:
            return Color(red: 0.165, green: 0.165, blue: 0.243) // medium slate #2A2A3E
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
        // Approximate darkening via UIColor
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
        default:          return isSelected ? 1.08 : 1.0
        }
    }
}
