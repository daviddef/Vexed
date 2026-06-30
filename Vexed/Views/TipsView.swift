import SwiftUI

struct TipsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("STRATEGY TIPS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(white: 0.4))
                    .tracking(3)
                    .padding(.bottom, 4)

                tipRow(number: 1,
                       title: "CONSONANTS ARE SHIELDS",
                       body: "Park consonants between same-type vowels to stop them from exploding.")

                tipRow(number: 2,
                       title: "SLIDE TOWARD WALLS",
                       body: "Tiles glide to the edge — use walls to chain multiple tiles into position in one move.")

                tipRow(number: 3,
                       title: "SHORT WORDS CLEAR SPACE",
                       body: "3–4 letter words free up room. Long words score big bonuses. Know when to use each.")

                tipRow(number: 4,
                       title: "RED GLOW = DANGER",
                       body: "That vowel cluster is one move from exploding. Break it up immediately.")

                tipRow(number: 5,
                       title: "CORNERS COUNT ON MEDIUM+",
                       body: "Diagonal adjacency is active — watch your corners, vowels can cluster diagonally too.")

                tipRow(number: 6,
                       title: "SACRIFICE TO OPEN PATHS",
                       body: "Sometimes losing a vowel to an explosion clears the path for a better word later.")

                tipRow(number: 7,
                       title: "WATCH THE VOWEL RADAR",
                       body: "When a vowel bar turns bright you have 2+ on the board — start separating them fast.")

                tipRow(number: 8,
                       title: "EXPERT: DEFEND THE EDGES",
                       body: "In Expert mode tiles creep in from edges. Prioritise board space over big words.")
            }
            .padding(24)
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.09))
    }

    private func tipRow(number: Int, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(Color(white: 0.25))
                .frame(width: 20)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(white: 0.75))
                    .tracking(1.5)
                Text(body)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(white: 0.42))
                    .lineSpacing(3)
            }
        }
    }
}
