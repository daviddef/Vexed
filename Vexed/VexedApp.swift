import SwiftUI

@main
struct VexedApp: App {
    @State private var showSplash = true
    @AppStorage("selectedDifficulty") private var savedDifficultyRaw: String = Difficulty.easy.rawValue

    init() {
        // Kick off word-list trie builds on a background thread immediately.
        // The 1.5s splash entrance animation gives ~1s buffer before the user
        // can interact with GameView, so the cache is warm by then.
        Task.detached(priority: .userInitiated) {
            _ = WordValidator.forResource("easy_words")
            _ = WordValidator.forResource("medium_words")
            _ = WordValidator.forResource("kid_words")
            _ = WordValidator.forResource("words")
        }
    }

    var body: some Scene {
        WindowGroup {
            let difficulty = Difficulty(rawValue: savedDifficultyRaw) ?? .easy
            ZStack {
                GameView(initialDifficulty: difficulty, onResetAll: {
                    withAnimation(.easeOut(duration: 0.2)) { showSplash = true }
                })

                if showSplash {
                    SplashView {
                        withAnimation(.easeIn(duration: 0.2)) {
                            showSplash = false
                        }
                    }
                    .zIndex(100)
                }
            }
        }
    }
}
