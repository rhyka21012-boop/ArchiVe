import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'list_page.dart';
import 'search_page.dart';
import 'analitics_page.dart';
import 'setting_page.dart';
import 'my_ad_widget.dart'; // バナー広告ウィジェットをインポート
//import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  /*
  Future<InitializationStatus> _initGoogleMobileAds() {
    // TODO: Initialize Google Mobile Ads SDK
    return MobileAds.instance.initialize();
  }
  */

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool _isPremium = false; //サブスク購入状態を保持

  final GlobalKey<ListPageState> _listPageKey = GlobalKey<ListPageState>();
  final GlobalKey<SearchPageState> _SearchPageKey =
      GlobalKey<SearchPageState>();
  final GlobalKey<AnalyticsPageState> _AnalyticsPageKey =
      GlobalKey<AnalyticsPageState>();
  final GlobalKey<ConsumerState<SettingsPage>> _SettingsPageKey =
      GlobalKey<ConsumerState<SettingsPage>>();

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  // BottomNavigationBarのタップイベント
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Widget> _pages = [
      ListPage(key: _listPageKey),
      SearchPage(key: _SearchPageKey),
      AnalyticsPage(key: _AnalyticsPageKey),
      SettingsPage(key: _SettingsPageKey),
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder),
                  label: 'フォルダ',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: '検索'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.whatshot),
                  label: '統計',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: '設定',
                ),
              ],
              currentIndex: _selectedIndex,
              //unselectedItemColor: colorScheme.onPrimary,
              unselectedItemColor:
                  colorScheme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
              selectedItemColor: colorScheme.primary,
              onTap: _onItemTapped,
            ),
            // ← プレミアムじゃなければ広告を表示
            if (!_isPremium) const MyAdWidget(),
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
          customerInfo.entitlements.all["premium"]?.isActive ?? false;
      setState(() {
        _isPremium = isActive;
      });
    } catch (e) {
      debugPrint("Error fetching subscription status: $e");
    }
  }
}
