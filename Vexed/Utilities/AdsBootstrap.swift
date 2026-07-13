import Foundation
import GoogleMobileAds
import UserMessagingPlatform
import UIKit

/// Starts the ad stack and gathers EEA/UK/Swiss consent — but only ever in Adult Mode. Kid Mode
/// must not initialize ad requests, gather consent, or show the consent form, per Apple's Kids
/// Category rules and COPPA. Callers gate on `kidMode` before invoking these.
enum AdsBootstrap {
    private static var didStart = false

    /// Idempotent SDK start. Safe to call more than once.
    static func startSDK() {
        guard !didStart else { return }
        didStart = true
        MobileAds.shared.start(completionHandler: nil)
    }

    /// Requests the latest consent info and presents Google's consent form if one is required
    /// (only shown to users in regions that need it, e.g. the EEA). No-op elsewhere. Presenting
    /// needs a live view controller, so call this once the UI is on screen.
    static func gatherConsentIfNeeded() {
        let params = RequestParameters()
        ConsentInformation.shared.requestConsentInfoUpdate(with: params) { error in
            guard error == nil else { return }
            guard let vc = UIApplication.shared.topViewController() else { return }
            ConsentForm.loadAndPresentIfRequired(from: vc) { _ in
                // Consent (or lack of it) is now recorded; the SDK serves personalized or
                // non-personalized ads accordingly. Rewarded ads work in both cases.
            }
        }
    }
}
