import SwiftUI

struct AvailableWordChip: View {
    let entry: GameEngine.AvailableWord
    @ObservedObject var engine: GameEngine
    var onShowDefinition: (String) -> Void

    private var isHighlighted: Bool {
        engine.highlightedPositions == Set(entry.positions)
    }

    private let gold = Color(red: 1.0, green: 0.82, blue: 0.2)
    private let red  = Color(red: 1, green: 0.38, blue: 0.38)

    var body: some View {
        Button {
            // Single tap: show definition + highlight the word on board
            onShowDefinition(entry.word)
            withAnimation(.easeInOut(duration: 0.18)) {
                engine.highlightedPositions = isHighlighted ? nil : Set(entry.positions)
            }
        } label: {
            Text(entry.word)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(isHighlighted ? .black : red)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHighlighted ? gold : red.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHighlighted ? gold : red.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }
}
