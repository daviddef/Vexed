import SwiftUI

struct GridView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        let rows = engine.config.rows
        let cols = engine.config.cols
        let tileSize = tileSize(cols: cols)
        let gap: CGFloat = 4

        VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: gap) {
                    ForEach(0..<cols, id: \.self) { c in
                        let pos = Position(r, c)
                        let isSelected = engine.selectedPosition == pos
                        TileCellView(tile: engine.grid[r][c], isSelected: isSelected, size: tileSize)
                            .onTapGesture { engine.select(position: pos) }
                    }
                }
            }
        }
        .padding(8)
        .background(Color(white: 0.09).cornerRadius(16))
        .gesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    if let dir = Direction(translation: value.translation) {
                        engine.slide(direction: dir)
                    }
                }
        )
    }

    private func tileSize(cols: Int) -> CGFloat {
        // Fit grid to ~90% of screen width
        let screenWidth = UIScreen.main.bounds.width * 0.9
        let gaps = CGFloat(cols - 1) * 4 + 16 // gaps + padding
        return max(36, (screenWidth - gaps) / CGFloat(cols))
    }
}
