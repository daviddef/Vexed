import SwiftUI

struct HUDView: View {
    let score: Int
    let wordCount: Int
    let lostVowels: Int
    let lastWord: String?

    var body: some View {
        HStack(spacing: 12) {
            statBox(value: score, label: "SCORE")
            statBox(value: wordCount, label: "WORDS")
            statBox(value: lostVowels, label: "LOST", accent: .red)

            if let word = lastWord {
                Text(word)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.12).cornerRadius(8))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: lastWord)
    }

    private func statBox(value: Int, label: String, accent: Color = Color(white: 0.9)) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundColor(accent)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(white: 0.4))
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(white: 0.1).cornerRadius(10))
    }
}
