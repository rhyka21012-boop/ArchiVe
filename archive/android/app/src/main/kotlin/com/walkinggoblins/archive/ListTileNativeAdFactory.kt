package com.walkinggoblins.archive

import android.content.Context
import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/**
 * リスト表示用のネイティブ広告テンプレート
 * native_ad_layout.xml を使用（左にアイコン、右にタイトル+本文の横並び）
 */
class ListTileNativeAdFactory(private val context: Context) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.tv_list_tile_native_ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.tv_list_tile_native_ad_body)
        val iconView = adView.findViewById<ImageView>(R.id.iv_list_tile_native_ad_icon)

        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        nativeAd.body?.let {
            bodyView.text = it
            bodyView.visibility = android.view.View.VISIBLE
        } ?: run {
            bodyView.visibility = android.view.View.GONE
        }
        adView.bodyView = bodyView

        nativeAd.icon?.let {
            iconView.setImageDrawable(it.drawable)
            iconView.visibility = android.view.View.VISIBLE
        } ?: run {
            iconView.visibility = android.view.View.GONE
        }
        adView.iconView = iconView

        adView.setNativeAd(nativeAd)
        return adView
    }
}
