import Foundation
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency
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

    /// Requests the latest consent info, presents Google's consent form if one is required (EEA/UK
    /// etc.), then requests App Tracking Transparency authorization. Ordering matters: the UMP
    /// consent form comes first, ATT second, per Google/Apple guidance. Presenting needs a live
    /// view controller, so call this once the UI is on screen — and ONLY in Adult Mode.
    static func gatherConsentIfNeeded() {
        let params = RequestParameters()
        ConsentInformation.shared.requestConsentInfoUpdate(with: params) { error in
            // Whether or not consent info succeeds, still ask for ATT so IDFA can be used where
            // the user allows it.
            guard error == nil, let vc = UIApplication.shared.topViewController() else {
                requestTrackingAuthorization()
                return
            }
            ConsentForm.loadAndPresentIfRequired(from: vc) { _ in
                requestTrackingAuthorization()
            }
        }
    }

    /// Shows Apple's ATT prompt (once per install; returns immediately if already decided). Granting
    /// it lets the Mobile Ads SDK use the IDFA for personalized ads; declining keeps ads
    /// non-personalized. Only reached from `gatherConsentIfNeeded`, which callers gate to Adult
    /// Mode — the ATT prompt must never appear in Kid Mode.
    private static func requestTrackingAuthorization() {
        DispatchQueue.main.async {
            ATTrackingManager.requestTrackingAuthorization { _ in
                // The Mobile Ads SDK reads the resulting ATT status itself when building ad
                // requests — nothing else to wire up here.
            }
        }
    }
}
