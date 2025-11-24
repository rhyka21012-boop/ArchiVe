import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;

  final List<String> _colors = ['オレンジ', 'グリーン', 'ブルー', 'ホワイト', 'レッド', 'イエロー'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final selectedColor = ref.watch(themeColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('ダークモード'),
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
            title: const Text('テーマカラー'),
            trailing: DropdownButton<String>(
              value: selectedColor,
              items:
                  _colors
                      .map(
                        (color) =>
                            DropdownMenuItem(value: color, child: Text(color)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeColorProvider.notifier).setColor(value);
                }
              },
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _showSubscriptionDialog,
              icon: const Icon(Icons.star, color: Colors.amber),
              label: const Text(
                'ArchiVe プレミアム',
                style: TextStyle(color: Colors.amber, fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),

                backgroundColor: Colors.black,
                /*
                    colorScheme.brightness == Brightness.light
                        ? Colors.grey[200]
                        : Color(0xFF2C2C2C),
                        */
              ),
            ),
          ),

          const Divider(),
          const ListTile(title: Text('アプリバージョン'), subtitle: Text('v1.2.0')),
          ListTile(
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              const url =
                  'https://drive.google.com/file/d/1USLSc2d0scQ5wTje7om3wBDd_vhsN0vz/view?usp=drive_link';
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
              Text(
                '• 広告なし\n• 好みの傾向がわかる統計機能\n• URLからタイトルを自動入力',
                style: TextStyle(fontSize: 18),
              ),
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
}
