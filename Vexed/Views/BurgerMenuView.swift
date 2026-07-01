import SwiftUI

struct BurgerMenuView: View {
    @Binding var difficulty: Difficulty
    @Environment(\.dismiss) private var dismiss
    var onReset: () -> Void
    var onShowInstructions: () -> Void
    var onShowMissedWords: () -> Void

    @AppStorage("includeRareWords") private var includeRareWords: Bool = false
    @State private var showTips = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.09).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
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
                    .padding(.top, 32)
                    .padding(.bottom, 28)

                    // Menu rows
                    VStack(spacing: 0) {
                        // Difficulty picker
                        VStack(alignment: .leading, spacing: 0) {
                            menuSectionHeader("GAME")

                            VStack(spacing: 10) {
                                difficultyPill
                                Text(difficulty.description)
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
                                onReset()
                                dismiss()
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
        HStack(spacing: 0) {
            ForEach(Difficulty.allCases) { d in
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
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.12), lineWidth: 1))
    }

    private func pillColor(_ d: Difficulty) -> Color {
        switch d {
        case .easy:   return Color(red: 0.3, green: 0.9, blue: 0.5)
        case .medium: return Color(red: 1.0, green: 0.75, blue: 0.1)
        case .hard:   return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
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
