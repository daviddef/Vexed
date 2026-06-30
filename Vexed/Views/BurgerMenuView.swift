import SwiftUI

struct BurgerMenuView: View {
    @Binding var difficulty: Difficulty
    @Environment(\.dismiss) private var dismiss
    var onReset: () -> Void
    var onShowInstructions: () -> Void
    var onShowMissedWords: () -> Void

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

                            HStack {
                                Text("Difficulty")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("Difficulty", selection: $difficulty) {
                                    ForEach(Difficulty.allCases) { d in
                                        Text(d.description).tag(d)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(Color(white: 0.5))
                                .onChange(of: difficulty) { _, _ in
                                    onReset()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
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

                            menuRow(icon: "questionmark.circle", label: "How to Play", color: .white) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    onShowInstructions()
                                }
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
