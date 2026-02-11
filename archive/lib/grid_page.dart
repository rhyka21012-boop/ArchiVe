import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'detail_page.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'premium_detail.dart';
import 'l10n/app_localizations.dart';
import 'tutorial_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GridPage extends ConsumerStatefulWidget {
  final Map<String, List<String>> selectedItems;
  final String searchText;
  final String rating;
  final String listName;
  final VoidCallback? onDeleted;

  const GridPage({
    required this.selectedItems,
    required this.searchText,
    required this.rating,
    required this.listName,
    this.onDeleted,
    super.key,
  });

  @override
  ConsumerState<GridPage> createState() => GridPageState();
}

class GridPageState extends ConsumerState<GridPage> {
  //検索されたアイテムリスト
  List<Map<String, dynamic>> _searchedItems = [];
  //ソートされたアイテムリスト
  List<Map<String, dynamic>> _sortedItems = [];

  //ソートボタンの選択値
  List<bool> _sortedMenuSelected = [false, false, false, false, false];

  //スクロール管理
  final ScrollController _scrollController = ScrollController();

  //グリッドビューかリストビューか
  bool _isGridView = true;

  //グリッドの列数
  int _gridCount = 2;

  //ローカル画像のパスを URL ごとに保存
  Map<String, List<String>> _localImagesMap = {};

  bool _isPremium = false; //サブスク購入状態を保持

  // FAB 用
  final GlobalKey fabKey = GlobalKey();
  Rect? fabRect;

  @override
  void initState() {
    super.initState();
    _searchMetadata();
    _loadLocalImages();
    _loadViewSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.watch(tutorialStepProvider) == TutorialStep.tapList) {
        //次のフェーズに進める
        ref.read(tutorialStepProvider.notifier).state = TutorialStep.createItem;
      }

      //FABの位置を取得
      _updateFabRect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var itemsToShow = _searchedItems;

    final tutorialStep = ref.watch(tutorialStepProvider);

    if (_sortedItems.isNotEmpty) {
      itemsToShow = _sortedItems;
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Scaffold(
            //backgroundColor: Color(0xFF121212),
            appBar: AppBar(
              //backgroundColor: Color(0xFF121212),
              title: Text(
                L10n.of(context)!.grid_page_item_count(itemsToShow.length),
              ),
              actions:
              //  ?
              [IconButton(onPressed: _showSortModal, icon: Icon(Icons.sort))],
              // : [],
            ),
            body:
                itemsToShow.isEmpty
                    ? Center(child: Text(L10n.of(context)!.grid_page_no_item))
                    : _isGridView
                    ? GridView.builder(
                      controller: _scrollController,
                      itemCount: itemsToShow.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridCount,
                        mainAxisSpacing: 0.2,
                        crossAxisSpacing: 0.2,
                        childAspectRatio: 1.4,
                      ),
                      itemBuilder: (context, index) {
                        final item = itemsToShow[index];

                        final url = item['url'] ?? '';
                        final localPaths = _localImagesMap[url] ?? [];

                        String? rating = item['rating'];
                        String? iconPath;
                        switch (rating) {
                          case 'critical':
                            iconPath = 'assets/icons/critical.png';
                            break;
                          case 'normal':
                            iconPath = 'assets/icons/normal.png';
                            break;
                          case 'maniac':
                            iconPath = 'assets/icons/maniac.png';
                            break;
                        }

                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DetailPage(
                                      listName: item['listName'],
                                      url: item['url'],
                                      title: item['title'],
                                      image: item['image'],
                                      cast: item['cast'] ?? '',
                                      genre: item['genre'] ?? '',
                                      series: item['series'] ?? '',
                                      label: item['label'] ?? '',
                                      maker: item['maker'] ?? '',
                                      rating: item['rating'],
                                      memo: item['memo'],
                                      isReadOnly: true,
                                    ),
                              ),
                            ).then((_) {
                              setState(() {
                                _searchMetadata();
                              });
                            });
                            // 戻ってきたタイミングでフォーカスを外す
                            FocusScope.of(context).unfocus();
                            if (result == true) (await _searchMetadata());
                          },
                          child: Stack(
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child:
                                          item['image'] != null
                                              ? Image.network(
                                                item['image'],
                                                fit: BoxFit.cover,
                                              )
                                              : placeholderWidget(context),
                                    ),

                                    // 下グラデーション（タイトル可読性）
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          item['title'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              //評価アイコンとリンクボタン
                              /*
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child:
                                          iconPath != null
                                              ? Image.asset(
                                                iconPath,
                                                width: 24,
                                                height: 24,
                                              )
                                              : const SizedBox(
                                                width: 24,
                                                height: 24,
                                              ),
                                    ),

                                    
                                    //リンクボタン
                                    IconButton(
                                      color: colorScheme.onPrimary,
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        final url =
                                            item['url'].toString().trim();
                                        if (url.isNotEmpty &&
                                            await canLaunchUrl(
                                              Uri.parse(url),
                                            )) {
                                          await launchUrl(
                                            Uri.parse(url),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                          return;
                                        }
                                        final encodedUrl = Uri.encodeFull(url);
                                        final _canLaunchAgain = await canLaunch(
                                          encodedUrl,
                                        );
                                        if (!_canLaunchAgain) {
                                          await launchUrl(
                                            Uri.parse(url),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                          return;
                                        }

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              L10n.of(
                                                context,
                                              )!.grid_page_url_unable,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    
                                  ],
                                ),
                              ),
                              */
                            ],
                          ),
                        );
                      },
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: itemsToShow.length,
                      itemBuilder: (context, index) {
                        final item = itemsToShow[index];
                        String? rating = item['rating'];
                        String? iconPath;
                        switch (rating) {
                          case 'critical':
                            iconPath = 'assets/icons/critical.png';
                            break;
                          case 'normal':
                            iconPath = 'assets/icons/normal.png';
                            break;
                          case 'maniac':
                            iconPath = 'assets/icons/maniac.png';
                            break;
                        }

                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DetailPage(
                                      listName: item['listName'],
                                      url: item['url'],
                                      title: item['title'],
                                      image: item['image'],
                                      cast: item['cast'] ?? '',
                                      genre: item['genre'] ?? '',
                                      series: item['series'] ?? '',
                                      label: item['label'] ?? '',
                                      maker: item['maker'] ?? '',
                                      rating: item['rating'],
                                      memo: item['memo'],
                                      isReadOnly: true,
                                    ),
                              ),
                            );
                            FocusScope.of(context).unfocus();
                            if (result == true) (await _searchMetadata());
                          },
                          child: Card(
                            color: colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        item['image'] != null
                                            ? Image.network(
                                              item['image'],
                                              height: 80,
                                              width: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  height: 80,
                                                  width: 90,
                                                  color: Colors.grey[300],
                                                  alignment: Alignment.center,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.broken_image,
                                                        size: 30,
                                                        color: Colors.grey,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        L10n.of(
                                                          context,
                                                        )!.grid_page_cant_load_image,
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            )
                                            : Container(
                                              height: 80,
                                              width: 90,
                                              color: Colors.grey[300],
                                              alignment: Alignment.center,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    size: 30,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    L10n.of(
                                                      context,
                                                    )!.grid_page_cant_load_image,
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 80,

                                      child: Stack(
                                        children: [
                                          // タイトル
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            child: Text(
                                              item['title'] ??
                                                  L10n.of(
                                                    context,
                                                  )!.grid_page_no_title,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // 評価アイコン（右下）
                                          if (iconPath != null)
                                            Positioned(
                                              bottom: 0,
                                              right: 70,
                                              child: Image.asset(
                                                iconPath,
                                                width: 24,
                                                height: 24,
                                              ),
                                            ),
                                          Positioned(
                                            bottom: -12,
                                            right: 0,
                                            child: IconButton(
                                              color: colorScheme.onPrimary,
                                              icon: const Icon(
                                                Icons.open_in_new,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                final url =
                                                    item['url']
                                                        .toString()
                                                        .trim();
                                                if (url.isNotEmpty &&
                                                    await canLaunchUrl(
                                                      Uri.parse(url),
                                                    )) {
                                                  await launchUrl(
                                                    Uri.parse(url),
                                                    mode:
                                                        LaunchMode
                                                            .externalApplication,
                                                  );
                                                  return;
                                                }
                                                final encodedUrl =
                                                    Uri.encodeFull(url);
                                                final _canLaunchAgain =
                                                    await canLaunch(encodedUrl);
                                                if (!_canLaunchAgain) {
                                                  await launchUrl(
                                                    Uri.parse(url),
                                                    mode:
                                                        LaunchMode
                                                            .externalApplication,
                                                  );
                                                  return;
                                                }

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      L10n.of(
                                                        context,
                                                      )!.grid_page_url_unable,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            floatingActionButton: FloatingActionButton(
              key: fabKey,
              onPressed: _onAddPressed,
              backgroundColor: colorScheme.primary,
              shape: CircleBorder(),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),

          // ===== チュートリアル：createItem =====
          if (tutorialStep == TutorialStep.createItem && fabRect != null)
            TutorialOverlayPseudoTap(
              holeRect: fabRect!,
              onTap: () async {
                // 擬似タップ → FAB 処理を呼ぶ
                await _onAddPressed();
              },
            ),

          // 説明バルーン（任意）
          if (tutorialStep == TutorialStep.createItem && fabRect != null)
            Positioned(
              right: 16,
              bottom: fabRect!.height + 80,
              child: _TutorialBalloon(text: L10n.of(context)!.tutorial_03),
            ),
        ],
      ),
    );
  }

  // ===== チュートリアル対応：追加ボタン押下 =====
  Future<void> _onAddPressed() async {
    final limit = await _countSaveLimit();
    final savedCount = await _countSavedItems();
    _isPremium = await _checkPremium();

    if (!_isPremium && savedCount >= limit) {
      await _showSaveLimitDialog(savedCount, limit);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(listName: widget.listName)),
    );
    await _searchMetadata();
  }

  //ローカル画像リストを定義
  List<String> _localImagePaths = [];

  // SharedPreferencesから画像パスを読み込み／保存
  Future<void> _loadLocalImages() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final Map<String, List<String>> tempMap = {};

    for (final item in _searchedItems) {
      final url = item['url'] ?? '';
      if (url.isEmpty) continue;

      final key = 'local_images_$url';
      final fileNames = prefs.getStringList(key) ?? [];

      // Documentsディレクトリの絶対パスと組み合わせる
      tempMap[url] =
          fileNames.map((name) => path.join(directory.path, name)).toList();
    }

    if (mounted) {
      setState(() {
        _localImagesMap = tempMap;
      });
    }
  }

  //===
  //検索
  //===
  Future<void> _searchMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_metadata') ?? [];

    final String text = _normalize(widget.searchText);
    final Map<String, List<String>> filters = widget.selectedItems;
    final String rate = widget.rating;
    final list = widget.listName;

    //if (!mounted) return;

    setState(() {
      _searchedItems =
          data.map((e) => jsonDecode(e) as Map<String, dynamic>).where((item) {
            //final String url = item['url']?.toString() ?? '';
            final String title = _normalize(item['title']?.toString() ?? '');
            final String rating = item['rating']?.toString() ?? '';
            final String listName = item['listName']?.toString() ?? '';

            // 条件①：searchText で検索
            if (text.isNotEmpty) {
              return title.contains(text);
            }

            // 条件②：selectedItems で検索
            if (filters.isNotEmpty) {
              return _matchesSelectedItems(item, filters);
            }

            // 条件③：rating で検索
            if (rate.isNotEmpty) {
              return rating == rate;
            }

            // 条件⑤：listName で検索
            if (list.isNotEmpty) {
              return listName == list;
            }

            // 条件④：指定がない場合、全て表示
            return true;
          }).toList();
    });
  }

  //全角→半角変換、ひらがな→カタカナ変換
  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '') //空白削除
        .replaceAllMapped(
          RegExp(r'[\u3041-\u3096]'), //ひらがな→カタカナ
          (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 0x60),
        );
  }

  bool _matchesSelectedItems(
    Map<String, dynamic> item,
    Map<String, List<String>> filters,
  ) {
    for (var key in filters.keys) {
      final List<String> filterValues = filters[key]!;
      final String fieldValue = item[key]?.toString() ?? '';

      // いずれかの値が item[key] に含まれているかチェック（OR条件）
      final bool hasMatch = filterValues.any(
        (value) => _normalize(fieldValue).contains(_normalize(value)),
      );

      // 一つでも一致しない key があれば AND 条件を満たさない
      if (!hasMatch) return false;
    }
    return true;
  }

  //====================
  //ソートのモーダルウィンドウ
  //====================
  void _showSortModal() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      backgroundColor: colorScheme.secondary,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 60, //キーボード分持ち上げる
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 2列グリッド
                  IconButton(
                    icon: const Icon(Icons.grid_view, size: 32),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        _isGridView && _gridCount == 2
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = true;
                        _gridCount = 2;
                      });
                      _saveViewSettings();
                      Navigator.pop(context);
                    },
                  ),

                  // 3列グリッド
                  IconButton(
                    icon: const Icon(Icons.grid_on, size: 32),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        _isGridView && _gridCount == 3
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = true;
                        _gridCount = 3;
                      });
                      _saveViewSettings();
                      Navigator.pop(context);
                    },
                  ),

                  // リスト表示
                  IconButton(
                    icon: const Icon(Icons.view_list, size: 32),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        !_isGridView ? colorScheme.primary : Colors.transparent,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = false;
                      });
                      _saveViewSettings();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _sortedMenuSelected = [true, false, false, false, false];
                    _sortSearchedItems('titleAsc');
                  });
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _sortedMenuSelected[0]
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  L10n.of(context)!.grid_page_sort_title,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortedMenuSelected = [false, true, false, false, false];
                    _sortSearchedItems('new');
                  });
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _sortedMenuSelected[1]
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  L10n.of(context)!.grid_page_sort_new,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortedMenuSelected = [false, false, true, false, false];
                    _sortSearchedItems('old');
                  });
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _sortedMenuSelected[2]
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  L10n.of(context)!.grid_page_sort_old,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              /*
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortedMenuSelected = [false, false, false, true, false];
                    _sortSearchedItems('countDesc');
                  });
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _sortedMenuSelected[3]
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  L10n.of(context)!.grid_page_sort_count_asc,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortedMenuSelected = [false, false, false, false, true];
                    _sortSearchedItems('countAsc');
                  });
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _sortedMenuSelected[4]
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  L10n.of(context)!.grid_page_sort_count_desc,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              */
            ],
          ),
        );
      },
    );
  }

  //ビュー設定を保存する
  Future<void> _saveViewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGridView', _isGridView);
    await prefs.setInt('gridCount', _gridCount);
  }

  //ビュー設定を読み込む
  Future<void> _loadViewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('isGridView') ?? true;
      _gridCount = prefs.getInt('gridCount') ?? 2;
    });
  }

  //ソートされたリストを返す
  void _sortSearchedItems(String sortType) {
    setState(() {
      switch (sortType) {
        case 'titleAsc': // ① 'title'順
          _sortedItems.sort((a, b) {
            final titleA = (a['title'] ?? '').toString();
            final titleB = (b['title'] ?? '').toString();
            return titleA.compareTo(titleB);
          });
          break;

        case 'new': // ② 元の逆の順番
          _sortedItems = _searchedItems.reversed.toList();
          break;

        case 'old': // ③ 元の順番に戻す
          _sortedItems = List.from(_searchedItems);
          break;
        case 'countDesc': // ④ 視聴数の降順
          _sortedItems = _searchedItems;
          break;
        case 'countAsc': // ⑤ 視聴数の昇順
          _sortedItems = _searchedItems;
          break;
      }
    });
  }

  /*
  // BottomNavigationBarのタップイベント
  void _onItemTapped(int index) {
    if (index == 2) {
      _showAddListModal();
    } else {
      setState(() {
        _selectedIndex = index < 2 ? index : index - 1; //index 2 はスキップ
      });
    }
  }
  */

  //====================
  //視聴数順でソート
  //====================
  /*
  Future<void> _sortByViewingCount() async {
    final prefs = await SharedPreferences.getInstance();

    // itemListは元々表示しているリスト
    itemList.sort((a, b) {
      final aCount = prefs.getInt(a.url) ?? 0;
      final bCount = prefs.getInt(b.url) ?? 0;
      return bCount.compareTo(aCount); // 降順（多い順）
    });

    setState(() {}); // 表示を更新
  }
  */

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

  void _updateFabRect() {
    final context = fabKey.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    setState(() {
      fabRect = offset & box.size;
    });
  }

  Widget placeholderWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceVariant,
      child: Stack(
        children: [
          // 背景パターン（うっすら）
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.video_library,
                size: 120,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // 中央アイコン
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.movie_outlined,
                  size: 40,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  L10n.of(context)!.grid_page_cant_load_image,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//チュートリアル - 案内コメント
class _TutorialBalloon extends StatelessWidget {
  final String text;

  const _TutorialBalloon({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.black, height: 1.4),
        ),
      ),
    );
  }
}
