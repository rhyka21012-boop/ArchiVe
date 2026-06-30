import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'auth_service.dart';
import 'l10n/app_localizations.dart';
import 'login_page.dart';
import 'main.dart';

enum PurchaseTier { free, premium, pro }

enum BillingPeriod { monthly, annual }

class PurchasePage extends StatefulWidget {
  final PurchaseTier focusedTier;
  const PurchasePage({super.key, this.focusedTier = PurchaseTier.premium});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFB8860B);
  static const _goldLight = Color(0xFFD4AF37);
  static const _tealDeep = Color(0xFF00695C);
  static const _tealMid = Color(0xFF00897B);
  static const _tealLight = Color(0xFF26A69A);

  BillingPeriod _period = BillingPeriod.annual;
  Offering? _premiumOffering;
  Offering? _proOffering;
  String _currentEntitlement = '';
  BillingPeriod? _currentPeriod;
  bool _isPurchasingPremium = false;
  bool _isPurchasingPro = false;

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
      String? currentProductId;
      if (info.entitlements.all['Pro Plan']?.isActive ?? false) {
        current = 'Pro Plan';
        currentProductId =
            info.entitlements.all['Pro Plan']?.productIdentifier;
      } else if (info.entitlements.all['Premium Plan']?.isActive ?? false) {
        current = 'Premium Plan';
        currentProductId =
            info.entitlements.all['Premium Plan']?.productIdentifier;
      }

      final premiumOffering = offerings.current;
      final proOffering = offerings.getOffering('pro');
      final currentPeriod = _periodOfProductId(
        currentProductId,
        current == 'Pro Plan' ? proOffering : premiumOffering,
      );

      if (!mounted) return;
      setState(() {
        _premiumOffering = premiumOffering;
        _proOffering = proOffering;
        _currentEntitlement = current;
        _currentPeriod = currentPeriod;
      });
    } catch (e) {
      debugPrint('Purchase page load error: $e');
    }
  }

  BillingPeriod? _periodOfProductId(String? productId, Offering? offering) {
    if (productId == null || offering == null) return null;
    final base = productId.split(':').first;
    for (final p in offering.availablePackages) {
      final pid = p.storeProduct.identifier.split(':').first;
      if (pid == base) {
        if (p.packageType == PackageType.monthly) return BillingPeriod.monthly;
        if (p.packageType == PackageType.annual) return BillingPeriod.annual;
      }
    }
    return null;
  }

  Package? _packageOf(Offering? offering, BillingPeriod period) {
    if (offering == null) return null;
    final type = period == BillingPeriod.monthly
        ? PackageType.monthly
        : PackageType.annual;
    for (final p in offering.availablePackages) {
      if (p.packageType == type) return p;
    }
    return null;
  }

  /// 年額にした場合の節約率（%）。両方ある場合のみ。
  int? _annualSavingsPercent(Offering? offering) {
    if (offering == null) return null;
    Package? monthly, annual;
    for (final p in offering.availablePackages) {
      if (p.packageType == PackageType.monthly) monthly = p;
      if (p.packageType == PackageType.annual) annual = p;
    }
    if (monthly == null || annual == null) return null;
    final monthlyYear = monthly.storeProduct.price * 12;
    if (monthlyYear <= 0) return null;
    final savings = (1 - annual.storeProduct.price / monthlyYear) * 100;
    if (savings <= 0) return null;
    return savings.round();
  }

  Future<void> _purchase(PurchaseTier tier) async {
    if (tier == PurchaseTier.pro && AuthService.currentUser == null) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const LoginPage(),
        ),
      );
      if (loggedIn != true) return;
    }

    final offering =
        tier == PurchaseTier.premium ? _premiumOffering : _proOffering;
    final package = _packageOf(offering, _period);
    if (package == null) return;
    final entitlementId =
        tier == PurchaseTier.premium ? 'Premium Plan' : 'Pro Plan';

    setState(() {
      if (tier == PurchaseTier.premium) {
        _isPurchasingPremium = true;
      } else {
        _isPurchasingPro = true;
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    try {
      await Purchases.purchasePackage(package);
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.all[entitlementId]?.isActive ?? false) {
        if (!mounted) return;
        await _completeDialog(colorScheme);
        if (mounted) AppRestart.restart(context);
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasingPremium = false;
          _isPurchasingPro = false;
        });
      }
    }
  }

  Future<void> _completeDialog(ColorScheme colorScheme) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Text(L10n.of(context)!.premium_detail_purchase_complete),
        content: Text(L10n.of(context)!.premium_detail_restart_message),
        actions: [
          TextButton(
            style: ButtonStyle(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(colorScheme.primary),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            child: Text(L10n.of(context)!.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _restore() async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final info = await Purchases.restorePurchases();
      final hasAny =
          (info.entitlements.all['Premium Plan']?.isActive ?? false) ||
              (info.entitlements.all['Pro Plan']?.isActive ?? false);
      if (!mounted) return;
      if (hasAny) {
        await _completeDialog(colorScheme);
        if (mounted) AppRestart.restart(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.premium_detail_restore_not_found),
          ),
        );
      }
    } catch (e) {
      debugPrint('restore error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0D07) : const Color(0xFFFAFAFA);

    final premiumSavings = _annualSavingsPercent(_premiumOffering);
    final proSavings = _annualSavingsPercent(_proOffering);
    final maxSavings = [premiumSavings, proSavings]
        .whereType<int>()
        .fold<int?>(null, (max, v) => max == null ? v : (v > max ? v : max));

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // メイン
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              child: Column(
                children: [
                  _buildHero(l, colorScheme),
                  const SizedBox(height: 24),
                  _buildPeriodToggle(l, colorScheme, maxSavings),
                  const SizedBox(height: 24),
                  _buildFreeCard(l, colorScheme),
                  const SizedBox(height: 14),
                  _buildPremiumCard(l, colorScheme),
                  const SizedBox(height: 14),
                  _buildProCard(l, colorScheme),
                  const SizedBox(height: 20),
                  _buildFooter(l, colorScheme),
                ],
              ),
            ),
            // 閉じるボタン
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Hero
  // ============================================================
  Widget _buildHero(L10n l, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          l.plans_page_title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.premium_detail_free_trial_badge,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Period toggle
  // ============================================================
  Widget _buildPeriodToggle(L10n l, ColorScheme colorScheme, int? maxSavings) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _periodChip(
              label: l.premium_detail_plan_monthly,
              selected: _period == BillingPeriod.monthly,
              onTap: () => setState(() => _period = BillingPeriod.monthly),
              colorScheme: colorScheme,
            ),
            _periodChip(
              label: l.premium_detail_plan_annual,
              selected: _period == BillingPeriod.annual,
              onTap: () => setState(() => _period = BillingPeriod.annual),
              colorScheme: colorScheme,
              savingsLabel: maxSavings != null
                  ? l.premium_detail_save_percent(maxSavings.toString())
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    String? savingsLabel,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colorScheme.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? colorScheme.surface : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (savingsLabel != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    savingsLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Free card
  // ============================================================
  Widget _buildFreeCard(L10n l, ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final isCurrent = _currentEntitlement.isEmpty;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final accentColor = colorScheme.onSurface.withValues(alpha: 0.55);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent
            ? Border.all(color: accentColor, width: 2)
            : Border.all(
                color: colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lock_open,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.plans_page_free_short,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l.plans_page_current_badge,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l.plans_page_free_price,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 18),
          ...[
            l.plans_page_free_item01,
            l.plans_page_free_item02,
            l.plans_page_free_item03,
            l.plans_page_free_item04,
          ].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: accentColor, size: 12),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Premium card
  // ============================================================
  Widget _buildPremiumCard(L10n l, ColorScheme colorScheme) {
    final pkg = _packageOf(_premiumOffering, _period);
    final isCurrent = _currentEntitlement == 'Premium Plan' &&
        _currentPeriod == _period;
    return _buildPlanCard(
      l: l,
      colorScheme: colorScheme,
      title: l.plans_page_premium_short,
      tagline: null,
      icon: Icons.star,
      gradientColors: const [_gold, _goldLight, _gold],
      accentColor: _gold,
      package: pkg,
      features: [
        l.premium_detail_premium_item01,
        l.premium_detail_premium_item02,
        l.premium_detail_premium_item03,
        l.premium_detail_premium_item04,
        l.premium_detail_premium_item05,
        l.premium_detail_premium_item06,
      ],
      isCurrent: isCurrent,
      isPurchasing: _isPurchasingPremium,
      isPopular: true,
      onTap: () => _purchase(PurchaseTier.premium),
    );
  }

  // ============================================================
  // Pro card
  // ============================================================
  Widget _buildProCard(L10n l, ColorScheme colorScheme) {
    final pkg = _packageOf(_proOffering, _period);
    final isCurrent =
        _currentEntitlement == 'Pro Plan' && _currentPeriod == _period;
    return _buildPlanCard(
      l: l,
      colorScheme: colorScheme,
      title: l.plans_page_pro_short,
      tagline: l.plans_page_includes_premium,
      icon: Icons.diamond,
      gradientColors: const [_tealDeep, _tealMid, _tealLight],
      accentColor: _tealMid,
      package: pkg,
      features: [
        l.pro_detail_feature_cloud_sync,
        l.pro_detail_feature_ai_tagging,
        l.pro_detail_feature_ai_recommend,
        l.pro_detail_feature_monthly_report,
        l.pro_detail_feature_public_sharing,
        l.pro_detail_feature_theme_teal,
      ],
      isCurrent: isCurrent,
      isPurchasing: _isPurchasingPro,
      isPopular: false,
      onTap: () => _purchase(PurchaseTier.pro),
    );
  }

  Widget _buildPlanCard({
    required L10n l,
    required ColorScheme colorScheme,
    required String title,
    required String? tagline,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    required Package? package,
    required List<String> features,
    required bool isCurrent,
    required bool isPurchasing,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
      stops: const [0.0, 0.5, 1.0],
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: isPopular
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                blurRadius: isPopular ? 24 : 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (tagline != null)
                          Text(
                            tagline,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l.plans_page_current_badge,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // 価格
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: package != null
                    ? Row(
                        key: ValueKey(
                            '${package.storeProduct.priceString}_${_period.name}'),
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            package.storeProduct.priceString,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _period == BillingPeriod.monthly
                                  ? l.premium_detail_per_month
                                  : l.premium_detail_per_year,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        height: 32,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 18),

              // 機能リスト
              ...features.map(
                (text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: accentColor,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CTA
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isCurrent || isPurchasing || package == null
                        ? null
                        : onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: isCurrent || package == null ? null : gradient,
                        color: isCurrent ? Colors.grey.shade400 : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isCurrent || package == null
                            ? []
                            : [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: isPurchasing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isCurrent
                                      ? l.plans_page_current_badge
                                      : l.premium_detail_start_trial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // POPULAR バッジ
        if (isPopular && !isCurrent)
          Positioned(
            top: -10,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // Footer
  // ============================================================
  Widget _buildFooter(L10n l, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l.premium_detail_note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _restore,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          child: Text(
            l.premium_detail_restore_button,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
