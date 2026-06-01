import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'l10n/app_localizations.dart';
import 'premium_detail.dart';
import 'pro_detail.dart';

/// プラン一覧画面：Premium と Pro を並べて表示し、各カードのタップで購入画面へ
class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  Offering? _premiumOffering;
  Offering? _proOffering;
  String _currentEntitlement = ''; // 'Premium Plan' / 'Pro Plan' / ''

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final offerings = await Purchases.getOfferings();
      final info = await Purchases.getCustomerInfo();

      String current = '';
      if (info.entitlements.all['Pro Plan']?.isActive ?? false) {
        current = 'Pro Plan';
      } else if (info.entitlements.all['Premium Plan']?.isActive ?? false) {
        current = 'Premium Plan';
      }

      if (!mounted) return;
      setState(() {
        _premiumOffering = offerings.current;
        _proOffering = offerings.getOffering('pro');
        _currentEntitlement = current;
      });
    } catch (e) {
      debugPrint('Plans load error: $e');
    }
  }

  Package? _findPackage(Offering? offering, PackageType type) {
    if (offering == null) return null;
    for (final p in offering.availablePackages) {
      if (p.packageType == type) return p;
    }
    return null;
  }

  String _priceLabel(Offering? offering, L10n l) {
    if (offering == null) return '';
    final monthly = _findPackage(offering, PackageType.monthly);
    final annual = _findPackage(offering, PackageType.annual);
    final parts = <String>[];
    if (monthly != null) {
      parts.add('${monthly.storeProduct.priceString}${l.premium_detail_per_month}');
    }
    if (annual != null) {
      parts.add('${annual.storeProduct.priceString}${l.premium_detail_per_year}');
    }
    return parts.join(' / ');
  }

  Future<void> _openPremium() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PremiumPurchasePage(),
      ),
    );
    if (mounted) _loadAll();
  }

  Future<void> _openPro() async {
    if (!mounted) return;
    await ProGate.ensurePro(context);
    if (mounted) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final isPremium = _currentEntitlement == 'Premium Plan';
    final isPro = _currentEntitlement == 'Pro Plan';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.plans_page_title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Premium カード
          _PlanCard(
            title: l.settings_page_premium,
            accentColor: const Color(0xFFB8860B),
            icon: Icons.star,
            priceText: _priceLabel(_premiumOffering, l),
            features: [
              l.premium_detail_premium_item01,
              l.premium_detail_premium_item02,
              l.premium_detail_premium_item03,
              l.premium_detail_premium_item04,
              l.premium_detail_premium_item05,
              l.premium_detail_premium_item06,
            ],
            isCurrent: isPremium,
            // Pro 加入者は Premium 機能を全て持っている → タップ不可
            onTap: isPro ? null : _openPremium,
            currentBadgeText: l.plans_page_current_badge,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 16),

          // Pro カード
          _PlanCard(
            title: l.pro_detail_title,
            accentColor: const Color(0xFF00897B),
            icon: Icons.diamond,
            priceText: _priceLabel(_proOffering, l),
            featuresLabel: l.plans_page_includes_premium,
            features: [
              l.pro_detail_feature_cloud_sync,
              l.pro_detail_feature_ai_tagging,
              l.pro_detail_feature_monthly_report,
              l.pro_detail_feature_public_sharing,
            ],
            isCurrent: isPro,
            onTap: isPro ? null : _openPro,
            currentBadgeText: l.plans_page_current_badge,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final IconData icon;
  final String priceText;
  final String? featuresLabel;
  final List<String> features;
  final bool isCurrent;
  final VoidCallback? onTap;
  final String currentBadgeText;
  final ColorScheme colorScheme;

  const _PlanCard({
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.priceText,
    required this.features,
    required this.isCurrent,
    required this.onTap,
    required this.currentBadgeText,
    required this.colorScheme,
    this.featuresLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[200];

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isCurrent
                ? Border.all(color: accentColor, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル行
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currentBadgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (priceText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              priceText,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: accentColor),
                ],
              ),

              const SizedBox(height: 12),

              if (featuresLabel != null) ...[
                Text(
                  featuresLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              ...features.map(
                (text) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
