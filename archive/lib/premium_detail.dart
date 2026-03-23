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
  String? _priceString;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering != null && offering.availablePackages.isNotEmpty) {
        final package = offering.availablePackages.first;

        setState(() {
          _priceString = package.storeProduct.priceString;
        });
      }
    } catch (e) {
      debugPrint("price load error: $e");
    }
  }

  Future<void> _startPurchase() async {
    final colorScheme = Theme.of(context).colorScheme;

    setState(() {
      _isPurchasing = true;
    });

    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering != null && offering.availablePackages.isNotEmpty) {
        final package = offering.availablePackages.first;

        await Purchases.purchasePackage(package);

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
                        elevation: MaterialStateProperty.all(0),
                        backgroundColor: MaterialStateProperty.all(
                          colorScheme.primary,
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          Colors.white,
                        ),
                        shape: MaterialStateProperty.all(
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
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all(
                        colorScheme.primary,
                      ),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(
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
              L10n.of(context)!.premium_detail_premium_title,
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
                L10n.of(context)!.premium_detail_free_trial_badge,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 28),

            _AnimatedFeatureItem(
              text: L10n.of(context)!.premium_detail_premium_item01,
              index: 0,
            ),
            _AnimatedFeatureItem(
              text: L10n.of(context)!.premium_detail_premium_item02,
              index: 1,
            ),
            _AnimatedFeatureItem(
              text: L10n.of(context)!.premium_detail_premium_item03,
              index: 2,
            ),
            _AnimatedFeatureItem(
              text: L10n.of(context)!.premium_detail_premium_item04,
              index: 3,
            ),
            _AnimatedFeatureItem(
              text: L10n.of(context)!.premium_detail_premium_item05,
              index: 4,
            ),
            _AnimatedFeatureItem(
              text: L10n.of(context)!.premium_detail_premium_item06,
              index: 5,
            ),

            const Spacer(),

            /// 購入ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _startPurchase,
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
                              L10n.of(context)!.premium_detail_start_trial,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8860B),
                              ),
                            ),
                            if (_priceString != null)
                              Text(
                                L10n.of(
                                  context,
                                )!.premium_detail_price_after_trial(
                                  _priceString.toString(),
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
              L10n.of(context)!.premium_detail_note,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 8),

            /// 購入復元
            TextButton(
              onPressed: _restore,
              child: Text(L10n.of(context)!.premium_detail_restore_button),
            ),

            const SizedBox(height: 50),
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
