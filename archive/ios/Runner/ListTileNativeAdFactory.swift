import Foundation
import google_mobile_ads
import Flutter
import UIKit

/// リスト表示用のネイティブ広告ファクトリ（プログラムでビュー構築）
class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(
        _ nativeAd: NativeAd,
        customOptions: [AnyHashable : Any]? = nil
    ) -> NativeAdView? {
        let adView = NativeAdView()
        adView.translatesAutoresizingMaskIntoConstraints = false

        // アイコン
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.image = nativeAd.icon?.image
        iconView.isHidden = nativeAd.icon == nil
        adView.addSubview(iconView)
        adView.iconView = iconView

        // ヘッドライン
        let headlineLabel = UILabel()
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = UIFont.boldSystemFont(ofSize: 15)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.text = nativeAd.headline
        adView.addSubview(headlineLabel)
        adView.headlineView = headlineLabel

        // 本文
        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = UIFont.systemFont(ofSize: 12)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil
        adView.addSubview(bodyLabel)
        adView.bodyView = bodyLabel

        // 「Ad」バッジ
        let badge = UILabel()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.text = "Ad"
        badge.font = UIFont.boldSystemFont(ofSize: 9)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.backgroundColor = UIColor(red: 0.95, green: 0.6, blue: 0.22, alpha: 0.9)
        badge.layer.cornerRadius = 3
        badge.clipsToBounds = true
        adView.addSubview(badge)

        // レイアウト
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),

            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            headlineLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            headlineLabel.topAnchor.constraint(equalTo: adView.topAnchor, constant: 14),

            bodyLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),

            badge.topAnchor.constraint(equalTo: adView.topAnchor, constant: 4),
            badge.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 4),
            badge.widthAnchor.constraint(equalToConstant: 20),
            badge.heightAnchor.constraint(equalToConstant: 14),
        ])

        adView.nativeAd = nativeAd
        return adView
    }
}
