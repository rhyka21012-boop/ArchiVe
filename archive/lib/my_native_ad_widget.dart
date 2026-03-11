import 'dart:io'; // プラットフォーム判定に必要
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MyNativeAdWidget extends StatefulWidget {
  const MyNativeAdWidget({super.key});

  @override
  State<MyNativeAdWidget> createState() => _MyNativeAdWidgetState();
}

class _MyNativeAdWidgetState extends State<MyNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  @override
  void initState() {
    super.initState();

    final adUnitId =
        Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111' // AndroidテストID
            : 'ca-app-pub-3940256099942544/2934735716'; // iOSテストID

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'GridView', // カスタムテンプレートID
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isNativeAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('NativeAd failed to load: $error');
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
    if (!_isNativeAdLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 330, // 表示するテンプレートに応じた高さ
      alignment: Alignment.center,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
