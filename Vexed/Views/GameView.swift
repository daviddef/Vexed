import SwiftUI

struct GameView: View {
    @StateObject private var engine = GameEngine(difficulty: .medium)
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var showBurgerMenu = false
    @State private var showInstructions = false
    @State private var showMissedWords = false
    @State private var isFirstLaunch = !UserDefaults.standard.bool(forKey: "vexed.launched")
    @State private var toastMessage: String? = nil

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Compact top bar ──────────────────────────────────────
                HStack(spacing: 0) {
                    // Score cluster
                    HStack(spacing: 12) {
                        miniStat(label: "SCORE", value: "\(engine.score)", color: .white)
                        miniStat(label: "WORDS", value: "\(engine.wordCount)", color: Color(white: 0.7))
                        miniStat(label: "LOST",  value: "\(engine.lostVowels)", color: Color(red: 1, green: 0.4, blue: 0.4))
                    }
                    .padding(.leading, 16)

                    Spacer()

                    // Controls
                    HStack(spacing: 8) {
                        iconButton("arrow.counterclockwise") { engine.reset(difficulty: selectedDifficulty) }
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
                                Text("selected — swipe to slide")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(white: 0.35))
                            }
                            .padding(.vertical, 4)
                            .transition(.opacity)
                        } else {
                            Text("drag any tile to slide it")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(white: 0.22))
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
                        .background(Color.yellow.cornerRadius(14))
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
                onReset: { engine.reset(difficulty: selectedDifficulty) },
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
    }

    // MARK: - Subviews

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
                            HStack(spacing: 4) {
                                Text(entry.word)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(white: 0.7))
                                Text("+\(entry.points)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.1).cornerRadius(8))
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
    }

    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(white: 0.45))
                .frame(width: 36, height: 36)
                .background(Color(white: 0.12).cornerRadius(8))
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
                    engine.reset(difficulty: selectedDifficulty)
                } label: {
                    Text("PLAY AGAIN")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundColor(.black)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(Color.white.cornerRadius(14))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helpers

    private func tileColor(_ tile: Tile) -> Color {
        switch tile.type {
        case .consonant:  return Color(white: 0.7)
        case .vowel(.A):  return Color(red: 1.0, green: 0.42, blue: 0.42)
        case .vowel(.E):  return Color(red: 0.42, green: 1.0, blue: 0.53)
        case .vowel(.I):  return Color(red: 0.42, green: 0.56, blue: 1.0)
        case .vowel(.O):  return Color(red: 1.0, green: 0.8, blue: 0.33)
        case .vowel(.U):  return Color(red: 0.8, green: 0.47, blue: 1.0)
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.3)) { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.25)) { toastMessage = nil }
        }
    }
}
