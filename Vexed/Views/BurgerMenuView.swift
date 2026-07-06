import SwiftUI

struct BurgerMenuView: View {
    @Binding var difficulty: Difficulty
    var currentScore: Int
    @Environment(\.dismiss) private var dismiss
    var onReset: () -> Void
    var onResetAll: () -> Void
    var onGoHome: () -> Void
    var onShowInstructions: () -> Void
    var onShowMissedWords: () -> Void
    var onStartDaily: () -> Void
    var onStartPuzzle: (Int) -> Void

    @AppStorage("includeRareWords") private var includeRareWords: Bool = false
    @AppStorage("kidMode") private var kidMode: Bool = false
    @AppStorage("kidAge") private var kidAgeRaw: String = KidAge.explorer.rawValue
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.regular.rawValue
    @AppStorage("themeIsUserSet") private var themeIsUserSet: Bool = false
    private var currentTheme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .regular }

    private var currentKidAge: KidAge {
        get { KidAge(rawValue: kidAgeRaw) ?? .explorer }
        set { kidAgeRaw = newValue.rawValue }
    }

    private var highScore: Int { GameEngine.highScore(for: difficulty) }
    @State private var showAllScores = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // ── Top quick-action row ─────────────────────────
                        HStack(spacing: 12) {
                            quickAction(icon: "house.fill", label: "HOME",
                                        color: Color(white: 0.75)) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    onGoHome()
                                }
                            }
                            quickAction(icon: "arrow.counterclockwise", label: "RESET",
                                        color: Color(red: 1.0, green: 0.75, blue: 0.3)) {
                                onReset()
                                dismiss()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // ── Score card ───────────────────────────────────
                        HStack(spacing: 0) {
                            scoreCell(label: "THIS GAME", value: currentScore, color: .white)
                            Rectangle()
                                .fill(Color(white: 0.12))
                                .frame(width: 1)
                                .padding(.vertical, 12)
                            Button { showAllScores = true } label: {
                                scoreCell(
                                    label: "PEAK VEXATION ›",
                                    value: highScore,
                                    color: highScore > 0 && currentScore >= highScore
                                        ? Color(red: 1, green: 0.85, blue: 0.2)
                                        : Color(red: 1, green: 0.85, blue: 0.2).opacity(0.6)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.07)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.11), lineWidth: 1))
                        .padding(.horizontal, 20)
                        .sheet(isPresented: $showAllScores) { allScoresSheet }

                        // ── Daily Puzzle ──────────────────────────────────
                        dailyPuzzleCard
                            .padding(.horizontal, 20)

                        // ── Puzzle Mode ────────────────────────────────────
                        puzzleModeCard
                            .padding(.horizontal, 20)

                        // ── Mode cards ───────────────────────────────────
                        sectionCard {
                            sectionLabel("MODE")
                            HStack(spacing: 10) {
                                modeCard(
                                    icon: "star.circle.fill",
                                    title: "Kid Mode",
                                    subtitle: "Hints · shorter words\nbigger forge bonus",
                                    isSelected: kidMode,
                                    accentColor: Color(red: 1.0, green: 0.75, blue: 0.1)
                                ) {
                                    if !kidMode {
                                        kidMode = true
                                        if difficulty == .hard { difficulty = .easy }
                                        onReset()
                                    }
                                }
                                modeCard(
                                    icon: "bolt.circle.fill",
                                    title: "Adult Mode",
                                    subtitle: "Full vocabulary\ncompetitive play",
                                    isSelected: !kidMode,
                                    accentColor: Color(red: 0.4, green: 0.7, blue: 1.0)
                                ) {
                                    if kidMode {
                                        kidMode = false
                                        onReset()
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)

                            if kidMode {
                                Divider().background(Color(white: 0.12)).padding(.horizontal, 14)
                                HStack(spacing: 4) {
                                    ForEach(KidAge.allCases) { age in
                                        ageTierButton(age)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)

                                Divider().background(Color(white: 0.12)).padding(.horizontal, 14)
                                NavigationLink {
                                    StickerGalleryView()
                                } label: {
                                    menuLinkRow(icon: "star.square.on.square.fill", label: "My Stickers (\(WordSticker.count()))")
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // ── Board size ───────────────────────────────────
                        sectionCard {
                            sectionLabel("BOARD SIZE")
                            difficultyRow
                            Text(kidMode ? kidBoardDescription : difficulty.description)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Color(white: 0.4))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 14)
                        }
                        .padding(.horizontal, 20)

                        // ── Theme ────────────────────────────────────────
                        sectionCard {
                            sectionLabel("THEME")
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                                ForEach(AppTheme.allCases) { t in
                                    modeCard(
                                        icon: t.icon,
                                        title: t.displayName,
                                        subtitle: t.subtitle,
                                        isSelected: currentTheme == t,
                                        accentColor: t.accentColor
                                    ) {
                                        appThemeRaw = t.rawValue
                                        themeIsUserSet = true
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 10)
                            Text("\(kidMode ? "Kid" : "Adult") mode defaults to \(kidMode ? "Fun" : "Regular") — pick any theme and it'll stick.")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color(white: 0.35))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 14)
                        }
                        .padding(.horizontal, 20)

                        // ── Help ─────────────────────────────────────────
                        sectionCard {
                            sectionLabel("HELP")
                            NavigationLink {
                                HowToPlayView()
                            } label: {
                                menuLinkRow(icon: "questionmark.circle", label: "How to Play")
                            }
                            Divider().background(Color(white: 0.12)).padding(.horizontal, 14)
                            NavigationLink {
                                TipsView()
                                    .navigationTitle("Tips")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.09), for: .navigationBar)
                                    .toolbarBackground(.visible, for: .navigationBar)
                            } label: {
                                menuLinkRow(icon: "lightbulb", label: "Tips & Tricks")
                            }
                            Divider().background(Color(white: 0.12)).padding(.horizontal, 14)
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onShowMissedWords() }
                            } label: {
                                menuLinkRow(icon: "magnifyingglass", label: "Show Missed Words")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)

                        // ── Settings ─────────────────────────────────────
                        sectionCard {
                            sectionLabel("SETTINGS")
                            toggleRow(
                                icon: "character.book.closed",
                                title: "Rare & archaic words",
                                subtitle: "Technical, abbreviations, non-English",
                                isOn: $includeRareWords,
                                tint: Color(white: 0.8)
                            ) { onReset(); dismiss() }
                        }
                        .padding(.horizontal, 20)

                        // ── Danger zone ───────────────────────────────────
                        sectionCard {
                            sectionLabel("DANGER ZONE")
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onResetAll() }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Reset Everything")
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                }
                                .foregroundColor(Color(red: 1, green: 0.35, blue: 0.35))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("VEXED")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(6)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(white: 0.35))
                    }
                }
            }
            .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.09), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Mode card

    private func modeCard(icon: String, title: String, subtitle: String,
                          isSelected: Bool, accentColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? accentColor : Color(white: 0.3))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(accentColor)
                    }
                }
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color(white: 0.4))
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Color(white: 0.55) : Color(white: 0.28))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor.opacity(0.12) : Color(white: 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor.opacity(0.5) : Color(white: 0.09), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Quick action button

    private func quickAction(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.09)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section card container

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.075)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(white: 0.11), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(Color(white: 0.3))
            .tracking(3)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func menuLinkRow(icon: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(white: 0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func toggleRow(icon: String, title: String, subtitle: String,
                           isOn: Binding<Bool>, tint: Color, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isOn.wrappedValue ? tint : Color(white: 0.55))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.4))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(tint == Color(white: 0.8) ? .accentColor : tint)
                .onChange(of: isOn.wrappedValue) { _, _ in onChange() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Difficulty picker (single row)

    private var difficultyRow: some View {
        HStack(spacing: 0) {
            if kidMode {
                kidBoardButton(.easy,   label: "Small")
                kidBoardButton(.medium, label: "Medium")
                kidBoardButton(.fill,   label: "Full")
            } else {
                difficultyButton(.easy)
                difficultyButton(.medium)
                difficultyButton(.hard)
                difficultyButton(.fill)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.05)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.10), lineWidth: 1))
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private func difficultyButton(_ d: Difficulty) -> some View {
        Button {
            guard d != difficulty else { return }
            difficulty = d
            onReset()
        } label: {
            Text(d.displayName)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundColor(d == difficulty ? .black : Color(white: 0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 9).fill(d == difficulty ? pillColor(d) : Color.clear))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: difficulty)
    }

    private func kidBoardButton(_ d: Difficulty, label: String) -> some View {
        Button {
            guard d != difficulty else { return }
            difficulty = d
            onReset()
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundColor(d == difficulty ? .black : Color(white: 0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 9)
                    .fill(d == difficulty ? Color(red: 1.0, green: 0.75, blue: 0.1) : Color.clear))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: difficulty)
    }

    private func ageTierButton(_ age: KidAge) -> some View {
        let isSelected = kidAgeRaw == age.rawValue
        return Button {
            guard !isSelected else { return }
            kidAgeRaw = age.rawValue
            onReset()
        } label: {
            VStack(spacing: 3) {
                Text(age.emoji).font(.system(size: 20))
                Text(age.displayName)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.5)
                Text(age.ageRange)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : Color(white: 0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color(red: 1.0, green: 0.75, blue: 0.1) : Color.clear))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: kidAgeRaw)
    }

    // MARK: - Daily Puzzle

    @ViewBuilder private var dailyPuzzleCard: some View {
        let status = GameEngine.dailyStatus()
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onStartDaily() }
        } label: {
            HStack(spacing: 14) {
                Text("🗓️")
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("DAILY PUZZLE")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundColor(.white)
                        if status.streak > 0 {
                            HStack(spacing: 2) {
                                Text("🔥")
                                Text("\(status.streak)")
                            }
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.2))
                        }
                    }
                    Text(status.playedToday
                        ? "Played today — score \(status.todayScore). Come back tomorrow!"
                        : "Same board for everyone today — see how you rank.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(white: 0.3))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Puzzle Mode

    private static let puzzleMoveLimits: [(label: String, moves: Int)] = [
        ("QUICK", 12), ("STANDARD", 20), ("LONG", 30)
    ]

    @ViewBuilder private var puzzleModeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Text("🧩")
                    .font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text("PUZZLE MODE")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundColor(.white)
                    Text("Solve a fresh board in a capped number of slides.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                        .lineLimit(2)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(Self.puzzleMoveLimits, id: \.moves) { option in
                    let best = GameEngine.puzzleBest(moveLimit: option.moves)
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onStartPuzzle(option.moves) }
                    } label: {
                        VStack(spacing: 2) {
                            Text(option.label)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(0.5)
                            Text("\(option.moves) moves")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(white: 0.5))
                            if best > 0 {
                                Text("best \(best)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.10)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.16), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.3, green: 0.75, blue: 1.0).opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.3, green: 0.75, blue: 1.0).opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - All scores sheet

    private var allScoresSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()
                let scores = GameEngine.allHighScores()
                if scores.isEmpty {
                    VStack(spacing: 12) {
                        Text("No scores yet")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(Color(white: 0.4))
                        Text("Complete a game to set your first peak vexation score.")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.3))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(scores.enumerated()), id: \.offset) { idx, entry in
                                HStack {
                                    Text("#\(idx + 1)")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundColor(idx == 0 ? Color(red: 1, green: 0.85, blue: 0.2) : Color(white: 0.3))
                                        .frame(width: 32, alignment: .leading)
                                    Text(entry.label)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(entry.score)")
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .foregroundColor(idx == 0 ? Color(red: 1, green: 0.85, blue: 0.2) : Color(white: 0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: idx == 0 ? 0.09 : 0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                                    idx == 0 ? Color(red: 1, green: 0.85, blue: 0.2).opacity(0.3) : Color(white: 0.08),
                                    lineWidth: 1))
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PEAK VEXATION")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(4)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAllScores = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(white: 0.35))
                    }
                }
            }
            .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.09), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private var kidBoardDescription: String {
        switch difficulty {
        case .easy:   return "Small board (5×5) · \(KidAge(rawValue: kidAgeRaw)?.minWordLength ?? 2)+ letters"
        case .medium: return "Medium board (7×7) · \(KidAge(rawValue: kidAgeRaw)?.minWordLength ?? 2)+ letters"
        case .fill:   return "Full screen · \(KidAge(rawValue: kidAgeRaw)?.minWordLength ?? 2)+ letters"
        default:      return "Small board · \(KidAge(rawValue: kidAgeRaw)?.minWordLength ?? 2)+ letters"
        }
    }

    private func pillColor(_ d: Difficulty) -> Color {
        switch d {
        case .easy:   return Color(red: 0.3, green: 0.9, blue: 0.5)
        case .medium: return Color(red: 1.0, green: 0.75, blue: 0.1)
        case .hard:   return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .fill:   return Color(red: 0.55, green: 0.35, blue: 1.0)
        }
    }

    private func scoreCell(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Color(white: 0.35))
                .tracking(2)
            if value > 0 {
                Text("\(value)")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(color)
            } else {
                Text("—")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(Color(white: 0.2))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}
