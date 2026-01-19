import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final adBadgeProvider = StateNotifierProvider<AdBadgeNotifier, bool>((ref) {
  return AdBadgeNotifier()..load();
});

class AdBadgeNotifier extends StateNotifier<bool> {
  AdBadgeNotifier() : super(false);

  Future<void> load() async {
    await resetIfNeeded();

    final prefs = await SharedPreferences.getInstance();
    final watched = prefs.getInt('watched_ads_today') ?? 0;
    state = watched < 3; // true = 赤バッジ表示
  }

  Future<void> incrementWatchedAds() async {
    final prefs = await SharedPreferences.getInstance();
    final watched = (prefs.getInt('watched_ads_today') ?? 0) + 1;
    await prefs.setInt('watched_ads_today', watched);
    state = watched < 3;
  }

  Future<void> resetIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('ad_date');

    if (savedDate != today) {
      await prefs.setString('ad_date', today);
      await prefs.setInt('watched_ads_today', 0);
      state = true;
    }
  }
}
