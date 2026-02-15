import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'premium_detail.dart';
import 'favorite_site_provider.dart';

class SmartPlayerPage extends ConsumerStatefulWidget {
  final String url;
  const SmartPlayerPage({super.key, required this.url});

  @override
  ConsumerState<SmartPlayerPage> createState() => _SmartPlayerPageState();
}

class _SmartPlayerPageState extends ConsumerState<SmartPlayerPage> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _ytController;

  bool get isYoutube =>
      widget.url.contains("youtube.com") || widget.url.contains("youtu.be");

  bool get isMp4 => widget.url.toLowerCase().endsWith(".mp4");

  InAppWebViewController? _webController;
  bool _canGoBack = false;

  String? _currentUrl;
  String _pageTitle = '';

  //お気に入りサイトの保存キー
  static const String _favoriteSitesKey = 'favorite_sites';

  //プレミアム判定
  bool _isPremium = false;

  //選択中の評価
  String? selectedRating;

  //ダイアログ専用の評価状態
  String? dialogSelectedRating;

  final List<Map<String, String>> _favoriteSites = [];

  String? _host(String? url) {
    if (url == null) return null;
    return Uri.tryParse(url)?.host;
  }

  @override
  void initState() {
    super.initState();

    _loadFavoriteSites();

    /// MP4
    if (isMp4) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _videoController!.play();
        });
    }

    /// YouTube
    if (isYoutube) {
      final id = YoutubePlayerController.convertUrlToId(widget.url);

      if (id != null) {
        _ytController = YoutubePlayerController.fromVideoId(
          videoId: id,
          autoPlay: true,
          params: const YoutubePlayerParams(showFullscreenButton: true),
        );
      }
    }

    _ytController?.stream.listen((event) {
      if (event.playerState == PlayerState.unknown) {
        _openExternal();
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _ytController?.close();
    _webController = null;
    super.dispose();
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 6,
        backgroundColor: colorScheme.surface,

        // 戻る専用
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (_canGoBack && _webController != null) {
              _webController!.goBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),

        title: Text(
          _pageTitle.isNotEmpty ? _pageTitle : widget.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        actions: [
          IconButton(
            tooltip: L10n.of(context)!.reload,
            icon: const Icon(Icons.refresh),
            onPressed:
                _webController == null ? null : () => _webController!.reload(),
          ),
          _buildIconWithLabel(
            Icons.refresh,
            L10n.of(context)!.reload,
            _webController == null ? null : () => _webController!.reload(),
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
      ),

      body: Center(child: _buildPlayer()),
    );
  }

  Widget _buildPlayer() {
    /// YouTube
    if (isYoutube && _ytController != null) {
      return YoutubePlayer(controller: _ytController!);
    }

    /// MP4
    if (isMp4 &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }

    /// fallback
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      onWebViewCreated: (controller) {
        _webController = controller;
      },
      onLoadStop: (controller, url) async {
        _currentUrl = url.toString();
        _canGoBack = await controller.canGoBack();
        _pageTitle = await controller.getTitle() ?? "";
        //_isFavoritePage = _favoriteSites.any((e) => e["url"] == _currentUrl);

        setState(() {});
      },
    );
  }

  void _openExternal() async {
    await InAppBrowser.openWithSystemBrowser(url: WebUri(widget.url));

    if (mounted) Navigator.pop(context);
  }

  //作品として保存するダイアログ
  Future<void> _showSaveWorkDialog() async {
    //評価をリセット
    selectedRating = null;

    final url = _currentUrl ?? widget.url;

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
                    elevation: MaterialStateProperty.all(0),
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
                    elevation: MaterialStateProperty.all(0),
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

    final result = await _webController!.evaluateJavascript(source: js);

    if (result == null || result.toString() == 'null') return null;

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

  void _toggleFavorite() {
    final url = _currentUrl ?? widget.url;
    if (url == null) return;

    final favorites = ref.read(favoriteSitesProvider);
    final index = favorites.indexWhere((e) => _host(e["url"]) == _host(url));

    // すでに登録済み → 削除確認
    if (index != -1) {
      _showDeleteFavoriteDialog(index);
    } else {
      _showAddFavoriteDialog(initialUrl: url);
    }
  }

  Future<String> _getPageTitle() async {
    if (_webController == null) return widget.url;

    final result = await _webController!.getTitle();
    return result ?? widget.url;
  }

  //テキスト付きアイコン生成
  Widget _buildIconWithLabel(
    IconData icon,
    String label,
    VoidCallback? onPressed, {
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
              ),
              child: Text(L10n.of(context)!.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
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

  //お気に入りサイト - 削除処理
  Future<void> _deleteFavorite(int index) async {
    ref.read(favoriteSitesProvider.notifier).remove(index);
  }

  // お気に入りサイト - 追加ダイアログ本体
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
                style: TextStyle(color: colorScheme.onPrimary),
                decoration: InputDecoration(
                  labelText: L10n.of(context)!.search_page_site_name,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                readOnly: true,
                style: TextStyle(color: colorScheme.onPrimary),
                decoration: InputDecoration(
                  labelText: L10n.of(context)!.url,
                  hintText: 'https://example.com',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                foregroundColor: MaterialStateProperty.all(Colors.black),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context)!.cancel),
            ),
            TextButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                final url = urlController.text.trim();

                if (title.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(L10n.of(context)!.search_page_input_all),
                    ),
                  );
                  return;
                }

                ref.read(favoriteSitesProvider.notifier).add(title, url);

                Navigator.of(context).pop();
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
}
