import SwiftUI

struct DailyShareCardData {
    let dateLabel: String
    let score: Int
    let bestWord: String
    let peakCombo: Int
    let wordCount: Int
    let streak: Int
}

struct DailyShareCardView: View {
    let data: DailyShareCardData

    var body: some View {
        VStack(spacing: 14) {
            Text("VEXED! 🧩")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(data.dateLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(white: 0.7))

            HStack(spacing: 24) {
                statBlock(label: "SCORE", value: "\(data.score)", color: Color(red: 1.0, green: 0.85, blue: 0.2))
                statBlock(label: "WORDS", value: "\(data.wordCount)", color: .white)
                if data.peakCombo >= 2 {
                    statBlock(label: "COMBO", value: "\(data.peakCombo)×", color: Color(red: 1.0, green: 0.4, blue: 0.1))
                }
            }
            .padding(.vertical, 4)

            if !data.bestWord.isEmpty {
                Text("Best word: \(data.bestWord.uppercased())")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.5, green: 0.85, blue: 1.0))
            }

            if data.streak > 1 {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(data.streak)-day streak")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.2))
                }
            }

            Text("Can you beat this today?")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color(white: 0.5))
        }
        .padding(28)
        .frame(width: 320)
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.14), Color(red: 0.16, green: 0.06, blue: 0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func statBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(Color(white: 0.4))
                .tracking(1)
        }
    }
}

@MainActor
func renderDailyShareImage(_ data: DailyShareCardData) -> UIImage? {
    let renderer = ImageRenderer(content: DailyShareCardView(data: data))
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}
