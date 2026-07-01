import SwiftUI

/// Expanding rounded-rect rings around a tile — kid-mode phase-2 "tap here" beacon.
/// Rings start at tile bounds and expand outward so the tile letter remains fully visible.
struct BeaconView: View {
    let size: CGFloat
    @State private var expand: Bool = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: size * 0.22 + (expand ? size * 0.3 : 0))
                    .stroke(
                        Color(red: 1.0, green: 0.85, blue: 0.2).opacity(expand ? 0.0 : 0.65),
                        lineWidth: 2.5
                    )
                    .frame(
                        width:  expand ? size * 1.7 : size,
                        height: expand ? size * 1.7 : size
                    )
                    .animation(
                        .easeOut(duration: 1.3)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.43),
                        value: expand
                    )
            }
        }
        .onAppear { expand = true }
    }
}
