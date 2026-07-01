import SwiftUI

struct VowelRadarView: View {
    let counts: [Vowel: Int]

    private let vowelColors: [Vowel: Color] = [
        .A: Color(red: 1.0, green: 0.35, blue: 0.35),
        .E: Color(red: 0.3,  green: 1.0, blue: 0.5),
        .I: Color(red: 0.45, green: 0.6, blue: 1.0),
        .O: Color(red: 1.0,  green: 0.75, blue: 0.2),
        .U: Color(red: 0.85, green: 0.4, blue: 1.0),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Vowel.allCases, id: \.self) { v in
                VowelPill(vowel: v, count: counts[v] ?? 0, color: vowelColors[v] ?? .white)
            }
        }
    }
}

// Separate view so each pill can own its own animation state
private struct VowelPill: View {
    let vowel: Vowel
    let count: Int
    let color: Color

    @State private var shakeOffset: CGFloat = 0
    @State private var pulseOpacity: Double = 0.15

    private var isDanger: Bool   { count >= 2 }
    private var isCritical: Bool { count >= 3 }

    var body: some View {
        VStack(spacing: 3) {
            Text(String(vowel.rawValue))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(isDanger ? color.opacity(0.9) : Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.1))
                .overlay(
                    // Danger tint layered ON TOP of the dark base — never the sole background,
                    // so the same-hue letter always keeps contrast against it.
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDanger ? color.opacity(pulseOpacity) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isDanger ? color.opacity(0.65) : Color(white: 0.15),
                            lineWidth: isDanger ? 2.0 : 1.5
                        )
                )
        )
        .shadow(
            color: isDanger ? color.opacity(0.5) : Color.black.opacity(0.3),
            radius: isDanger ? 8 : 3,
            x: 0, y: isDanger ? 3 : 2
        )
        .offset(x: shakeOffset)
        .animation(.easeInOut(duration: 0.25), value: count)
        .onChange(of: count) { _, newCount in
            if newCount >= 2 {
                // Pulsing glow
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.28
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    pulseOpacity = 0.15
                }
            }

            if newCount >= 3 {
                // Warning shake
                shake()
            }
        }
        .onAppear {
            if count >= 2 {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.28
                }
            }
        }
    }

    private func shake() {
        let offsets: [CGFloat] = [0, -6, 6, -5, 5, -3, 3, 0]
        var delay: Double = 0
        for offset in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.06)) {
                    shakeOffset = offset
                }
            }
            delay += 0.06
        }
    }
}
