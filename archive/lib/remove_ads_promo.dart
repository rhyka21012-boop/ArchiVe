import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'subscription_prompt_dialog.dart';

const _kPrefLastShownDate = 'remove_ads_promo_last_shown';

/// インターステイシャル広告表示後などに、控えめな SnackBar で
/// 「広告を非表示にするには → Premium」の導線を出す。
///
/// - 1 日 1 回まで (SharedPreferences で日付ガード)
/// - 自動で消える (Duration: 6 秒) — 操作を阻害しない
/// - Premium/Pro 加入済みや未マウント状態では出さない
Future<void> showRemoveAdsPromoIfNeeded(BuildContext context) async {
  if (!context.mounted) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastShown = prefs.getString(_kPrefLastShownDate);
    if (lastShown == today) return;
    await prefs.setString(_kPrefLastShownDate, today);
  } catch (_) {
    return;
  }
  if (!context.mounted) return;

  final l = L10n.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      content: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFB8860B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.remove_ads_promo_message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: l.remove_ads_promo_action,
        textColor: const Color(0xFFD4AF37),
        onPressed: () async {
          if (!context.mounted) return;
          await promptAndOpenPurchase(
            context: context,
            tier: SubscriptionTier.premium,
            featureLabel: l.remove_ads_promo_feature,
            icon: Icons.block,
          );
        },
      ),
    ),
  );
}
