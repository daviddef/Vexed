import SwiftUI

struct AvailableWordChip: View {
    let entry: GameEngine.AvailableWord
    @ObservedObject var engine: GameEngine

    private var isHighlighted: Bool {
        engine.highlightedPositions == Set(entry.positions)
    }

    private let red = Color(red: 1, green: 0.38, blue: 0.38)

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                if isHighlighted {
                    engine.highlightedPositions = nil
                } else {
                    engine.highlightedPositions = Set(entry.positions)
                }
            }
        } label: {
            Text(entry.word)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(isHighlighted ? .black : red)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHighlighted ? red : red.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(red.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }
}
