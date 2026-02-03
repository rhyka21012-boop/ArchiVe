import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'l10n/app_localizations.dart';
import 'premium_detail.dart';

class SearchResultPage extends StatefulWidget {
  final String initialUrl;
  final String title;

  const SearchResultPage({
    super.key,
    required this.initialUrl,
    required this.title,
  });

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late final WebViewController _controller;
  bool _canGoBack = false;

  String? _currentUrl;
  String _pageTitle = '';
  bool _isFavoritePage = false;

  //お気に入りサイトの保存キー
  static const String _favoriteSitesKey = 'favorite_sites';

  //プレミアム判定
  bool _isPremium = false;

  //選択中の評価
  String? selectedRating;

  //ダイアログ専用の評価状態
  String? dialogSelectedRating;

  final List<Map<String, String>> _favoriteSites = [];

  @override
  void initState() {
    super.initState();

    _loadFavoriteSites();

    final initialUrl = _resolveInitialUrl(widget.initialUrl);

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) async {
                final canBack = await _controller.canGoBack();
                final title = await _getPageTitle();

                setState(() {
                  _canGoBack = canBack;
                  _currentUrl = url;
                  _pageTitle = title;
                  _isFavoritePage = _isFavorite(url);
                });
              },
            ),
          )
          ..loadRequest(Uri.parse(initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        backgroundColor: colorScheme.surface,

        // 戻る専用
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (_canGoBack) {
              _controller.goBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),

        title: Text(
          _pageTitle.isNotEmpty ? _pageTitle : widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        actions: [
          IconButton(
            tooltip: L10n.of(context)!.reload,
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            tooltip: L10n.of(context)!.favorite,
            icon: Icon(_isFavoritePage ? Icons.star : Icons.star_border),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            tooltip: L10n.of(context)!.search_result_page_save_as_item,
            icon: const Icon(Icons.add),
            onPressed: _showSaveWorkDialog,
          ),
          IconButton(
            tooltip: L10n.of(context)!.close,
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
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

  bool _isFavorite(String url) {
    final host = Uri.tryParse(url)?.host;
    if (host == null) return false;

    return _favoriteSites.any((s) {
      final favHost = Uri.tryParse(s['url'] ?? '')?.host;
      return favHost == host;
    });
  }

  Future<void> _saveSite() async {
    final url = await _controller.currentUrl();
    if (url == null) return;

    final title = await _getPageTitle();
    //final favicon = await _getFaviconUrl(url);

    setState(() {
      _favoriteSites.add({
        'title': title.isNotEmpty ? title : Uri.parse(url).host,
        'url': url,
      });
      _isFavoritePage = true;
    });

    await _saveFavoriteSites();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L10n.of(context)!.search_result_page_site_saved)),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_currentUrl == null) return;

    final currentHost = Uri.parse(_currentUrl!).host;

    if (_isFavoritePage) {
      setState(() {
        _favoriteSites.removeWhere((s) {
          final host = Uri.tryParse(s['url'] ?? '')?.host;
          return host == currentHost;
        });
        _isFavoritePage = false;
      });
    } else {
      //final favicon = await _getFaviconUrl(_currentUrl!);

      setState(() {
        _favoriteSites.add({
          'title': _pageTitle.isNotEmpty ? _pageTitle : currentHost,
          'url': 'https://$currentHost', // ← host正規化
        });
        _isFavoritePage = true;
      });
    }

    await _saveFavoriteSites();
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
                    DropdownButtonFormField<String>(
                      value: selectedList,
                      decoration: InputDecoration(
                        labelText:
                            L10n.of(context)!.search_result_page_saving_list,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'none',
                          child: Text(L10n.of(context)!.no_select),
                        ),
                        ...allLists.map(
                          (list) =>
                              DropdownMenuItem(value: list, child: Text(list)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedList = value ?? 'none';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Colors.grey[300],
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.of(context)!.cancel),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      colorScheme.primary,
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: () async {
                    selectedRating = dialogSelectedRating;

                    //サムネイル取得
                    final thumbnailUrl = await _getThumbnailFromPage();

                    await _saveWorkFromWebView(
                      url: urlController.text,
                      title: titleController.text,
                      listName: selectedList == 'none' ? '' : selectedList,
                      thumbnailUrl: thumbnailUrl,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(L10n.of(context)!.save),
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

  //サムネイルの取得
  Future<String?> _getThumbnailFromPage() async {
    final js = '''
    (function() {
      const og = document.querySelector('meta[property="og:image"]');
      if (og && og.content) return og.content;

      const tw = document.querySelector('meta[name="twitter:image"]');
      if (tw && tw.content) return tw.content;

      return null;
    })();
  ''';

    final result = await _controller.runJavaScriptReturningResult(js);

    if (result == null || result == 'null') return null;

    return result.toString().replaceAll('"', '');
  }

  //追加作品の保存
  Future<void> _saveWorkFromWebView({
    required String url,
    required String title,
    required String listName,
    String? thumbnailUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 保存数チェック
    final limit = await _countSaveLimit();
    final savedCount = await _countSavedItems();
    final isPremium = await _checkPremium();

    if (!isPremium && savedCount >= limit) {
      await _showSaveLimitDialog(savedCount, limit);
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
      SnackBar(
        content: Text(L10n.of(context)!.search_result_page_save_as_item),
      ),
    );
  }

  //*************
  //保存数の上限管理
  //*************
  //保存数の上限をカウント
  Future<int> _countSaveLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final extraSaveLimit = prefs.getInt('extra_save_limit') ?? 0;
    return 100 + extraSaveLimit;
  }

  //作品数カウント
  Future<int> _countSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];
    return list.length;
  }

  //作品数上限オーバー時の案内ダイアログ
  Future<void> _showSaveLimitDialog(int count, int limit) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(L10n.of(context)!.save_limit_dialog_title),
          content: Text(
            L10n.of(context)!.save_limit_dialog_description(limit, count),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context)!.back),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!await PremiumGate.ensurePremium(context)) return;

                setState(() {
                  _isPremium = true;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      L10n.of(context)!.save_limit_dialog_already_purchased,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.star, color: Color(0xFFB8860B)),
              label: Text(
                L10n.of(context)!.save_limit_dialog_premium_detail,
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
          ],
        );
      },
    );
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

  //=====================
  //SharedPreferrence処理
  //=====================
  Future<void> _saveFavoriteSites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _favoriteSites.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_favoriteSitesKey, jsonList);
  }

  Future<void> _loadFavoriteSites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoriteSitesKey) ?? [];

    setState(() {
      _favoriteSites
        ..clear()
        ..addAll(jsonList.map((e) => Map<String, String>.from(jsonDecode(e))));
    });
  }
}
