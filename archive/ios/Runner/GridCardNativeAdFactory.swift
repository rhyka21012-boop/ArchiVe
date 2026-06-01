import Foundation
import google_mobile_ads
import Flutter
import UIKit

/// グリッド表示用のネイティブ広告ファクトリ（プログラムでビュー構築）
class GridCardNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(
        _ nativeAd: NativeAd,
        customOptions: [AnyHashable : Any]? = nil
    ) -> NativeAdView? {
        let adView = NativeAdView()
        adView.translatesAutoresizingMaskIntoConstraints = false
        adView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        // メディアビュー（全面）
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.mediaContent = nativeAd.mediaContent
        adView.addSubview(mediaView)
        adView.mediaView = mediaView

        // 下部オーバーレイ（半透明黒帯）
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.55)
        adView.addSubview(overlay)

        // ヘッドライン
        let headlineLabel = UILabel()
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = UIFont.boldSystemFont(ofSize: 12)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 2
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.text = nativeAd.headline
        overlay.addSubview(headlineLabel)
        adView.headlineView = headlineLabel

        // 「Ad」バッジ（左上）
        let badge = UILabel()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.text = "Ad"
        badge.font = UIFont.boldSystemFont(ofSize: 10)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = UIColor(red: 0.95, green: 0.6, blue: 0.22, alpha: 0.9)
        badge.layer.cornerRadius = 3
        badge.clipsToBounds = true
        adView.addSubview(badge)

        // レイアウト
        NSLayoutConstraint.activate([
            // メディア全面
            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
            mediaView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),

            // 下部オーバーレイ
            overlay.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: adView.bottomAnchor),

            // ヘッドライン（オーバーレイ内）
            headlineLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 8),
            headlineLabel.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -8),
            headlineLabel.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 6),
            headlineLabel.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -6),

            // バッジ
            badge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 6),
            badge.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 6),
            badge.widthAnchor.constraint(equalToConstant: 22),
            badge.heightAnchor.constraint(equalToConstant: 16),
        ])

        adView.nativeAd = nativeAd
        return adView
    }
}
