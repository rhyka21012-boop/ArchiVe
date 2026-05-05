import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart' show Clipboard;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:archive_app/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'list_page.dart';
import 'search_page.dart';
import 'analitics_page.dart';
import 'setting_page.dart';
import 'my_ad_widget.dart';
import 'ad_badge_provider.dart';
import 'l10n/app_localizations.dart';
import 'home_tab_index_provider.dart';
import 'save_limit_helper.dart';
import 'app_group_service.dart';
import 'random_image_reload_provider.dart';
import 'list_reload_provider.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  //late TabController _tabController;
  int _selectedIndex = 0;
  bool _isPremium = false; //サブスク購入状態を保持

  final GlobalKey<ListPageState> _listPageKey = GlobalKey<ListPageState>();
  final GlobalKey<SearchPageState> _SearchPageKey =
      GlobalKey<SearchPageState>();
  final GlobalKey<AnalyticsPageState> _AnalyticsPageKey =
      GlobalKey<AnalyticsPageState>();

  RewardedAd? _rewardedAd;
  String? _lastCheckedClipboardUrl;

  //保存済みバージョン保存用キー
  static const _shownVersionKey = 'last_shown_update_version';

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

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppTrackingTransparency.requestTrackingAuthorization();
      checkAppVersion(context);
      await _processPendingShare();
      await _checkClipboard();
    });
    _checkSubscriptionStatus();

    _loadAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    //_tabController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processPendingShare().then((_) => _checkClipboard());
    }
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = (data?.text ?? '').trim();
    if (!text.startsWith('http://') && !text.startsWith('https://')) return;
    if (text == _lastCheckedClipboardUrl) return;
    _lastCheckedClipboardUrl = text;

    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.of(ctx)!.clipboard_dialog_title),
        content: Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.55)),
        ),
        actions: [
          TextButton(
            style: ButtonStyle(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
              foregroundColor: WidgetStateProperty.all(Colors.black),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.of(ctx)!.cancel),
          ),
          TextButton(
            style: ButtonStyle(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(colorScheme.primary),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L10n.of(ctx)!.ok),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(url: text, listName: '選択なし')),
    );
  }

  // Share Extension (iOS) / Share Intent (Android) からのデータを処理して saved_metadata に保存する
  Future<void> _processPendingShare() async {
    if (Platform.isAndroid) {
      await _processAndroidShare();
      return;
    }

    final pending = await AppGroupService.getPendingShare();
    if (pending == null) return;

    final url = (pending['url'] as String? ?? '').trim();
    if (url.isEmpty) return;

    await AppGroupService.clearPendingShare();

    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_metadata') ?? [];

    // 重複チェック
    final isDuplicate = savedList.any((item) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      return map['url'] == url;
    });

    if (isDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context)!.share_already_saved)),
        );
      }
      return;
    }

    final data = <String, dynamic>{
      'url': url,
      'title': pending['title'] ?? '',
      'listName': pending['listName'] ?? '',
      'image': pending['image'] ?? '',
      'cast': '',
      'genre': '',
      'series': '',
      'label': '',
      'maker': '',
      'memo': '',
      'rating': null,
    };

    savedList.add(jsonEncode(data));
    await prefs.setStringList('saved_metadata', savedList);

    ref.read(randomImageReloadProvider.notifier).state++;
    ref.read(listReloadProvider.notifier).state++;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context)!.share_saved)),
      );
    }
  }

  // Android: 共有インテントで受け取った URL のダイアログを表示して保存する
  Future<void> _processAndroidShare() async {
    final url = await AppGroupService.getSharedUrl();
    if (url == null || url.isEmpty) return;
    await AppGroupService.clearSharedUrl();

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_metadata') ?? [];

    final isDuplicate = savedList.any((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['url'] == url;
      } catch (_) {
        return false;
      }
    });

    if (isDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context)!.share_already_saved)),
        );
      }
      return;
    }

    final allLists = prefs.getStringList('all_lists') ?? [];
    final titleController = TextEditingController();
    bool isFetchingTitle = true;
    String selectedList = '';
    bool fetchStarted = false;
    String fetchedImageUrl = '';

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (!fetchStarted) {
            fetchStarted = true;
            _fetchPageMeta(url).then((meta) {
              if (meta.title != null && titleController.text.isEmpty) {
                titleController.text = meta.title!;
              }
              fetchedImageUrl = meta.image ?? '';
              setDialogState(() => isFetchingTitle = false);
            });
          }
          return AlertDialog(
            title: Text(L10n.of(context)!.share_dialog_title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'URL',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        L10n.of(ctx)!.title,
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (isFetchingTitle) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: L10n.of(ctx)!.share_title_hint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    L10n.of(ctx)!.share_list_section,
                    style: const TextStyle(fontSize: 12),
                  ),
                  DropdownButton<String>(
                    value: selectedList,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(L10n.of(ctx)!.no_select),
                      ),
                      ...allLists.map(
                        (l) => DropdownMenuItem(value: l, child: Text(l)),
                      ),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedList = v ?? ''),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(L10n.of(ctx)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(L10n.of(ctx)!.save),
              ),
            ],
          );
        },
      ),
    );

    final titleText = titleController.text.trim();
    titleController.dispose();

    if (confirmed != true) return;

    final data = <String, dynamic>{
      'url': url,
      'title': titleText,
      'listName': selectedList,
      'image': fetchedImageUrl,
      'cast': '',
      'genre': '',
      'series': '',
      'label': '',
      'maker': '',
      'memo': '',
      'rating': null,
    };

    savedList.add(jsonEncode(data));
    await prefs.setStringList('saved_metadata', savedList);

    ref.read(randomImageReloadProvider.notifier).state++;
    ref.read(listReloadProvider.notifier).state++;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context)!.share_saved)),
      );
    }
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

  //バージョンチェック
  Future<void> checkAppVersion(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('https://archive-e4efc.firebaseapp.com/version.json'),
      );

      print(response.statusCode);
      print(response.headers);
      print(response.bodyBytes.length);
      print(response.bodyBytes.take(20).toList());

      if (response.statusCode != 200) return;

      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      final latestVersion = Version.parse(data["latest_version"]);
      final minRequiredVersion = Version.parse(data["min_required_version"]);

      if (!mounted) return;

      // 🔹 強制アップデートは毎回チェック
      if (currentVersion < minRequiredVersion) {
        _showUpdateDialog(context, data, force: true);
        return;
      }

      // 🔹 任意アップデート
      if (currentVersion < latestVersion) {
        final prefs = await SharedPreferences.getInstance();
        final shownVersion = prefs.getString(_shownVersionKey);

        // すでに表示済みなら出さない
        if (shownVersion == latestVersion.toString()) {
          return;
        }

        _showUpdateDialog(context, data, force: false);

        // 表示済みとして保存
        await prefs.setString(_shownVersionKey, latestVersion.toString());
      }
    } catch (e) {
      debugPrint("Version check failed: $e");
    }
  }

  //アップデートダイアログ
  void _showUpdateDialog(
    BuildContext context,
    Map<String, dynamic> data, {
    required bool force,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: !force,
      builder:
          (_) => AlertDialog(
            title: Text(L10n.of(context)!.main_page_update_info),
            content: Text(data["message"]),
            actions: [
              if (!force)
                TextButton(
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all(
                      Colors.grey[300],
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.of(context)!.main_page_update_later),
                ),
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
                onPressed: () {
                  final url =
                      Platform.isIOS ? data["ios_url"] : data["android_url"];

                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Text(L10n.of(context)!.main_page_update_now),
              ),
            ],
          ),
    );
  }
}

Future<({String? title, String? image})> _fetchPageMeta(String url) async {
  try {
    final response = await http
        .get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return (title: null, image: null);

    final html = utf8.decode(response.bodyBytes, allowMalformed: true);

    // og:title (attribute order variants)
    String? title;
    for (final pattern in [
      RegExp(
        r'''<meta[^>]+property=["']og:title["'][^>]+content=["']([^"'<>]+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta[^>]+content=["']([^"'<>]+)["'][^>]+property=["']og:title["']''',
        caseSensitive: false,
      ),
    ]) {
      final m = pattern.firstMatch(html);
      if (m != null) {
        final t = _decodeHtmlEntities(m.group(1) ?? '');
        if (t.isNotEmpty) { title = t; break; }
      }
    }
    if (title == null) {
      final m = RegExp(
        r'<title[^>]*>([^<]+)</title>',
        caseSensitive: false,
      ).firstMatch(html);
      if (m != null) {
        final t = _decodeHtmlEntities(m.group(1)?.trim() ?? '');
        if (t.isNotEmpty) title = t;
      }
    }

    // og:image (attribute order variants)
    String? image;
    for (final pattern in [
      RegExp(
        r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"'<>]+)["']''',
        caseSensitive: false,
      ),
      RegExp(
        r'''<meta[^>]+content=["']([^"'<>]+)["'][^>]+property=["']og:image["']''',
        caseSensitive: false,
      ),
    ]) {
      final m = pattern.firstMatch(html);
      if (m != null) {
        final img = m.group(1)?.trim() ?? '';
        if (img.isNotEmpty) { image = img; break; }
      }
    }

    return (title: title, image: image);
  } catch (_) {
    return (title: null, image: null);
  }
}

String _decodeHtmlEntities(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&nbsp;', ' ');
