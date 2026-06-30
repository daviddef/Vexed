import SwiftUI

struct GameView: View {
    @StateObject private var engine = GameEngine(difficulty: .easy)
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showBurgerMenu = false
    @State private var showInstructions = false
    @State private var showMissedWords = false
    @State private var isFirstLaunch = !UserDefaults.standard.bool(forKey: "vexed.launched")
    @State private var toastMessage: String? = nil
    @State private var toastRotation: Double = 0
    @State private var showNoWordsLeft: Bool = false
    @State private var vanishMessage: String? = nil
    @State private var displayScore: Int = 0
    @State private var activeBursts: [GameEngine.BurstEvent] = []
    @State private var dangerPulse: Bool = false
    @State private var celebrationScale: CGFloat = 0.1
    @State private var breathPhase: Bool = false
    @State private var wordScoreFlash: Bool = false
    @State private var tutorialStep: Int = 0

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()
            // Breathing overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.08, blue: 0.18).opacity(breathPhase ? 0.4 : 0.15),
                    Color.clear
                ]),
                center: .center,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.width * 0.8
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: breathPhase)
            .onAppear { breathPhase = true }
            // Word score flash overlay
            Color(red: 0.3, green: 0.2, blue: 0.0)
                .opacity(wordScoreFlash ? 0.12 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {

                // ── Compact top bar ──────────────────────────────────────
                HStack(spacing: 0) {
                    // Score cluster
                    HStack(spacing: 12) {
                        miniStat(label: "SCORE",  value: "\(displayScore)", color: .white, isScore: true)
                        miniStat(label: "WORDS",  value: "\(engine.wordCount)", color: Color(white: 0.7))
                        miniStat(label: "FORGED", value: "\(engine.tilesForged)", color: Color(red: 0.3, green: 0.9, blue: 1.0))
                        miniStat(label: "LOST",   value: "\(engine.lostVowels)", color: Color(red: 1, green: 0.4, blue: 0.4))
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

                // ── Footer ───────────────────────────────────────────────
                VStack(spacing: 0) {
                    // Line 1: selected tile hint
                    selectedTileHint
                        .animation(.easeInOut(duration: 0.2), value: engine.selectedPosition)

                    // Line 2: available words (red) — tap to highlight on board
                    if !engine.availableWords.isEmpty {
                        availableWordsStrip
                            .frame(height: 36)
                    }

                    // Line 3: word history chips
                    wordHistoryStrip
                        .frame(height: 36)
                }
                .padding(.bottom, 8)
            }

            // ── Danger vignette ──────────────────────────────────────
            if let color = engine.dangerVowelColor {
                dangerVignette(color: color)
            }

            // ── Word flash ────────────────────────────────────────────
            if let word = engine.flashWord { wordFlashOverlay(word) }

            // ── Particle bursts ───────────────────────────────────────
            particleBurstLayer

            // ── Combo badge ───────────────────────────────────────────
            if engine.combo >= 2 {
                comboBadge
            }

            // ── Word length celebration ───────────────────────────────
            if let word = engine.celebrationWord { wordCelebration(word) }

            // ── Toast for word scored ─────────────────────────────────
            if let msg = toastMessage { wordToast(msg) }

            // ── Vowel vanish banner ───────────────────────────────────
            if let msg = vanishMessage { vanishBanner(msg) }

            // ── Tile Forge banner ─────────────────────────────────────
            if let msg = engine.forgeMessage { forgeBanner(msg) }

            // ── No-words-left overlay ─────────────────────────────────
            if showNoWordsLeft && !engine.gameOver {
                endScreenOverlay(isGameOver: false).zIndex(8)
            }

            // ── Instructions overlay ──────────────────────────────────
            if showInstructions {
                InstructionsView {
                    withAnimation(.easeOut(duration: 0.25)) { showInstructions = false }
                }
                .zIndex(10)
            }
            if isFirstLaunch && tutorialStep > 0 && tutorialStep <= 3 {
                tutorialOverlay.zIndex(10)
            }

            // ── Game over overlay ─────────────────────────────────────
            if engine.gameOver {
                endScreenOverlay(isGameOver: true).zIndex(9)
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
            withAnimation(.easeOut(duration: 0.15)) { wordScoreFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.6)) { wordScoreFlash = false }
            }
        }
        .onChange(of: engine.lostVowels) { old, new in
            let just = new - old
            guard just > 0 else { return }
            let plural = just == 1 ? "" : "s"
            let msg = "💥 \(just) vowel\(plural) vanished!"
            withAnimation(.easeOut(duration: 0.3)) { vanishMessage = msg }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeIn(duration: 0.25)) { vanishMessage = nil }
            }
        }
        .onChange(of: engine.noWordsLeft) { _, isLeft in
            if isLeft { showNoWordsLeft = true }
        }
        .onChange(of: engine.score) { _, newScore in
            let start = displayScore
            let diff = newScore - start
            guard diff > 0 else { displayScore = newScore; return }
            let steps = min(diff, 30) // cap animation frames
            let interval = 0.35 / Double(steps)
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                    displayScore = start + (diff * i / steps)
                }
            }
        }
        .onChange(of: engine.burstEvents) { _, events in
            let existingIDs = Set(activeBursts.map(\.id))
            let newBursts = events.filter { !existingIDs.contains($0.id) }
            activeBursts.append(contentsOf: newBursts)
        }
        .onChange(of: engine.dangerVowelColor) { _, _ in
            dangerPulse = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { dangerPulse = true }
        }
        .onChange(of: engine.celebrationWord) { _, word in
            if word != nil { celebrationScale = 0.1 }
        }
        .onAppear {
            if isFirstLaunch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { tutorialStep = 1 }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder private func endScreenOverlay(isGameOver: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 24) {
                // Grade badge
                ZStack {
                    Circle()
                        .fill(gradeColor(engine.letterGrade))
                        .frame(width: 90, height: 90)
                        .shadow(color: gradeColor(engine.letterGrade).opacity(0.5), radius: 16)
                    Text(engine.letterGrade)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }

                // Title
                Text(isGameOver ? "GAME OVER" : "NO MOVES LEFT")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.5))

                // Score
                VStack(spacing: 4) {
                    Text("\(engine.score)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    Text("POINTS")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(4)
                        .foregroundColor(.white.opacity(0.4))
                }

                // Stats row
                HStack(spacing: 24) {
                    endStat(label: "WORDS", value: "\(engine.wordCount)")
                    endStat(label: "LOST", value: "\(engine.lostVowels)")
                    if engine.peakScore > 0 {
                        let pct = min(100, engine.score * 100 / max(1, engine.peakScore))
                        endStat(label: "PEAK%", value: "\(pct)%")
                    }
                }

                // Best word
                if let best = engine.bestWord {
                    HStack(spacing: 8) {
                        Text("BEST WORD")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.35))
                        Text(best)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                }

                // Buttons row
                HStack(spacing: 12) {
                    // Share button
                    Button {
                        shareResult()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("SHARE")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .tracking(2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    // Play again button
                    Button {
                        withAnimation {
                            showNoWordsLeft = false
                            engine.reset(difficulty: selectedDifficulty)
                        }
                    } label: {
                        Text("PLAY AGAIN")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                            .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }

    @ViewBuilder private func endStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "S": return Color(red: 1.0, green: 0.85, blue: 0.0)
        case "A": return Color(red: 0.2, green: 0.85, blue: 0.4)
        case "B": return Color(red: 0.2, green: 0.5, blue: 1.0)
        case "C": return Color(red: 1.0, green: 0.6, blue: 0.1)
        case "D": return Color(red: 0.8, green: 0.3, blue: 0.1)
        default:  return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }

    private func shareResult() {
        let grade = engine.letterGrade
        let bestWord = engine.bestWord.map { " Best word: \($0)." } ?? ""
        let text = "VEXED! Score: \(engine.score) pts | \(engine.wordCount) words | Grade: \(grade).\(bestWord) Can you beat me?"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = scene.windows.first?.rootViewController {
            vc.present(av, animated: true)
        }
    }

    @ViewBuilder private func wordFlashOverlay(_ word: String) -> some View {
        VStack {
            Spacer()
            Text(word)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, Color(white: 0.85)],
                                               startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                .scaleEffect(1.0)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.4).combined(with: .opacity),
                    removal: .scale(scale: 1.3).combined(with: .opacity)
                ))
            Spacer()
        }
        .allowsHitTesting(false)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: engine.flashWord)
    }

    @ViewBuilder private var selectedTileHint: some View {
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

    @ViewBuilder private var particleBurstLayer: some View {
        let cx = UIScreen.main.bounds.width / 2
        let cy = UIScreen.main.bounds.height / 2
        ForEach(activeBursts) { burst in
            ParticleBurstView(origin: CGPoint(x: cx, y: cy), color: burst.color) {
                activeBursts.removeAll { $0.id == burst.id }
            }
        }
    }

    @ViewBuilder private func wordToast(_ msg: String) -> some View {
        VStack {
            Spacer()
            Text(msg)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.yellow))
                .shadow(color: Color.yellow.opacity(0.6), radius: 12, x: 0, y: 4)
                .rotationEffect(.degrees(toastRotation))
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder private func forgeBanner(_ msg: String) -> some View {
        VStack {
            Spacer()
            Text(msg)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.3, green: 0.9, blue: 1.0)))
                .shadow(color: Color.cyan.opacity(0.5), radius: 10, x: 0, y: 3)
                .padding(.bottom, 80)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder private func vanishBanner(_ msg: String) -> some View {
        VStack {
            Text(msg)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.85, green: 0.15, blue: 0.15)))
                .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 3)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            Spacer()
        }
    }

    private var availableWordsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(engine.availableWords) { entry in
                    let isHighlighted = engine.highlightedPositions == Set(entry.positions)
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            if isHighlighted {
                                engine.highlightedPositions = nil
                            } else {
                                engine.highlightedPositions = Set(entry.positions)
                            }
                        }
                    } label: {
                        Text(entry.word)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(isHighlighted ? .black : Color(red: 1, green: 0.38, blue: 0.38))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isHighlighted
                                          ? Color(red: 1, green: 0.38, blue: 0.38)
                                          : Color(red: 1, green: 0.38, blue: 0.38).opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 1, green: 0.38, blue: 0.38).opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isHighlighted)
                }
            }
            .padding(.horizontal, 12)
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

    private func miniStat(label: String, value: String, color: Color, isScore: Bool = false) -> some View {
        VStack(spacing: 1) {
            Group {
                if isScore {
                    Text(value)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(color)
                        .contentTransition(.numericText())
                } else {
                    Text(value)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(color)
                }
            }
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

    // MARK: - New UX overlays

    @ViewBuilder private var comboBadge: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text("\(engine.combo)x")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("COMBO")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(comboColor())
                        .shadow(color: comboColor().opacity(0.5), radius: 10, x: 0, y: 4)
                )
                .scaleEffect(engine.combo >= 2 ? 1 : 0.5)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.55), value: engine.combo)
                .padding(.trailing, 16)
            }
            .padding(.top, 60)
            Spacer()
        }
    }

    private func comboColor() -> Color {
        switch engine.combo {
        case 2: return Color(red: 1.0, green: 0.7, blue: 0.0)    // gold
        case 3: return Color(red: 1.0, green: 0.4, blue: 0.1)    // orange
        default: return Color(red: 0.9, green: 0.1, blue: 0.9)   // magenta for 4+
        }
    }

    @ViewBuilder private func dangerVignette(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.clear, color.opacity(dangerPulse ? 0.35 : 0.15)]),
                    center: .center,
                    startRadius: UIScreen.main.bounds.width * 0.3,
                    endRadius: UIScreen.main.bounds.width * 0.85
                )
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: dangerPulse)
            .onAppear { dangerPulse = true }
            .onDisappear { dangerPulse = false }
    }

    @ViewBuilder private func wordCelebration(_ word: String) -> some View {
        let is6Plus = word.count >= 6
        VStack {
            Spacer()
            Spacer()
            VStack(spacing: 8) {
                Text(is6Plus ? "AMAZING!" : "GREAT!")
                    .font(.system(size: is6Plus ? 36 : 28, weight: .black, design: .rounded))
                    .foregroundColor(is6Plus ? Color(red: 1.0, green: 0.85, blue: 0.0) : .white)
                    .shadow(color: (is6Plus ? Color.yellow : Color.white).opacity(0.5),
                            radius: 12, x: 0, y: 0)
                Text(word)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Text("\(word.count) letters")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(is6Plus ? Color.yellow.opacity(0.6) : Color.white.opacity(0.2),
                                    lineWidth: 1.5)
                    )
            )
            .scaleEffect(celebrationScale)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.3).combined(with: .opacity),
                removal: .opacity
            ))
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    celebrationScale = 1.0
                }
            }
            .onDisappear { celebrationScale = 0.1 }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Tutorial

    @ViewBuilder private var tutorialOverlay: some View {
        let steps: [(icon: String, title: String, body: String)] = [
            ("hand.tap", "TAP A TILE", "Select any tile — it highlights the paths it can slide along."),
            ("arrow.right", "SWIPE TO SLIDE", "Swipe to send it flying! Tiles glide until they hit a wall or another tile."),
            ("text.word.spacing", "SPELL WORDS", "Line up letters in a row or column to score. 3+ of the same vowel touching will vanish — watch out!")
        ]
        let step = steps[tutorialStep - 1]

        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: step.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color.white.opacity(0.15)))

                Text(step.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.white)

                Text(step.body)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { i in
                        Circle()
                            .fill(i == tutorialStep ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }

                Button {
                    if tutorialStep < 3 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { tutorialStep += 1 }
                    } else {
                        withAnimation(.easeOut(duration: 0.25)) {
                            tutorialStep = 0
                            isFirstLaunch = false
                        }
                        UserDefaults.standard.set(true, forKey: "vexed.launched")
                    }
                } label: {
                    Text(tutorialStep < 3 ? "NEXT →" : "LET'S GO!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.82))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.12), lineWidth: 1))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
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
