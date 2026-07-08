import Foundation

/// Abstraction over "watch a rewarded video ad, get a reward" so the power-up UI doesn't need to
/// know which ad SDK is behind it. Swap `MockAdRewardProvider` for a real Google Mobile Ads (or
/// other network) implementation once an AdMob account + ad unit IDs exist — everything else in
/// the power-up flow (GameEngine.grantCharges, the power-up tray UI) stays unchanged.
protocol AdRewardProvider {
    /// Presents a rewarded ad. Calls back on the main thread with `true` if the user watched it
    /// to completion and earned the reward, `false` if they dismissed early or the ad failed to load.
    func showRewardedAd(completion: @escaping (Bool) -> Void)
}

/// Placeholder provider used until a real ad SDK (e.g. Google Mobile Ads) is wired in. Simulates
/// the watch-to-completion flow with a timed countdown sheet so the reward loop is fully testable
/// today. TODO: replace with a GADRewardedAd-backed provider before shipping ad-funded power-ups
/// publicly — see AdRewardProvider doc comment.
final class MockAdRewardProvider: AdRewardProvider {
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        // Real implementation would load/present a GADRewardedAd here and only call back true
        // from the ad's reward callback (userDidEarnReward), not on presentation alone.
        completion(true)
    }
}
