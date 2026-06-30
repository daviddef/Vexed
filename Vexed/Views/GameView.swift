import SwiftUI

struct GameView: View {
    @StateObject private var engine = GameEngine(difficulty: .medium)
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var showDifficultyPicker = false

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()

            VStack(spacing: 14) {
                // Title + difficulty
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VEXED")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(8)
                        Text("SLIDE · FORM · SURVIVE")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(white: 0.35))
                            .tracking(2)
                    }
                    Spacer()
                    Button {
                        showDifficultyPicker = true
                    } label: {
                        Text(selectedDifficulty.displayName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(white: 0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(white: 0.12).cornerRadius(8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.2), lineWidth: 1))
                    }
                }
                .padding(.horizontal)

                // HUD
                HUDView(
                    score: engine.score,
                    wordCount: engine.wordCount,
                    lostVowels: engine.lostVowels,
                    lastWord: engine.lastWord
                )
                .padding(.horizontal)

                // Vowel radar
                VowelRadarView(counts: engine.vowelCounts())
                    .padding(.horizontal)

                // Grid
                GridView(engine: engine)
                    .padding(.horizontal)

                // D-pad + selected tile display
                HStack(alignment: .center, spacing: 24) {
                    // Selected tile
                    VStack(spacing: 4) {
                        Text("SELECTED")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(white: 0.3))
                            .tracking(2)
                        if let pos = engine.selectedPosition,
                           let tile = engine.grid[pos.row][pos.col] {
                            Text(String(tile.letter))
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundColor(tileDisplayColor(tile))
                        } else {
                            Text("—")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(Color(white: 0.2))
                        }
                    }
                    .frame(width: 80)

                    DirectionPadView { dir in
                        engine.slide(direction: dir)
                    }

                    // Reset button
                    Button {
                        engine.reset(difficulty: selectedDifficulty)
                    } label: {
                        VStack(spacing: 4) {
                            Text("↺")
                                .font(.system(size: 22))
                                .foregroundColor(Color(white: 0.5))
                            Text("RESET")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(white: 0.3))
                                .tracking(1)
                        }
                        .frame(width: 80)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
            .padding(.top)

            // Game over overlay
            if engine.gameOver {
                gameOverOverlay
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog("Difficulty", isPresented: $showDifficultyPicker, titleVisibility: .visible) {
            ForEach(Difficulty.allCases) { diff in
                Button(diff.displayName) {
                    selectedDifficulty = diff
                    engine.reset(difficulty: diff)
                }
            }
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("VEXED")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Score: \(engine.score)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.yellow)
                Text("Words: \(engine.wordCount)  •  Vowels lost: \(engine.lostVowels)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.6))
                Button("Play Again") {
                    engine.reset(difficulty: selectedDifficulty)
                }
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(14)
            }
            .padding(32)
        }
    }

    private func tileDisplayColor(_ tile: Tile) -> Color {
        switch tile.type {
        case .consonant:  return Color(white: 0.7)
        case .vowel(.A):  return Color(red: 1.0, green: 0.42, blue: 0.42)
        case .vowel(.E):  return Color(red: 0.42, green: 1.0, blue: 0.53)
        case .vowel(.I):  return Color(red: 0.42, green: 0.56, blue: 1.0)
        case .vowel(.O):  return Color(red: 1.0, green: 0.8, blue: 0.33)
        case .vowel(.U):  return Color(red: 0.8, green: 0.47, blue: 1.0)
        }
    }
}
