import SwiftUI

struct SplashView: View {
    var onDismiss: () -> Void

    // Each tile animates in independently
    @State private var tileVisible: [Bool] = Array(repeating: false, count: 5)
    @State private var wordmarkVisible = false
    @State private var taglineVisible = false
    @State private var tapPromptVisible = false
    @State private var tapPulse = false
    @State private var dismissing = false

    // V E X / E D
    private let row1: [(String, Color)] = [
        ("V", Color(red: 0.165, green: 0.165, blue: 0.243)),
        ("E", Color(red: 0.18,  green: 0.82,  blue: 0.35)),
        ("X", Color(red: 0.165, green: 0.165, blue: 0.243)),
    ]
    private let row2: [(String, Color)] = [
        ("E", Color(red: 0.18,  green: 0.82,  blue: 0.35)),
        ("D", Color(red: 0.165, green: 0.165, blue: 0.243)),
    ]

    var body: some View {
        ZStack {
            // ── Background ────────────────────────────────────────────
            RadialGradient(
                colors: [Color(red: 0.12, green: 0.12, blue: 0.20),
                         Color(red: 0.04, green: 0.04, blue: 0.08)],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Subtle centre bloom
            Ellipse()
                .fill(Color(red: 0.18, green: 0.18, blue: 0.45).opacity(0.28))
                .frame(width: 340, height: 260)
                .offset(y: -60)

            VStack(spacing: 0) {
                Spacer()

                // ── Tile grid ─────────────────────────────────────────
                VStack(spacing: 14) {
                    // Row 1: V E X
                    HStack(spacing: 14) {
                        ForEach(0..<row1.count, id: \.self) { i in
                            SplashTile(letter: row1[i].0, color: row1[i].1)
                                .scaleEffect(tileVisible[i] ? 1 : 0.3)
                                .opacity(tileVisible[i] ? 1 : 0)
                        }
                    }
                    // Row 2: E D (centred)
                    HStack(spacing: 14) {
                        ForEach(0..<row2.count, id: \.self) { i in
                            SplashTile(letter: row2[i].0, color: row2[i].1)
                                .scaleEffect(tileVisible[3 + i] ? 1 : 0.3)
                                .opacity(tileVisible[3 + i] ? 1 : 0)
                        }
                    }
                }

                Spacer().frame(height: 44)

                // ── Wordmark ──────────────────────────────────────────
                Text("VEXED")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(16)
                    .opacity(wordmarkVisible ? 1 : 0)
                    .offset(y: wordmarkVisible ? 0 : 20)

                Spacer().frame(height: 8)

                Text("WORD PUZZLE")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.38))
                    .tracking(6)
                    .opacity(taglineVisible ? 1 : 0)

                Spacer().frame(height: 52)

                // ── Tap prompt ────────────────────────────────────────
                Text("TAP TO PLAY")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(tapPulse ? 0.75 : 0.30))
                    .tracking(5)
                    .opacity(tapPromptVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: tapPulse)

                Spacer()
            }
        }
        .opacity(dismissing ? 0 : 1)
        .scaleEffect(dismissing ? 1.06 : 1)
        .onTapGesture { dismiss() }
        .onAppear { runEntrance() }
    }

    private func runEntrance() {
        // Stagger tiles: 0.08s apart, spring bounce
        for i in 0..<5 {
            let delay = 0.15 + Double(i) * 0.10
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.52)) {
                    tileVisible[i] = true
                }
            }
        }
        // Wordmark rises after last tile
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.80) {
            withAnimation(.easeOut(duration: 0.45)) { wordmarkVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.easeOut(duration: 0.35)) { taglineVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.40) {
            withAnimation(.easeOut(duration: 0.4)) { tapPromptVisible = true }
            tapPulse = true
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.28)) {
            dismissing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onDismiss()
        }
    }
}

// MARK: - Single splash tile

private struct SplashTile: View {
    let letter: String
    let color: Color

    var body: some View {
        let size: CGFloat = 96
        let cr: CGFloat = size * 0.22

        ZStack {
            // Base
            RoundedRectangle(cornerRadius: cr).fill(color)

            // Top bevel
            RoundedRectangle(cornerRadius: cr)
                .fill(LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.42), location: 0),
                        .init(color: .clear, location: 0.42)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))

            // Bottom shadow
            RoundedRectangle(cornerRadius: cr)
                .fill(LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.58),
                        .init(color: .black.opacity(0.30), location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                ))

            // Inner border
            RoundedRectangle(cornerRadius: cr)
                .strokeBorder(color.opacity(0.5), lineWidth: 2)

            // White shimmer
            RoundedRectangle(cornerRadius: cr)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)

            // Letter
            Text(letter)
                .font(.system(size: size * 0.52, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 0, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: color.opacity(0.6), radius: 10, x: 0, y: 6)
    }
}
