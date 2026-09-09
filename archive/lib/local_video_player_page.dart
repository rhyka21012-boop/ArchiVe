import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'circle_app_bar_icon.dart';
import 'l10n/app_localizations.dart';
import 'mini_player_provider.dart';
import 'offline_quality_picker.dart';
import 'pip_helper.dart';

/// ダウンロード済みのローカル動画をフルスクリーンで再生するプレイヤー画面。
/// プレイヤー本体は [miniPlayerProvider] が保持し、この画面はビューとして機能する。
class LocalVideoPlayerPage extends ConsumerStatefulWidget {
  final String filePath;
  final String title;
  final String? itemUrl; // 視聴回数カウント用のキー

  const LocalVideoPlayerPage({
    super.key,
    required this.filePath,
    this.title = '',
    this.itemUrl,
  });

  @override
  ConsumerState<LocalVideoPlayerPage> createState() =>
      _LocalVideoPlayerPageState();
}

class _LocalVideoPlayerPageState extends ConsumerState<LocalVideoPlayerPage>
    with WidgetsBindingObserver {
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _progressSaveTimer;
  String? _error;
  double _speed = 1.0;
  static const _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  static String posKey(String itemUrl) => 'offline_pos_$itemUrl';
  static String durKey(String itemUrl) => 'offline_dur_$itemUrl';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // アプリがバックグラウンドに行くとき、Android なら PiP を起動して継続再生
    if (s == AppLifecycleState.inactive || s == AppLifecycleState.paused) {
      final c = _controller;
      if (c != null && c.value.isPlaying) {
        PipHelper().enterPip();
      }
    }
  }

  Future<void> _init() async {
    final current = ref.read(miniPlayerProvider);
    // 既にミニプレイヤーで同じ動画が動いていればそれを引き継ぎ、
    // フルスクリーン状態に切り替えるだけ
    if (current.controller != null && current.filePath == widget.filePath) {
      ref.read(miniPlayerProvider.notifier).expand();
      if (!mounted) return;
      current.controller!.addListener(_onTick);
      _speed = current.controller!.value.playbackSpeed;
      setState(() {});
      _scheduleHide();
      // Texture 再バインドのため 200ms 後に再度 build → VideoPlayer 描画確定
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() {});
      });
      return;
    }
    try {
      final c = await ref.read(miniPlayerProvider.notifier).start(
            filePath: widget.filePath,
            title: widget.title,
            itemUrl: widget.itemUrl,
          );
      if (!mounted) return;
      c.addListener(_onTick);
      setState(() {});
      _scheduleHide();
      // 視聴回数を +1 (オンライン再生と同じ挙動を維持)
      _bumpViewCount();
      // 前回中断位置 (レジューム) + 進捗保存タイマー起動
      _restoreLastPosition(c);
      _startProgressSaveTimer();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _restoreLastPosition(VideoPlayerController c) async {
    final url = widget.itemUrl;
    if (url == null || url.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sec = prefs.getInt(posKey(url));
      if (sec == null || sec <= 3) return; // 数秒以内なら復元しない
      final dur = c.value.duration;
      // 動画終端付近 (残り 10 秒未満) なら復元せず先頭から
      if (dur.inSeconds > 0 && dur.inSeconds - sec < 10) return;
      await c.seekTo(Duration(seconds: sec));
    } catch (_) {}
  }

  void _startProgressSaveTimer() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
  }

  Future<void> _saveProgress() async {
    final url = widget.itemUrl;
    if (url == null || url.isEmpty) return;
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pos = c.value.position.inSeconds;
      final dur = c.value.duration.inSeconds;
      if (dur > 0) await prefs.setInt(durKey(url), dur);
      // 動画終端付近ならクリア (次回は最初から)
      if (dur > 0 && dur - pos < 10) {
        await prefs.remove(posKey(url));
      } else if (pos > 3) {
        await prefs.setInt(posKey(url), pos);
      }
    } catch (_) {}
  }

  Future<void> _bumpViewCount() async {
    final url = widget.itemUrl;
    if (url == null || url.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(url) ?? 0;
      await prefs.setInt(url, current + 1);
    } catch (_) {}
  }

  VideoPlayerController? get _controller =>
      ref.read(miniPlayerProvider).controller;

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  Future<void> _seekBy(Duration delta) async {
    final c = _controller;
    if (c == null) return;
    final now = c.value.position;
    final target = now + delta;
    final duration = c.value.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    await c.seekTo(clamped);
    _scheduleHide();
  }

  Future<void> _pickSpeed() async {
    final c = _controller;
    if (c == null) return;
    _hideTimer?.cancel();
    final l = L10n.of(context)!;
    final picked = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (bctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.player_speed,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _speeds)
                      PickerChip(
                        label: l.player_speed_x(_formatSpeed(s)),
                        icon: Icons.speed,
                        isSelected: s == _speed,
                        onTap: () => Navigator.pop(bctx, s),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) {
      _scheduleHide();
      return;
    }
    await c.setPlaybackSpeed(picked);
    setState(() => _speed = picked);
    _scheduleHide();
  }

  void _minimize() {
    _controller?.removeListener(_onTick);
    ref.read(miniPlayerProvider.notifier).minimize();
    Navigator.of(context).maybePop();
  }

  Future<void> _closePlayer() async {
    _controller?.removeListener(_onTick);
    await ref.read(miniPlayerProvider.notifier).close();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _progressSaveTimer?.cancel();
    // 最後の位置を保存 (非同期だが fire-and-forget で OK)
    _saveProgress();
    _controller?.removeListener(_onTick);
    // 戻るボタン等で明示的な close/minimize が呼ばれず pop された場合は
    // ミニプレイヤーに切り替える (再生継続)
    final state = ref.read(miniPlayerProvider);
    if (state.controller != null && state.isFullScreen) {
      ref.read(miniPlayerProvider.notifier).minimize();
    }
    // controller は provider が管理 → ここでは dispose しない
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildPlayer()),
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _buildOverlayControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Playback error:\n$_error',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio > 0
              ? controller.value.aspectRatio
              : 16 / 9,
          child: RepaintBoundary(
            child: VideoPlayer(controller, key: ObjectKey(controller)),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayControls() {
    final l = L10n.of(context)!;
    final controller = _controller;
    final duration = controller?.value.duration ?? Duration.zero;
    final position = controller?.value.position ?? Duration.zero;
    final isPlaying = controller?.value.isPlaying ?? false;

    return GestureDetector(
      // オーバーレイ表示中にタップ → 即非表示
      onTap: () {
        _hideTimer?.cancel();
        setState(() => _showControls = false);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                CircleAppBarIcon(
                  icon: Icons.keyboard_arrow_down,
                  backgroundColor: Colors.black45,
                  iconColor: Colors.white,
                  tooltip: l.player_minimize,
                  onPressed: _minimize,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CircleAppBarIcon(
                  icon: Icons.close,
                  backgroundColor: Colors.black45,
                  iconColor: Colors.white,
                  tooltip: l.player_close,
                  onPressed: _closePlayer,
                ),
              ],
            ),
          ),
          const Spacer(),
          // 下部コントロールパネル: シークバー → その下に速度 + 早送り/再生/停止 の順
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
                // シークバー行: 経過 / スライダー / 全長
                Row(
                  children: [
                    Text(
                      _fmt(position),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        value: position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                        max:
                            duration.inMilliseconds.toDouble().clamp(1, 1e12),
                        onChanged: (v) {
                          controller
                              ?.seekTo(Duration(milliseconds: v.toInt()));
                          _scheduleHide();
                        },
                      ),
                    ),
                    Text(
                      _fmt(duration),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                // シークバーの下: 速度 (左) + 早送り/再生/停止 (中央) + 予約 (右)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Row(
                    children: [
                      // 左: 速度チップ
                      Material(
                        color: Colors.black45,
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _pickSpeed,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.speed,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  l.player_speed_x(_formatSpeed(_speed)),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 中央: -10 / -5 / play/pause / +5 / +10
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _CenterActionButton(
                              iconSize: 30,
                              icon: Icons.replay_10,
                              onTap: () =>
                                  _seekBy(const Duration(seconds: -10)),
                            ),
                            const SizedBox(width: 4),
                            _CenterActionButton(
                              iconSize: 26,
                              icon: Icons.replay_5,
                              onTap: () =>
                                  _seekBy(const Duration(seconds: -5)),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              iconSize: 48,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                if (controller == null) return;
                                if (isPlaying) {
                                  await controller.pause();
                                } else {
                                  await controller.play();
                                }
                                _scheduleHide();
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 4),
                            _CenterActionButton(
                              iconSize: 26,
                              icon: Icons.forward_5,
                              onTap: () =>
                                  _seekBy(const Duration(seconds: 5)),
                            ),
                            const SizedBox(width: 4),
                            _CenterActionButton(
                              iconSize: 30,
                              icon: Icons.forward_10,
                              onTap: () =>
                                  _seekBy(const Duration(seconds: 10)),
                            ),
                          ],
                        ),
                      ),
                      // 右: 予約スペース (レイアウト対称性のため、速度チップと同幅相当)
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _formatSpeed(double s) {
    if (s == s.toInt().toDouble()) return '${s.toInt()}';
    return s.toString();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _CenterActionButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _CenterActionButton({
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: iconSize,
      icon: Icon(icon, color: Colors.white),
      onPressed: onTap,
    );
  }
}
