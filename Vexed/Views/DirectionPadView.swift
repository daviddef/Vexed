import SwiftUI

struct DirectionPadView: View {
    let onSlide: (Direction) -> Void

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                arrow(.upLeft,   "↖")
                arrow(.up,       "↑")
                arrow(.upRight,  "↗")
            }
            GridRow {
                arrow(.left,  "←")
                centerDot
                arrow(.right, "→")
            }
            GridRow {
                arrow(.downLeft,  "↙")
                arrow(.down,      "↓")
                arrow(.downRight, "↘")
            }
        }
    }

    private func arrow(_ dir: Direction, _ symbol: String) -> some View {
        Button {
            onSlide(dir)
        } label: {
            Text(symbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(white: 0.6))
                .frame(width: 48, height: 48)
                .background(Color(white: 0.12))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var centerDot: some View {
        Color(white: 0.08)
            .frame(width: 48, height: 48)
            .cornerRadius(10)
    }
}
