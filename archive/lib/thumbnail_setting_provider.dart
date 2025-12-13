import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final showThumbnailProvider =
    StateNotifierProvider<ShowThumbnailNotifier, bool>((ref) {
      return ShowThumbnailNotifier();
    });

class ShowThumbnailNotifier extends StateNotifier<bool> {
  ShowThumbnailNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('showThumbnail') ?? true;
  }

  Future<void> set(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    state = value;
    await prefs.setBool('showThumbnail', value);
  }
}
