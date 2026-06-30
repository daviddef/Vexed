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
                // Filled tile with gradient
                RoundedRectangle(cornerRadius: size * 0.30)
                    .fill(backgroundGradient(for: tile))
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.30)
                            .stroke(borderColor(for: tile), lineWidth: isSelected ? 3.0 : 2.5)
                    )

                Text(String(tile.letter))
                    .font(.system(size: size * 0.46, weight: .black, design: .rounded))
                    .foregroundColor(letterColor(for: tile))
            } else {
                // Empty cell: dashed base outline
                RoundedRectangle(cornerRadius: size * 0.30)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .foregroundColor(pathColor != nil ? pathColor!.opacity(0.5) : Color(white: 0.55))

                // Path fill tint
                if let col = pathColor {
                    RoundedRectangle(cornerRadius: size * 0.30)
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
        .scaleEffect(isTouching ? 1.12 : scaleFor(tile?.animState))
        .rotationEffect(.degrees(tile?.animState == .vanishing ? vanishRotation : 0))
        .opacity(tile?.animState == .vanishing ? 0 : 1)
        .shadow(color: dropShadowColor, radius: 6, x: 0, y: 4)
        .shadow(color: isTouching ? touchGlowColor : dangerGlowColor,
                radius: isTouching ? 16 : (isDanger ? 14 : 0))
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

    // MARK: - Gradient backgrounds

    private func backgroundGradient(for tile: Tile) -> LinearGradient {
        switch tile.type {
        case .consonant:
            return LinearGradient(
                colors: [Color(white: 0.18), Color(white: 0.11)],
                startPoint: .top, endPoint: .bottom
            )
        case .vowel(.A):
            return LinearGradient(
                colors: [Color(red: 0.35, green: 0.12, blue: 0.12), Color(red: 0.22, green: 0.07, blue: 0.07)],
                startPoint: .top, endPoint: .bottom
            )
        case .vowel(.E):
            return LinearGradient(
                colors: [Color(red: 0.12, green: 0.32, blue: 0.15), Color(red: 0.07, green: 0.20, blue: 0.09)],
                startPoint: .top, endPoint: .bottom
            )
        case .vowel(.I):
            return LinearGradient(
                colors: [Color(red: 0.12, green: 0.15, blue: 0.38), Color(red: 0.07, green: 0.09, blue: 0.25)],
                startPoint: .top, endPoint: .bottom
            )
        case .vowel(.O):
            return LinearGradient(
                colors: [Color(red: 0.35, green: 0.26, blue: 0.06), Color(red: 0.22, green: 0.16, blue: 0.03)],
                startPoint: .top, endPoint: .bottom
            )
        case .vowel(.U):
            return LinearGradient(
                colors: [Color(red: 0.30, green: 0.10, blue: 0.38), Color(red: 0.18, green: 0.06, blue: 0.24)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    // MARK: - Colours

    private func borderColor(for tile: Tile) -> Color {
        if isSelected { return .white }
        switch tile.type {
        case .consonant:  return Color(white: 0.28)
        case .vowel(.A):  return Color(red: 0.7, green: 0.20, blue: 0.20)
        case .vowel(.E):  return Color(red: 0.20, green: 0.65, blue: 0.28)
        case .vowel(.I):  return Color(red: 0.25, green: 0.35, blue: 0.80)
        case .vowel(.O):  return Color(red: 0.75, green: 0.58, blue: 0.12)
        case .vowel(.U):  return Color(red: 0.62, green: 0.24, blue: 0.78)
        }
    }

    private func letterColor(for tile: Tile) -> Color {
        switch tile.type {
        case .consonant:  return Color(white: 0.72)
        case .vowel(.A):  return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .vowel(.E):  return Color(red: 0.3, green: 1.0, blue: 0.5)
        case .vowel(.I):  return Color(red: 0.45, green: 0.6, blue: 1.0)
        case .vowel(.O):  return Color(red: 1.0, green: 0.75, blue: 0.2)
        case .vowel(.U):  return Color(red: 0.85, green: 0.4, blue: 1.0)
        }
    }

    private var dropShadowColor: Color {
        guard let tile else { return .clear }
        switch tile.type {
        case .consonant:  return Color.black.opacity(0.5)
        case .vowel(.A):  return Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.6)
        case .vowel(.E):  return Color(red: 0.3, green: 1.0, blue: 0.5).opacity(0.6)
        case .vowel(.I):  return Color(red: 0.45, green: 0.6, blue: 1.0).opacity(0.6)
        case .vowel(.O):  return Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.6)
        case .vowel(.U):  return Color(red: 0.85, green: 0.4, blue: 1.0).opacity(0.6)
        }
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
