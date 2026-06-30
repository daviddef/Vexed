import SwiftUI

struct GridView: View {
    @ObservedObject var engine: GameEngine
    @State private var dragStart: Position? = nil

    var body: some View {
        GeometryReader { geo in
            let rows = engine.config.rows
            let cols = engine.config.cols
            let gap: CGFloat = 5
            let totalGapW = gap * CGFloat(cols - 1) + 16
            let totalGapH = gap * CGFloat(rows - 1) + 16
            let tileW = (geo.size.width - totalGapW) / CGFloat(cols)
            let tileH = (geo.size.height - totalGapH) / CGFloat(rows)
            let tileSize = min(tileW, tileH)

            VStack(spacing: gap) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { c in
                            let pos = Position(r, c)
                            let isSelected = engine.selectedPosition == pos
                            TileCellView(
                                tile: engine.grid[r][c],
                                isSelected: isSelected,
                                size: tileSize
                            )
                            .contentShape(Rectangle())
                            .gesture(tileDragGesture(at: pos))
                            .onTapGesture { engine.select(position: pos) }
                        }
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // Drag on a tile: if selected tile matches, slide it; otherwise select then slide
    private func tileDragGesture(at pos: Position) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // Record drag origin tile once
                if dragStart == nil { dragStart = pos }
            }
            .onEnded { value in
                guard let origin = dragStart else { return }
                dragStart = nil
                guard let dir = Direction(translation: value.translation) else { return }

                // Select origin tile if not already, then slide
                if engine.selectedPosition != origin {
                    engine.select(position: origin)
                }
                engine.slide(direction: dir)
            }
    }
}
