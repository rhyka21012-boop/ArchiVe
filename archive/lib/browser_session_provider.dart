import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// アプリ内ブラウザにタブを追加するリクエスト。
/// `seq` は毎回インクリメントされる連番で、同じ URL でも再リクエストを区別する。
@immutable
class BrowserOpenRequest {
  final String url;
  final String title;
  final List<Map<String, dynamic>>? playlistItems;
  final int? playlistIndex;
  final int seq;

  const BrowserOpenRequest({
    required this.url,
    this.title = '',
    this.playlistItems,
    this.playlistIndex,
    required this.seq,
  });
}

class BrowserSessionNotifier extends StateNotifier<BrowserOpenRequest?> {
  BrowserSessionNotifier() : super(null);
  int _seq = 0;

  /// アプリ内ブラウザ (search タブ) で URL を開くリクエストを発行。
  /// - SearchResultPage が既に mount されていれば新規タブを追加
  /// - まだ mount されていなければ MainPage 側で push、その initial URL に使われる
  void requestOpen(
    String url, {
    String title = '',
    List<Map<String, dynamic>>? playlistItems,
    int? playlistIndex,
  }) {
    _seq += 1;
    state = BrowserOpenRequest(
      url: url,
      title: title,
      playlistItems: playlistItems,
      playlistIndex: playlistIndex,
      seq: _seq,
    );
  }

  /// consumer 側で消費後にクリアする用
  void clear() {
    state = null;
  }
}

final browserSessionProvider =
    StateNotifierProvider<BrowserSessionNotifier, BrowserOpenRequest?>(
        (ref) => BrowserSessionNotifier());
