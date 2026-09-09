import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'pip_helper.dart';

@immutable
class MiniPlayerState {
  final VideoPlayerController? controller;
  final String? filePath;
  final String title;
  final String? itemUrl; // 視聴回数カウント用のキー
  final bool isFullScreen; // true = full page open, false = mini overlay

  const MiniPlayerState({
    this.controller,
    this.filePath,
    this.title = '',
    this.itemUrl,
    this.isFullScreen = false,
  });

  bool get isActive => controller != null;

  MiniPlayerState copyWith({
    VideoPlayerController? controller,
    String? filePath,
    String? title,
    String? itemUrl,
    bool? isFullScreen,
    bool clearController = false,
  }) {
    return MiniPlayerState(
      controller: clearController ? null : (controller ?? this.controller),
      filePath: clearController ? null : (filePath ?? this.filePath),
      title: title ?? this.title,
      itemUrl: clearController ? null : (itemUrl ?? this.itemUrl),
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }
}

class MiniPlayerNotifier extends StateNotifier<MiniPlayerState> {
  MiniPlayerNotifier() : super(const MiniPlayerState());

  /// 新しい動画で開始。既存のプレイヤーは破棄する。
  Future<VideoPlayerController> start({
    required String filePath,
    required String title,
    String? itemUrl,
  }) async {
    // 既存プレイヤーがあれば破棄
    await _disposeCurrent();
    // アプリがバックグラウンドに行っても音声/映像を継続 (iOS+Android)
    final controller = VideoPlayerController.file(
      File(filePath),
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
    );
    await controller.initialize();
    await controller.play();
    state = MiniPlayerState(
      controller: controller,
      filePath: filePath,
      title: title,
      itemUrl: itemUrl,
      isFullScreen: true,
    );
    // Android 12+ で「ホームボタンで離れた瞬間に自動 PiP」を有効化
    final aspect = controller.value.aspectRatio;
    final w = (aspect * 9).round().clamp(9, 21);
    PipHelper().armAutoPip(aspectWidth: w, aspectHeight: 9);
    // PiP モードの × ボタンで閉じられた時に再生停止 (アプリ外からの close)
    PipHelper().setOnPipClosedByUser(() => close());
    // PiP に入った瞬間ミニ状態なら fullscreen へ (小窓に UI が縮小されるのを防止)
    PipHelper().setOnPipEntered(() {
      if (!mounted) return;
      final cur = state;
      if (cur.controller != null && !cur.isFullScreen) {
        state = cur.copyWith(isFullScreen: true);
      }
    });
    return controller;
  }

  /// 既存のフルスクリーンプレイヤーからミニプレイヤーに切り替え
  void minimize() {
    if (state.controller == null) return;
    state = state.copyWith(isFullScreen: false);
  }

  /// ミニプレイヤーからフルスクリーンに戻る
  void expand() {
    if (state.controller == null) return;
    state = state.copyWith(isFullScreen: true);
  }

  /// 完全にプレイヤーを閉じる (controller を破棄)
  Future<void> close() async {
    await _disposeCurrent();
    state = const MiniPlayerState();
    // Auto-PiP を無効化 (Android 12+)
    PipHelper().disarmAutoPip();
    // PiP 閉じ検知コールバックを解除 (再帰呼び出し防止)
    PipHelper().setOnPipClosedByUser(null);
    PipHelper().setOnPipEntered(null);
  }

  Future<void> _disposeCurrent() async {
    final c = state.controller;
    if (c == null) return;
    try {
      await c.pause();
    } catch (_) {}
    try {
      await c.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposeCurrent();
    super.dispose();
  }
}

final miniPlayerProvider =
    StateNotifierProvider<MiniPlayerNotifier, MiniPlayerState>(
        (ref) => MiniPlayerNotifier());
