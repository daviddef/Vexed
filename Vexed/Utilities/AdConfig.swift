import UIKit

/// Central AdMob identifiers. Keeping them in one place makes the dev→production swap a single edit.
enum AdConfig {
    /// AdMob application ID (also mirrored in Info.plist under `GADApplicationIdentifier`).
    static let applicationID = "ca-app-pub-4156851882993001~1849747214"

    /// Real rewarded ad unit (AdMob → Ad units). Serves only to genuine App Store installs.
    private static let productionRewardedAdUnitID = "ca-app-pub-4156851882993001/2203581371"

    /// Google's official test rewarded unit — serves real Google test ads, earns nothing. Used for
    /// debug and TestFlight builds so our own testing never registers as invalid traffic (which
    /// risks an AdMob account strike).
    private static let testRewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// The rewarded unit to actually request. Auto-selects by build channel so there's no flag to
    /// remember to flip: debug and TestFlight builds get the test unit, real App Store installs get
    /// the production unit. (TestFlight builds ship a `sandboxReceipt`; App Store builds don't.)
    static var rewardedAdUnitID: String {
        isTestBuild ? testRewardedAdUnitID : productionRewardedAdUnitID
    }

    /// True for debug builds and TestFlight betas, false for public App Store installs.
    static var isTestBuild: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }
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
