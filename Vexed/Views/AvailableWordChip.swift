import SwiftUI

struct AvailableWordChip: View {
    let entry: GameEngine.AvailableWord
    @ObservedObject var engine: GameEngine

    private var isHighlighted: Bool {
        Set(engine.highlightedWords.map(\.id)) == [entry.id]
    }

    private let vexedGreen = Color(red: 0.18, green: 0.82, blue: 0.35)
    private let red = Color(red: 1, green: 0.38, blue: 0.38)

    @State private var pulse = false

    var body: some View {
        Button {
            if isHighlighted {
                // Second tap on the already-highlighted word — collect it.
                engine.collectWord(entry)
            } else {
                // First tap — preview: highlight in VEXED green, show the discreet
                // points/definition overlay, don't score yet.
                withAnimation(.easeInOut(duration: 0.18)) {
                    engine.highlightedWords = [entry]
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
                        .fill(isHighlighted ? vexedGreen : red.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHighlighted ? vexedGreen : red.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: vexedGreen.opacity(isHighlighted && pulse ? 0.7 : 0), radius: isHighlighted && pulse ? 8 : 0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
