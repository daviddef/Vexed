import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 1.0, green: 0.85, blue: 0.2)
    private let bg     = Color(red: 0.07, green: 0.07, blue: 0.11)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section("The Basics") {
                        bodyText("Letters sit on a grid. Tap a tile to select it, then swipe in any direction — the tile slides until it hits a wall or another tile.")
                        bodyText("When tiles spell a valid word (left→right or top→bottom), a **gold outline** appears. Tap any tile inside the outline to collect it. Tiles vanish and your score goes up.")
                    }

                    section("The Vowel Rule", accent: Color(red: 1, green: 0.38, blue: 0.38)) {
                        bodyText("If **3 or more of the same vowel touch** — horizontally or vertically in any shape — they all vanish instantly. No warning. No score.")
                        bodyText("The board edge pulses with that vowel's colour when a cluster is close to 3:")
                        tagGrid([
                            ("A", Color(red: 0.95, green: 0.22, blue: 0.22)),
                            ("E", Color(red: 0.18, green: 0.82, blue: 0.35)),
                            ("I", Color(red: 0.15, green: 0.48, blue: 1.0)),
                            ("O", Color(red: 1.0, green: 0.55, blue: 0.05)),
                            ("U", Color(red: 0.72, green: 0.22, blue: 0.95)),
                        ])
                        bodyText("Slide one of those vowels away before the cluster reaches 3.")
                    }

                    section("Scoring") {
                        table(
                            headers: ["Word length", "Base points"],
                            rows: [
                                ["3 letters", "30 pts"],
                                ["4 letters", "40 pts"],
                                ["5 letters", "70 pts ✦"],
                                ["6 letters", "80 pts"],
                                ["7 letters", "90 pts"],
                                ["+1 letter", "+10 pts"],
                            ]
                        )
                        bodyText("✦ A bonus kicks in at 5 letters — longer words score disproportionately more than stacking short ones.")

                        subheading("Combo Multiplier")
                        bodyText("Score words back-to-back without losing vowels and your multiplier climbs:")
                        table(
                            headers: ["Consecutive words", "Multiplier"],
                            rows: [
                                ["1", "×1.0"],
                                ["2", "×1.5"],
                                ["3", "×2.0"],
                                ["4+", "×3.0"],
                            ]
                        )
                        bodyText("Losing vowels or running out of moves resets the combo to zero.")
                    }

                    section("Tile Forge") {
                        bodyText("Every word you collect forges new tiles into empty spaces. Longer words forge more — this is how you keep the board alive.")
                        bodyText("**Standard mode** — Forge tiles = word length − difficulty threshold (no cap):")
                        table(
                            headers: ["Word length", "Easy (−1)", "Medium/Fill (−2)", "Hard (−3)"],
                            rows: [
                                ["3 letters", "+2", "+1", "—"],
                                ["4 letters", "+3", "+2", "+1"],
                                ["5 letters", "+4", "+3", "+2"],
                                ["6 letters", "+5", "+4", "+3"],
                                ["7 letters", "+6", "+5", "+4"],
                            ]
                        )
                        bodyText("**Kid Mode** — Every word gives a flat bonus regardless of length:")
                        table(
                            headers: ["Age tier", "Forge bonus per word"],
                            rows: [
                                ["🌟 Little (5–7)", "+4 tiles"],
                                ["🔍 Explorer (8–10)", "+3 tiles"],
                                ["⚡ Challenger (11+)", "standard formula"],
                            ]
                        )
                        bodyText("Forged tiles flash white when they appear. They're weighted toward letters that are under-represented on the board.")
                    }

                    section("Word Strip") {
                        bodyText("The strip at the bottom shows every word scoreable **right now** without moving anything — sorted longest-first.")
                        bodyText("Tap a chip to highlight those tiles and see the word's definition. Tap a highlighted tile on the board to collect it.")
                    }

                    section("Game Over") {
                        bodyText("The game ends when no slide can form a word, even looking two moves ahead. You'll see a grade based on how much of the board's total potential score you captured:")
                        table(
                            headers: ["Grade", "Score captured"],
                            rows: [
                                ["S", "90%+"],
                                ["A", "75–89%"],
                                ["B", "60–74%"],
                                ["C", "45–59%"],
                                ["D", "30–44%"],
                                ["F", "Below 30%"],
                            ]
                        )
                    }

                    section("Difficulty Levels") {
                        difficultyCard(
                            name: "Easy",
                            color: Color(red: 0.3, green: 0.9, blue: 0.5),
                            grid: "5×5",
                            words: "20,000 everyday words",
                            minLen: "3 letters",
                            forge: "−1 (3-letter words give +2 tiles)"
                        )
                        difficultyCard(
                            name: "Medium",
                            color: Color(red: 1.0, green: 0.75, blue: 0.1),
                            grid: "7×7",
                            words: "62,000 words",
                            minLen: "3 letters",
                            forge: "−2 (3-letter words give +1 tile)"
                        )
                        difficultyCard(
                            name: "Hard",
                            color: Color(red: 1.0, green: 0.3, blue: 0.3),
                            grid: "9 cols × screen height",
                            words: "62,000 words (toggle for 132k)",
                            minLen: "4 letters minimum",
                            forge: "−3 (need 4+ letters to forge anything)"
                        )
                        difficultyCard(
                            name: "Fill",
                            color: Color(red: 0.55, green: 0.35, blue: 1.0),
                            grid: "7 cols × screen height",
                            words: "62,000 words",
                            minLen: "3 letters",
                            forge: "−2 (same as Medium)"
                        )
                    }

                    section("Kid Mode", accent: Color(red: 1.0, green: 0.75, blue: 0.1)) {
                        bodyText("Turn on **Kid Mode** in the ☰ menu to unlock a friendlier version of VEXED! designed for younger players. Choose an age tier — each one adjusts the rules:")
                        kidTierCard(
                            emoji: "🌟",
                            name: "Little",
                            range: "5–7",
                            minLen: "2+ letters",
                            forge: "Flat +4 tiles per word",
                            hints: "Gold hint glow after 8s idle, tap beacon after 18s",
                            words: "20,000 kid-friendly words + all 2-letter Scrabble words"
                        )
                        kidTierCard(
                            emoji: "🔍",
                            name: "Explorer",
                            range: "8–10",
                            minLen: "3+ letters",
                            forge: "Flat +3 tiles per word",
                            hints: "Gold hint glow after 15s idle, tap beacon after 30s",
                            words: "20,000 everyday English words"
                        )
                        kidTierCard(
                            emoji: "⚡",
                            name: "Challenger",
                            range: "11+",
                            minLen: "3+ letters",
                            forge: "Standard formula (same as adult Easy)",
                            hints: "No auto-hints",
                            words: "62,000 words — full adult dictionary"
                        )
                        bodyText("In Kid Mode the board size picker changes to **Small / Medium / Full** — same grids as Easy / Medium / Fill. Hard mode is replaced by Full screen.")

                        subheading("Auto-hints")
                        bodyText("If the player hasn't moved for a while, a word that can be collected **right now** gets a bright pulsing gold border. Wait a little longer and a **tap beacon** (expanding rings + hand icon) appears on the first tile of that word to show exactly where to tap.")
                    }

                    section("Tips") {
                        tip("Think before you slide. Tiles move fast; vowels vanish faster.")
                        tip("Check the word strip first — there may already be words to collect without moving anything.")
                        tip("Spread vowels deliberately. Two Es side by side is fine. Three is catastrophe.")
                        tip("Longer words pay double. A 6-letter word scores roughly as much as two 3-letter words and forges far more tiles.")
                        tip("Combos matter most on Hard. A ×3 multiplier on a 7-letter word is your path to an S grade.")
                        tip("Tap any word chip in the history strip to look up its definition.")
                    }

                    section("Settings") {
                        bodyText("**Kid Mode** — Friendlier rules for younger players: shorter word minimums, flat forge bonuses, and auto-hints. Toggle in the ☰ menu.")
                        bodyText("**Arcade Mode** — Vivid background, textured tiles, bold scoreboard, and serif fonts. Toggle in the ☰ menu.")
                        bodyText("**Rare & archaic words** — Adds technical, abbreviations and non-English words to the dictionary. Off by default.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(bg.ignoresSafeArea())
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(accent)
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Components

    @ViewBuilder
    private func section<Content: View>(_ title: String, accent accentColor: Color? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(accentColor ?? accent)
                    .frame(width: 3, height: 18)
                    .cornerRadius(2)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(accentColor ?? accent)
                    .tracking(2)
            }
            content()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }

    private func subheading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 4)
    }

    private func bodyText(_ text: String) -> some View {
        Text(AttributedString(markdown: text) ?? AttributedString(text))
            .font(.system(size: 14, design: .default))
            .foregroundColor(.white.opacity(0.75))
            .lineSpacing(4)
    }

    private func tip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("→")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(accent)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(4)
        }
    }

    private func table(headers: [String], rows: [[String]]) -> some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(headers.indices, id: \.self) { i in
                    Text(headers[i])
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(accent.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: i == 0 ? .leading : .center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                }
            }
            .background(Color.white.opacity(0.06))
            // Data rows
            ForEach(rows.indices, id: \.self) { ri in
                Divider().background(Color.white.opacity(0.06))
                HStack(spacing: 0) {
                    ForEach(rows[ri].indices, id: \.self) { ci in
                        Text(rows[ri][ci])
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(ci == 0 ? 0.6 : 0.9))
                            .frame(maxWidth: .infinity, alignment: ci == 0 ? .leading : .center)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                    }
                }
                .background(ri.isMultiple(of: 2) ? Color.clear : Color.white.opacity(0.025))
            }
        }
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func tagGrid(_ items: [(String, Color)]) -> some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.0) { letter, color in
                HStack(spacing: 5) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(letter)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
            }
        }
    }

    private func kidTierCard(emoji: String, name: String, range: String, minLen: String, forge: String, hints: String, words: String) -> some View {
        let color = Color(red: 1.0, green: 0.75, blue: 0.1)
        return HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.5), lineWidth: 1))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(emoji).font(.system(size: 16))
                    Text("\(name)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(color)
                    Text("· \(range)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                row("Min word", minLen)
                row("Tile forge", forge)
                row("Hints", hints)
                row("Dictionary", words)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.15), lineWidth: 1))
    }

    private func difficultyCard(name: String, color: Color, grid: String, words: String, minLen: String, forge: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.5), lineWidth: 1))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(color)
                row("Grid", grid)
                row("Dictionary", words)
                row("Min word", minLen)
                row("Tile forge", forge)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.15), lineWidth: 1))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label + ":")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.38))
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

private extension AttributedString {
    init?(markdown text: String) {
        try? self.init(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }
}
