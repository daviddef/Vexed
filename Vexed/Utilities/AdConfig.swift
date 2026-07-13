import UIKit

/// Central AdMob identifiers. Keeping them in one place makes the dev→production swap a single edit.
enum AdConfig {
    /// AdMob application ID (also mirrored in Info.plist under `GADApplicationIdentifier`).
    static let applicationID = "ca-app-pub-4156851882993001~1849747214"

    /// Rewarded ad unit ID.
    ///
    /// Currently Google's official **test** rewarded unit — it serves real Google test ads, earns
    /// nothing, and is the correct, policy-safe choice for development and TestFlight (using a live
    /// unit in beta/testing counts as invalid traffic and risks an AdMob account strike).
    ///
    /// ⚠️ Before the public App Store release, replace this with the real rewarded ad unit ID from
    /// AdMob → Ad units → (your rewarded unit). It's isolated here so the swap is one line.
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
}

extension UIApplication {
    /// The frontmost view controller, used to present full-screen ads and the consent form.
    func topViewController() -> UIViewController? {
        let scene = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
