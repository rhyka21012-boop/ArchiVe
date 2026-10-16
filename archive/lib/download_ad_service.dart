import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'remove_ads_promo.dart';

/// ダウンロード完了時に 3 回に 1 回インターステイシャル広告を表示するサービス。
/// - Premium/Pro プランのユーザーは表示しない
/// - カウントは SharedPreferences に永続化 (アプリ再起動を跨ぐ)
class DownloadAdService {
  DownloadAdService._();
  static final DownloadAdService _instance = DownloadAdService._();
  factory DownloadAdService() => _instance;

  InterstitialAd? _ad;
  bool _loading = false;
  static const _prefsKey = 'download_ad_count';
  static const _playbackKey = 'offline_playback_ad_count';
  static const _startKey = 'download_start_ad_count';
  static const _showEvery = 3;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8268997781284735/8554245309';
    }
    return 'ca-app-pub-8268997781284735/2906478597';
  }

  /// 起動時にプリロード
  void preload() {
    if (_ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
          _ad = null;
        },
      ),
    );
  }

  /// ダウンロード完了時に呼び出す。3 回に 1 回だけ広告表示。
  /// Premium/Pro なら常にスキップ。
  Future<void> maybeShowAfterDownload(BuildContext context) =>
      _maybeShow(context, _prefsKey);

  /// オフライン動画再生 (プレイヤー終了) 時に呼び出す。3 回に 1 回だけ広告表示。
  /// Premium/Pro なら常にスキップ。
  Future<void> maybeShowAfterOfflinePlayback(BuildContext context) =>
      _maybeShow(context, _playbackKey);

  /// ダウンロード開始時 (詳細画面) に呼び出す。3 回に 1 回だけ広告表示。
  /// Premium/Pro なら常にスキップ。
  Future<void> maybeShowBeforeDownload(BuildContext context) =>
      _maybeShow(context, _startKey);

  /// ダウンロード失敗時に呼び出す — 開始時にインクリメントしたカウンタを差し戻す
  /// (失敗したものは広告カウントに含めない)
  Future<void> revertStartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_startKey) ?? 0;
    if (current > 0) await prefs.setInt(_startKey, current - 1);
  }

  /// 最後に確認できた課金状態。
  ///
  /// 加入判定は毎回 RevenueCat に問い合わせており、失敗することがある
  /// (圏外、初回取得前など)。以前は失敗時に広告を表示していたため、
  /// 広告を消すために課金した利用者に広告が出てしまっていた。
  /// 一度でも課金が確認できていれば、判定できない間はそれを信じる。
  static const _paidCacheKey = 'last_known_paid';

  /// 課金ユーザーかどうか。判定できなければ最後に確認できた値を使う。
  Future<bool> _isPaid() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.active;
      final isPaid = active['Premium Plan']?.isActive == true ||
          active['Pro Plan']?.isActive == true;
      await prefs.setBool(_paidCacheKey, isPaid);
      return isPaid;
    } catch (_) {
      // 未確認の利用者は false (既定) になるため、無課金に広告は出続ける
      return prefs.getBool(_paidCacheKey) ?? false;
    }
  }

  Future<void> _maybeShow(BuildContext context, String counterKey) async {
    if (await _isPaid()) return;

    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(counterKey) ?? 0) + 1;
    await prefs.setInt(counterKey, count);
    if (count % _showEvery != 0) return;

    final ad = _ad;
    if (ad == null) {
      // ロード済みでなければスキップして次回のためにプリロード
      preload();
      return;
    }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        preload();
        // 広告閉じたタイミングで「広告を非表示にするには？」プロモを出す
        // (1 日 1 回まで、SnackBar なので操作を阻害しない)
        if (context.mounted) showRemoveAdsPromoIfNeeded(context);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        preload();
      },
    );
    try {
      await ad.show();
    } catch (e) {
      debugPrint('Interstitial show failed: $e');
      preload();
    }
  }
}
