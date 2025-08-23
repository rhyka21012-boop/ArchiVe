import Foundation
import google_mobile_ads
import Flutter

class GridViewNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(
        nativeAd: GADNativeAd,
        customOptions: [AnyHashable : Any]? = nil
    ) -> GADNativeAdView {
        let view = Bundle.main.loadNibNamed("NativeAdView", owner: nil, options: nil)?.first as! GADNativeAdView
        (view.headlineView as! UILabel).text = nativeAd.headline
        view.nativeAd = nativeAd
        return view
    }
}
