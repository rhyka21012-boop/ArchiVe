import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

final favoriteSitesProvider =
    StateNotifierProvider<FavoriteSitesNotifier, List<Map<String, String>>>(
      (ref) => FavoriteSitesNotifier(),
    );

class FavoriteSitesNotifier extends StateNotifier<List<Map<String, String>>> {
  FavoriteSitesNotifier() : super([]) {
    load();
  }

  static const _key = 'favorite_sites';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);

    /// 初回起動
    if (list == null || list.isEmpty) {
      state = [
        {"title": "Youtube", "url": "https://m.youtube.com"},
        {"title": "Vimeo", "url": "https://vimeo.com"},
        {"title": "Dailymotion", "url": "https://www.dailymotion.com"},
        {"title": "TikTok", "url": "https://www.tiktok.com"},
      ];

      await _save();
      return;
    }

    /// 通常ロード
    state = list.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
  }

  Future<void> toggle(String url, String title) async {
    final exists = state.any((e) => e["url"] == url);

    if (exists) {
      state = state.where((e) => e["url"] != url).toList();
    } else {
      state = [
        ...state,
        {"url": url, "title": title},
      ];
    }

    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_key, jsonList);
  }

  bool isFavorite(String url) {
    return state.any((e) => e["url"] == url);
  }

  void add(String title, String url) {
    state = [
      ...state,
      {"title": title, "url": url},
    ];
    _save();
  }

  void remove(int index) {
    final list = [...state];
    list.removeAt(index);
    state = list;
    _save();
  }

  void update(int index, String title, String url) {
    final list = [...state];
    list[index] = {"title": title, "url": url};
    state = list;
    _save();
  }
}
