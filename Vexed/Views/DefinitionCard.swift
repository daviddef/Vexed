import SwiftUI

// DefinitionEntry kept for backwards compat in GameView
struct DefinitionEntry: Equatable, Identifiable {
    var id: String { word }
    let word: String
    let points: Int?
}

struct DefinitionSheetView: View {
    let entry: DefinitionEntry

    var body: some View {
        VStack(spacing: 0) {
            // Header with word + points
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(entry.word.uppercased())
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(3)
                if let pts = entry.points {
                    Text("+\(pts) pts")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.15)))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider().background(Color(white: 0.18))

            // System dictionary view
            SystemDictionaryView(term: entry.word)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
    }
}
