package com.walkinggoblins.archive

import android.content.Context
import android.view.LayoutInflater
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/**
 * グリッド表示用のネイティブ広告テンプレート
 * card_native_ad.xml を使用（メディア全面 + 下部ヘッドライン + 左上「広告」バッジ）
 */
class GridCardNativeAdFactory(private val context: Context) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.card_native_ad, null) as NativeAdView

        val mediaView = adView.findViewById<MediaView>(R.id.iv_card_native_ad_media)
        val headlineView = adView.findViewById<TextView>(R.id.tv_card_native_ad_headline)

        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView
        adView.mediaView = mediaView

        adView.setNativeAd(nativeAd)
        return adView
    }
}
