import SwiftUI

struct GameView: View {
    @StateObject private var engine = GameEngine(difficulty: .medium)
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var showBurgerMenu = false
    @State private var showInstructions = false
    @State private var showMissedWords = false
    @State private var isFirstLaunch = !UserDefaults.standard.bool(forKey: "vexed.launched")
    @State private var toastMessage: String? = nil
    @State private var toastRotation: Double = 0
    @State private var showNoWordsLeft: Bool = false
    @State private var vanishMessage: String? = nil

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Compact top bar ──────────────────────────────────────
                HStack(spacing: 0) {
                    // Score cluster
                    HStack(spacing: 12) {
                        miniStat(label: "SCORE", value: "\(engine.score)", color: .white)
                        miniStat(label: "BEST", value: "\(engine.potentialScore)", color: Color(red:0.3,green:1.0,blue:0.5))
                        miniStat(label: "PEAK%", value: "\(securedPct())%", color: peakColor())
                        miniStat(label: "WORDS", value: "\(engine.wordCount)", color: Color(white: 0.7))
                        miniStat(label: "LOST",  value: "\(engine.lostVowels)", color: Color(red: 1, green: 0.4, blue: 0.4))
                    }
                    .padding(.leading, 16)

                    Spacer()

                    // Controls
                    HStack(spacing: 8) {
                        iconButton("arrow.counterclockwise") {
                            showNoWordsLeft = false
                            engine.reset(difficulty: selectedDifficulty)
                        }
                        iconButton("line.3.horizontal") { showBurgerMenu = true }
                    }
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 10)

                // ── Vowel radar ──────────────────────────────────────────
                VowelRadarView(counts: engine.vowelCounts())
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                // ── GRID — fills all remaining space ─────────────────────
                GridView(engine: engine)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Two-part footer ──────────────────────────────────────
                VStack(spacing: 0) {
                    // Line 1: selected tile hint
                    Group {
                        if let pos = engine.selectedPosition, let tile = engine.grid[pos.row][pos.col] {
                            HStack(spacing: 6) {
                                Text(String(tile.letter))
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(tileColor(tile))
                                Text("selected — swipe!")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(white: 0.35))
                            }
                            .padding(.vertical, 4)
                            .transition(.opacity)
                        } else {
                            Text("✦ drag any tile to slide")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(white: 0.28))
                                .padding(.vertical, 4)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: engine.selectedPosition)

                    // Line 2: word history chips
                    wordHistoryStrip
                        .frame(height: 36)
                }
                .padding(.bottom, 8)
            }

            // ── Toast for word scored ─────────────────────────────────
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.yellow.cornerRadius(16))
                        .shadow(color: Color.yellow.opacity(0.6), radius: 12, x: 0, y: 4)
                        .rotationEffect(.degrees(toastRotation))
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // ── Vowel vanish banner ───────────────────────────────────
            if let msg = vanishMessage {
                VStack {
                    Text(msg)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.85, green: 0.15, blue: 0.15).cornerRadius(12))
                        .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 3)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
            }

            // ── No-words-left overlay ─────────────────────────────────
            if showNoWordsLeft && !engine.gameOver {
                noWordsLeftOverlay.zIndex(8)
            }

            // ── Instructions overlay ──────────────────────────────────
            if showInstructions || isFirstLaunch {
                InstructionsView {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showInstructions = false
                        isFirstLaunch = false
                    }
                    UserDefaults.standard.set(true, forKey: "vexed.launched")
                }
                .zIndex(10)
            }

            // ── Game over overlay ─────────────────────────────────────
            if engine.gameOver {
                gameOverOverlay.zIndex(9)
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showBurgerMenu) {
            BurgerMenuView(
                difficulty: $selectedDifficulty,
                onReset: {
                    showNoWordsLeft = false
                    engine.reset(difficulty: selectedDifficulty)
                },
                onShowInstructions: { showInstructions = true },
                onShowMissedWords: { showMissedWords = true }
            )
        }
        .sheet(isPresented: $showMissedWords) {
            MissedWordsView(grid: engine.grid, config: engine.config)
                .preferredColorScheme(.dark)
        }
        .onChange(of: engine.lastWord) { _, word in
            guard let word else { return }
            showToast("✨ \(word)")
        }
        .onChange(of: engine.lostVowels) { old, new in
            let just = new - old
            guard just > 0 else { return }
            withAnimation(.easeOut(duration: 0.3)) { vanishMessage = "💥 \(just) vowel\(just == 1 ? "" : "s") vanished!" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeIn(duration: 0.25)) { vanishMessage = nil }
            }
        }
        .onChange(of: engine.noWordsLeft) { _, isLeft in
            if isLeft { showNoWordsLeft = true }
        }
    }

    // MARK: - Subviews

    private var noWordsLeftOverlay: some View {
        ZStack {
            Color.black.opacity(0.80).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("NO MOVES LEFT")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(4)
                Text("VEXED")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(10)
                VStack(spacing: 8) {
                    Text("\(engine.score)")
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                    let pct = engine.peakScore > 0 ? min(100, Int(Double(engine.score) / Double(engine.peakScore) * 100)) : 0
                    Text("You captured \(pct)% of the estimated peak")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.45))
                    Text("\(engine.wordCount) word\(engine.wordCount == 1 ? "" : "s")  •  \(engine.lostVowels) vowel\(engine.lostVowels == 1 ? "" : "s") lost")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.35))
                }
                Button {
                    showNoWordsLeft = false
                    engine.reset(difficulty: selectedDifficulty)
                } label: {
                    Text("PLAY AGAIN")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundColor(.black)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(Color.white.cornerRadius(14))
                        .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

    private var wordHistoryStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if engine.wordHistory.isEmpty {
                        Text("— no words yet —")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(white: 0.2))
                            .padding(.horizontal, 12)
                    } else {
                        ForEach(Array(engine.wordHistory.enumerated()), id: \.offset) { idx, entry in
                            let chipColor = chipTint(for: entry.word)
                            HStack(spacing: 4) {
                                Text(entry.word)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(chipColor.foreground)
                                Text("+\(entry.points)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(chipColor.background.cornerRadius(10))
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            .id(idx)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .onChange(of: engine.wordHistory.count) { _, count in
                if count > 0 {
                    withAnimation {
                        proxy.scrollTo(count - 1, anchor: .trailing)
                    }
                }
            }
        }
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Color(white: 0.3))
                .tracking(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(white: 0.55))
                .frame(width: 40, height: 40)
                .background(Color(white: 0.13).cornerRadius(12))
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("BOARD FULL")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(4)
                Text("VEXED")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(10)
                VStack(spacing: 6) {
                    Text("\(engine.score)")
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                    Text("\(engine.wordCount) word\(engine.wordCount == 1 ? "" : "s")  •  \(engine.lostVowels) vowel\(engine.lostVowels == 1 ? "" : "s") lost")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.4))
                }
                Button {
                    showNoWordsLeft = false
                    engine.reset(difficulty: selectedDifficulty)
                } label: {
                    Text("PLAY AGAIN")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundColor(.black)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(Color.white.cornerRadius(14))
                        .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helpers

    private func securedPct() -> Int {
        guard engine.peakScore > 0 else { return 0 }
        return min(100, Int(Double(engine.score) / Double(engine.peakScore) * 100))
    }

    private func peakColor() -> Color {
        let secured = securedPct()
        if secured >= 80 { return Color(red: 0.3, green: 1.0, blue: 0.5) }
        if secured >= 50 { return Color(red: 1.0, green: 0.8, blue: 0.2) }
        return Color(white: 0.45)
    }

    private struct ChipTint {
        let foreground: Color
        let background: Color
    }

    private func chipTint(for word: String) -> ChipTint {
        switch word.count {
        case 6...:
            return ChipTint(
                foreground: Color(red: 1.0, green: 0.85, blue: 0.3),
                background: Color(red: 0.22, green: 0.18, blue: 0.04)
            )
        case 5:
            return ChipTint(
                foreground: Color(red: 0.5, green: 0.75, blue: 1.0),
                background: Color(red: 0.06, green: 0.12, blue: 0.22)
            )
        default:
            return ChipTint(
                foreground: Color(white: 0.70),
                background: Color(white: 0.10)
            )
        }
    }

    private func tileColor(_ tile: Tile) -> Color {
        switch tile.type {
        case .consonant:  return Color(white: 0.72)
        case .vowel(.A):  return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .vowel(.E):  return Color(red: 0.3, green: 1.0, blue: 0.5)
        case .vowel(.I):  return Color(red: 0.45, green: 0.6, blue: 1.0)
        case .vowel(.O):  return Color(red: 1.0, green: 0.75, blue: 0.2)
        case .vowel(.U):  return Color(red: 0.85, green: 0.4, blue: 1.0)
        }
    }

    private func showToast(_ message: String) {
        toastRotation = 0
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            toastMessage = message
        }
        // Wobble
        withAnimation(.easeInOut(duration: 0.08).delay(0.05)) { toastRotation = 3 }
        withAnimation(.easeInOut(duration: 0.08).delay(0.13)) { toastRotation = -3 }
        withAnimation(.easeInOut(duration: 0.08).delay(0.21)) { toastRotation = 2 }
        withAnimation(.easeInOut(duration: 0.08).delay(0.29)) { toastRotation = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.25)) { toastMessage = nil }
        }
    }
}
