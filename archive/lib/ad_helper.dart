import 'dart:io';

//現在未使用のクラス
class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8268997781284735/2705018912';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-8268997781284735/6780895685';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8268997781284735/5742245797';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-8268997781284735/1300152498';
    }
    throw UnsupportedError("Unsupported platform");
  }
}
