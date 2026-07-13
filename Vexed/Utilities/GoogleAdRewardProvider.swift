import GoogleMobileAds
import UIKit

/// Real `AdRewardProvider` backed by a Google Mobile Ads `RewardedAd`. Preloads an ad, presents it
/// on demand, and reports `true` in the completion only if the user actually earned the reward
/// (watched to the reward point) — never merely for opening the ad. Reloads the next ad after each
/// present so a charge is usually available immediately.
///
/// Only ever instantiated for the Adult-Mode power-up tray. Kid Mode has no ad surface at all
/// (Apple Kids Category guideline 1.3), so this class is never reached from there.
final class GoogleAdRewardProvider: NSObject, AdRewardProvider {
    private var rewardedAd: RewardedAd?
    private var isLoading = false
    private var earnedReward = false
    private var pendingCompletion: ((Bool) -> Void)?

    override init() {
        super.init()
        preload()
    }

    /// Loads (or reloads) a rewarded ad in the background so one is ready when the player taps.
    private func preload() {
        guard rewardedAd == nil, !isLoading else { return }
        isLoading = true
        RewardedAd.load(with: AdConfig.rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            self.isLoading = false
            if let ad {
                ad.fullScreenContentDelegate = self
                self.rewardedAd = ad
            } else {
                self.rewardedAd = nil  // leave nil; next tap triggers another load attempt
            }
        }
    }

    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd, let vc = UIApplication.shared.topViewController() else {
            // Nothing ready to show — kick off a load for next time and report no reward now.
            preload()
            completion(false)
            return
        }
        earnedReward = false
        pendingCompletion = completion
        ad.present(from: vc) { [weak self] in
            self?.earnedReward = true
        }
    }
}

extension GoogleAdRewardProvider: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish(rewarded: earnedReward)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finish(rewarded: false)
    }

    private func finish(rewarded: Bool) {
        let completion = pendingCompletion
        pendingCompletion = nil
        rewardedAd = nil
        preload()  // get the next one ready
        DispatchQueue.main.async { completion?(rewarded) }
    }
}
