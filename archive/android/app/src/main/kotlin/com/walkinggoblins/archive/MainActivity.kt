package com.walkinggoblins.archive

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {

    private val shareChannelName = "com.walkinggoblins.archive/share"
    private var pendingShareUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handleShareIntent(intent)

        // ネイティブ広告ファクトリ登録（リスト表示用）
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            ListTileNativeAdFactory(context)
        )
        // ネイティブ広告ファクトリ登録（グリッド表示用）
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "gridCard",
            GridCardNativeAdFactory(context)
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedUrl" -> result.success(pendingShareUrl)
                    "clearSharedUrl" -> {
                        pendingShareUrl = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // 通知設定画面を開く導線。
        //
        // 通知が拒否されていると前景サービスの通知を掲示できず、前景サービス
        // そのものが成立しない。すると OS からは背景アプリ扱いのままなので、
        // 従量制回線ではダウンロード中のソケットが遮断される。
        // Android は一度拒否された権限を再要求しても再表示しないため、
        // 設定画面へ直接誘導するしかない。
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.walkinggoblins.archive/app_settings"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    try {
                        val intent =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            } else {
                                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                                    .setData(Uri.fromParts("package", packageName, null))
                            }
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "gridCard")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShareIntent(intent)
    }

    private fun handleShareIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return
            val url = Regex("https?://\\S+").find(text)?.value?.trimEnd('.', ',', ')', ']')
            if (url != null) pendingShareUrl = url
        }
    }
}
