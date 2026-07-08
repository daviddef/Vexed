import SwiftUI

/// Adult Mode only power-up tray: Bomb (remove a tile) and Reveal (instant hint), each earned by
/// watching a rewarded ad for a batch of charges. Kid Mode never shows this — no ads/IAP surface
/// should reach Kid Mode (Apple Kids Category guideline 1.3).
struct PowerUpTrayView: View {
    @ObservedObject var engine: GameEngine
    var adProvider: AdRewardProvider = MockAdRewardProvider()

    @State private var watchingAdFor: PowerUpKind? = nil

    var body: some View {
        HStack(spacing: 10) {
            powerUpButton(.bomb, charges: engine.bombCharges, isActive: engine.bombTargetingActive)
            powerUpButton(.reveal, charges: engine.revealCharges, isActive: false)
        }
        .sheet(item: $watchingAdFor) { kind in
            RewardedAdSheet(kind: kind, adProvider: adProvider) { earned in
                if earned { engine.grantCharges(kind, count: kind.rewardAmount) }
                watchingAdFor = nil
            }
            .presentationDetents([.height(260)])
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
                watchingAdFor = kind
            }
        } label: {
            HStack(spacing: 5) {
                Text(kind.emoji).font(.system(size: 16))
                Text(charges > 0 ? "\(charges)" : "Ad")
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .foregroundColor(isActive ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isActive ? Color(red: 1.0, green: 0.85, blue: 0.0) : Color.white.opacity(0.12))
            )
            .overlay(
                Capsule().stroke(isActive ? Color.clear : Color.white.opacity(0.25), lineWidth: 1)
            )
        }
        .accessibilityLabel("\(kind.title): \(charges) charges")
    }
}

/// Placeholder rewarded-ad presentation — see AdRewardProvider for the swap-in point for a real
/// ad SDK. Shows a short countdown so the reward loop reads as "watch to completion", not instant.
private struct RewardedAdSheet: View {
    let kind: PowerUpKind
    let adProvider: AdRewardProvider
    let onComplete: (Bool) -> Void

    @State private var secondsLeft = 3
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Text(kind.emoji).font(.system(size: 44))
            Text(isLoading ? "Loading ad…" : "Watching ad…")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("+\(kind.rewardAmount) \(kind.title) charge\(kind.rewardAmount == 1 ? "" : "s") when it finishes")
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.65))
            if !isLoading {
                Text("\(secondsLeft)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.0))
            }
            Button("Cancel") { onComplete(false) }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(white: 0.55))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.07, blue: 0.11))
        .onAppear {
            adProvider.showRewardedAd { available in
                guard available else { onComplete(false); return }
                isLoading = false
                tick()
            }
        }
    }

    private func tick() {
        guard secondsLeft > 0 else { onComplete(true); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            secondsLeft -= 1
            tick()
        }
    }
}
