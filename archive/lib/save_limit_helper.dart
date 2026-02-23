import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'premium_detail.dart';
import 'ad_badge_provider.dart';

class SaveLimitHelper {
  /// 上限取得
  static Future<int> _getLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final extra = prefs.getInt('extra_save_limit') ?? 0;
    return 100 + extra;
    //return 1 + extra; //デバッグ用
  }

  /// 保存数取得
  static Future<int> _getCount() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];
    return list.length;
  }

  /// 保存可能かチェック
  static Future<bool> canSave(
    BuildContext context,
    RewardedAd? ad,
    WidgetRef ref,
  ) async {
    /// ⭐ プレミアムなら無条件保存OK
    final isPremium = await _checkPremium();
    if (isPremium) return true;

    final count = await _getCount();
    final limit = await _getLimit();

    if (count < limit) return true;

    if (!context.mounted) return false;

    await _showDialog(context, count, limit, ad, ref);
    return false;
  }

  //プレミアムか確認
  static Future<bool> _checkPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['Premium Plan']?.isActive ?? false;
    } catch (e) {
      debugPrint('Subscription check error: $e');
      return false;
    }
  }

  /// ダイアログ表示
  static Future<void> _showDialog(
    BuildContext context,
    int count,
    int limit,
    RewardedAd? ad,
    WidgetRef ref,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          title: Text(L10n.of(context)!.save_limit_dialog_title),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10n.of(context)!.save_limit_dialog_status_label, //保存済み
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                "$count / $limit",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              children: [
                /// 広告ボタン
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all(
                        colorScheme.brightness == Brightness.light
                            ? Colors.grey[300]
                            : Colors.grey.shade800,
                      ),
                      foregroundColor: MaterialStateProperty.all(
                        colorScheme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      // 今日の広告視聴上限チェック
                      final watchedAds = ref.read(adBadgeProvider);

                      if (watchedAds >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              L10n.of(context)!.settings_page_ad_limit_reached,
                            ),
                          ),
                        );
                        return;
                      }

                      // 広告未ロード
                      if (ad == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              L10n.of(context)!.save_limit_loading_ad, //広告ロード中
                            ),
                          ),
                        );
                        return;
                      }

                      // 広告再生
                      ad.show(
                        onUserEarnedReward: (_, __) async {
                          final prefs = await SharedPreferences.getInstance();
                          final current = prefs.getInt('extra_save_limit') ?? 0;
                          await prefs.setInt('extra_save_limit', current + 5);

                          ref.read(adBadgeProvider.notifier).increment();
                        },
                      );

                      ad.dispose();
                      Navigator.pop(context);
                    },

                    icon: const Icon(Icons.ondemand_video),
                    label: Text(
                      L10n.of(context)!.settings_page_watch_ad,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// プレミアム
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all(
                        colorScheme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      if (!await PremiumGate.ensurePremium(context)) return;
                    },
                    icon: const Icon(Icons.star, color: Color(0xFFB8860B)),
                    label: Text(
                      L10n.of(context)!.save_limit_dialog_premium_detail,
                      style: const TextStyle(
                        color: Color(0xFFB8860B),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// 閉じる
                TextButton(
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all(
                      Colors.grey[300],
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.of(context)!.back),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
