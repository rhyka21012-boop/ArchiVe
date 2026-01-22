import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';
//import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'thumbnail_setting_provider.dart';
import 'premium_detail.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
//import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ad_badge_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;

  final List<String> _colors = ['オレンジ', 'グリーン', 'ブルー', 'ホワイト', 'レッド', 'イエロー'];

  bool _isPremium = false;

  int currentCount = 0; // 現在の保存数
  int baseLimit = 100; // 基本上限

  static const bool isTestMode = false;
  String rewardedAdUnitId =
      isTestMode
          ? 'ca-app-pub-3940256099942544/1712485313' //テスト用
          : 'ca-app-pub-8268997781284735/5356923320'; //本番用

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadExtraSaveLimit();
    _loadRewardedAd();
    _countSavedItems();
    ref.read(themeModeProvider.notifier).loadTheme();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
  }

  @override
  void dispose() {
    _saveSettings();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watchedAdsToday = ref.watch(adBadgeProvider);
    final showAdBadge = watchedAdsToday < 3;
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final selectedColor = ref.watch(themeColorProvider);
    //final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text('設定')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('ダークモード'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).updateTheme(value);
            },
          ),
          /*
          SwitchListTile(
            title: const Text('通知を有効にする'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          */
          ListTile(
            title: const Text(
              'テーマカラー★',
              style: TextStyle(color: Color(0xFFB8860B)),
            ),
            //デバッグ用切り替え箇所
            onTap: () async {
              if (!await PremiumGate.ensurePremium(context)) return;

              setState(() {
                _isPremium = true;
              });
            },
            trailing: DropdownButton<String>(
              value: selectedColor,
              items:
                  _colors
                      .map(
                        (color) =>
                            DropdownMenuItem(value: color, child: Text(color)),
                      )
                      .toList(),
              onChanged:
                  _isPremium
                      //true //デバッグ用切り替え箇所
                      ? (value) {
                        if (value != null) {
                          ref.read(themeColorProvider.notifier).setColor(value);
                        }
                      }
                      : null,
            ),
          ),
          SwitchListTile(
            title: const Text('リスト画像の表示/非表示'),
            value: ref.watch(showThumbnailProvider),
            onChanged: (value) {
              ref.read(showThumbnailProvider.notifier).set(value);
            },
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color:
                colorScheme.brightness == Brightness.light
                    ? Colors.grey[200]
                    : Color(0xFF2C2C2C),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  const Row(
                    children: [
                      Icon(Icons.inventory_2, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '作品保存数の状態',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 保存数表示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('保存数'),
                      Text(
                        '$currentCount / $maxSaveLimit',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 広告視聴回数
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('本日の視聴回数'),
                      Text(
                        '$watchedAdsToday / 3 回',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 広告ボタン
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                watchedAdsToday >= 3
                                    ? null
                                    : () async {
                                      await _showRewardedAd();
                                    },
                            icon: const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                            ),
                            label: const Text(
                              '広告を見て +5 枠',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        // 🔴 赤バッチ
                        if (showAdBadge)
                          Positioned(top: 3, right: 0, child: _AdBadge()),
                      ],
                    ),
                  ),

                  if (watchedAdsToday >= 3) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '本日の広告視聴上限に達しました',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                if (!await PremiumGate.ensurePremium(context)) return;

                setState(() {
                  _isPremium = true;
                });

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('既に購入済みです。')));
              },
              icon: const Icon(Icons.star, color: Color(0xFFB8860B)),
              label: const Text(
                'ArchiVe プレミアム',
                style: TextStyle(
                  color: Color(0xFFB8860B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),

                backgroundColor: Colors.black,
              ),
            ),
          ),
          const Divider(),
          const ListTile(title: Text('アプリバージョン'), subtitle: Text('v1.2.0')),
          ListTile(
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              const url = 'https://archive-e4efc.firebaseapp.com/privacy.html';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした')));
              }
            },
          ),
          ListTile(
            title: const Text('利用規約（Apple標準EULA）'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              const url =
                  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('リンクを開けませんでした')));
              }
            },
          ),
        ],
      ),
    );
  }

  //リワード広告のロード
  int extraSaveLimit = 0; // 広告で増えた保存枠（+5ずつ）
  RewardedAd? _rewardedAd;

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  //広告を表示して報酬付与（+5枠）
  Future<void> _showRewardedAd() async {
    if (_rewardedAd == null) {
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        final prefs = await SharedPreferences.getInstance();

        setState(() {
          extraSaveLimit += 5;
        });

        await prefs.setInt('extra_save_limit', extraSaveLimit);

        ref.read(adBadgeProvider.notifier).increment();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存枠が +5 されました')));
      },
    );

    _rewardedAd = null;
    _loadRewardedAd();
  }

  //保存上限の計算
  int get maxSaveLimit {
    if (_isPremium) return 999999; // 実質無制限
    return 100 + extraSaveLimit;
  }

  //保存作品数カウント
  Future<void> _countSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];

    setState(() {
      currentCount = list.length;
    });
  }

  //保存枠を再読み込み
  Future<void> _loadExtraSaveLimit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      extraSaveLimit = prefs.getInt('extra_save_limit') ?? 0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _countSavedItems();
  }

  /*　premium_detail.dartに移植済み
  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              Text(
                'ArchiVe プレミアム',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('• 広告なし\n• 好みの傾向がわかる統計機能', style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              Text(
                '¥170/月',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル', style: TextStyle(color: Colors.black)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                Navigator.pop(context);
                _startPurchase();
              },
              child: const Text('購入する', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
  

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
  */
}

class _AdBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
