import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'auth_service.dart';
import 'l10n/app_localizations.dart';
import 'login_page.dart';
import 'main.dart';
import 'purchase_page.dart';

// Pro のテーマカラー：ティールグラデーション
const _proColorDeep = Color(0xFF00695C);
const _proColorMid = Color(0xFF00897B);
const _proColorLight = Color(0xFF26A69A);
const _proGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_proColorDeep, _proColorLight, _proColorDeep],
  stops: [0.0, 0.5, 1.0],
);

/// ===============================
/// Pro 機能ゲート（ログイン必須 + 課金チェック）
/// ===============================
class ProGate {
  static const String entitlementId = 'Pro Plan';
  static const String offeringId = 'pro';

  static Future<bool> ensurePro(BuildContext context) async {
    // 1. ログイン必須（Pro機能はFirebase Auth必須）
    if (AuthService.currentUser == null) {
      if (!context.mounted) return false;
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const LoginPage(),
        ),
      );
      if (loggedIn != true) return false;
    }

    // 2. Pro加入チェック
    if (await _isPro()) return true;

    // 3. 統合購入画面（Pro フォーカス）
    if (!context.mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PurchasePage(focusedTier: PurchaseTier.pro),
      ),
    );
    return await _isPro();
  }

  /// 購入先行型ゲート（未加入ユーザーにサインインを促さず、まず購入画面を表示）
  /// Pro 加入後に Cloud Function などでログインが必要な場合のみログイン要求
  static Future<bool> ensureProPurchaseFirst(BuildContext context) async {
    // 1. 既に Pro なら、ログイン状態を確認するだけ
    if (await _isPro()) {
      if (AuthService.currentUser != null) return true;
      if (!context.mounted) return false;
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const LoginPage(),
        ),
      );
      return loggedIn == true;
    }

    // 2. 未加入なら、まず購入画面（サインインなし）
    if (!context.mounted) return false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PurchasePage(focusedTier: PurchaseTier.pro),
      ),
    );

    // 3. 購入完了後、再度 Pro チェック
    if (!await _isPro()) return false;

    // 4. Pro 加入後にログインしていなければ、ここで初めてサインインを求める
    if (AuthService.currentUser != null) return true;
    if (!context.mounted) return false;
    final loggedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LoginPage(),
      ),
    );
    return loggedIn == true;
  }

  static Future<bool> _isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Pro check error: $e');
      return false;
    }
  }

  /// 外部から Pro 加入状態を確認するための public wrapper
  static Future<bool> isPro() => _isPro();
}

/// ===============================
/// Pro 購入画面
/// ===============================
class ProPurchasePage extends StatefulWidget {
  const ProPurchasePage({super.key});

  @override
  State<ProPurchasePage> createState() => _ProPurchasePageState();
}

class _ProPurchasePageState extends State<ProPurchasePage> {
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
      final offering = offerings.getOffering(ProGate.offeringId);
      if (offering == null || offering.availablePackages.isEmpty) return;

      final packages = offering.availablePackages;
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
    } catch (e) {
      debugPrint('package load error: $e');
    }
  }

  Package? _packageByType(PackageType type) {
    for (final p in _packages) {
      if (p.packageType == type) return p;
    }
    return null;
  }

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
    setState(() => _isPurchasing = true);
    try {
      await Purchases.purchasePackage(_selectedPackage!);
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.all[ProGate.entitlementId]?.isActive ?? false) {
        if (!mounted) return;
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
        if (mounted) AppRestart.restart(context);
      }
    } catch (e) {
      debugPrint('Pro purchase error: $e');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final info = await Purchases.restorePurchases();
      if (info.entitlements.all[ProGate.entitlementId]?.isActive ?? false) {
        if (!mounted) return;
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
        if (mounted) AppRestart.restart(context);
      } else {
        if (!mounted) return;
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ダイヤモンドアイコン（コバルトブルーグラデーション）
              ShaderMask(
                shaderCallback: (bounds) => _proGradient.createShader(bounds),
                child: const Icon(
                  Icons.diamond,
                  size: 70,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              /// タイトル
              Text(
                l.pro_detail_title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              /// 無料トライアルバッジ（コバルトブルーグラデーション）
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: _proGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l.premium_detail_free_trial_badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Pro 限定機能（アニメーション付き）
              _AnimatedFeatureItem(
                text: l.pro_detail_feature_cloud_sync,
                index: 0,
              ),
              _AnimatedFeatureItem(
                text: l.pro_detail_feature_ai_tagging,
                index: 1,
              ),
              _AnimatedFeatureItem(
                text: l.pro_detail_feature_monthly_report,
                index: 2,
              ),
              _AnimatedFeatureItem(
                text: l.pro_detail_feature_public_sharing,
                index: 3,
              ),

              const SizedBox(height: 24),

              /// プラン選択
              if (annual != null) ...[
                _PlanCard(
                  label: l.premium_detail_plan_annual,
                  priceString: annual.storeProduct.priceString,
                  periodSuffix: l.premium_detail_per_year,
                  isSelected: _selectedPackage == annual,
                  badgeText: l.premium_detail_best_value,
                  savingsText: savings != null
                      ? l.premium_detail_save_percent(savings.toString())
                      : null,
                  onTap: () => setState(() => _selectedPackage = annual),
                ),
                const SizedBox(height: 8),
              ],
              if (monthly != null)
                _PlanCard(
                  label: l.premium_detail_plan_monthly,
                  priceString: monthly.storeProduct.priceString,
                  periodSuffix: l.premium_detail_per_month,
                  isSelected: _selectedPackage == monthly,
                  onTap: () => setState(() => _selectedPackage = monthly),
                ),

              const SizedBox(height: 16),

              /// 購入ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPurchasing || _selectedPackage == null
                      ? null
                      : _startPurchase,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: colorScheme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isPurchasing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  _proGradient.createShader(bounds),
                              child: Text(
                                l.premium_detail_start_trial,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (_selectedPackage != null)
                              Text(
                                _selectedPackage!.packageType ==
                                        PackageType.annual
                                    ? l.premium_detail_price_after_trial_yearly(
                                        _selectedPackage!
                                            .storeProduct
                                            .priceString,
                                      )
                                    : l.premium_detail_price_after_trial(
                                        _selectedPackage!
                                            .storeProduct
                                            .priceString,
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      ),
    );
  }
}

/// ===============================
/// プラン選択カード（Premium と同じ構造、色のみコバルト）
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _proColorMid.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _proColorMid
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _proColorMid : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? _proColorMid : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
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
                            gradient: _proGradient,
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
                            color: _proColorMid,
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
/// プレミアム説明アイテム（Premiumと同じ）
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
/// アニメーション付き説明（Premiumと同じ）
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
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
