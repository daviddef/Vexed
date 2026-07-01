import SwiftUI

/// Expanding pulsing circle overlay — used as the kid-mode phase-2 "tap here" hint.
struct BeaconView: View {
    let size: CGFloat
    @State private var expand: Bool = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(expand ? 0.0 : 0.7), lineWidth: 2.5)
                    .frame(width: expand ? size * 1.5 : size * 0.6,
                           height: expand ? size * 1.5 : size * 0.6)
                    .animation(
                        .easeOut(duration: 1.2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.4),
                        value: expand
                    )
            }
            // Finger tap icon
            Image(systemName: "hand.tap.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2))
                .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.8), radius: 6)
        }
        .onAppear { expand = true }
    }
}
