import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
//import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'l10n/app_localizations.dart';
import 'favorite_site_provider.dart';
import 'list_reload_provider.dart';
import 'save_limit_helper.dart';

class SearchResultPage extends ConsumerStatefulWidget {
  final String initialUrl;
  final String title;

  const SearchResultPage({
    super.key,
    required this.initialUrl,
    required this.title,
  });

  @override
  ConsumerState<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends ConsumerState<SearchResultPage> {
  late final WebViewController _controller;
  bool _canGoBack = false;

  String? _currentUrl;
  String _pageTitle = '';

  //プレミアム判定
  bool _isPremium = false;

  //選択中の評価
  String? selectedRating;

  //ダイアログ専用の評価状態
  String? dialogSelectedRating;

  String? _host(String? url) {
    if (url == null) return null;
    return Uri.tryParse(url)?.host;
  }

  //サムネイル用変数
  String? thumbnailUrl;

  //インターステイシャル広告
  InterstitialAd? _interstitialAd;
  int _saveCount = 0;

  RewardedAd? _rewardedAd;

  //検索履歴リスト
  List<WebHistoryItem> _history = [];

  //プログレスバーの表示
  int _progress = 0;

  //リワード広告のロード
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

          /// ⭐ 見終わったら自動再ロード
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
  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
    _checkSubscriptionStatus();
    _loadAd();

    final initialUrl = _resolveInitialUrl(widget.initialUrl);

    late final PlatformWebViewControllerCreationParams params;

    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const {},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller =
        WebViewController.fromPlatformCreationParams(params)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (progress) {
                setState(() {
                  _progress = progress;
                });
              },

              onPageFinished: (url) async {
                final title = await _getPageTitle();

                //検索履歴を追加
                if (_history.isEmpty || _history.last != url) {
                  _history.add(WebHistoryItem(url, title));
                }

                final canBack = await _controller.canGoBack();

                setState(() {
                  _canGoBack = canBack;
                  _currentUrl = url;
                  _pageTitle = title;
                });
              },
            ),
          )
          ..loadRequest(Uri.parse(initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isFav = ref.watch(
      favoriteSitesProvider.select(
        (list) => list.any((e) => _host(e["url"]) == _host(_currentUrl)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        backgroundColor: colorScheme.surface,

        // 戻る専用
        leading: GestureDetector(
          onTap: () async {
            if (_canGoBack) {
              await _controller.goBack();
            } else {
              Navigator.pop(context);
            }
          },
          onLongPress: () {
            _showHistoryDialog(); // ← 履歴表示
          },
          child: const Padding(
            padding: EdgeInsets.all(12), // タップ領域を確保
            child: Icon(Icons.arrow_back),
          ),
        ),

        title: Text(
          _pageTitle.isNotEmpty ? _pageTitle : widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        actions: [
          _buildIconWithLabel(
            Icons.refresh,
            L10n.of(context)!.reload,
            () => _controller.reload(),
          ),
          _buildIconWithLabel(
            isFav ? Icons.star : Icons.star_border,
            L10n.of(context)!.favorite,
            _toggleFavorite,
          ),
          _buildIconWithLabel(
            Icons.add,
            L10n.of(context)!.save,
            _showSaveWorkDialog,
          ),
          IconButton(
            tooltip: L10n.of(context)!.close,
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child:
              _progress < 100
                  ? LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 2,
                  )
                  : const SizedBox.shrink(),
        ),
      ),

      body: WebViewWidget(controller: _controller),
    );
  }

  // =========================
  // アクション
  // =========================

  Future<String> _getPageTitle() async {
    final result = await _controller.runJavaScriptReturningResult(
      'document.title',
    );
    return result.toString().replaceAll('"', '');
  }

  /*
  Future<String> _getFaviconUrl(String pageUrl) async {
    final uri = Uri.parse(pageUrl);
    return '${uri.scheme}://${uri.host}/favicon.ico';
  }
  */

  //お気にいりボタン押下時処理
  void _toggleFavorite() {
    final url = _currentUrl;
    if (url == null) return;

    final favorites = ref.read(favoriteSitesProvider);
    final index = favorites.indexWhere((e) => _host(e["url"]) == _host(url));

    if (index != -1) {
      _showDeleteFavoriteDialog(index);
    } else {
      _showAddFavoriteDialog(initialUrl: url);
    }
  }

  //お気に入りサイト削除ダイアログ
  Future<void> _showDeleteFavoriteDialog(int index) async {
    final colorScheme = Theme.of(context).colorScheme;
    final favorites = ref.read(favoriteSitesProvider);
    final siteName = favorites[index]["title"] ?? "";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(
            L10n.of(context)!.favorite,
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          content: Text(
            L10n.of(context)!.search_result_page_delete_site(siteName),
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                foregroundColor: MaterialStateProperty.all(Colors.black),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: Text(L10n.of(context)!.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: Text(L10n.of(context)!.delete),
              onPressed: () {
                ref.read(favoriteSitesProvider.notifier).remove(index);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  //URL生成メソッド
  //初期表示時にGoogl動画タブを開く
  String _buildGoogleVideoSearchUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://www.google.com/search?q=$encoded&tbm=vid&safe=off';
  }

  //initialUrlがURLの場合に分岐
  String _resolveInitialUrl(String input) {
    if (input.startsWith('http')) {
      return input; // そのまま表示
    }
    return _buildGoogleVideoSearchUrl(input); // 検索語 → 動画検索
  }

  //作品として保存するダイアログ
  Future<void> _showSaveWorkDialog() async {
    //評価をリセット
    selectedRating = null;

    final url = await _controller.currentUrl();
    if (url == null) return;

    final title = await _getPageTitle();

    final prefs = await SharedPreferences.getInstance();

    // リスト一覧取得
    final allLists = prefs.getStringList('all_lists') ?? [];

    String selectedList = 'none';
    final titleController = TextEditingController(text: title);
    final urlController = TextEditingController(text: url);
    final colorScheme = Theme.of(context).colorScheme;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.secondary,
              title: Text(L10n.of(context)!.search_result_page_saving_as_item),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //サムネ表示
                    /*
                    if (thumbnailUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            thumbnailUrl!,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),*/

                    // 評価
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ratingButton(
                          isSelected: dialogSelectedRating == 'critical',
                          label: L10n.of(context)!.critical,
                          imagePath: 'assets/icons/critical.png',
                          grayPath: 'assets/icons/critical_gray.png',
                          onTap: () {
                            setState(() {
                              dialogSelectedRating =
                                  dialogSelectedRating == 'critical'
                                      ? null
                                      : 'critical';
                            });
                          },
                        ),
                        _ratingButton(
                          isSelected: dialogSelectedRating == 'normal',
                          label: L10n.of(context)!.normal,
                          imagePath: 'assets/icons/normal.png',
                          grayPath: 'assets/icons/normal_gray.png',
                          onTap: () {
                            setState(() {
                              dialogSelectedRating =
                                  dialogSelectedRating == 'normal'
                                      ? null
                                      : 'normal';
                            });
                          },
                        ),
                        _ratingButton(
                          isSelected: dialogSelectedRating == 'maniac',
                          label: L10n.of(context)!.maniac,
                          imagePath: 'assets/icons/maniac.png',
                          grayPath: 'assets/icons/maniac_gray.png',
                          onTap: () {
                            setState(() {
                              dialogSelectedRating =
                                  dialogSelectedRating == 'maniac'
                                      ? null
                                      : 'maniac';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // URL（読み取り専用）
                    TextField(
                      controller: urlController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: L10n.of(context)!.url,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // タイトル
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: L10n.of(context)!.title,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // リスト選択
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedList,
                            decoration: InputDecoration(
                              labelText:
                                  L10n.of(
                                    context,
                                  )!.search_result_page_saving_list,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'none',
                                child: Text(L10n.of(context)!.no_select),
                              ),
                              ...allLists.map(
                                (list) => DropdownMenuItem(
                                  value: list,
                                  child: Text(list),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedList = value ?? 'none';
                              });
                            },
                          ),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            elevation: MaterialStateProperty.all(0),
                            backgroundColor: MaterialStateProperty.all(
                              Colors.grey[300],
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              Colors.black,
                            ),
                          ),
                          onPressed: () async {
                            final nameController = TextEditingController();

                            await showDialog(
                              context:
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).context,
                              builder: (_) {
                                return AlertDialog(
                                  backgroundColor: colorScheme.secondary,
                                  title: Text(
                                    L10n.of(
                                      context,
                                    )!.search_result_page_new_list,
                                  ),
                                  content: TextField(
                                    controller: nameController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText:
                                          L10n.of(
                                            context,
                                          )!.search_result_page_input_list_name,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      style: ButtonStyle(
                                        elevation: MaterialStateProperty.all(0),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                              Colors.grey[300],
                                            ),
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                              Colors.black,
                                            ),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(L10n.of(context)!.cancel),
                                    ),
                                    TextButton(
                                      style: ButtonStyle(
                                        elevation: MaterialStateProperty.all(0),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                              colorScheme.primary,
                                            ),
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                              Colors.white,
                                            ),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final name = nameController.text.trim();
                                        if (name.isEmpty) return;

                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        final lists =
                                            prefs.getStringList('all_lists') ??
                                            [];

                                        // ★ 重複チェック（追加）
                                        if (lists.contains(name)) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                L10n.of(
                                                  context,
                                                )!.search_result_page_list_already_exists,
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          return;
                                        }

                                        // リスト追加
                                        lists.add(name);
                                        await prefs.setStringList(
                                          'all_lists',
                                          lists,
                                        );
                                        // リスト画面に通知
                                        ref
                                            .read(listReloadProvider.notifier)
                                            .state++;

                                        // 評価確定
                                        selectedRating = dialogSelectedRating;

                                        //サムネ取得
                                        thumbnailUrl =
                                            await _getThumbnailFromPage();

                                        // 保存実行
                                        await _saveWorkFromWebView(
                                          url: urlController.text,
                                          title: titleController.text,
                                          listName: name,
                                          thumbnailUrl: thumbnailUrl,
                                        );

                                        if (!context.mounted) return;

                                        Navigator.pop(context); // 新規リスト
                                        Navigator.pop(context); // 保存ダイアログ
                                      },

                                      child: Text(L10n.of(context)!.ok),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            L10n.of(context)!.search_result_page_new_list,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
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
                  child: Text(L10n.of(context)!.cancel), //保存キャンセルボタン
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
                  onPressed: () async {
                    selectedRating = dialogSelectedRating;

                    //サムネ取得
                    thumbnailUrl = await _getThumbnailFromPage();

                    await _saveWorkFromWebView(
                      url: urlController.text,
                      title: titleController.text,
                      listName: selectedList == 'none' ? '' : selectedList,
                      thumbnailUrl: thumbnailUrl,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(L10n.of(context)!.save), //保存ボタン
                ),
              ],
            );
          },
        );
      },
    );
  }

  //評価ボタンのウィジェット
  Widget _ratingButton({
    required bool isSelected,
    required VoidCallback onTap,
    required String label,
    required String imagePath,
    required String grayPath,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Image.asset(
              isSelected ? imagePath : grayPath,
              width: 35,
              height: 35,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getThumbnailFromPage() async {
    final url = await _controller.currentUrl();
    if (url == null) return null;

    // ⭐ YouTube専用
    final ytThumb = _extractYoutubeThumbnail(url);
    if (ytThumb != null) return ytThumb;

    // ⭐ DOM完全読み込み待ち
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final result = await _controller.runJavaScriptReturningResult("""
    (function() {

      function abs(u){
        try { return new URL(u, location.href).href; }
        catch(e){ return u; }
      }

      // ① og:image
      let el = document.querySelector('meta[property="og:image"]');
      if(el?.content) return abs(el.content);

      // ② twitter:image
      el = document.querySelector('meta[name="twitter:image"]');
      if(el?.content) return abs(el.content);

      // ③ itemprop image
      el = document.querySelector('meta[itemprop="image"]');
      if(el?.content) return abs(el.content);

      // ④ video poster
      let v = document.querySelector('video');
      if(v?.poster) return abs(v.poster);

      // ⑤ link image_src
      let link = document.querySelector('link[rel="image_src"]');
      if(link?.href) return abs(link.href);

      // ⑥ 大きい画像優先取得
      let imgs = [...document.images]
        .filter(i => i.width > 200 && i.height > 200)
        .sort((a,b)=> (b.width*b.height)-(a.width*a.height));

      if(imgs.length) return abs(imgs[0].src);

      // ⑦ 最終fallback
      let img = document.querySelector('img');
      if(img?.src) return abs(img.src);

      return null;
    })();
    """);

      if (result == null || result == 'null') return null;

      return result.toString().replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }

  String? _extractYoutubeThumbnail(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    String? id;

    if (uri.host.contains('youtu.be')) {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (uri.host.contains('youtube.com')) {
      id = uri.queryParameters['v'];

      // shorts
      if (id == null && uri.pathSegments.contains('shorts')) {
        id = uri.pathSegments.last;
      }

      // embed
      if (id == null && uri.pathSegments.contains('embed')) {
        id = uri.pathSegments.last;
      }
    }

    if (id == null) return null;

    return "https://img.youtube.com/vi/$id/hqdefault.jpg";
  }

  //追加作品の保存
  Future<void> _saveWorkFromWebView({
    required String url,
    required String title,
    required String listName,
    String? thumbnailUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    //作品数上限チェック
    if (!await SaveLimitHelper.canSave(context, _rewardedAd, ref)) {
      _loadAd();
      return;
    }

    final data = {
      'listName': listName,
      'url': url,
      'title': title,
      'image': thumbnailUrl,
      'memo': '',
      'rating': selectedRating,
    };

    final savedList = prefs.getStringList('saved_metadata') ?? [];

    // 重複URL防止
    final exists = savedList.any((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['url'] == url;
    });

    if (exists) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.search_result_page_url_already_saved),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!exists) {
      savedList.add(jsonEncode(data));
      await prefs.setStringList('saved_metadata', savedList);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L10n.of(context)!.search_result_page_has_saved)),
    );

    //広告表示処理
    await _maybeShowAd();
  }

  static Future<bool> _checkPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['Premium Plan']?.isActive ?? false;
    } catch (e) {
      debugPrint('Subscription check error: $e');
      return false;
    }
  }

  //テキスト付きアイコン生成
  Widget _buildIconWithLabel(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    Key? key,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  //お気に入りサイト追加ダイアログ
  Future<void> _showAddFavoriteDialog({required String initialUrl}) async {
    final titleController = TextEditingController(
      text: getBaseDomain(initialUrl),
    );
    final urlController = TextEditingController(text: getOrigin(initialUrl));

    await showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(
            L10n.of(context)!.search_page_add_favorite,
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: L10n.of(context)!.search_page_site_name,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                readOnly: true,
                decoration: InputDecoration(labelText: L10n.of(context)!.url),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                foregroundColor: MaterialStateProperty.all(Colors.black),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.of(context)!.cancel),
            ),
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              onPressed: () {
                ref
                    .read(favoriteSitesProvider.notifier)
                    .add(
                      titleController.text.trim(),
                      urlController.text.trim(),
                    );
                Navigator.pop(context);
              },
              child: Text(L10n.of(context)!.add),
            ),
          ],
        );
      },
    );
  }

  //URL正規化関数
  String getBaseDomain(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;

    final parts = uri.host.split('.');
    if (parts.length < 2) return uri.host;

    return "${parts[parts.length - 2]}.${parts[parts.length - 1]}";
  }

  String getOrigin(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return "${uri.scheme}://${uri.host}";
  }

  //検索履歴を表示
  // 履歴を表示
  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 上部タイトル
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  L10n.of(context)!.search_result_page_history,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),

              // 🔹 履歴リスト
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = _history.length - 1 - index;
                    final item = _history[reversedIndex];

                    return ListTile(
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        item.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _controller.loadRequest(Uri.parse(item.url));

                        _history = _history.sublist(0, reversedIndex + 1);

                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //=========
  //広告関連
  //=========
  //インターステイシャル広告のロード
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  //広告表示処理
  Future<void> _maybeShowAd() async {
    if (_isPremium) return;

    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt("save_ad_count") ?? 0;

    count++;
    await prefs.setInt("save_ad_count", count);

    // 初回保護（3回未満は広告なし）
    if (count < 3) return;

    final remainder = count % 5;

    // ⭐ 4回目（予告）
    if (remainder == 4) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.search_result_page_ad_remainder01),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // ⭐ 5回目（広告表示）
    if (remainder == 0 && _interstitialAd != null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.search_result_page_ad_remainder02),
          duration: Duration(milliseconds: 800),
        ),
      );

      // 少し待ってから表示（突然感をなくす）
      await Future.delayed(const Duration(milliseconds: 800));

      _interstitialAd!.show();

      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
    }
  }

  String get _adUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-8268997781284735/8554245309"; //本番用
      //return "ca-app-pub-3940256099942544/1033173712"; //テスト用
    } else {
      return "ca-app-pub-8268997781284735/2906478597";
    }
  }

  /// サブスクリプション状態を確認
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

//検索履歴を管理するクラス
class WebHistoryItem {
  final String url;
  final String title;

  WebHistoryItem(this.url, this.title);
}
