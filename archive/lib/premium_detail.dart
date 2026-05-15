import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'main.dart';
import 'l10n/app_localizations.dart';

/// ===============================
/// 外部から呼ぶためのゲートクラス
/// ===============================
class PremiumGate {
  static const String entitlementId = 'Premium Plan';

  static Future<bool> ensurePremium(BuildContext context) async {
    final isPremium = await _checkSubscriptionStatus();
    if (isPremium) return true;

    final purchased = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PremiumPurchasePage(),
      ),
    );

    return purchased == true;
  }

  static Future<bool> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Subscription check error: $e');
      return false;
    }
  }
}

/// ===============================
/// 購入画面
/// ===============================
class PremiumPurchasePage extends StatefulWidget {
  const PremiumPurchasePage({super.key});

  @override
  State<PremiumPurchasePage> createState() => _PremiumPurchasePageState();
}

class _PremiumPurchasePageState extends State<PremiumPurchasePage> {
  bool _isPurchasing = false;
  List<Package> _packages = [];
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering != null && offering.availablePackages.isNotEmpty) {
        final packages = offering.availablePackages;

        // 年額があればデフォルト選択、なければ最初のパッケージ
        Package? annual;
        for (final p in packages) {
          if (p.packageType == PackageType.annual) {
            annual = p;
            break;
          }
        }

        setState(() {
          _packages = packages;
          _selectedPackage = annual ?? packages.first;
        });
      }
    } catch (e) {
      debugPrint("package load error: $e");
    }
  }

  Package? _packageByType(PackageType type) {
    for (final p in _packages) {
      if (p.packageType == type) return p;
    }
    return null;
  }

  /// 月額に対する年額の節約率（両方ある場合のみ）
  int? _savingsPercent() {
    final monthly = _packageByType(PackageType.monthly);
    final annual = _packageByType(PackageType.annual);
    if (monthly == null || annual == null) return null;
    final monthlyYearly = monthly.storeProduct.price * 12;
    if (monthlyYearly <= 0) return null;
    final savings = (1 - annual.storeProduct.price / monthlyYearly) * 100;
    if (savings <= 0) return null;
    return savings.round();
  }

  Future<void> _startPurchase() async {
    if (_selectedPackage == null) return;
    final colorScheme = Theme.of(context).colorScheme;

    setState(() {
      _isPurchasing = true;
    });

    try {
      await Purchases.purchasePackage(_selectedPackage!);

      final customerInfo = await Purchases.getCustomerInfo();

      if (customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => AlertDialog(
                backgroundColor: colorScheme.secondary,
                title: Text(
                  L10n.of(context)!.premium_detail_purchase_complete,
                ),
                content: Text(
                  L10n.of(context)!.premium_detail_restart_message,
                ),
                actions: [
                  TextButton(
                    style: ButtonStyle(
                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.primary,
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    child: Text(L10n.of(context)!.ok),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
        );

        AppRestart.restart(context);
      }
    } catch (e) {
      debugPrint("purchase error $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  Future<void> _restore() async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final customerInfo = await Purchases.restorePurchases();

      if (customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => AlertDialog(
                backgroundColor: colorScheme.secondary,
                title: Text(L10n.of(context)!.premium_detail_purchase_complete),
                content: Text(L10n.of(context)!.premium_detail_restart_message),
                actions: [
                  TextButton(
                    style: ButtonStyle(
                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(
                        colorScheme.primary,
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    child: Text(L10n.of(context)!.ok),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
        );

        AppRestart.restart(context);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.premium_detail_restore_not_found),
          ),
        );
      }
    } catch (e) {
      debugPrint("restore error $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = L10n.of(context)!;

    final monthly = _packageByType(PackageType.monthly);
    final annual = _packageByType(PackageType.annual);
    final savings = _savingsPercent();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.star, size: 70, color: Color(0xFFB8860B)),

            const SizedBox(height: 12),

            /// タイトル
            Text(
              l.premium_detail_premium_title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            /// 無料トライアルバッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB8860B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l.premium_detail_free_trial_badge,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 28),

            _AnimatedFeatureItem(
              text: l.premium_detail_premium_item01,
              index: 0,
            ),
            _AnimatedFeatureItem(
              text: l.premium_detail_premium_item02,
              index: 1,
            ),
            _AnimatedFeatureItem(
              text: l.premium_detail_premium_item03,
              index: 2,
            ),
            _AnimatedFeatureItem(
              text: l.premium_detail_premium_item04,
              index: 3,
            ),
            _AnimatedFeatureItem(
              text: l.premium_detail_premium_item05,
              index: 4,
            ),
            _AnimatedFeatureItem(
              text: l.premium_detail_premium_item06,
              index: 5,
            ),

            const Spacer(),

            /// プラン選択
            if (annual != null) ...[
              _PlanCard(
                label: l.premium_detail_plan_annual,
                priceString: annual.storeProduct.priceString,
                periodSuffix: l.premium_detail_per_year,
                isSelected: _selectedPackage == annual,
                badgeText: l.premium_detail_best_value,
                savingsText:
                    savings != null
                        ? l.premium_detail_save_percent(savings.toString())
                        : null,
                onTap:
                    () => setState(() {
                      _selectedPackage = annual;
                    }),
              ),
              const SizedBox(height: 8),
            ],
            if (monthly != null)
              _PlanCard(
                label: l.premium_detail_plan_monthly,
                priceString: monthly.storeProduct.priceString,
                periodSuffix: l.premium_detail_per_month,
                isSelected: _selectedPackage == monthly,
                onTap:
                    () => setState(() {
                      _selectedPackage = monthly;
                    }),
              ),

            const SizedBox(height: 16),

            /// 購入ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isPurchasing || _selectedPackage == null
                        ? null
                        : _startPurchase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor:
                      colorScheme.brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                    _isPurchasing
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Column(
                          children: [
                            Text(
                              l.premium_detail_start_trial,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8860B),
                              ),
                            ),
                            if (_selectedPackage != null)
                              Text(
                                _selectedPackage!.packageType ==
                                        PackageType.annual
                                    ? l.premium_detail_price_after_trial_yearly(
                                      _selectedPackage!.storeProduct.priceString,
                                    )
                                    : l.premium_detail_price_after_trial(
                                      _selectedPackage!.storeProduct.priceString,
                                    ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
              ),
            ),

            const SizedBox(height: 12),

            /// 安心テキスト
            Text(
              l.premium_detail_note,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 8),

            /// 購入復元
            TextButton(
              onPressed: _restore,
              child: Text(l.premium_detail_restore_button),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// プラン選択カード
/// ===============================
class _PlanCard extends StatelessWidget {
  final String label;
  final String priceString;
  final String periodSuffix;
  final bool isSelected;
  final String? badgeText;
  final String? savingsText;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    required this.priceString,
    required this.periodSuffix,
    required this.isSelected,
    required this.onTap,
    this.badgeText,
    this.savingsText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const gold = Color(0xFFB8860B);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? gold.withValues(alpha: 0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected
                    ? gold
                    : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 選択ラジオ
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? gold : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? gold : Colors.transparent,
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
            ),

            const SizedBox(width: 12),

            // ラベル + 価格
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        priceString,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        periodSuffix,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (savingsText != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          savingsText!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// プレミアム説明アイテム
/// ===============================
class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

/// ===============================
/// アニメーション付き説明
/// ===============================
class _AnimatedFeatureItem extends StatefulWidget {
  final String text;
  final int index;

  const _AnimatedFeatureItem({required this.text, required this.index});

  @override
  State<_AnimatedFeatureItem> createState() => _AnimatedFeatureItemState();
}

class _AnimatedFeatureItemState extends State<_AnimatedFeatureItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _offset = Tween(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 150 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: _FeatureItem(text: widget.text),
      ),
    );
  }
}
