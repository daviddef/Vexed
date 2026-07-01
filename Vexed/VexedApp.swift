import SwiftUI

@main
struct VexedApp: App {
    @State private var showSplash = true
    @State private var wordListsReady = false
    @AppStorage("selectedDifficulty") private var savedDifficultyRaw: String = Difficulty.easy.rawValue

    var body: some Scene {
        WindowGroup {
            let difficulty = Difficulty(rawValue: savedDifficultyRaw) ?? .easy
            ZStack {
                // Only render GameView once word lists are pre-warmed to avoid main-thread freeze
                if wordListsReady {
                    GameView(initialDifficulty: difficulty, onResetAll: {
                        withAnimation(.easeOut(duration: 0.2)) { showSplash = true }
                    })
                } else {
                    // Background while word lists load — splash sits on top
                    Color(red: 0.04, green: 0.04, blue: 0.08).ignoresSafeArea()
                }

                if showSplash {
                    SplashView {
                        withAnimation(.easeIn(duration: 0.2)) {
                            showSplash = false
                        }
                    }
                    .zIndex(100)
                }
            }
            .task {
                // Pre-warm all word lists off the main thread so GameView.init is instant
                await Task.detached(priority: .userInitiated) {
                    _ = WordValidator.forResource("easy_words")
                    _ = WordValidator.forResource("medium_words")
                    _ = WordValidator.forResource("kid_words")
                    _ = WordValidator.forResource("words")
                }.value
                wordListsReady = true
            }
        }
    }
}
