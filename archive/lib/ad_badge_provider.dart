import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final adBadgeProvider = StateNotifierProvider<AdBadgeNotifier, int>((ref) {
  return AdBadgeNotifier()..load();
});

class AdBadgeNotifier extends StateNotifier<int> {
  AdBadgeNotifier() : super(0);

  bool get showBadge => state < 3;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNeeded(prefs);
    state = prefs.getInt('watched_ads_today') ?? 0;
  }

  Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    state++;
    await prefs.setInt('watched_ads_today', state);
  }

  Future<void> _resetIfNeeded(SharedPreferences prefs) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('ad_date');

    if (savedDate != today) {
      await prefs.setString('ad_date', today);
      await prefs.setInt('watched_ads_today', 0);
      state = 0;
    }
  }
}
