import 'dart:io'; // プラットフォーム判定に必要
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MyAdWidget extends StatefulWidget {
  const MyAdWidget({Key? key}) : super(key: key);

  @override
  _MyAdWidgetState createState() => _MyAdWidgetState();
}

class _MyAdWidgetState extends State<MyAdWidget> {
  late BannerAd _bannerAd; // バナー広告のインスタンス
  bool _isAdLoaded = false; // 広告がロード済みかどうかを管理

  @override
  void initState() {
    super.initState();

    // テスト用広告ユニットID（Google公式のテストID）
    const String testAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
    const String testAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';

    // 本番用広告ユニットID（AdMobで発行されたIDを使用）
    const String productionAdUnitIdAndroid =
        'ca-app-pub-8268997781284735/2705018912';
    const String productionAdUnitIdIOS =
        'ca-app-pub-8268997781284735/6780895685';

    // テストモードの切り替え（true: テスト広告, false: 本番広告）
    const bool isTestMode = false;

    // プラットフォームごとに適切な広告ユニットIDを選択
    String adUnitId;
    if (Platform.isAndroid) {
      adUnitId = isTestMode ? testAdUnitIdAndroid : productionAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      adUnitId = isTestMode ? testAdUnitIdIOS : productionAdUnitIdIOS;
    } else {
      debugPrint('Unsupported platform');
      return; // iOSまたはAndroid以外の環境では処理を行わない
    }

    // バナー広告のインスタンスを生成
    _bannerAd = BannerAd(
      adUnitId: adUnitId, // 選択された広告ユニットID
      size: AdSize.banner, // バナー広告のサイズ（標準）
      request: const AdRequest(), // 広告リクエスト
      listener: BannerAdListener(
        onAdLoaded: (_) {
          // 広告が正常にロードされた場合
          setState(() {
            _isAdLoaded = true;
          });
          debugPrint('Ad loaded successfully.');
        },
        onAdFailedToLoad: (ad, error) {
          // 広告のロードが失敗した場合
          debugPrint('Ad failed to load: $error');
          ad.dispose(); // メモリリークを防ぐためリソースを解放
          setState(() {
            _isAdLoaded = false; // 広告のロードに失敗した場合は非表示
          });
        },
      ),
    )..load(); // 広告のロードを開始
  }

  @override
  void dispose() {
    // ウィジェットが破棄される際に広告リソースを解放
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (!_isAdLoaded) {
      // 広告がロードされていない場合は空のウィジェットを返す
      return const SizedBox.shrink();
    }

    // 広告が正常にロードされた場合のみ表示
    return Container(
      //width: _bannerAd.size.width.toDouble(), // 横幅いっぱいに広げる
      width: double.infinity, // 「横幅をデバイスの横幅いっぱいに広げる」場合
      height: _bannerAd.size.height.toDouble(), // 広告の高さを指定
      alignment: Alignment.center, // 中央揃え
      color: colorScheme.surface,
      child: AdWidget(ad: _bannerAd), // バナー広告を表示
    );
  }
}
