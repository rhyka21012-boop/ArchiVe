import 'home_tab_index_provider.dart';
import 'list_tab_index_provider.dart';
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
import 'l10n/app_localizations.dart';
import 'tutorial_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;

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
      appBar: AppBar(
        title: Text(L10n.of(context)!.settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.school),
            tooltip: L10n.of(context)!.tutorial, // なければ 'チュートリアル'
            onPressed: () async {
              await _restartTutorial(context);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(L10n.of(context)!.settings_page_dark_mode),
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
            //テーマカラー設定
            title: Text(
              L10n.of(context)!.settings_page_theme_color,
              style: TextStyle(color: Color(0xFFB8860B)),
            ),

            //デバッグ用切り替え箇所
            onTap: () async {
              if (!await PremiumGate.ensurePremium(context)) return;

              setState(() {
                _isPremium = true;
              });
            },

            trailing: DropdownButton<ThemeColorType>(
              value: selectedColor,
              items:
                  ThemeColorType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(themeColorLabel(context, type)),
                    );
                  }).toList(),
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
            title: Text(L10n.of(context)!.settings_page_thumbnail_visibility),
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
                  Row(
                    children: [
                      Icon(Icons.inventory_2, size: 20),
                      SizedBox(width: 8),
                      Text(
                        L10n.of(context)!.settings_page_save_status,
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
                      Text(L10n.of(context)!.settings_page_save_count),
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
                      Text(L10n.of(context)!.settings_page_watch_count),
                      Text(
                        L10n.of(
                          context,
                        )!.settings_page_watch_ad_today(watchedAdsToday),
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
                            label: Text(
                              L10n.of(context)!.settings_page_watch_ad,
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
                    Text(
                      L10n.of(context)!.settings_page_ad_limit_reached,
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

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      L10n.of(context)!.settings_page_already_purchased,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.star, color: Colors.white),
              label: Text(
                L10n.of(context)!.settings_page_premium,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),

                backgroundColor: Color(0xFFB8860B),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(L10n.of(context)!.settings_page_app_version),
            subtitle: Text(L10n.of(context)!.version),
          ),
          ListTile(
            title: Text(L10n.of(context)!.settings_page_plivacy_policy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              const url = 'https://archive-e4efc.firebaseapp.com/privacy.html';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(L10n.of(context)!.settings_page_disable_link),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: Text(L10n.of(context)!.settings_page_terms),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              const url =
                  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(L10n.of(context)!.settings_page_disable_link),
                  ),
                );
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.settings_page_save_count_increased),
          ),
        );
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

  //チュートリアルをリセットする
  Future<void> _restartTutorial(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(L10n.of(context)!.start_tutorial_dialog),
            content: Text(L10n.of(context)!.start_tutorial_dialog_description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(L10n.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(L10n.of(context)!.ok),
              ),
            ],
          ),
    );

    if (result != true) return;

    // 1. 永続状態
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', true);

    // 2. チュートリアル状態
    ref.read(isTutorialModeProvider.notifier).state = true;
    ref.read(tutorialStepProvider.notifier).state = TutorialStep.createList;

    // 3. 表示タブ
    ref.read(homeTabIndexProvider.notifier).state = 0;
    ref.read(listTabIndexProvider.notifier).state = 0; // ListPage 内 Tab

    // 4. 画面戻す
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
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
