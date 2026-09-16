import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'premium_detail.dart';
import 'pro_detail.dart';

enum SubscriptionTier { premium, pro }

const Color _gold = Color(0xFFB8860B);
const Color _goldLight = Color(0xFFD4AF37);
const Color _tealDeep = Color(0xFF00695C);
const Color _tealMid = Color(0xFF00897B);
const Color _tealLight = Color(0xFF26A69A);

/// サブスク限定機能の入口で「プラン紹介 → 詳細画面へ」の 2 段導線を作るヘルパ。
///
/// - [featureLabel] : ダイアログ本文の XX 部分 (「Premium プランでは XX ができます」)
/// - [imageAsset] : 未指定なら [icon] + プラン色グラデでヒーローを構築
///
/// 戻り値: 実際に購入 (or 加入済み) に至れば true。ダイアログでキャンセルされた
/// 場合、または購入画面でキャンセルされた場合は false。
Future<bool> promptAndOpenPurchase({
  required BuildContext context,
  required SubscriptionTier tier,
  required String featureLabel,
  String? imageAsset,
  IconData icon = Icons.star,
}) async {
  final confirmed = await _showSubscriptionPromptDialog(
    context: context,
    tier: tier,
    featureLabel: featureLabel,
    imageAsset: imageAsset,
    icon: icon,
  );
  if (confirmed != true) return false;
  if (!context.mounted) return false;
  if (tier == SubscriptionTier.premium) {
    return await PremiumGate.ensurePremium(context);
  } else {
    return await ProGate.ensureProPurchaseFirst(context);
  }
}

Future<bool?> _showSubscriptionPromptDialog({
  required BuildContext context,
  required SubscriptionTier tier,
  required String featureLabel,
  String? imageAsset,
  required IconData icon,
}) {
  final l = L10n.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  final isPremium = tier == SubscriptionTier.premium;
  final planName = isPremium ? l.plans_page_premium_short : l.plans_page_pro_short;
  final gradientColors =
      isPremium ? const [_gold, _goldLight, _gold] : const [_tealDeep, _tealMid, _tealLight];
  final accentColor = isPremium ? _gold : _tealMid;

  return showDialog<bool>(
    context: context,
    builder: (dctx) {
      return AlertDialog(
        backgroundColor: colorScheme.secondary,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== ヒーロー (画像 or アイコン+グラデ) =====
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: imageAsset != null
                      ? Image.asset(
                          imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildIconHero(gradientColors, icon),
                        )
                      : _buildIconHero(gradientColors, icon),
                ),
              ),
              const SizedBox(height: 20),
              // ===== 本文 =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.subscription_prompt_body(planName, featureLabel),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.subscription_prompt_question(planName),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ===== アクション =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dctx, false),
                        child: Text(l.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dctx, true),
                        child: Text(
                          l.subscription_prompt_confirm(planName),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildIconHero(List<Color> gradientColors, IconData icon) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
        stops: const [0.0, 0.5, 1.0],
      ),
    ),
    child: Center(
      child: Icon(icon, color: Colors.white, size: 72),
    ),
  );
}
