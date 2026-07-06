import SwiftUI
import AVFoundation

struct GameView: View {
    var initialDifficulty: Difficulty = .easy
    var onResetAll: (() -> Void)? = nil
    @StateObject private var engine: GameEngine
    @State private var selectedDifficulty: Difficulty
    @AppStorage("selectedDifficulty") private var savedDifficultyRaw: String = Difficulty.fill.rawValue

    init(initialDifficulty: Difficulty = .easy, onResetAll: (() -> Void)? = nil) {
        self.initialDifficulty = initialDifficulty
        self.onResetAll = onResetAll
        _engine = StateObject(wrappedValue: GameEngine(difficulty: initialDifficulty))
        _selectedDifficulty = State(initialValue: initialDifficulty)
    }
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
    @State private var celebrationScale: CGFloat = 0.1
    @State private var breathPhase: Bool = false
    @State private var wordScoreFlash: Bool = false
    @State private var tutorialStep: Int = 0
    @State private var definitionEntry: DefinitionEntry? = nil
    @State private var hintCooldown = false
    @AppStorage("kidMode") private var kidMode: Bool = false
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.regular.rawValue
    @AppStorage("themeIsUserSet") private var themeIsUserSet: Bool = false
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .regular }
    private var theme: GameTheme { GameTheme(style: currentTheme) }
    /// Fun and Light both have bright/white backgrounds — text needs the same dark-on-light
    /// contrast treatment in header stats/icons regardless of which of the two is active.
    private var isLightBg: Bool { currentTheme == .fun || currentTheme == .light }

    var body: some View {
        ZStack {
            theme.bgBase.ignoresSafeArea()
            // Fun theme: pastel rainbow diagonal tint over the sky-blue base
            if currentTheme == .fun {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.88, blue: 0.95).opacity(0.45),
                        Color(red: 0.68, green: 0.88, blue: 1.0).opacity(0.0),
                        Color(red: 0.85, green: 1.0, blue: 0.88).opacity(0.35)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            // Arcade theme: faint CRT scanlines for retro cabinet flavor
            if theme.showScanlines {
                GeometryReader { geo in
                    let lineSpacing: CGFloat = 4
                    let lineCount = Int(geo.size.height / lineSpacing)
                    VStack(spacing: lineSpacing - 1) {
                        ForEach(0..<lineCount, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.12))
                                .frame(height: 1)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .blendMode(.multiply)
            }
            // Corner glows (arcade + fun theme)
            if theme.showCornerGlows {
                GeometryReader { geo in
                    RadialGradient(
                        colors: [theme.cornerGlowColors.topRight.opacity(theme.cornerGlowOpacity.topRight), .clear],
                        center: .topTrailing, startRadius: 0, endRadius: geo.size.width * 0.7
                    )
                    .ignoresSafeArea()
                    RadialGradient(
                        colors: [theme.cornerGlowColors.bottomLeft.opacity(theme.cornerGlowOpacity.bottomLeft), .clear],
                        center: .bottomLeading, startRadius: 0, endRadius: geo.size.width * 0.6
                    )
                    .ignoresSafeArea()
                }
                .allowsHitTesting(false)
            }
            // Breathing overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    theme.bgBreathColor.opacity(breathPhase ? theme.bgBreathOpacityHigh : theme.bgBreathOpacityLow),
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
                    // Score cluster — SCORE/WORDS/FORGED/LOST/COMBO always shown, in both modes,
                    // so the header stays the same width and alignment across modes.
                    HStack(spacing: 10) {
                        miniStat(label: "SCORE",  value: "\(displayScore)", color: isLightBg ? Color(red: 0.55, green: 0.38, blue: 0.0) : currentTheme == .arcade ? Color(red: 1.0, green: 0.0, blue: 0.85) : .white, isScore: true)
                        miniStat(label: "WORDS",  value: "\(engine.wordCount)", color: isLightBg ? Color(red: 0.10, green: 0.30, blue: 0.55) : currentTheme == .arcade ? Color(red: 0.0, green: 1.0, blue: 1.0) : Color(white: 0.85))
                        miniStat(label: "FORGED", value: "\(engine.tilesForged)", color: isLightBg ? Color(red: 0.0, green: 0.40, blue: 0.55) : currentTheme == .arcade ? Color(red: 0.75, green: 0.4, blue: 1.0) : Color(red: 0.3, green: 0.9, blue: 1.0))
                        miniStat(label: "LOST",   value: "\(engine.lostVowels)", color: isLightBg ? Color(red: 0.55, green: 0.10, blue: 0.10) : Color(red: 1, green: 0.4, blue: 0.4))
                        comboStat
                    }
                    .padding(.leading, 16)

                    Spacer()

                    // Controls
                    HStack(spacing: 8) {
                        if !kidMode {
                            hintIconButton
                        }
                        iconButton("line.3.horizontal") { showBurgerMenu = true }
                    }
                    .padding(.trailing, 12)
                }
                .padding(.vertical, 10)

                // ── Daily Puzzle indicator ────────────────────────────────
                if engine.isDailyMode {
                    HStack(spacing: 5) {
                        Text("🗓️ TODAY'S PUZZLE")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1)
                        if engine.dailyStreak > 0 {
                            Text("🔥\(engine.dailyStreak)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                    }
                    .foregroundColor(Color(red: 0.75, green: 0.55, blue: 1.0))
                    .padding(.bottom, 4)
                }

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

                    // Line 2: one scrollable row — pending words (tap to highlight) then collected chips
                    wordStrip
                        .frame(height: 36)
                }
                .padding(.bottom, 8)
            }

            // ── Word flash ────────────────────────────────────────────
            if let word = engine.flashWord { wordFlashOverlay(word) }

            // ── Particle bursts ───────────────────────────────────────
            particleBurstLayer

            // Combo badge removed — combo shown inline in kid header; multiplier visible on word chips

            // ── Word length celebration ───────────────────────────────
            if let word = engine.celebrationWord { wordCelebration(word) }

            // ── Toast for word scored ─────────────────────────────────
            if let msg = toastMessage { wordToast(msg) }

            // ── Vowel vanish banner ───────────────────────────────────
            if let msg = vanishMessage { vanishBanner(msg) }

            // ── Tile Forge banner ─────────────────────────────────────
            if let msg = engine.forgeMessage { forgeBanner(msg) }

            // ── New sticker earned (Kid Mode) ─────────────────────────
            if let word = engine.newStickerWord { newStickerBanner(word) }

            // ── Daily streak bonus (pre-placed forge tiles) ───────────
            if let msg = engine.streakBonusMessage { streakBonusBanner(msg) }

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
        .onChange(of: engine.boardVersion) { _, _ in hintCooldown = false }
        .sheet(isPresented: $showBurgerMenu) {
            BurgerMenuView(
                difficulty: $selectedDifficulty,
                currentScore: engine.score,
                onReset: {
                    showNoWordsLeft = false
                    engine.reset(difficulty: selectedDifficulty)
                },
                onResetAll: { resetEverything() },
                onGoHome: {
                    showNoWordsLeft = false
                    onResetAll?()
                },
                onShowInstructions: { showInstructions = true },
                onShowMissedWords: { showMissedWords = true },
                onStartDaily: {
                    showNoWordsLeft = false
                    engine.startDaily()
                }
            )
        }
        .sheet(isPresented: $showMissedWords) {
            MissedWordsView(grid: engine.grid, config: engine.config)
                .preferredColorScheme(.dark)
        }
        .sheet(item: Binding(
            get: { definitionEntry },
            set: { definitionEntry = $0 }
        )) { entry in
            DefinitionSheetView(entry: entry)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedDifficulty) { _, d in savedDifficultyRaw = d.rawValue }
        // React when splash screen (or any external writer) changes the stored difficulty
        .onChange(of: savedDifficultyRaw) { _, raw in
            guard let d = Difficulty(rawValue: raw), d != selectedDifficulty else { return }
            selectedDifficulty = d
            showNoWordsLeft = false
            engine.reset(difficulty: d)
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
            showNoWordsLeft = isLeft
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
        .onChange(of: engine.celebrationWord) { _, word in
            if let word {
                celebrationScale = 0.1
                if kidMode { KidVoice.say(word) }
            }
        }
        .onAppear {
            if isFirstLaunch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { tutorialStep = 1 }
            }
            applyDefaultThemeIfNeeded()
        }
        .onChange(of: kidMode) { _, _ in applyDefaultThemeIfNeeded() }
    }

    /// Kid mode defaults to Fun, Adult mode defaults to Regular — but once the player explicitly
    /// picks a theme in the burger menu, it sticks regardless of mode.
    private func applyDefaultThemeIfNeeded() {
        guard !themeIsUserSet else { return }
        appThemeRaw = (kidMode ? AppTheme.fun : AppTheme.regular).rawValue
    }

    // MARK: - Subviews

    @ViewBuilder private func endScreenOverlay(isGameOver: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 20) {
                // Daily Puzzle badge
                if engine.isDailyMode {
                    HStack(spacing: 6) {
                        Text("🗓️ DAILY PUZZLE")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.5)
                        if engine.dailyStreak > 0 {
                            Text("· 🔥 \(engine.dailyStreak)-day streak")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                    }
                    .foregroundColor(Color(red: 0.75, green: 0.55, blue: 1.0))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.18))
                            .overlay(Capsule().stroke(Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.4), lineWidth: 1))
                    )
                }

                // NEW HIGH SCORE banner
                if engine.isNewHighScore {
                    HStack(spacing: 6) {
                        Text("🏆")
                            .font(.system(size: 20))
                        Text("NEW HIGH SCORE!")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundColor(Color(red: 0.05, green: 0.05, blue: 0.05))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.2))
                            .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.6), radius: 16, x: 0, y: 0)
                    )
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }

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
                HStack(spacing: 10) {
                    // Home button
                    Button {
                        showNoWordsLeft = false
                        onResetAll?()
                    } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(white: 0.7))
                            .frame(width: 46, height: 46)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)

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
                        .padding(.horizontal, 16)
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
                            .padding(.horizontal, 20)
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
        var activityItems: [Any] = []
        if engine.isDailyMode {
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            let data = DailyShareCardData(
                dateLabel: df.string(from: Date()),
                score: engine.score,
                bestWord: engine.bestWord ?? "",
                peakCombo: engine.dailyPeakCombo,
                wordCount: engine.wordCount,
                streak: engine.dailyStreak
            )
            if let image = renderDailyShareImage(data) {
                activityItems.append(image)
            }
            activityItems.append("I played today's VEXED! Daily Puzzle — score \(engine.score)! Can you beat it?")
        } else {
            let grade = engine.letterGrade
            let bestWord = engine.bestWord.map { " Best word: \($0)." } ?? ""
            activityItems.append("VEXED! Score: \(engine.score) pts | \(engine.wordCount) words | Grade: \(grade).\(bestWord) Can you beat me?")
        }
        let av = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
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
            ParticleBurstView(origin: CGPoint(x: cx, y: cy), color: burst.color, intensity: burst.intensity) {
                activeBursts.removeAll { $0.id == burst.id }
            }
        }
    }

    @ViewBuilder private func wordToast(_ msg: String) -> some View {
        VStack {
            Spacer()
            Text(msg)
                .font(theme.toastFont)
                .foregroundColor(.black)
                .padding(.horizontal, theme.toastPaddingH)
                .padding(.vertical, theme.toastPaddingV)
                .background(RoundedRectangle(cornerRadius: theme.toastCornerRadius).fill(theme.toastFill))
                .shadow(color: Color.yellow.opacity(0.65), radius: (currentTheme == .arcade) ? 18 : 12, x: 0, y: 4)
                .rotationEffect(.degrees(toastRotation))
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder private func forgeBanner(_ msg: String) -> some View {
        VStack {
            Spacer()
            Text(msg)
                .font(theme.forgeBannerFont)
                .foregroundColor(.black)
                .padding(.horizontal, (currentTheme == .arcade) ? 22 : 18)
                .padding(.vertical, (currentTheme == .arcade) ? 11 : 9)
                .background(RoundedRectangle(cornerRadius: theme.forgeBannerRadius).fill(theme.forgeBannerFill))
                .shadow(color: Color.cyan.opacity(0.55), radius: (currentTheme == .arcade) ? 16 : 10, x: 0, y: 3)
                .padding(.bottom, 80)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder private func newStickerBanner(_ word: String) -> some View {
        VStack {
            HStack(spacing: 10) {
                Text(engine.newStickerEmoji)
                    .font(.system(size: 30))
                VStack(alignment: .leading, spacing: 1) {
                    Text("NEW STICKER!")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(.black.opacity(0.7))
                    Text(word.capitalized)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.3), Color(red: 1.0, green: 0.65, blue: 0.15)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            )
            .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.6), radius: 12, x: 0, y: 4)
            .padding(.top, 60)
            .transition(.move(edge: .top).combined(with: .opacity))
            Spacer()
        }
        .allowsHitTesting(false)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: engine.newStickerWord)
    }

    @ViewBuilder private func streakBonusBanner(_ msg: String) -> some View {
        VStack {
            Text(msg)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(
                    Capsule().fill(
                        LinearGradient(colors: [Color(red: 0.55, green: 0.35, blue: 1.0), Color(red: 0.85, green: 0.25, blue: 0.75)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                )
                .shadow(color: Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.6), radius: 14, x: 0, y: 4)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            Spacer()
        }
        .allowsHitTesting(false)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: engine.streakBonusMessage)
    }

    @ViewBuilder private func vanishBanner(_ msg: String) -> some View {
        VStack {
            Text(msg)
                .font(theme.vanishBannerFont)
                .foregroundColor(.white)
                .padding(.horizontal, (currentTheme == .arcade) ? 24 : 20)
                .padding(.vertical, (currentTheme == .arcade) ? 12 : 10)
                .background(RoundedRectangle(cornerRadius: theme.vanishBannerRadius).fill(theme.vanishBannerFill))
                .shadow(color: Color.red.opacity(0.55), radius: (currentTheme == .arcade) ? 16 : 10, x: 0, y: 3)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            Spacer()
        }
    }

    /// Single scrollable row: pending (scoreable-now) words first, then a divider, then the
    /// collected word history — replaces the old two stacked strips.
    private var wordStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(engine.availableWords) { entry in
                        AvailableWordChip(entry: entry, engine: engine) { word in
                            showDefinition(for: word, points: nil)
                        }
                    }
                    if !engine.availableWords.isEmpty && !engine.wordHistory.isEmpty {
                        Rectangle()
                            .fill(Color(white: 0.2))
                            .frame(width: 1, height: 18)
                            .padding(.horizontal, 2)
                    }
                    if engine.availableWords.isEmpty && engine.wordHistory.isEmpty {
                        Text("— no words yet —")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(white: 0.2))
                            .padding(.horizontal, 12)
                    } else {
                        ForEach(Array(engine.wordHistory.enumerated()), id: \.offset) { idx, entry in
                            let chipColor = chipTint(for: entry.word)
                            HStack(spacing: 4) {
                                Text(entry.word)
                                    .font(theme.chipFont)
                                    .foregroundColor(chipColor.foreground)
                                if entry.multiplier > 1.0 {
                                    Text("×\(entry.multiplier == 1.5 ? "1.5" : entry.multiplier == 2.0 ? "2" : "3")")
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundColor(comboColor())
                                }
                                Text("+\(entry.points)")
                                    .font(theme.chipPointsFont)
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, theme.chipPaddingH)
                            .padding(.vertical, theme.chipPaddingV)
                            .background(
                                RoundedRectangle(cornerRadius: theme.chipCornerRadius)
                                    .fill(theme.chipBg(forWordLength: entry.word.count))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.chipCornerRadius)
                                            .stroke(theme.chipBorder(forWordLength: entry.word.count) ?? .clear, lineWidth: 1.25)
                                    )
                            )
                            .shadow(color: (theme.chipBorder(forWordLength: entry.word.count) ?? .black).opacity(theme.chipBorder(forWordLength: entry.word.count) != nil ? 0.5 : 0.3), radius: 3, x: 0, y: 2)
                            .id(idx)
                            .onTapGesture { showDefinition(for: entry.word, points: entry.points) }
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
                        .font(theme.scoreFont)
                        .foregroundColor(color)
                        .tracking(theme.scoreTracking)
                        .contentTransition(.numericText())
                } else {
                    Text(value)
                        .font(theme.scoreFont)
                        .foregroundColor(color)
                        .tracking(theme.scoreTracking)
                }
            }
            Text(label)
                .font(theme.statLabelFont)
                .foregroundColor(theme.statLabelColor)
                .tracking(theme.statLabelTracking)
        }
        .padding(.vertical, (currentTheme == .arcade) ? 7 : 6)
        .padding(.horizontal, (currentTheme == .arcade) ? 8 : 4)
        .background(
            RoundedRectangle(cornerRadius: theme.statCornerRadius)
                .fill(theme.statBgColor(for: label).opacity(theme.statBgOpacity))
        )
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        let isLight = isLightBg
        let isArcade = currentTheme == .arcade
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isLight ? Color(red: 0.10, green: 0.25, blue: 0.65) : isArcade ? Color(red: 0.0, green: 1.0, blue: 0.95) : Color(white: 0.55))
                .frame(width: 40, height: 40)
                .background((isLight ? Color(white: 0.95) : Color(white: 0.13)).cornerRadius(12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isArcade ? Color(red: 0.0, green: 1.0, blue: 0.95).opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: (isLight ? Color(red: 0.0, green: 0.3, blue: 0.7) : isArcade ? Color(red: 0.0, green: 1.0, blue: 0.95) : Color.black).opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - New UX overlays

    /// Lightbulb hint icon for adult mode — sits beside the burger menu, triggers the same
    /// path + glow system as kid auto-hints.
    @ViewBuilder private var hintIconButton: some View {
        let isActive = engine.hintWordId != nil || !engine.hintMoves.isEmpty
        Button {
            guard !hintCooldown else { return }
            hintCooldown = true
            engine.requestHint()
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                hintCooldown = false
            }
        } label: {
            Image(systemName: isActive ? "lightbulb.fill" : "lightbulb")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isActive
                    ? Color(red: 1.0, green: 0.85, blue: 0.0)
                    : hintCooldown ? Color(white: 0.22) : Color(white: 0.55))
                .frame(width: 40, height: 40)
                .background(
                    (isActive ? Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.14) : Color(white: 0.13))
                        .cornerRadius(12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(hintCooldown && !isActive)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }

    /// Inline combo display — shown in both modes' headers.
    @ViewBuilder private var comboStat: some View {
        let active = engine.combo >= 2
        let color = comboColor()
        VStack(spacing: 1) {
            Text(active ? "\(engine.combo)×" : "—")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(active ? color : (isLightBg ? Color(red: 0.10, green: 0.25, blue: 0.50) : Color(white: 0.25)))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.55), value: engine.combo)
            Text("COMBO")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundColor(isLightBg
                    ? Color(red: 0.10, green: 0.25, blue: 0.50).opacity(active ? 0.85 : 0.55)
                    : Color(white: active ? 0.45 : 0.20))
                .tracking(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(active ? color.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(active ? color.opacity(0.45) : Color.clear, lineWidth: 1)
        )
        .shadow(color: active ? color.opacity(0.4) : .clear, radius: 6, x: 0, y: 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: active)
    }

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

    /// Friendly mascot who "reads" the word back in Kid Mode — reinforces the spelling mechanic
    /// itself rather than layering a generic reward on top of it.
    private let mascotEmoji = "🦉"

    @ViewBuilder private func wordCelebration(_ word: String) -> some View {
        let is6Plus = word.count >= 6
        let combo = engine.combo
        VStack {
            Spacer()
            Spacer()
            VStack(spacing: 8) {
                if kidMode {
                    Text(mascotEmoji)
                        .font(.system(size: 44))
                        .rotationEffect(.degrees(celebrationScale > 0.9 ? 0 : -8))
                }
                Text(is6Plus ? "AMAZING!" : "GREAT!")
                    .font(.system(size: is6Plus ? 36 : 28, weight: .black, design: .rounded))
                    .foregroundColor(is6Plus ? Color(red: 1.0, green: 0.85, blue: 0.0) : .white)
                    .shadow(color: (is6Plus ? Color.yellow : Color.white).opacity(0.5),
                            radius: 12, x: 0, y: 0)
                if combo >= 2 {
                    Text("🔥 \(combo)× COMBO")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(comboColor())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(comboColor().opacity(0.18))
                                .overlay(Capsule().stroke(comboColor().opacity(0.6), lineWidth: 1))
                        )
                        .shadow(color: comboColor().opacity(0.6), radius: 8, x: 0, y: 0)
                }
                if kidMode {
                    Text("\"\(word)\"")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                } else {
                    Text(word)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
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
        let steps: [(icon: String, title: String, body: String, accent: Color)] = [
            ("hand.tap",        "TAP TO SELECT",   "Tap any tile to select it. Arrows show every direction it can slide.", Color(red: 0.4, green: 0.8, blue: 1.0)),
            ("arrow.right",     "SWIPE TO SLIDE",  "Swipe in any direction — the tile flies until it hits a wall or another tile.", Color(red: 0.5, green: 0.9, blue: 0.5)),
            ("exclamationmark.triangle.fill", "THE VOWEL RULE", "3 or more of the SAME vowel touching = instant vanish. No score. Keep A E I O U separated!", Color(red: 1.0, green: 0.38, blue: 0.38)),
            ("star.fill",       "SCORE & FORGE",   "Spell words (left→right or top→bottom) and tap the gold outline to collect them. Longer words forge more new tiles back onto the board.", Color(red: 1.0, green: 0.85, blue: 0.2)),
        ]
        let step = steps[tutorialStep - 1]

        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: step.icon)
                    .font(.system(size: 32))
                    .foregroundColor(step.accent)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(step.accent.opacity(0.15)))

                Text(step.title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.white)

                Text(step.body)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)

                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { i in
                        Capsule()
                            .fill(i == tutorialStep ? step.accent : Color.white.opacity(0.2))
                            .frame(width: i == tutorialStep ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: tutorialStep)
                    }
                }

                Button {
                    if tutorialStep < 4 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { tutorialStep += 1 }
                    } else {
                        withAnimation(.easeOut(duration: 0.25)) {
                            tutorialStep = 0
                            isFirstLaunch = false
                        }
                        UserDefaults.standard.set(true, forKey: "vexed.launched")
                    }
                } label: {
                    Text(tutorialStep < 4 ? "NEXT →" : "LET'S PLAY!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(step.accent))
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

    // MARK: - Reset everything

    private func resetEverything() {
        // Clear high scores — new stable keys
        let ud = UserDefaults.standard
        for d in Difficulty.allCases {
            ud.removeObject(forKey: "hs_\(d.rawValue)")
            for age in KidAge.allCases {
                ud.removeObject(forKey: "hs_kid_\(age.rawValue)_\(d.rawValue)")
            }
        }
        // Clear tutorial-seen flag so it replays
        UserDefaults.standard.removeObject(forKey: "vexed.launched")
        // Clear Kid Mode sticker collection
        WordSticker.clearAll()
        // Clear Daily Puzzle streak/history
        ud.removeObject(forKey: "dailyLastPlayedKey")
        ud.removeObject(forKey: "dailyStreak")
        ud.removeObject(forKey: "dailyStreakBonusTiles")
        for daysAgo in 0..<400 {
            guard let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let key = SeededRNG.todayKey(date: date)
            ud.removeObject(forKey: "dailyScore_\(key)")
            ud.removeObject(forKey: "dailyBestWord_\(key)")
            ud.removeObject(forKey: "dailyPeakCombo_\(key)")
            ud.removeObject(forKey: "dailyWordCount_\(key)")
        }
        // Restore theme to its mode default
        themeIsUserSet = false
        applyDefaultThemeIfNeeded()
        // Reset game
        showNoWordsLeft = false
        engine.reset(difficulty: selectedDifficulty)
        // Restore first-launch state so tutorial fires after splash
        isFirstLaunch = true
        tutorialStep = 0
        // Go back to splash
        onResetAll?()
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

    func showDefinition(for word: String, points: Int?) {
        definitionEntry = DefinitionEntry(word: word, points: points)
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
