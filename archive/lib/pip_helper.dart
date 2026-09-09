import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_pip_mode/simple_pip.dart';

/// Picture-in-Picture / バックグラウンド音声の統合ヘルパ。
///
/// - iOS: `UIBackgroundModes: audio` + AVAudioSession `.playback` によって
///        バックグラウンドでも音声再生が継続する (映像は停止)。
///        video PiP を完全対応するには video_player の iOS 実装への
///        カスタムネイティブコード追加が必要 (現時点では未対応)。
/// - Android: `android:supportsPictureInPicture` を Activity に付与 +
///            [SimplePip] パッケージで PiP モードに移行して小窓表示。
class PipHelper {
  static final PipHelper _instance = PipHelper._();
  factory PipHelper() => _instance;
  PipHelper._();

  SimplePip? _pip;
  bool _audioConfigured = false;
  VoidCallback? _onPipClosedByUser;
  VoidCallback? _onPipEntered;

  /// PiP の × ボタンで閉じられた時に呼ぶコールバックを登録。
  /// 呼び出し側で `null` にリセットすること。
  void setOnPipClosedByUser(VoidCallback? cb) {
    _onPipClosedByUser = cb;
    _ensurePipCallbacks();
  }

  /// PiP に入った瞬間に呼ぶコールバックを登録。
  /// (ミニプレイヤー状態から入った時に fullscreen へ促す用途)
  void setOnPipEntered(VoidCallback? cb) {
    _onPipEntered = cb;
    _ensurePipCallbacks();
  }

  /// SimplePip インスタンスをコールバック付きで初期化 (1 度だけ)。
  /// - onPipExited: PiP モード終了時に発火。
  ///   ライフサイクルが resumed でなければ「× で閉じた」とみなす。
  void _ensurePipCallbacks() {
    if (_pip != null) return;
    if (!Platform.isAndroid) return;
    _pip = SimplePip(
      onPipEntered: () {
        _wasInPip = true;
        _onPipEntered?.call();
      },
      onPipExited: () {
        // onPipExited 発火時点ではライフサイクル状態がまだ確定していない事が多いので、
        // 1.2 秒までポーリング (100ms 間隔) して:
        //   - resumed に到達 → ユーザーが PiP をタップしてアプリ復帰 → 何もしない
        //   - resumed にならないまま経過 → × で閉じたとみなして close
        _pollLifecycleAfterPip();
      },
    );
  }

  bool _wasInPip = false;

  Future<void> _pollLifecycleAfterPip() async {
    const maxWaitMs = 1200;
    const stepMs = 100;
    int elapsed = 0;
    while (elapsed < maxWaitMs) {
      await Future.delayed(const Duration(milliseconds: stepMs));
      elapsed += stepMs;
      final state = WidgetsBinding.instance.lifecycleState;
      if (state == AppLifecycleState.resumed) {
        // ユーザーが PiP をタップしてアプリに戻ってきた
        _wasInPip = false;
        return;
      }
    }
    // 1.2 秒経っても resumed にならなかった → × で閉じた
    if (_wasInPip) {
      _wasInPip = false;
      _onPipClosedByUser?.call();
    }
  }

  /// アプリ起動時 (main) から一度だけ呼び出す。音声セッションを設定。
  Future<void> ensureConfigured() async {
    if (_audioConfigured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      // active にしないと iOS 側でバックグラウンド音声継続が効かない
      await session.setActive(true);
      _audioConfigured = true;
    } catch (e) {
      debugPrint('AudioSession configure failed: $e');
    }
  }

  Future<bool> isPipAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      return await SimplePip.isPipAvailable;
    } catch (_) {
      return false;
    }
  }

  /// PiP モードに切り替え。Android のみ動作。iOS では何もしない。
  /// (フォールバック: setAutoPip が効かない Android 11 以下用)
  Future<void> enterPip({
    int aspectWidth = 16,
    int aspectHeight = 9,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final available = await SimplePip.isPipAvailable;
      if (!available) return;
      _ensurePipCallbacks();
      _pip ??= SimplePip();
      await _pip!.enterPipMode(
        aspectRatio: (aspectWidth, aspectHeight),
      );
    } catch (e) {
      debugPrint('SimplePip enterPipMode failed: $e');
    }
  }

  /// Android 12+ の Auto-PiP を有効化: ユーザーがホームボタンで離れた瞬間に
  /// 自動的に PiP モードに移行する。動画再生開始時に一度呼べば OK。
  Future<void> armAutoPip({
    int aspectWidth = 16,
    int aspectHeight = 9,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final autoAvailable = await SimplePip.isAutoPipAvailable;
      if (!autoAvailable) return; // Android 12 未満はスキップ
      _ensurePipCallbacks();
      _pip ??= SimplePip();
      await _pip!.setAutoPipMode(
        aspectRatio: (aspectWidth, aspectHeight),
        autoEnter: true,
        seamlessResize: true,
      );
    } catch (e) {
      debugPrint('SimplePip setAutoPipMode failed: $e');
    }
  }

  /// Auto-PiP を無効化 (プレイヤー close 時)
  Future<void> disarmAutoPip() async {
    if (!Platform.isAndroid) return;
    try {
      _ensurePipCallbacks();
      _pip ??= SimplePip();
      await _pip!.setAutoPipMode(autoEnter: false);
    } catch (e) {
      debugPrint('SimplePip disarm failed: $e');
    }
  }

  Future<bool> get isInPip async {
    if (!Platform.isAndroid) return false;
    try {
      return await SimplePip.isPipActivated;
    } catch (_) {
      return false;
    }
  }
}
