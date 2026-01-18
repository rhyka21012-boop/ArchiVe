import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// ===============================
/// 外部から呼ぶためのゲートクラス
/// ===============================
class PremiumGate {
  static const String entitlementId = 'Premium Plan';

  /// プレミアムなら true
  /// 非プレミアムなら購入画面を表示
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
/// 購入画面（UI）
/// ===============================
class PremiumPurchasePage extends StatefulWidget {
  const PremiumPurchasePage({super.key});

  @override
  State<PremiumPurchasePage> createState() => _PremiumPurchasePageState();
}

class _PremiumPurchasePageState extends State<PremiumPurchasePage> {
  bool _isPurchasing = false;

  void _startPurchase() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering != null && offering.availablePackages.isNotEmpty) {
        final package = offering.availablePackages.first;

        // 購入処理（PurchaseResultを受け取る）
        final purchaseResult = await Purchases.purchasePackage(package);

        // 最新のCustomerInfoを取得
        final customerInfo = await Purchases.getCustomerInfo();

        // RevenueCatのEntitlement IDを確認（例: "premium"）
        if (customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('プレミアムを購入しました！')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('購入は完了しましたが、プレミアムが有効化されませんでした')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('購入可能なプランが見つかりません')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('購入エラー: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            const Icon(Icons.star, size: 64, color: Color(0xFFB8860B)),

            const SizedBox(height: 16),

            const Text(
              'ArchiVe Premium',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 32),

            const _FeatureItem(text: '広告なしで快適に利用'),
            const _FeatureItem(text: 'テーマカラーを自由に変更'),
            const _FeatureItem(text: '画像を自由に変更'),
            const _FeatureItem(text: '複数のタグで検索'),
            const _FeatureItem(text: '無制限の保存枠'),
            const _FeatureItem(text: '統計機能'),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _startPurchase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isPurchasing
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          '¥170 / 月で始める',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'いつでもキャンセル可能',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

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
