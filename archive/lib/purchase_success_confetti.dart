import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// プラン購入/復元の成功時に画面全体に紙吹雪を舞わせるためのヘルパ。
///
/// 使い方:
/// ```dart
/// showPurchaseSuccessConfetti(context, isPro: true);
/// await _completeDialog(...);
/// ```
///
/// - オーバーレイとして描画されるので、直後に表示するダイアログの上にも紙吹雪が乗る
/// - [isPro] で色パレットを Pro (シルバー/ブルー系) と Premium (ゴールド系) に切り替え
/// - 約 3 秒で自動的にオーバーレイから消える
void showPurchaseSuccessConfetti(
  BuildContext context, {
  bool isPro = false,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _PurchaseConfettiOverlay(
      isPro: isPro,
      duration: duration,
      onFinished: () {
        try {
          entry.remove();
        } catch (_) {}
      },
    ),
  );
  overlay.insert(entry);
}

class _PurchaseConfettiOverlay extends StatefulWidget {
  final bool isPro;
  final Duration duration;
  final VoidCallback onFinished;

  const _PurchaseConfettiOverlay({
    required this.isPro,
    required this.duration,
    required this.onFinished,
  });

  @override
  State<_PurchaseConfettiOverlay> createState() =>
      _PurchaseConfettiOverlayState();
}

class _PurchaseConfettiOverlayState extends State<_PurchaseConfettiOverlay> {
  late final ConfettiController _left;
  late final ConfettiController _center;
  late final ConfettiController _right;
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _left = ConfettiController(duration: widget.duration);
    _center = ConfettiController(duration: widget.duration);
    _right = ConfettiController(duration: widget.duration);
    // 少しずらしてトリガー
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _center.play();
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _left.play();
        _right.play();
      });
    });
    _cleanupTimer =
        Timer(widget.duration + const Duration(milliseconds: 1500), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _left.dispose();
    _center.dispose();
    _right.dispose();
    super.dispose();
  }

  List<Color> get _colors {
    if (widget.isPro) {
      return const [
        Color(0xFF64B5F6), // light blue
        Color(0xFF1E88E5), // blue
        Color(0xFFB0BEC5), // silver
        Color(0xFFECEFF1), // near white
        Color(0xFF9575CD), // accent purple
      ];
    }
    return const [
      Color(0xFFFFD700), // gold
      Color(0xFFB8860B), // dark gold
      Color(0xFFFFC107), // amber
      Color(0xFFFFEE58), // pale yellow
      Color(0xFFFFAB40), // orange
    ];
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // 中央上から真下に扇状
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _center,
                blastDirection: math.pi / 2, // 下向き
                blastDirectionality: BlastDirectionality.directional,
                shouldLoop: false,
                emissionFrequency: 0.03,
                numberOfParticles: 8,
                maxBlastForce: 20,
                minBlastForce: 8,
                gravity: 0.35,
                colors: _colors,
              ),
            ),
          ),
          // 左上から右下方向
          Positioned(
            top: 0,
            left: 0,
            child: ConfettiWidget(
              confettiController: _left,
              blastDirection: math.pi / 3, // 60°: 右下寄り
              blastDirectionality: BlastDirectionality.directional,
              shouldLoop: false,
              emissionFrequency: 0.02,
              numberOfParticles: 5,
              maxBlastForce: 20,
              minBlastForce: 6,
              gravity: 0.35,
              colors: _colors,
            ),
          ),
          // 右上から左下方向
          Positioned(
            top: 0,
            right: 0,
            child: ConfettiWidget(
              confettiController: _right,
              blastDirection: 2 * math.pi / 3, // 120°: 左下寄り
              blastDirectionality: BlastDirectionality.directional,
              shouldLoop: false,
              emissionFrequency: 0.02,
              numberOfParticles: 5,
              maxBlastForce: 20,
              minBlastForce: 6,
              gravity: 0.35,
              colors: _colors,
            ),
          ),
        ],
      ),
    );
  }
}
