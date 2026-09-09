import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'l10n/app_localizations.dart';
import 'mini_player_provider.dart';
import 'pip_helper.dart';
import 'premium_detail.dart';

/// アプリのルート Stack に常駐する、
/// **単一 VideoPlayer widget** をミニ / フルスクリーンで使い回すレイヤー。
///
/// 以前は「ミニ = MiniPlayerOverlay 内の VideoPlayer」「フル = LocalVideoPlayerPage 内の VideoPlayer」で
/// 別 Element だったため、切替時に Texture のバインドが失敗して音声のみになる事故が発生していた。
/// このレイヤーでは VideoPlayer を 1 個だけマウントし、Positioned の
/// 座標/サイズと外側コントロールだけを state に応じて切り替える。
class GlobalPlayerLayer extends ConsumerStatefulWidget {
  const GlobalPlayerLayer({super.key});

  @override
  ConsumerState<GlobalPlayerLayer> createState() => _GlobalPlayerLayerState();
}

class _GlobalPlayerLayerState extends ConsumerState<GlobalPlayerLayer>
    with WidgetsBindingObserver {
  // ミニカードの位置 (ドラッグで移動)
  Offset _miniOffset = const Offset(0, 0);
  // ミニカードのスケール (ピンチでサイズ変更、0.6〜2.0)
  double _miniScale = 1.0;
  double _scaleStart = 1.0;
  Size? _lastScreenSize;
  double? _lastAspect;
  // フルスクリーン用コントロール表示
  bool _showFullControls = true;
  Timer? _hideTimer;
  Timer? _progressSaveTimer;
  double _speed = 1.0;
  bool _viewCounted = false;
  String? _viewCountedItemUrl;
  // 前回中断位置の復元は 1 動画につき 1 回だけ実行 (build 毎の呼び出し防止)
  bool _positionRestored = false;
  String? _positionRestoredItemUrl;
  // シークバードラッグ中の一時的な値 (指の位置を即反映する用)
  double? _dragValue;
  static const _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  // OverlayEntry を保持しておき、setState 時に markNeedsBuild で
  // 内側の Consumer の builder を再実行させる (Overlay は
  // initialEntries を 1 度しか消費しないため親 setState では再ビルドされない)
  OverlayEntry? _overlayEntry;
  // 自前 Overlay の OverlayState 参照 (速度ピッカー等の一時 Entry 挿入に使用)。
  // Navigator が無いため showModalBottomSheet 等が使えないので、自前 Overlay に挿す。
  OverlayState? _selfOverlayState;

  // ─────────── 新機能用 state ───────────
  // Premium/Pro 判定 (A-B ループ、ブックマーク、音声のみ、カスタム速度に使用)
  bool _isPremium = false;
  bool _premiumChecked = false;

  // ループ再生 (無料)
  bool _loopEnabled = false;

  // ピンチズーム/パン (無料) — フルスクリーン時のみ
  final TransformationController _videoTransform = TransformationController();

  // A-B ループ (Premium+)
  Duration? _abLoopA;
  Duration? _abLoopB;
  VoidCallback? _abLoopListener;

  // タイムスタンプブックマーク (Premium+)
  final Map<String, List<_Bookmark>> _bookmarksByUrl = {};

  // 音声のみモード (Premium+)
  bool _audioOnly = false;

  // カスタム速度 (Premium+)
  double? _customSpeed;

  // アプリ内音量 (端末音量とは独立、0.0〜1.0)。無料機能。
  double _volume = 1.0;

  // スリープタイマー (無料機能)
  Timer? _sleepTimer;
  Timer? _sleepTicker;
  DateTime? _sleepEndsAt;
  Duration? _sleepDuration;

  // プレイヤー詳細メニュー (閉じるボタン下のメニュー) の開閉状態
  bool _showPlayerMenu = false;

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _overlayEntry?.markNeedsBuild();
  }

  // ミニカードは 220x260 のバウンディングボックスに収める。
  // アスペクト比を優先: 縦長動画は width を縮めて縦長カードに、
  // 横長動画は height を縮めて横長カードに。
  static const double _miniMaxWidth = 220;
  static const double _miniMaxHeight = 260;
  static const double _bottomInset = 100;
  /// 動画のアスペクト比を尊重した (width, height) を返す。
  /// (maxWidth × maxHeight のボックスに、アスペクト比を保ってフィットさせる)
  Size _miniSizeFor(double aspect) {
    final a = aspect <= 0 ? (16 / 9) : aspect;
    double w = _miniMaxWidth;
    double h = w / a;
    if (h > _miniMaxHeight) {
      h = _miniMaxHeight;
      w = h * a;
    }
    return Size(w, h);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPremiumStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _progressSaveTimer?.cancel();
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _detachAbLoopListener();
    _videoTransform.dispose();
    super.dispose();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final isPremium =
          info.entitlements.all['Premium Plan']?.isActive ?? false;
      final isPro = info.entitlements.all['Pro Plan']?.isActive ?? false;
      if (!mounted) return;
      setState(() {
        _isPremium = isPremium || isPro;
        _premiumChecked = true;
      });
    } catch (_) {
      if (mounted) setState(() => _premiumChecked = true);
    }
  }

  /// Premium ゲート: 無料ユーザーには「動画の上に導線ダイアログ」を表示。
  /// 導線ダイアログの CTA でユーザーが加入を選んだ場合のみ、
  /// プレイヤーをミニに縮小してから購入画面を push (でないと動画に隠れる)。
  Future<bool> _ensurePremium() async {
    if (_isPremium) return true;
    final wantsUpgrade = await _showPremiumPromoOverlay();
    if (wantsUpgrade != true || !mounted) return false;
    // 全画面 → ミニに縮小してから購入画面へ (root navigator)
    ref.read(miniPlayerProvider.notifier).minimize();
    await Future.delayed(const Duration(milliseconds: 60));
    if (!mounted) return false;
    final bought = await PremiumGate.ensurePremium(context);
    if (bought && mounted) {
      setState(() => _isPremium = true);
    }
    return bought;
  }

  /// 動画の上に表示する Premium+ 導線ダイアログ。
  /// true = 加入する / false or null = 閉じる
  Future<bool?> _showPremiumPromoOverlay() async {
    final overlayState = _selfOverlayState;
    if (overlayState == null) return false;
    final completer = Completer<bool?>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PremiumPromoOverlay(
        onUpgrade: () {
          if (!completer.isCompleted) completer.complete(true);
        },
        onDismiss: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    overlayState.insert(entry);
    final result = await completer.future;
    entry.remove();
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.inactive || s == AppLifecycleState.paused) {
      final state = ref.read(miniPlayerProvider);
      if (state.controller?.value.isPlaying == true) {
        // ミニ状態のまま PiP に入ると小窓の中にアプリ UI が丸ごと縮小されて
        // 見切れるため、事前に fullscreen へ切り替えて動画が画面全体を
        // 占める状態にしてから PiP へ入る
        if (!state.isFullScreen) {
          ref.read(miniPlayerProvider.notifier).expand();
        }
        PipHelper().enterPip();
      }
    }
  }

  void _scheduleHideFull() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showFullControls = false);
    });
  }

  void _toggleFullControls() {
    setState(() => _showFullControls = !_showFullControls);
    if (_showFullControls) _scheduleHideFull();
  }

  Future<void> _seekBy(VideoPlayerController c, Duration delta) async {
    final now = c.value.position;
    final duration = c.value.duration;
    final target = now + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    await c.seekTo(clamped);
    _scheduleHideFull();
  }

  Future<void> _pickSpeed(VideoPlayerController c) async {
    _hideTimer?.cancel();
    final overlayState = _selfOverlayState;
    if (overlayState == null) return;
    final l = L10n.of(context)!;
    final completer = Completer<Object?>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SpeedPickerOverlay(
        current: _speed,
        speeds: _speeds,
        title: l.player_speed,
        labelBuilder: (s) => l.player_speed_x(_fmtSpeed(s)),
        customLabel: l.player_speed_custom,
        onPick: (v) {
          if (!completer.isCompleted) completer.complete(v);
        },
        onPickCustom: () {
          if (!completer.isCompleted) completer.complete('custom');
        },
        onDismiss: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    overlayState.insert(entry);
    final picked = await completer.future;
    entry.remove();
    if (!mounted) return;
    if (picked == 'custom') {
      if (!await _ensurePremium()) {
        _scheduleHideFull();
        return;
      }
      if (!mounted) return;
      final custom = await _promptCustomSpeed();
      if (custom != null) {
        await c.setPlaybackSpeed(custom);
        if (!mounted) return;
        setState(() {
          _speed = custom;
          _customSpeed = custom;
        });
      }
    } else if (picked is double) {
      await c.setPlaybackSpeed(picked);
      if (!mounted) return;
      setState(() => _speed = picked);
    }
    _scheduleHideFull();
  }

  Future<double?> _promptCustomSpeed() async {
    final overlayState = _selfOverlayState;
    if (overlayState == null) return null;
    final l = L10n.of(context)!;
    final completer = Completer<double?>();
    double value = _customSpeed ?? _speed;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CustomSpeedOverlay(
        initial: value,
        title: l.player_speed_custom,
        onPick: (v) {
          if (!completer.isCompleted) completer.complete(v);
        },
        onDismiss: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    overlayState.insert(entry);
    final picked = await completer.future;
    entry.remove();
    return picked;
  }

  // ─────────── ループ再生 (無料) ───────────
  Future<void> _toggleLoop(VideoPlayerController c) async {
    final next = !_loopEnabled;
    await c.setLooping(next);
    if (!mounted) return;
    setState(() => _loopEnabled = next);
    _scheduleHideFull();
  }

  // ─────────── A-B ループ (Premium+) ───────────
  void _attachAbLoopListener(VideoPlayerController c) {
    _detachAbLoopListener();
    _abLoopListener = () async {
      final a = _abLoopA;
      final b = _abLoopB;
      if (a == null || b == null) return;
      final pos = c.value.position;
      if (pos >= b) {
        await c.seekTo(a);
      }
    };
    c.addListener(_abLoopListener!);
  }

  void _detachAbLoopListener() {
    final l = _abLoopListener;
    if (l == null) return;
    final controller = ref.read(miniPlayerProvider).controller;
    controller?.removeListener(l);
    _abLoopListener = null;
  }

  Future<void> _handleAbLoopA(VideoPlayerController c) async {
    if (!await _ensurePremium()) return;
    setState(() => _abLoopA = c.value.position);
    if (_abLoopA != null && _abLoopB != null) _attachAbLoopListener(c);
    _scheduleHideFull();
  }

  Future<void> _handleAbLoopB(VideoPlayerController c) async {
    if (!await _ensurePremium()) return;
    final pos = c.value.position;
    // A より後ろでなければ何もしない
    if (_abLoopA != null && pos <= _abLoopA!) return;
    setState(() => _abLoopB = pos);
    if (_abLoopA != null && _abLoopB != null) _attachAbLoopListener(c);
    _scheduleHideFull();
  }

  void _clearAbLoop() {
    _detachAbLoopListener();
    setState(() {
      _abLoopA = null;
      _abLoopB = null;
    });
    _scheduleHideFull();
  }

  // ─────────── タイムスタンプ・ブックマーク (Premium+) ───────────
  Future<void> _loadBookmarks(String url) async {
    if (url.isEmpty) return;
    if (_bookmarksByUrl.containsKey(url)) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('bookmarks_$url') ?? [];
    final list = raw
        .map((s) {
          try {
            final parts = s.split('|');
            final sec = int.parse(parts[0]);
            final label = parts.length > 1 ? parts.sublist(1).join('|') : '';
            return _Bookmark(Duration(seconds: sec), label);
          } catch (_) {
            return null;
          }
        })
        .whereType<_Bookmark>()
        .toList();
    _bookmarksByUrl[url] = list;
  }

  Future<void> _saveBookmarks(String url) async {
    final list = _bookmarksByUrl[url] ?? const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'bookmarks_$url',
      list.map((b) => '${b.position.inSeconds}|${b.label}').toList(),
    );
  }

  Future<void> _addBookmark(VideoPlayerController c, String url) async {
    if (!await _ensurePremium()) return;
    if (url.isEmpty) return;
    await _loadBookmarks(url);
    final list = _bookmarksByUrl.putIfAbsent(url, () => []);
    list.add(_Bookmark(c.value.position, ''));
    list.sort((a, b) => a.position.compareTo(b.position));
    await _saveBookmarks(url);
    if (!mounted) return;
    setState(() {});
    _scheduleHideFull();
  }

  Future<void> _showBookmarksSheet(
      VideoPlayerController c, String url) async {
    if (!await _ensurePremium()) return;
    await _loadBookmarks(url);
    final overlayState = _selfOverlayState;
    if (overlayState == null) return;
    final l = L10n.of(context)!;
    final completer = Completer<void>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BookmarksSheetOverlay(
        title: l.player_bookmarks,
        emptyLabel: l.player_bookmarks_empty,
        bookmarks: _bookmarksByUrl[url] ?? const [],
        formatDuration: _fmt,
        onTap: (b) async {
          await c.seekTo(b.position);
          if (!completer.isCompleted) completer.complete();
        },
        onDelete: (b) async {
          _bookmarksByUrl[url]?.remove(b);
          await _saveBookmarks(url);
          if (!mounted) return;
          setState(() {});
        },
        onDismiss: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlayState.insert(entry);
    await completer.future;
    entry.remove();
    _scheduleHideFull();
  }

  // ─────────── 音声のみモード (Premium+) ───────────
  // ─────────── スリープタイマー (無料) ───────────
  Duration? get _sleepRemaining {
    final end = _sleepEndsAt;
    if (end == null) return null;
    final r = end.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  String get _sleepLabel {
    final r = _sleepRemaining;
    if (r == null) return 'OFF';
    final m = r.inMinutes;
    final s = r.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startSleepTimer(VideoPlayerController c, Duration d) {
    _cancelSleepTimer();
    _sleepDuration = d;
    _sleepEndsAt = DateTime.now().add(d);
    _sleepTimer = Timer(d, () async {
      if (!mounted) return;
      try {
        await c.pause();
      } catch (_) {}
      _cancelSleepTimer();
    });
    // 1 秒毎の UI 更新
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
    setState(() {});
    _scheduleHideFull();
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTicker?.cancel();
    _sleepTicker = null;
    _sleepEndsAt = null;
    _sleepDuration = null;
    if (mounted) setState(() {});
  }

  Future<void> _pickSleepTimer(VideoPlayerController c) async {
    // Premium+ 限定
    if (!await _ensurePremium()) return;
    _hideTimer?.cancel();
    final overlayState = _selfOverlayState;
    if (overlayState == null) return;
    final completer = Completer<Duration?>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SleepTimerPickerOverlay(
        currentDuration: _sleepDuration,
        onPick: (d) => completer.complete(d),
        onDismiss: () => completer.complete(null),
      ),
    );
    overlayState.insert(entry);
    final result = await completer.future;
    entry.remove();
    if (!mounted) return;
    if (result == null) {
      _scheduleHideFull();
      return;
    }
    if (result == Duration.zero) {
      _cancelSleepTimer();
    } else {
      _startSleepTimer(c, result);
    }
  }

  // ─────────── アプリ内音量 (無料、端末音量とは独立) ───────────
  Future<void> _setVolume(VideoPlayerController c, double v) async {
    final clamped = v.clamp(0.0, 1.0);
    await c.setVolume(clamped);
    if (!mounted) return;
    setState(() => _volume = clamped);
  }

  Future<void> _toggleAudioOnly() async {
    if (!_audioOnly && !await _ensurePremium()) return;
    setState(() => _audioOnly = !_audioOnly);
    _scheduleHideFull();
  }

  static String _fmtSpeed(double s) {
    if (s == s.toInt().toDouble()) return '${s.toInt()}';
    return s.toString();
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _bumpViewCount(String url) async {
    if (url.isEmpty) return;
    if (_viewCountedItemUrl == url && _viewCounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(url) ?? 0;
      await prefs.setInt(url, current + 1);
      _viewCountedItemUrl = url;
      _viewCounted = true;
    } catch (_) {}
  }

  Future<void> _saveProgress(VideoPlayerController c, String? itemUrl) async {
    if (itemUrl == null || itemUrl.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pos = c.value.position.inSeconds;
      final dur = c.value.duration.inSeconds;
      if (dur > 0) await prefs.setInt('offline_dur_$itemUrl', dur);
      if (dur > 0 && dur - pos < 10) {
        await prefs.remove('offline_pos_$itemUrl');
      } else if (pos > 3) {
        await prefs.setInt('offline_pos_$itemUrl', pos);
      }
    } catch (_) {}
  }

  Future<void> _restoreLastPosition(
      VideoPlayerController c, String? itemUrl) async {
    if (itemUrl == null || itemUrl.isEmpty) return;
    // 同じ動画に対しては 1 度だけ実行 (再ビルドの度に seek 戻しをしない)
    if (_positionRestored && _positionRestoredItemUrl == itemUrl) return;
    _positionRestored = true;
    _positionRestoredItemUrl = itemUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sec = prefs.getInt('offline_pos_$itemUrl');
      if (sec == null || sec <= 3) return;
      final dur = c.value.duration;
      if (dur.inSeconds > 0 && dur.inSeconds - sec < 10) return;
      await c.seekTo(Duration(seconds: sec));
    } catch (_) {}
  }

  void _ensureProgressTimer(VideoPlayerController c, String? itemUrl) {
    if (_progressSaveTimer != null) return;
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveProgress(c, itemUrl);
    });
  }

  void _resetForNewController() {
    _viewCounted = false;
    _viewCountedItemUrl = null;
    _positionRestored = false;
    _positionRestoredItemUrl = null;
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    _speed = 1.0;
    _showFullControls = true;
    // 新しい動画に切り替わったらスリープタイマーもリセット
    _cancelSleepTimer();
    // 新しいコントローラーにも現在の音量値を適用
    final c = ref.read(miniPlayerProvider).controller;
    if (c != null && c.value.isInitialized) {
      // ignore: unawaited_futures
      c.setVolume(_volume);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Slider / Tooltip / OverlayPortal 等の Material widget が要求する
    // Overlay 祖先をこのレイヤー内で提供する (MaterialApp.builder 外は Navigator が無い)。
    // OverlayEntry.builder 内で Consumer を使うことで、
    // miniPlayerProvider の変化にリアクティブに再ビルドされる。
    // 加えて外側 setState では _overlayEntry.markNeedsBuild() で強制再ビルド。
    _overlayEntry ??= OverlayEntry(
      builder: (overlayCtx) => Consumer(
        builder: (consumerCtx, ref, _) {
              // 自前 Overlay の OverlayState を掴んでおく (速度ピッカー等に使用)
              _selfOverlayState ??= Overlay.of(overlayCtx);
              final state = ref.watch(miniPlayerProvider);
              if (!state.isActive) return const SizedBox.shrink();
              final controller = state.controller;
              if (controller == null || !controller.value.isInitialized) {
                return const SizedBox.shrink();
              }

              // controller が切り替わった時のリセット (ref.listen は 1 度だけ)
              ref.listen<MiniPlayerState>(miniPlayerProvider, (prev, next) {
                if (prev?.controller != next.controller) {
                  _resetForNewController();
                }
              });

              final screen = MediaQuery.of(consumerCtx).size;
              final aspect = controller.value.aspectRatio > 0
                  ? controller.value.aspectRatio
                  : (16 / 9);
              final miniSize = _miniSizeFor(aspect);
              if (_lastScreenSize != screen || _lastAspect != aspect) {
                _lastScreenSize = screen;
                _lastAspect = aspect;
                _miniOffset = Offset(
                  screen.width - miniSize.width - 12,
                  screen.height - miniSize.height - _bottomInset,
                );
              }

              if (state.isFullScreen) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _bumpViewCount(state.itemUrl ?? '');
                  _restoreLastPosition(controller, state.itemUrl);
                  _ensureProgressTimer(controller, state.itemUrl);
                });
              }

              if (state.isFullScreen) {
                return Positioned.fill(
                    child: _buildFullScreen(controller, state));
              }
              return _buildMini(controller, state, screen, miniSize);
            },
      ),
    );
    return Overlay(initialEntries: [_overlayEntry!]);
  }

  /// GlobalPlayerLayer は Navigator の外にあり Tooltip 用の Overlay が無いため、
  /// CircleAppBarIcon の代わりに Tooltip を使わない簡易円形ボタンで代替する。
  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 20,
  }) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: iconSize, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFullScreen(VideoPlayerController c, MiniPlayerState state) {
    final l = L10n.of(context)!;
    final aspect =
        c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Builder(
          builder: (context) {
            return Stack(
              children: [
                // 動画本体 + ピンチズーム/パン (無料)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleFullControls,
                    child: _audioOnly
                        // 音声のみ: 動画描画をスキップして黒背景に置換
                        ? const _AudioOnlyPlaceholder()
                        : Center(
                            child: InteractiveViewer(
                              transformationController: _videoTransform,
                              minScale: 1.0,
                              maxScale: 4.0,
                              panEnabled: true,
                              scaleEnabled: true,
                              child: AspectRatio(
                                aspectRatio: aspect,
                                child: VideoPlayer(
                                  c,
                                  key: const ValueKey('global-video'),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showFullControls ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showFullControls,
                    child: _fullOverlay(c, state, l),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fullOverlay(
      VideoPlayerController c, MiniPlayerState state, L10n l) {
    return GestureDetector(
      onTap: () {
        // メニュー表示中はメニューだけ閉じる、それ以外は控えるを隠す
        if (_showPlayerMenu) {
          setState(() => _showPlayerMenu = false);
          _scheduleHideFull();
          return;
        }
        _hideTimer?.cancel();
        setState(() => _showFullControls = false);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _circleBtn(
                        icon: Icons.keyboard_arrow_down,
                        onTap: () {
                          ref.read(miniPlayerProvider.notifier).minimize();
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          state.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _circleBtn(
                        icon: Icons.close,
                        onTap: () {
                          ref.read(miniPlayerProvider.notifier).close();
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // シーク行だけは controller の position 変化に追随させるため
                  // ValueListenableBuilder でラップして再ビルドを局所化
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: c,
                    builder: (_, v, __) {
                      final live = v.position;
                      final dur = v.duration;
                      final showPos = _dragValue != null
                          ? Duration(milliseconds: _dragValue!.toInt())
                          : live;
                      final maxMs = dur.inMilliseconds.toDouble().clamp(1, 1e12);
                      final sliderVal = (_dragValue ??
                              live.inMilliseconds
                                  .clamp(0, dur.inMilliseconds)
                                  .toDouble())
                          .clamp(0, maxMs.toDouble());
                      return Row(
                        children: [
                          Text(
                            _fmt(showPos),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          Expanded(
                            child: Slider(
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                              value: sliderVal.toDouble(),
                              max: maxMs.toDouble(),
                              onChangeStart: (nv) {
                                setState(() => _dragValue = nv);
                                _hideTimer?.cancel();
                              },
                              onChanged: (nv) {
                                setState(() => _dragValue = nv);
                                c.seekTo(Duration(milliseconds: nv.toInt()));
                              },
                              onChangeEnd: (nv) async {
                                await c
                                    .seekTo(Duration(milliseconds: nv.toInt()));
                                if (!mounted) return;
                                setState(() => _dragValue = null);
                                _scheduleHideFull();
                              },
                            ),
                          ),
                          Text(_fmt(dur),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _seekBtn(Icons.replay_10, 30,
                            () => _seekBy(c, const Duration(seconds: -10))),
                        const SizedBox(width: 4),
                        _seekBtn(Icons.replay_5, 26,
                            () => _seekBy(c, const Duration(seconds: -5))),
                        const SizedBox(width: 4),
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: c,
                          builder: (_, v, __) {
                            final playing = v.isPlaying;
                            return IconButton(
                              iconSize: 48,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                playing
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                if (playing) {
                                  await c.pause();
                                } else {
                                  await c.play();
                                }
                                _scheduleHideFull();
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        _seekBtn(Icons.forward_5, 26,
                            () => _seekBy(c, const Duration(seconds: 5))),
                        const SizedBox(width: 4),
                        _seekBtn(Icons.forward_10, 30,
                            () => _seekBy(c, const Duration(seconds: 10))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
            // 閉じるボタンの下: メニュートグルボタン (常に右上に浮かべる)
            Positioned(
              top: 52,
              right: 12,
              child: _circleBtn(
                icon: _showPlayerMenu ? Icons.expand_less : Icons.more_vert,
                onTap: () {
                  setState(() => _showPlayerMenu = !_showPlayerMenu);
                  if (_showPlayerMenu) {
                    _hideTimer?.cancel();
                  } else {
                    _scheduleHideFull();
                  }
                },
              ),
            ),
            // メニュー本体 (動画に重ねて表示、枠なし)
            if (_showPlayerMenu)
              Positioned(
                top: 96,
                right: 12,
                child: _PlayerMenu(
                  isPremium: _isPremium,
                  speedLabel: l.player_speed_x(_fmtSpeed(_speed)),
                  loopEnabled: _loopEnabled,
                  audioOnly: _audioOnly,
                  abA: _abLoopA,
                  abB: _abLoopB,
                  formatDuration: _fmt,
                  bookmarksLabel: l.player_bookmarks,
                  volume: _volume,
                  onVolume: (v) => _setVolume(c, v),
                  sleepLabel: _sleepLabel,
                  sleepActive: _sleepEndsAt != null,
                  onSleep: () async {
                    setState(() => _showPlayerMenu = false);
                    await _pickSleepTimer(c);
                  },
                  onSpeed: () async {
                    setState(() => _showPlayerMenu = false);
                    await _pickSpeed(c);
                  },
                  onLoop: () => _toggleLoop(c),
                  onAudioOnly: _toggleAudioOnly,
                  onAbA: () => _handleAbLoopA(c),
                  onAbB: () => _handleAbLoopB(c),
                  onAbClear: _clearAbLoop,
                  onAddBookmark: () => _addBookmark(c, state.itemUrl ?? ''),
                  onShowBookmarks: () async {
                    setState(() => _showPlayerMenu = false);
                    await _showBookmarksSheet(c, state.itemUrl ?? '');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _seekBtn(IconData icon, double size, VoidCallback onTap) {
    return Opacity(
      opacity: 0.75,
      child: IconButton(
        iconSize: size,
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMini(VideoPlayerController c, MiniPlayerState state,
      Size screen, Size miniSize) {
    // ピンチでスケール変更 → 有効サイズを算出 (アスペクト比を保つ)
    final effectiveWidth = miniSize.width * _miniScale;
    final effectiveHeight = miniSize.height * _miniScale;
    return Positioned(
      left: _miniOffset.dx,
      top: _miniOffset.dy,
      child: _MiniCard(
        controller: c,
        title: state.title,
        width: effectiveWidth,
        height: effectiveHeight,
        onScaleStart: (_) {
          _scaleStart = _miniScale;
        },
        onScaleUpdate: (details) {
          setState(() {
            // ドラッグ (1 指) と ピンチ (2 指) を同時ハンドル
            _miniOffset += details.focalPointDelta;
            // 画面内で移動余地を残すため、幅が screen.width - 60 を超えないように
            // 上限スケールを動的に計算 (画面より少しはみ出す = ドラッグ不能を防止)
            final maxScaleByWidth =
                (screen.width - 60) / miniSize.width;
            final maxScaleByHeight =
                (screen.height - 200) / miniSize.height;
            final maxScale = maxScaleByWidth < maxScaleByHeight
                ? maxScaleByWidth
                : maxScaleByHeight;
            final upperBound =
                (maxScale < 2.0 ? maxScale : 2.0).clamp(0.6, 2.0);
            _miniScale = (_scaleStart * details.scale)
                .clamp(0.6, upperBound)
                .toDouble();
            // 有効サイズで画面内に収める (アスペクト比を保つ)
            final w = miniSize.width * _miniScale;
            final h = miniSize.height * _miniScale;
            final maxDx = (screen.width - w).clamp(0.0, double.infinity);
            final maxDy = (screen.height - h - 40)
                .clamp(MediaQuery.of(context).padding.top, double.infinity);
            _miniOffset = Offset(
              _miniOffset.dx.clamp(0, maxDx),
              _miniOffset.dy
                  .clamp(MediaQuery.of(context).padding.top, maxDy),
            );
          });
        },
        onExpand: () {
          ref.read(miniPlayerProvider.notifier).expand();
        },
        onClose: () {
          ref.read(miniPlayerProvider.notifier).close();
        },
      ),
    );
  }
}

class _MiniCard extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final double width;
  final double height;
  final ValueChanged<ScaleStartDetails> onScaleStart;
  final ValueChanged<ScaleUpdateDetails> onScaleUpdate;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  const _MiniCard({
    required this.controller,
    required this.title,
    required this.width,
    required this.height,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onExpand,
    required this.onClose,
  });

  @override
  State<_MiniCard> createState() => _MiniCardState();
}

class _MiniCardState extends State<_MiniCard> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  void _toggle() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // pan (1 指ドラッグ) と pinch (2 指) の両方を onScale* で扱う
      onScaleStart: widget.onScaleStart,
      onScaleUpdate: widget.onScaleUpdate,
      onTap: _toggle,
      child: Material(
        elevation: 8,
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio > 0
                      ? widget.controller.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(widget.controller,
                      key: const ValueKey('global-video')),
                ),
              ),
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 中央: 拡大ボタン
                      Center(
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              _hideTimer?.cancel();
                              widget.onExpand();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.fullscreen,
                                  size: 22, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      // 右上: 閉じる
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.onClose,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      // 下部中央: 再生/停止
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 6,
                        child: Center(
                          child: ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: widget.controller,
                            builder: (_, v, __) => Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  if (v.isPlaying) {
                                    widget.controller.pause();
                                  } else {
                                    widget.controller.play();
                                  }
                                  _scheduleHide();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    v.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 最下部プログレスバー
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: widget.controller,
                          builder: (_, v, __) {
                            final total = v.duration.inMilliseconds
                                .clamp(1, 1 << 30)
                                .toDouble();
                            final now = v.position.inMilliseconds
                                .clamp(0, v.duration.inMilliseconds)
                                .toDouble();
                            return LinearProgressIndicator(
                              value: now / total,
                              minHeight: 2,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// GlobalPlayerLayer 自前 Overlay 上に挿入する簡易ボトムシート型
/// 速度ピッカー (Navigator が無いため showModalBottomSheet 代替)。
class _SpeedPickerOverlay extends StatelessWidget {
  final double current;
  final List<double> speeds;
  final String title;
  final String Function(double s) labelBuilder;
  final ValueChanged<double> onPick;
  final VoidCallback onDismiss;
  final String? customLabel;
  final VoidCallback? onPickCustom;

  const _SpeedPickerOverlay({
    required this.current,
    required this.speeds,
    required this.title,
    required this.labelBuilder,
    required this.onPick,
    required this.onDismiss,
    this.customLabel,
    this.onPickCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // バリア (タップで dismiss)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: const ColoredBox(color: Color(0x88000000)),
            ),
          ),
          // 下部のシート
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: const Color(0xFF1E1E1E),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in speeds)
                            _SpeedChip(
                              label: labelBuilder(s),
                              selected: s == current,
                              onTap: () => onPick(s),
                            ),
                          if (customLabel != null && onPickCustom != null)
                            _SpeedChip(
                              label: customLabel!,
                              selected: !speeds.contains(current),
                              onTap: onPickCustom!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white12,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.speed,
                size: 16,
                color: selected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// タイムスタンプブックマーク (Premium+)
class _Bookmark {
  final Duration position;
  final String label;
  const _Bookmark(this.position, this.label);
}

/// カスタム速度入力用のオーバーレイシート
class _CustomSpeedOverlay extends StatefulWidget {
  final double initial;
  final String title;
  final ValueChanged<double> onPick;
  final VoidCallback onDismiss;
  const _CustomSpeedOverlay({
    required this.initial,
    required this.title,
    required this.onPick,
    required this.onDismiss,
  });

  @override
  State<_CustomSpeedOverlay> createState() => _CustomSpeedOverlayState();
}

class _CustomSpeedOverlayState extends State<_CustomSpeedOverlay> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial.clamp(0.25, 4.0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: const ColoredBox(color: Color(0x88000000)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: const Color(0xFF1E1E1E),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_value.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: _value,
                        min: 0.25,
                        max: 4.0,
                        divisions: 75,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        onChanged: (v) => setState(() => _value = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: widget.onDismiss,
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.white70)),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => widget.onPick(_value),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ブックマーク一覧のオーバーレイシート
class _BookmarksSheetOverlay extends StatelessWidget {
  final String title;
  final String emptyLabel;
  final List<_Bookmark> bookmarks;
  final String Function(Duration) formatDuration;
  final void Function(_Bookmark) onTap;
  final void Function(_Bookmark) onDelete;
  final VoidCallback onDismiss;

  const _BookmarksSheetOverlay({
    required this.title,
    required this.emptyLabel,
    required this.bookmarks,
    required this.formatDuration,
    required this.onTap,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: const ColoredBox(color: Color(0x88000000)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: const Color(0xFF1E1E1E),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (bookmarks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                emptyLabel,
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: bookmarks.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(color: Colors.white12),
                              itemBuilder: (_, i) {
                                final b = bookmarks[i];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.bookmark,
                                    color: Colors.amber,
                                  ),
                                  title: Text(
                                    formatDuration(b.position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: b.label.isEmpty
                                      ? null
                                      : Text(
                                          b.label,
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () => onDelete(b),
                                  ),
                                  onTap: () => onTap(b),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 音声のみモード時の中央プレースホルダー (Premium+)
class _AudioOnlyPlaceholder extends StatelessWidget {
  const _AudioOnlyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(
              Icons.headset_rounded,
              color: Colors.white70,
              size: 44,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Audio only',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A-B ループコントロール (Premium+)
class _AbLoopControl extends StatelessWidget {
  final Duration? a;
  final Duration? b;
  final String Function(Duration) formatDuration;
  final VoidCallback onTapA;
  final VoidCallback onTapB;
  final VoidCallback onClear;

  const _AbLoopControl({
    required this.a,
    required this.b,
    required this.formatDuration,
    required this.onTapA,
    required this.onTapB,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final aOn = a != null;
    final bOn = b != null;
    return Material(
      color: Colors.black54,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTapA,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              child: Text(
                aOn ? 'A ${formatDuration(a!)}' : 'A',
                style: TextStyle(
                  color: aOn ? Colors.amber : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 16, color: Colors.white24),
          InkWell(
            onTap: onTapB,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              child: Text(
                bOn ? 'B ${formatDuration(b!)}' : 'B',
                style: TextStyle(
                  color: bOn ? Colors.amber : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (aOn || bOn) ...[
            Container(width: 1, height: 16, color: Colors.white24),
            InkWell(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: Icon(Icons.close,
                    color: Colors.white70, size: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// フルスクリーンプレイヤーの詳細メニュー (メニューボタンから表示)。
/// - 動画に重ねて表示、枠なしのシンプルなリスト
/// - タイル形式: アイコン + ラベル + 補助情報
class _PlayerMenu extends StatelessWidget {
  final bool isPremium;
  final String speedLabel;
  final bool loopEnabled;
  final bool audioOnly;
  final Duration? abA;
  final Duration? abB;
  final String Function(Duration) formatDuration;
  final String bookmarksLabel;
  final double volume;
  final ValueChanged<double> onVolume;
  final String sleepLabel;
  final bool sleepActive;
  final VoidCallback onSleep;
  final VoidCallback onSpeed;
  final VoidCallback onLoop;
  final VoidCallback onAudioOnly;
  final VoidCallback onAbA;
  final VoidCallback onAbB;
  final VoidCallback onAbClear;
  final VoidCallback onAddBookmark;
  final VoidCallback onShowBookmarks;

  const _PlayerMenu({
    required this.isPremium,
    required this.speedLabel,
    required this.loopEnabled,
    required this.audioOnly,
    required this.abA,
    required this.abB,
    required this.formatDuration,
    required this.bookmarksLabel,
    required this.volume,
    required this.onVolume,
    required this.sleepLabel,
    required this.sleepActive,
    required this.onSleep,
    required this.onSpeed,
    required this.onLoop,
    required this.onAudioOnly,
    required this.onAbA,
    required this.onAbB,
    required this.onAbClear,
    required this.onAddBookmark,
    required this.onShowBookmarks,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MenuTile(
              icon: Icons.speed,
              label: '再生速度',
              trailing: speedLabel,
              onTap: onSpeed,
            ),
            // アプリ内音量 (端末音量とは独立)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    volume <= 0.01
                        ? Icons.volume_off
                        : (volume < 0.5
                            ? Icons.volume_down
                            : Icons.volume_up),
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white24,
                      ),
                      child: Slider(
                        value: volume,
                        onChanged: onVolume,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(volume * 100).round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _MenuTile(
              icon: loopEnabled ? Icons.repeat_one_on : Icons.repeat,
              label: 'ループ',
              trailing: loopEnabled ? 'ON' : 'OFF',
              trailingActive: loopEnabled,
              onTap: onLoop,
            ),
            _MenuTile(
              icon: sleepActive ? Icons.timer : Icons.timer_outlined,
              label: 'タイマー',
              trailing: sleepLabel,
              trailingActive: sleepActive,
              locked: !isPremium,
              onTap: onSleep,
            ),
            _MenuTile(
              icon: audioOnly ? Icons.headset : Icons.headset_outlined,
              label: '音声のみ',
              trailing: audioOnly ? 'ON' : 'OFF',
              trailingActive: audioOnly,
              locked: !isPremium,
              onTap: onAudioOnly,
            ),
            // A-B ループ (Premium+)
            _MenuTile(
              icon: Icons.first_page,
              label: 'A-B ループ A',
              trailing: abA != null ? formatDuration(abA!) : '未設定',
              trailingActive: abA != null,
              locked: !isPremium,
              onTap: onAbA,
            ),
            _MenuTile(
              icon: Icons.last_page,
              label: 'A-B ループ B',
              trailing: abB != null ? formatDuration(abB!) : '未設定',
              trailingActive: abB != null,
              locked: !isPremium,
              onTap: onAbB,
            ),
            if (abA != null || abB != null)
              _MenuTile(
                icon: Icons.clear,
                label: 'A-B クリア',
                onTap: onAbClear,
              ),
            _MenuTile(
              icon: Icons.bookmark_add_outlined,
              label: 'ブックマーク追加',
              locked: !isPremium,
              onTap: onAddBookmark,
            ),
            _MenuTile(
              icon: Icons.bookmarks_outlined,
              label: bookmarksLabel,
              locked: !isPremium,
              onTap: onShowBookmarks,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  /// Premium+ 機能で無料ユーザー時に金色 + 鍵アイコンで表示するかどうか
  final bool locked;
  final IconData icon;
  final String label;
  final String? trailing;
  final bool trailingActive;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.trailingActive = false,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Premium+ 機能で未加入時: 金色 + 鍵マーク付き
    final labelColor = locked ? const Color(0xFFFFC94A) : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: labelColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.lock, color: labelColor, size: 12),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Text(
                trailing!,
                style: TextStyle(
                  color: trailingActive
                      ? Colors.amber
                      : (locked ? labelColor : Colors.white70),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 3),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 動画レイヤーの上に表示する Premium+ 導線ダイアログ。
/// アプリの他のダイアログ (AlertDialog) と同じデザインに揃える。
class _PremiumPromoOverlay extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;
  const _PremiumPromoOverlay({
    required this.onUpgrade,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // バリア
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: const ColoredBox(color: Color(0x88000000)),
            ),
          ),
          // 標準 AlertDialog 相当を自前で描画 (Navigator 不要)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Material(
                  color: cs.secondary,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Premium 限定機能',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'この機能は Premium/Pro プランで解除できます。'
                          'A-B ループ、ブックマーク、音声のみ再生、'
                          'スリープタイマー等が使えるようになります。',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.75),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: onDismiss,
                              child: const Text('後で'),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: onUpgrade,
                              child: const Text('詳細を見る'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// スリープタイマー選択オーバーレイ (下部シート)
class _SleepTimerPickerOverlay extends StatelessWidget {
  final Duration? currentDuration;
  final ValueChanged<Duration> onPick;
  final VoidCallback onDismiss;
  const _SleepTimerPickerOverlay({
    required this.currentDuration,
    required this.onPick,
    required this.onDismiss,
  });

  static const _options = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: const ColoredBox(color: Color(0x88000000)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: const Color(0xFF1E1E1E),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'スリープタイマー',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '指定時間後に自動的に一時停止します',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final d in _options)
                            _SpeedChip(
                              label: '${d.inMinutes} 分',
                              selected: currentDuration == d,
                              onTap: () => onPick(d),
                            ),
                          _SpeedChip(
                            label: 'OFF',
                            selected: currentDuration == null,
                            onTap: () => onPick(Duration.zero),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
