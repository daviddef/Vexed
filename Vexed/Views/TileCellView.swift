import SwiftUI

struct TileCellView: View {
    let tile: Tile?
    let isSelected: Bool
    let size: CGFloat
    var isTouching: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.18)
                        .stroke(borderColor, lineWidth: isSelected ? 2.5 : 1.5)
                )

            if let tile {
                Text(String(tile.letter))
                    .font(.system(size: size * 0.42, weight: .black, design: .rounded))
                    .foregroundColor(letterColor(for: tile))
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isTouching ? 1.05 : scaleFor(tile?.animState))
        .opacity(tile?.animState == .vanishing ? 0 : 1)
        .shadow(color: isTouching ? touchGlowColor : dangerGlowColor,
                radius: isTouching ? 12 : (isDanger ? 8 : 0))
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.12, dampingFraction: 0.6), value: isTouching)
        .animation(.easeInOut(duration: 0.35), value: tile?.animState)
    }

    // MARK: - Colours

    private var background: Color {
        guard let tile else { return Color(white: 0.07) }
        switch tile.type {
        case .consonant:      return Color(white: 0.12)
        case .vowel(.A):      return Color(red: 0.18, green: 0.10, blue: 0.10)
        case .vowel(.E):      return Color(red: 0.10, green: 0.18, blue: 0.10)
        case .vowel(.I):      return Color(red: 0.10, green: 0.10, blue: 0.22)
        case .vowel(.O):      return Color(red: 0.18, green: 0.15, blue: 0.06)
        case .vowel(.U):      return Color(red: 0.16, green: 0.10, blue: 0.18)
        }
    }

    private var borderColor: Color {
        guard let tile else { return Color(white: 0.12) }
        if isSelected { return .white }
        switch tile.type {
        case .consonant:  return Color(white: 0.22)
        case .vowel(.A):  return Color(red: 0.6, green: 0.15, blue: 0.15)
        case .vowel(.E):  return Color(red: 0.15, green: 0.55, blue: 0.2)
        case .vowel(.I):  return Color(red: 0.2, green: 0.28, blue: 0.7)
        case .vowel(.O):  return Color(red: 0.65, green: 0.5, blue: 0.1)
        case .vowel(.U):  return Color(red: 0.55, green: 0.2, blue: 0.7)
        }
    }

    private func letterColor(for tile: Tile) -> Color {
        switch tile.type {
        case .consonant:  return Color(white: 0.6)
        case .vowel(.A):  return Color(red: 1.0, green: 0.42, blue: 0.42)
        case .vowel(.E):  return Color(red: 0.42, green: 1.0, blue: 0.53)
        case .vowel(.I):  return Color(red: 0.42, green: 0.56, blue: 1.0)
        case .vowel(.O):  return Color(red: 1.0, green: 0.8, blue: 0.33)
        case .vowel(.U):  return Color(red: 0.8, green: 0.47, blue: 1.0)
        }
    }

    private var isDanger: Bool { tile?.animState == .danger }

    private var touchGlowColor: Color {
        // Bright gold/white glow on touch
        Color(red: 1.0, green: 0.92, blue: 0.6).opacity(0.85)
    }

    private var dangerGlowColor: Color {
        guard isDanger, let tile, let v = tile.vowel else { return .clear }
        switch v {
        case .A: return .red
        case .E: return .green
        case .I: return .blue
        case .O: return .orange
        case .U: return .purple
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
