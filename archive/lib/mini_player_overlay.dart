import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'local_video_player_page.dart';
import 'mini_player_provider.dart';
import 'pip_helper.dart';

/// 画面下部に浮かぶミニプレイヤーウィジェット。
/// [miniPlayerProvider] の state が active かつ [isFullScreen] が false の時のみ表示。
class MiniPlayerOverlay extends ConsumerStatefulWidget {
  const MiniPlayerOverlay({super.key});

  @override
  ConsumerState<MiniPlayerOverlay> createState() => _MiniPlayerOverlayState();
}

class _MiniPlayerOverlayState extends ConsumerState<MiniPlayerOverlay>
    with WidgetsBindingObserver {
  Offset _offset = const Offset(0, 0);
  Size? _screenSize;
  double? _lastAspect;
  // 幅は固定、高さは動画のアスペクト比から計算
  static const double _fixedWidth = 220;
  static const double _minHeight = 100;
  static const double _maxHeight = 260;
  static const double _bottomInset = 100; // MainPage の bottom nav 分を避ける

  double _heightForAspect(double aspect) {
    // aspect = width/height  →  height = width / aspect
    final h = _fixedWidth / (aspect <= 0 ? (16 / 9) : aspect);
    return h.clamp(_minHeight, _maxHeight);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // ミニプレイヤーで再生中にアプリがバックグラウンドに → PiP へ (Android のみ)
    if (s == AppLifecycleState.inactive || s == AppLifecycleState.paused) {
      final state = ref.read(miniPlayerProvider);
      if (state.controller?.value.isPlaying == true) {
        PipHelper().enterPip();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(miniPlayerProvider);
    if (!state.isActive || state.isFullScreen) {
      return const SizedBox.shrink();
    }
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final screen = MediaQuery.of(context).size;
    // 動画のアスペクト比から実際のサイズを決定
    final aspect = controller.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : (16 / 9);
    final cardW = _fixedWidth;
    final cardH = _heightForAspect(aspect);
    // 初期位置: 右下 (画面サイズ or アスペクト比が変化したら再計算)
    if (_screenSize != screen || _lastAspect != aspect) {
      _screenSize = screen;
      _lastAspect = aspect;
      _offset = Offset(
        screen.width - cardW - 12,
        screen.height - cardH - _bottomInset,
      );
    }
    // 親 Stack に依存しないよう、自前で Stack を組み立てる
    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned(
            left: _offset.dx,
            top: _offset.dy,
            child: _MiniCard(
              controller: controller,
              title: state.title,
              width: cardW,
              height: cardH,
              onDrag: (delta) {
                setState(() {
                  _offset += delta;
                  // 画面外に出ないようクランプ
                  final maxDx = screen.width - cardW;
                  final maxDy = screen.height - cardH - 40;
                  _offset = Offset(
                    _offset.dx.clamp(0, maxDx),
                    _offset.dy.clamp(MediaQuery.of(context).padding.top, maxDy),
                  );
                });
              },
              onTap: () async {
                // フルスクリーン再表示
                final path = state.filePath;
                if (path == null) return;
                // ミニカードの VideoPlayer を確実に unmount してから
                // フルスクリーン側の VideoPlayer が Texture を掴めるよう
                // (1) state を isFullScreen: true にして次フレームで再ビルド
                // (2) endOfFrame + 追加 100ms 待機
                ref.read(miniPlayerProvider.notifier).expand();
                await WidgetsBinding.instance.endOfFrame;
                await Future.delayed(const Duration(milliseconds: 100));
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LocalVideoPlayerPage(
                      filePath: path,
                      title: state.title,
                    ),
                  ),
                );
              },
              onClose: () {
                ref.read(miniPlayerProvider.notifier).close();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final double width;
  final double height;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _MiniCard({
    required this.controller,
    required this.title,
    required this.width,
    required this.height,
    required this.onDrag,
    required this.onTap,
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

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  VideoPlayerController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => widget.onDrag(d.delta),
      onTap: _toggleControls,
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
              // 動画
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              // リモコン群 (タップで表示/非表示)
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      // 半透明レイヤー (視認性のため)
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
                      // 中央: 拡大ボタン (タップでフルスクリーンに戻る)
                      Center(
                        child: _MiniControl(
                          icon: Icons.fullscreen,
                          iconSize: 22,
                          padding: 8,
                          onTap: () {
                            _hideTimer?.cancel();
                            widget.onTap();
                          },
                        ),
                      ),
                      // 右上: 閉じるボタン (少し大きめに)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _MiniControl(
                          icon: Icons.close,
                          iconSize: 18,
                          padding: 6,
                          onTap: widget.onClose,
                        ),
                      ),
                      // 下部: play-pause のみ (早送り/巻き戻しは撤去)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 6,
                        child: Center(
                          child: ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: controller,
                            builder: (_, v, __) {
                              return _MiniControl(
                                icon: v.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                iconSize: 20,
                                padding: 5,
                                onTap: () {
                                  if (v.isPlaying) {
                                    controller.pause();
                                  } else {
                                    controller.play();
                                  }
                                  _scheduleHide();
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 最下部プログレスバー
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: controller,
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
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final double padding;
  final VoidCallback onTap;

  const _MiniControl({
    required this.icon,
    required this.iconSize,
    required this.padding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(icon, size: iconSize, color: Colors.white),
        ),
      ),
    );
  }
}
