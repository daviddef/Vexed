import SwiftUI

struct VowelRadarView: View {
    let counts: [Vowel: Int]

    private let vowelColors: [Vowel: Color] = [
        .A: Color(red: 1.0, green: 0.42, blue: 0.42),
        .E: Color(red: 0.42, green: 1.0, blue: 0.53),
        .I: Color(red: 0.42, green: 0.56, blue: 1.0),
        .O: Color(red: 1.0, green: 0.8, blue: 0.33),
        .U: Color(red: 0.8, green: 0.47, blue: 1.0),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Vowel.allCases, id: \.self) { v in
                let count = counts[v] ?? 0
                VStack(spacing: 2) {
                    Text(String(v.rawValue))
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(vowelColors[v])
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(count >= 2 ? vowelColors[v]!.opacity(0.15) : Color(white: 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(count >= 2 ? vowelColors[v]!.opacity(0.5) : Color(white: 0.15), lineWidth: 1.5)
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: count)
            }
        }
    }
}
