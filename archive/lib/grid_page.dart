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
import 'random_image_reload_provider.dart';
import 'home_tab_index_provider.dart';
import 'search_tab_index_provider.dart';
import 'search_result_page.dart';

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

  //Youtube形式のグリッド
  bool _isYoutubeGrid = false;

  //ローカル画像のパスを URL ごとに保存
  Map<String, List<String>> _localImagesMap = {};

  bool _isPremium = false; //サブスク購入状態を保持

  //選択中アイテム管理
  Set<int> _selectedIndexes = {};
  bool _isSelectionMode = false;
  bool _selectionAnimating = false;

  Set<int> _removingIndexes = {};

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
                _isSelectionMode
                    ? "${_selectedIndexes.length} seleted" //選択モード中は選択数を表示
                    : L10n.of(
                      context,
                    )!.grid_page_item_count(itemsToShow.length),
              ),
              leading:
                  _isSelectionMode
                      ? IconButton(
                        icon: const Icon(Icons.close), //選択モード中は閉じるアイコンを表示
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIndexes.clear();
                          });
                        },
                      )
                      : null,
              actions:
                  _isSelectionMode
                      ? [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _confirmDeleteSelected,
                        ),
                      ]
                      : [
                        IconButton(
                          onPressed: _showSortModal,
                          icon: Icon(Icons.sort),
                        ),
                      ],
            ),
            body:
                itemsToShow.isEmpty
                    ? Center(
                      child:
                          widget.rating.isNotEmpty
                              /// ⭐ 評価フィルタ表示時
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    size: 64,
                                    color: _getRatingColor(),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    L10n.of(context)!.grid_page_rating_guidance,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                              /// ⭐ 通常リスト表示時
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    L10n.of(context)!.grid_page_no_item,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    L10n.of(context)!.grid_page_add_item,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 24),

                                  /// Web検索追加
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.search),
                                    label: Text(
                                      L10n.of(context)!.grid_page_by_web,
                                    ),
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
                                    onPressed: () {
                                      ref
                                          .read(homeTabIndexProvider.notifier)
                                          .state = 1;
                                      ref
                                          .read(searchTabIndexProvider.notifier)
                                          .state = 0;
                                      Navigator.pop(context);
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  /// 手動追加
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      L10n.of(context)!.grid_page_by_manual,
                                    ),
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
                                    onPressed: _onAddPressed,
                                  ),
                                ],
                              ),
                    )
                    : _isGridView
                    ? GridView.builder(
                      controller: _scrollController,
                      itemCount: itemsToShow.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridCount,
                        mainAxisSpacing: 0.2,
                        crossAxisSpacing: 0.2,
                        childAspectRatio: _isYoutubeGrid ? 0.7 : 1.4,
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
                          onLongPress: () {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedIndexes.add(index);
                            });
                          },
                          onTap: () async {
                            if (_isSelectionMode) {
                              setState(() {
                                if (_selectedIndexes.contains(index)) {
                                  _selectedIndexes.remove(index);
                                  if (_selectedIndexes.isEmpty) {
                                    _isSelectionMode = false;
                                  }
                                } else {
                                  _selectedIndexes.add(index);
                                }
                              });
                              return;
                            }
                            final result = await Navigator.push(
                              context,
                              fadeScaleRoute(
                                DetailPage(
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
                              AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale:
                                    _removingIndexes.contains(index)
                                        ? 0.8
                                        : _selectedIndexes.contains(index)
                                        ? 0.92 // ← 好みで 0.9〜0.95 に調整OK
                                        : 1,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity:
                                      _removingIndexes.contains(index) ? 0 : 1,
                                  child: Card(
                                    elevation: 0,
                                    color:
                                        colorScheme.brightness ==
                                                Brightness.light
                                            ? Colors.grey[200]
                                            : const Color(0xFF2C2C2C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side:
                                          _selectedIndexes.contains(index)
                                              ? BorderSide(
                                                color: colorScheme.primary,
                                                width: 6,
                                              )
                                              : BorderSide.none,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child:
                                        _isYoutubeGrid //Youtube風グリッドUI
                                            ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                /// サムネ（比率 2）
                                                Expanded(
                                                  flex: 3,
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Stack(
                                                      children: [
                                                        Positioned.fill(
                                                          child:
                                                              item['image'] !=
                                                                      null
                                                                  ? Image.network(
                                                                    item['image'],
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                  )
                                                                  : placeholderWidget(
                                                                    context,
                                                                  ),
                                                        ),

                                                        /// 外部リンクボタン
                                                        Positioned(
                                                          right: 6,
                                                          bottom: 6,
                                                          child: GestureDetector(
                                                            onTap:
                                                                () => openPlayer(
                                                                  item['url'],
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    Colors
                                                                        .black54,
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .play_arrow,
                                                                size: 18,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                                /// タイトル（比率 1）
                                                Expanded(
                                                  flex: 2,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          10,
                                                          8,
                                                          10,
                                                          2,
                                                        ),
                                                    child: Text(
                                                      item['title'] ?? '',
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                            /// 大サムネUI
                                            : Stack(
                                              children: [
                                                Positioned.fill(
                                                  child:
                                                      item['image'] != null
                                                          ? Image.network(
                                                            item['image'],
                                                            fit: BoxFit.cover,
                                                          )
                                                          : placeholderWidget(
                                                            context,
                                                          ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end:
                                                            Alignment
                                                                .bottomCenter,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black
                                                              .withOpacity(0.7),
                                                        ],
                                                      ),
                                                    ),
                                                    child: Text(
                                                      item['title'] ?? '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                              ),

                              // 選択モード中の表示
                              if (_isSelectionMode)
                                Positioned.fill(
                                  child: Container(
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        child:
                                            _selectedIndexes.contains(index)
                                                ? Icon(
                                                  Icons.check_circle,
                                                  color: colorScheme.primary,
                                                  size: 28,
                                                )
                                                : Icon(
                                                  Icons.radio_button_unchecked,
                                                  color: Colors.white,
                                                  key: ValueKey(false),
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
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
                              fadeScaleRoute(
                                DetailPage(
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
                            elevation: 0,
                            color:
                                colorScheme.brightness == Brightness.light
                                    ? Colors.grey[200]
                                    : const Color(0xFF2C2C2C),
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
              backgroundColor: _getRatingColor(),
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
      fadeScaleRoute(DetailPage(listName: widget.listName)),
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

  //******** */
  //削除処理
  //******** */
  Future<void> _confirmDeleteSelected() async {
    if (_selectedIndexes.isEmpty) return;

    final colorScheme = Theme.of(context).colorScheme;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.secondary,
            title: Center(
              child: Text(
                L10n.of(context)!.detail_page_delete_confirm01,
                textAlign: TextAlign.center,
              ),
            ),
            content: Text(
              L10n.of(
                context,
              )!.grid_page_items_selected_delete(_selectedIndexes.length),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                  foregroundColor: MaterialStateProperty.all(Colors.black),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: Text(L10n.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: ButtonStyle(
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
                child: Text(L10n.of(context)!.delete),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    final prefs = await SharedPreferences.getInstance();

    final savedList = prefs.getStringList('saved_metadata') ?? [];
    final rankingList = prefs.getStringList('saved_ranking') ?? [];

    /// 選択中URL一覧取得
    final itemsToShow = _sortedItems.isNotEmpty ? _sortedItems : _searchedItems;

    final selectedUrls =
        _selectedIndexes.map((i) => itemsToShow[i]['url']).toSet();

    /// metadata削除
    final updatedList =
        savedList.where((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return !selectedUrls.contains(map['url']);
        }).toList();

    /// ranking削除
    final updatedRanking =
        rankingList
            .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
            .where((item) => !selectedUrls.contains(item['url']))
            .map((item) => jsonEncode(item))
            .toList();

    await prefs.setStringList('saved_metadata', updatedList);
    await prefs.setStringList('saved_ranking', updatedRanking);

    /// 削除対象保存
    final removing = Set<int>.from(_selectedIndexes);

    setState(() {
      _removingIndexes.addAll(removing);
    });

    await Future.delayed(const Duration(milliseconds: 250));

    await _searchMetadata();

    setState(() {
      _sortedItems.clear();
      _removingIndexes.clear();
      _selectedIndexes.clear();
      _isSelectionMode = false;
    });
  }

  //動画再生処理
  void openPlayer(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultPage(initialUrl: url, title: url),
      ),
    );
  }

  //評価ごとの色
  Color _getRatingColor() {
    switch (widget.rating) {
      case 'critical':
        return Colors.red[800]!;
      case 'normal':
        return Colors.yellow[800]!;
      case 'maniac':
        return Colors.purple[800]!;
      default:
        return Theme.of(context).colorScheme.primary;
    }
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
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all(
                        _isGridView && _gridCount == 2 && !_isYoutubeGrid
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isYoutubeGrid = false;
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
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all(
                        _isGridView && _gridCount == 3 && !_isYoutubeGrid
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isYoutubeGrid = false;
                        _isGridView = true;
                        _gridCount = 3;
                      });
                      _saveViewSettings();
                      Navigator.pop(context);
                    },
                  ),

                  // YouTube風3列グリッド
                  IconButton(
                    icon: const Icon(Icons.video_library, size: 32),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        _isYoutubeGrid
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = true;
                        _gridCount = 3;
                        _isYoutubeGrid = true;
                      });
                      _saveViewSettings();
                      Navigator.pop(context);
                    },
                  ),

                  // リスト表示
                  IconButton(
                    icon: const Icon(Icons.view_list, size: 32),
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.all(
                        !_isGridView ? colorScheme.primary : Colors.transparent,
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = false;
                        _isYoutubeGrid = false;
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
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(
                    _sortedMenuSelected[0]
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(
                    _sortedMenuSelected[1]
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(
                    _sortedMenuSelected[2]
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                elevation: MaterialStateProperty.all(0),
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
                elevation: MaterialStateProperty.all(0),
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
    await prefs.setBool('youtubeGrid', _isYoutubeGrid);
  }

  //ビュー設定を読み込む
  Future<void> _loadViewSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('isGridView') ?? true;
      _gridCount = prefs.getInt('gridCount') ?? 2;
      _isYoutubeGrid = prefs.getBool('youtubeGrid') ?? false;
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
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.secondary,
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

  //画面遷移のアニメーション
  Route fadeScaleRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
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
