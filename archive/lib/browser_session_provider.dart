import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// アプリ内ブラウザの「ホーム画面」を開くリクエストを発行する。
  ///
  /// ホームタブは URL を持たない特別な状態なので、URL では表現できない。
  /// url が空のリクエストを「ホームを開く合図」として扱う。
  void requestOpenHome() {
    _seq += 1;
    state = BrowserOpenRequest(url: '', seq: _seq);
  }

  /// consumer 側で消費後にクリアする用
  void clear() {
    state = null;
  }
}

final browserSessionProvider =
    StateNotifierProvider<BrowserSessionNotifier, BrowserOpenRequest?>(
        (ref) => BrowserSessionNotifier());

/// ブラウザで開いているページ 1 件分 (ホームタブは含めない)
@immutable
class OpenBrowserTab {
  final String url;

  /// ページタイトル。取得前や復元直後は空になりうる。
  final String title;

  /// ページの代表画像 (og:image 等)。取得前は空文字列。
  final String thumbnailUrl;

  /// 今ブラウザで前面に出ているタブか。
  /// ホーム画面のウィジェットは「今いるタブ」を除いて見せるため、
  /// (ブラウザタブを押せば行ける先と重複させない) この判定が必要。
  final bool isActive;

  const OpenBrowserTab({
    required this.url,
    this.title = '',
    this.thumbnailUrl = '',
    this.isActive = false,
  });
}

/// ブラウザで「今」開いているページの一覧。
///
/// タブの実体は SearchResultPage の private State なので直接は参照できない。
/// MainPage が IndexedStack で全ページを常時マウントする構造のため、
/// ホーム側には再構築の契機が無く prefs を読み直す方式では古い内容が残る。
/// そのため SearchResultPage からこの provider へ能動的に反映する。
class OpenBrowserTabsNotifier extends StateNotifier<List<OpenBrowserTab>> {
  OpenBrowserTabsNotifier() : super(const []) {
    _loadFromPrefs();
  }

  static const _kUrls = 'browser_tab_urls_v1';
  static const _kTitles = 'browser_tab_titles_v1';
  static const _kImages = 'browser_tab_images_v1';
  // NOTE: SearchResultPage の _kPrefBrowserActiveIndex と同じ値。
  static const _kActiveIndex = 'browser_active_tab_v1';

  /// ブラウザ側から呼ぶ。[urls] と [titles] は同じ順序で渡すこと。
  /// 空の URL はホームタブを表すので一覧から除外する。
  ///
  /// 並びは「直近に見ていたページが先頭」にする。[activeIndex] が指すタブを
  /// 先頭へ回し、残りはタブ順のまま後ろへ続ける。
  /// ホーム画面のウィジェットは先頭 1 件だけを表示するため、この順序が
  /// そのまま「直近のページ」の意味になる。
  void publish({
    required List<String> urls,
    required List<String> titles,
    List<String> images = const [],
    int? activeIndex,
  }) {
    OpenBrowserTab? active;
    final rest = <OpenBrowserTab>[];
    for (var i = 0; i < urls.length; i++) {
      if (urls[i].isEmpty) continue; // ホームタブ
      final tab = OpenBrowserTab(
        url: urls[i],
        title: i < titles.length ? titles[i] : '',
        thumbnailUrl: i < images.length ? images[i] : '',
        isActive: i == activeIndex,
      );
      if (i == activeIndex && active == null) {
        active = tab;
      } else {
        rest.add(tab);
      }
    }
    state = List.unmodifiable([if (active != null) active, ...rest]);
  }

  /// 起動直後、まだブラウザを一度も開いていない間の表示用に復元する。
  /// ブラウザ側から [publish] が来たらそちらが上書きする。
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final urls = prefs.getStringList(_kUrls) ?? const <String>[];
      final titles = prefs.getStringList(_kTitles) ?? const <String>[];
      final images = prefs.getStringList(_kImages) ?? const <String>[];
      final activeIndex = prefs.getInt(_kActiveIndex);
      // 復元中に publish が走っていたら、新しい方を優先して何もしない
      if (state.isNotEmpty) return;
      publish(
        urls: urls,
        titles: titles,
        images: images,
        activeIndex: activeIndex,
      );
    } catch (_) {}
  }
}

final openBrowserTabsProvider =
    StateNotifierProvider<OpenBrowserTabsNotifier, List<OpenBrowserTab>>(
        (ref) => OpenBrowserTabsNotifier());
