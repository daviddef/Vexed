import SwiftUI

struct BurgerMenuView: View {
    @Binding var difficulty: Difficulty
    var currentScore: Int
    @Environment(\.dismiss) private var dismiss
    var onReset: () -> Void
    var onResetAll: () -> Void
    var onShowInstructions: () -> Void
    var onShowMissedWords: () -> Void

    @AppStorage("includeRareWords") private var includeRareWords: Bool = false
    @AppStorage("arcadeMode") private var arcadeMode: Bool = false
    @AppStorage("kidMode") private var kidMode: Bool = false
    @AppStorage("kidAge") private var kidAgeRaw: String = KidAge.explorer.rawValue
    @State private var showTips = false

    private var currentKidAge: KidAge {
        get { KidAge(rawValue: kidAgeRaw) ?? .explorer }
        set { kidAgeRaw = newValue.rawValue }
    }

    private var highScore: Int { GameEngine.highScore(for: difficulty) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("VEXED")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(10)
                            Text("SLIDE · FORM · SURVIVE")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(Color(white: 0.3))
                                .tracking(3)
                        }

                        // Score card
                        HStack(spacing: 0) {
                            scoreCell(label: "THIS GAME", value: currentScore, color: .white)
                            Rectangle()
                                .fill(Color(white: 0.12))
                                .frame(width: 1)
                                .padding(.vertical, 12)
                            scoreCell(
                                label: "PEAK VEXATION",
                                value: highScore,
                                color: highScore > 0 && currentScore >= highScore
                                    ? Color(red: 1, green: 0.85, blue: 0.2)
                                    : Color(red: 1, green: 0.85, blue: 0.2).opacity(0.6)
                            )
                        }
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.07)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.11), lineWidth: 1))
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                    // Menu rows
                    VStack(spacing: 0) {
                        // Kid Mode + Game section
                        VStack(alignment: .leading, spacing: 0) {
                            menuSectionHeader("KID MODE")

                            // Kid mode toggle
                            HStack(spacing: 14) {
                                Image(systemName: "star.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(kidMode ? Color(red: 1.0, green: 0.75, blue: 0.1) : .white)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Kid Mode")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Shorter words · hints · bigger forge bonus")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(white: 0.4))
                                }
                                Spacer()
                                Toggle("", isOn: $kidMode)
                                    .labelsHidden()
                                    .tint(Color(red: 1.0, green: 0.75, blue: 0.1))
                                    .onChange(of: kidMode) { _, _ in
                                        onReset()
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(white: 0.08))

                            if kidMode {
                                Divider().background(Color(white: 0.1))
                                // Age tier picker
                                VStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        ForEach(KidAge.allCases) { age in
                                            ageTierButton(age)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(white: 0.08))
                            }

                            Divider().background(Color(white: 0.1))

                            menuSectionHeader("GAME")

                            VStack(spacing: 10) {
                                difficultyPill
                                Text(kidMode ? kidBoardDescription : difficulty.description)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(white: 0.4))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(white: 0.08))

                            Divider().background(Color(white: 0.1))

                            menuRow(icon: "arrow.counterclockwise", label: "Reset Board", color: .white) {
                                onReset()
                                dismiss()
                            }
                        }

                        Spacer().frame(height: 20)

                        VStack(alignment: .leading, spacing: 0) {
                            menuSectionHeader("HELP")

                            NavigationLink {
                                HowToPlayView()
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 24)
                                    Text("How to Play")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(white: 0.3))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(white: 0.08))
                            }

                            Divider().background(Color(white: 0.1))

                            NavigationLink {
                                TipsView()
                                    .navigationTitle("Tips")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbarBackground(Color(red: 0.06, green: 0.06, blue: 0.09), for: .navigationBar)
                                    .toolbarBackground(.visible, for: .navigationBar)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "lightbulb")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 24)
                                    Text("Tips")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(white: 0.3))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(white: 0.08))
                            }

                            Divider().background(Color(white: 0.1))

                            Divider().background(Color(white: 0.1))

                            // Rare words toggle
                            HStack(spacing: 14) {
                                Image(systemName: "character.book.closed")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rare & archaic words")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Includes technical, abbreviations, non-English")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(white: 0.4))
                                }
                                Spacer()
                                Toggle("", isOn: $includeRareWords)
                                    .labelsHidden()
                                    .onChange(of: includeRareWords) { _, _ in
                                        onReset()
                                        dismiss()
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(white: 0.08))

                            Divider().background(Color(white: 0.1))

                            // Arcade mode toggle
                            HStack(spacing: 14) {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(arcadeMode ? Color(red: 0.7, green: 0.4, blue: 1.0) : .white)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Arcade Mode")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Vivid background, textured tiles, bold scoreboard")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(white: 0.4))
                                }
                                Spacer()
                                Toggle("", isOn: $arcadeMode)
                                    .labelsHidden()
                                    .tint(Color(red: 0.7, green: 0.4, blue: 1.0))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(white: 0.08))

                            Divider().background(Color(white: 0.1))

                            menuRow(icon: "magnifyingglass", label: "Show Missed Words", color: .white) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    onShowMissedWords()
                                }
                            }
                        }

                        Spacer().frame(height: 20)

                        // Danger zone
                        VStack(alignment: .leading, spacing: 0) {
                            menuSectionHeader("DANGER ZONE")

                            menuRow(icon: "trash", label: "Reset Everything", color: Color(red: 1, green: 0.3, blue: 0.3)) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    onResetAll()
                                }
                            }
                        }
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
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

    private var difficultyPill: some View {
        Group {
            if kidMode {
                // Kid mode: Small / Medium / Full (3 options, no Hard)
                HStack(spacing: 0) {
                    kidBoardButton(.easy,   label: "Small")
                    kidBoardButton(.medium, label: "Medium")
                    kidBoardButton(.fill,   label: "Full")
                }
            } else {
                // Normal: 2×2 grid
                VStack(spacing: 4) {
                    HStack(spacing: 0) {
                        difficultyButton(.easy)
                        difficultyButton(.medium)
                    }
                    HStack(spacing: 0) {
                        difficultyButton(.hard)
                        difficultyButton(.fill)
                    }
                }
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.12), lineWidth: 1))
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
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(d == difficulty ? pillColor(d) : Color.clear)
                )
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
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(d == difficulty ? Color(red: 1.0, green: 0.75, blue: 0.1) : Color.clear)
                )
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
                Text(age.emoji)
                    .font(.system(size: 20))
                Text(age.displayName)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(0.5)
                Text(age.ageRange)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : Color(white: 0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(red: 1.0, green: 0.75, blue: 0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: kidAgeRaw)
    }

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

    private func menuSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .black))
            .foregroundColor(Color(white: 0.3))
            .tracking(3)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 6)
    }

    private func menuRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(white: 0.08))
        }
        .buttonStyle(.plain)
    }
}
