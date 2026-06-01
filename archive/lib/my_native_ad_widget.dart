import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// リスト表示用のネイティブ広告
/// Android: factoryId = "listTile" → native_ad_layout.xml で描画
/// iOS: 未対応（Phase 2 で実装予定）
class ListTileNativeAd extends StatefulWidget {
  const ListTileNativeAd({super.key});

  @override
  State<ListTileNativeAd> createState() => _ListTileNativeAdState();
}

class _ListTileNativeAdState extends State<ListTileNativeAd> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();

    // プラットフォーム別の広告ユニットID
    final String adUnitId;
    if (Platform.isAndroid) {
      adUnitId = kDebugMode
          ? 'ca-app-pub-3940256099942544/2247696110' // Android テスト
          : 'ca-app-pub-8268997781284735/3147588845'; // Android 本番
    } else if (Platform.isIOS) {
      adUnitId = kDebugMode
          ? 'ca-app-pub-3940256099942544/3986624511' // iOS テスト Native
          : 'ca-app-pub-8268997781284735/6208336228'; // iOS 本番
    } else {
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('ListTileNativeAd failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.brightness == Brightness.light
          ? Colors.grey[200]
          : const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: SizedBox(
        height: 84,
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}

/// 旧名（後方互換 — 既存呼び出しがあれば差し替えやすいよう残す）
@Deprecated('Use ListTileNativeAd instead')
class MyNativeAdWidget extends StatelessWidget {
  const MyNativeAdWidget({super.key});

  @override
  Widget build(BuildContext context) => const ListTileNativeAd();
}

/// グリッド表示用のネイティブ広告（セルの形に合わせて全面表示）
/// Android: factoryId = "gridCard" → card_native_ad.xml で描画
/// iOS: 未対応（Phase 2 で実装予定）
class GridCardNativeAd extends StatefulWidget {
  const GridCardNativeAd({super.key});

  @override
  State<GridCardNativeAd> createState() => _GridCardNativeAdState();
}

class _GridCardNativeAdState extends State<GridCardNativeAd> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();

    final String adUnitId;
    if (Platform.isAndroid) {
      adUnitId = kDebugMode
          ? 'ca-app-pub-3940256099942544/2247696110' // Android テスト
          : 'ca-app-pub-8268997781284735/3147588845'; // Android 本番
    } else if (Platform.isIOS) {
      adUnitId = kDebugMode
          ? 'ca-app-pub-3940256099942544/3986624511' // iOS テスト Native
          : 'ca-app-pub-8268997781284735/6208336228'; // iOS 本番
    } else {
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'gridCard',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('GridCardNativeAd failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.brightness == Brightness.light
          ? Colors.grey[200]
          : const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
