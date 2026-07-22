import SwiftUI

/// Adult Mode only power-up tray: Bomb (remove a tile) and Reveal (instant hint), each earned by
/// watching a rewarded ad for a batch of charges. Kid Mode never shows this — no ads/IAP surface
/// should reach Kid Mode (Apple Kids Category guideline 1.3).
struct PowerUpTrayView: View {
    @ObservedObject var engine: GameEngine
    /// The app-wide shared ad provider — one ad-rendering pipeline for the whole app, so tearing
    /// down and rebuilding this view never spins up extra ad WebViews.
    private let adProvider: AdRewardProvider = GoogleAdRewardProvider.shared

    @State private var requestingAdFor: PowerUpKind? = nil
    @State private var noAdMessageVisible = false

    var body: some View {
        HStack(spacing: 10) {
            powerUpButton(.bomb, charges: engine.bombCharges, isActive: engine.bombTargetingActive)
            powerUpButton(.reveal, charges: engine.revealCharges, isActive: false)
        }
        .overlay(alignment: .top) {
            if noAdMessageVisible {
                Text("No ad available — try again shortly")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
                    .offset(y: -34)
                    .transition(.opacity)
            }
        }
    }

    private func requestAd(for kind: PowerUpKind) {
        guard requestingAdFor == nil else { return }
        requestingAdFor = kind
        adProvider.showRewardedAd { earned in
            requestingAdFor = nil
            if earned {
                engine.grantCharges(kind, count: kind.rewardAmount)
            } else {
                withAnimation { noAdMessageVisible = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { noAdMessageVisible = false }
                }
            }
        }
    }

    @ViewBuilder
    private func powerUpButton(_ kind: PowerUpKind, charges: Int, isActive: Bool) -> some View {
        Button {
            Haptics.light()
            if charges > 0 {
                switch kind {
                case .bomb: engine.toggleBombTargeting()
                case .reveal: engine.useReveal()
                }
            } else {
                requestAd(for: kind)
            }
        } label: {
            HStack(spacing: 5) {
                Text(kind.emoji).font(.system(size: 16))
                if requestingAdFor == kind {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                } else {
                    Text(charges > 0 ? "\(charges)" : "Ad")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
            }
            .foregroundColor(isActive ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(minWidth: 52)
            .background(
                Capsule().fill(isActive ? Color(red: 1.0, green: 0.85, blue: 0.0) : Color.white.opacity(0.12))
            )
            .overlay(
                Capsule().stroke(isActive ? Color.clear : Color.white.opacity(0.25), lineWidth: 1)
            )
        }
        .disabled(requestingAdFor != nil)
        .accessibilityLabel("\(kind.title): \(charges) charges")
    }
}
