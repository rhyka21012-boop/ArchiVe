import 'dart:io';

import 'package:archive_app/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'list_page.dart';
import 'search_page.dart';
import 'analitics_page.dart';
import 'setting_page.dart';
import 'my_ad_widget.dart';
import 'ad_badge_provider.dart';
import 'l10n/app_localizations.dart';
import 'home_tab_index_provider.dart';
import 'save_limit_helper.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with SingleTickerProviderStateMixin {
  //late TabController _tabController;
  int _selectedIndex = 0;
  bool _isPremium = false; //サブスク購入状態を保持

  final GlobalKey<ListPageState> _listPageKey = GlobalKey<ListPageState>();
  final GlobalKey<SearchPageState> _SearchPageKey =
      GlobalKey<SearchPageState>();
  final GlobalKey<AnalyticsPageState> _AnalyticsPageKey =
      GlobalKey<AnalyticsPageState>();

  RewardedAd? _rewardedAd;

  void _loadAd() {
    String adUnitId;

    const bool isTest = false; // ←テスト時だけtrueにする

    if (isTest) {
      adUnitId = 'ca-app-pub-3940256099942544/1712485313';
    } else if (Platform.isAndroid) {
      adUnitId = 'ca-app-pub-8268997781284735/8948638186';
    } else if (Platform.isIOS) {
      adUnitId = 'ca-app-pub-8268997781284735/5356923320';
    } else {
      return;
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;

          /// ⭐ 見終わったら自動再ロード（超重要）
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppTrackingTransparency.requestTrackingAuthorization();
    });
    _checkSubscriptionStatus();

    _loadAd();
  }

  @override
  void dispose() {
    //_tabController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // BottomNavigationBarのタップイベント
  void _onItemTapped(int index) async {
    if (index == 2) {
      //作品数上限チェック
      if (!await SaveLimitHelper.canSave(context, _rewardedAd, ref)) {
        _loadAd();
        return;
      }

      //作品数 <= 100または、プレミアム会員の場合のは作品追加画面へ
      // +アイコンをタップでDetailPageを開く
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DetailPage(listName: '選択なし')),
      );
      return; // ページ遷移したらBottomNavigationBarの選択は変更しない
    }
    setState(() {
      if (index >= 3) {
        _selectedIndex = index - 1; // 3→2, 4→3
      } else {
        _selectedIndex = index; // 0→0, 1→1
      }
    });

    // 👇 Providerにも反映
    ref.read(homeTabIndexProvider.notifier).state = _selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(homeTabIndexProvider, (previous, next) {
      if (_selectedIndex != next) {
        setState(() {
          _selectedIndex = next;
        });
      }
    });

    final watchedAdToday = ref.watch(adBadgeProvider);
    final showAdBadge = watchedAdToday < 3;
    final colorScheme = Theme.of(context).colorScheme;

    final List<Widget> _pages = [
      ListPage(key: _listPageKey),
      SearchPage(key: _SearchPageKey),
      AnalyticsPage(key: _AnalyticsPageKey),
      const SettingsPage(),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFF121212),
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
          // 広告ウィジェット（画面最下部に固定）
          /*
          Positioned(
            bottom: 56, // BottomNabigationBarの高さ分上にずらす
            left: 0,
            right: 0,
            child: SafeArea(child: MyAdWidget()),
          ),
          */
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // 重要: 最小限の高さに抑える
          children: [
            BottomNavigationBar(
              backgroundColor: colorScheme.secondary,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder),
                  label: L10n.of(context)!.main_page_lists,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: L10n.of(context)!.main_page_search,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add, size: 30),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.whatshot),
                  label: L10n.of(context)!.main_page_analytics,
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.settings),
                      if (showAdBadge)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: L10n.of(context)!.main_page_settings,
                ),
              ],
              currentIndex:
                  _selectedIndex <= 1 ? _selectedIndex : _selectedIndex + 1,
              //unselectedItemColor: colorScheme.onPrimary,
              unselectedItemColor:
                  colorScheme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
              selectedItemColor: colorScheme.primary,
              onTap: _onItemTapped,
            ),
            // ← プレミアムじゃなければ広告を表示
            //if (!_isPremium) const MyAdWidget(),
          ],
        ),
      ),
    );
  }

  //サブスクリプション購入状態を確認
  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive =
          customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false;
      setState(() {
        _isPremium = isActive;
      });
    } catch (e) {
      debugPrint("Error fetching subscription status: $e");
    }
  }
}
