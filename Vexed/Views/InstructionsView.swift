import SwiftUI

struct InstructionsView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("VEXED")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(10)
                    Text("SLIDE · FORM · SURVIVE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(white: 0.4))
                        .tracking(3)
                }
                .padding(.top, 32)
                .padding(.bottom, 28)

                // Rules as game lore
                VStack(alignment: .leading, spacing: 20) {
                    rule(
                        icon: "🧊",
                        title: "SLIDE TILES",
                        body: "Drag any tile — it glides until it hits a wall or another tile. Plan your path."
                    )
                    rule(
                        icon: "🔤",
                        title: "FORM WORDS",
                        body: "Spell a word in any row or column. The tiles vanish and you score points."
                    )
                    rule(
                        icon: "💥",
                        title: "VOWEL DANGER",
                        body: "Three or more identical vowels touching will EXPLODE. You lose them forever."
                    )
                    rule(
                        icon: "🛡️",
                        title: "PROTECT YOUR VOWELS",
                        body: "Keep consonants between same vowels. No vowels = no words = game over."
                    )
                    rule(
                        icon: "⚡",
                        title: "LONGER = BETTER",
                        body: "5+ letter words score a bonus. Short words are safe moves. Your call."
                    )
                }
                .padding(.horizontal, 28)

                Spacer()

                // Vowel colour key
                VStack(spacing: 10) {
                    Text("VOWEL KEY")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(white: 0.3))
                        .tracking(2)
                    HStack(spacing: 10) {
                        vowelChip("A", color: Color(red: 1.0, green: 0.42, blue: 0.42))
                        vowelChip("E", color: Color(red: 0.42, green: 1.0, blue: 0.53))
                        vowelChip("I", color: Color(red: 0.42, green: 0.56, blue: 1.0))
                        vowelChip("O", color: Color(red: 1.0, green: 0.8, blue: 0.33))
                        vowelChip("U", color: Color(red: 0.8, green: 0.47, blue: 1.0))
                    }
                }
                .padding(.bottom, 20)

                Button {
                    onDismiss()
                } label: {
                    Text("LET'S PLAY")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                    .ignoresSafeArea()
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func rule(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(icon)
                .font(.system(size: 24))
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(white: 0.8))
                    .tracking(2)
                Text(body)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(white: 0.45))
                    .lineSpacing(3)
            }
        }
    }

    private func vowelChip(_ letter: String, color: Color) -> some View {
        Text(letter)
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundColor(color)
            .frame(width: 44, height: 44)
            .background(color.opacity(0.12))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.4), lineWidth: 1.5))
    }
}
