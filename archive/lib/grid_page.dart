import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'l10n/app_localizations.dart';
import 'tutorial_page.dart';
import 'detail_page.dart';
import 'random_image_reload_provider.dart';
import 'home_tab_index_provider.dart';
import 'search_tab_index_provider.dart';
import 'search_result_page.dart';
import 'save_limit_helper.dart';
import 'pro_detail.dart';
import 'share_dialog.dart';
import 'sync_service.dart';
import 'list_reload_provider.dart';
// import 'my_native_ad_widget.dart'; // 一覧内ネイティブ広告は廃止
import 'theme_provider.dart';
import 'rating_label_provider.dart';
import 'circle_app_bar_icon.dart';
import 'local_video_player_page.dart';
import 'mini_player_provider.dart';
import 'offline_indicators.dart';
import 'browser_session_provider.dart';
import 'offline_cleanup.dart';

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
  List<bool> _sortedMenuSelected = [false, true, false, false, false]; // 既定は new
  // 現在のソートキー (AppBar チップに表示、拡張ソート対応)
  String _sortKey = 'new';

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
    _searchMetadata();
    _loadLocalImages();
    _loadViewSettings();
    _loadAd();

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
  void dispose() {
    //_tabController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var itemsToShow = _searchedItems;

    final tutorialStep = ref.watch(tutorialStepProvider);

    if (_sortedItems.isNotEmpty) {
      itemsToShow = _sortedItems;
    }

    final isDark = colorScheme.brightness == Brightness.dark;
    final pageBg = isDark ? colorScheme.surface : kHomeSurfaceLight;
    final sectionName = _sectionName();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: pageBg,
            appBar: AppBar(
              backgroundColor: pageBg,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: _isSelectionMode
                  ? Text("${_selectedIndexes.length} seleted")
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            sectionName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          L10n.of(context)!
                              .grid_page_item_count(itemsToShow.length),
                          style: TextStyle(
                            fontSize: 12,
                            color: (isDark ? Colors.white : Colors.black87)
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
              leading: _isSelectionMode
                  ? CircleAppBarIcon(
                      icon: Icons.close,
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedIndexes.clear();
                        });
                      },
                    )
                  : CircleAppBarIcon(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
              actions: _isSelectionMode
                  ? [
                      CircleAppBarIcon(
                        icon: Icons.drive_file_move,
                        tooltip: L10n.of(context)!.grid_page_move_action,
                        onPressed: () => _moveSelectedToList(itemsToShow),
                      ),
                      CircleAppBarIcon(
                        icon: Icons.delete,
                        onPressed: _confirmDeleteSelected,
                      ),
                      const SizedBox(width: 4),
                    ]
                  : [
                      CircleAppBarIcon(
                        icon: Icons.share,
                        onPressed: () => _openShareDialog(itemsToShow),
                      ),
                      // 現在のソート順を表示するチップ + 並び替えメニュー呼び出し
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _showSortModal,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sort,
                                      size: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 120),
                                    child: Text(
                                      _sortLabel(),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.arrow_drop_down,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
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
                    ? LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth >= 600; //タブレット判定
                        final effectiveGridCount =
                            isTablet
                                ? _gridCount + 1
                                : _gridCount; //タブレットの場合のグリッド数
                        final childAspectRatio = isTablet
                            ? (_isYoutubeGrid ? 0.8 : 1.6)
                            : (_isYoutubeGrid ? 0.7 : 1.4);

                        // 一覧内ネイティブ広告は廃止（コメントアウト）
                        // const adInterval = 10;
                        // final adCount = _isPremium
                        //     ? 0
                        //     : itemsToShow.length ~/ adInterval;
                        final totalCount = itemsToShow.length;

                        return CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: effectiveGridCount,
                                    mainAxisSpacing: 0.2,
                                    crossAxisSpacing: 0.2,
                                    childAspectRatio: childAspectRatio,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, displayIndex) {
                                  // 広告セル判定（廃止）
                                  // if (!_isPremium &&
                                  //     displayIndex > 0 &&
                                  //     (displayIndex + 1) % (adInterval + 1) ==
                                  //         0) {
                                  //   return const GridCardNativeAd();
                                  // }
                                  return _buildGridItem(
                                    context,
                                    displayIndex,
                                    colorScheme,
                                  );
                                },
                                childCount: totalCount,
                              ),
                            ),
                            // Android の 3 ボタンナビや FAB と被らないよう
                            // 底部にセーフエリア + 追加スペースを確保
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.bottom + 96,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: itemsToShow.length,
                      itemBuilder: (context, index) {
                        if (index >= itemsToShow.length) {
                          return const SizedBox.shrink();
                        }
                        final item = itemsToShow[index];
                        return _buildListItem(context, item, index, isDark, colorScheme);
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

  /// グリッドアイテムのカードを構築（YouTube風 or 大サムネ）
  Widget _buildGridItem(
    BuildContext context,
    int index,
    ColorScheme colorScheme,
  ) {
    // build() と同じ優先順で並び替え結果を反映
    final itemsToShow =
        _sortedItems.isNotEmpty ? _sortedItems : _searchedItems;
    if (index < 0 || index >= itemsToShow.length) {
      return const SizedBox.shrink();
    }
    final item = itemsToShow[index];

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
        FocusScope.of(context).unfocus();
        if (result == true) (await _searchMetadata());
      },
      child: Stack(
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: _removingIndexes.contains(index)
                ? 0.8
                : _selectedIndexes.contains(index)
                    ? 0.92
                    : 1,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _removingIndexes.contains(index) ? 0 : 1,
              child: Card(
                elevation: colorScheme.brightness == Brightness.dark ? 0 : 4,
                shadowColor: Colors.black.withValues(alpha: 0.32),
                color: colorScheme.brightness == Brightness.light
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: _selectedIndexes.contains(index)
                      ? BorderSide(color: colorScheme.primary, width: 6)
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                child: _isYoutubeGrid
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: item['image'] != null
                                        ? CachedNetworkImage(
                                            imageUrl: item['image'],
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) =>
                                                placeholderWidget(context),
                                          )
                                        : placeholderWidget(context),
                                  ),
                                  // 前回シークバーのみサムネ上端に重ねる
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: OfflineProgressBar(item: item),
                                  ),
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 再生ボタンの左に「サイズ + DL 済み」を並べる
                                        OfflineInlineChips(item: item),
                                        if (_hasLocalVideo(item))
                                          const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => openPlayer(item['url']),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                              child: Text(
                                item['title'] ?? '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: item['image'] != null
                                ? CachedNetworkImage(
                                    imageUrl: item['image'],
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        placeholderWidget(context),
                                  )
                                : placeholderWidget(context),
                          ),
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
                          // 前回シークバーのみサムネ上端に重ねる
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: OfflineProgressBar(item: item),
                          ),
                          // 再生ボタンの左に「サイズ + DL 済み」を並べる
                          Positioned(
                            right: 6,
                            bottom: 24,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OfflineInlineChips(item: item),
                                if (_hasLocalVideo(item))
                                  const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => openPlayer(item['url']),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_isSelectionMode)
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: _selectedIndexes.contains(index)
                      ? Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 28,
                        )
                      : const Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.white,
                          key: ValueKey(false),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== チュートリアル対応：追加ボタン押下 =====
  Future<void> _onAddPressed() async {
    _isPremium = await _checkPremium();

    //作品数上限チェック
    if (!await SaveLimitHelper.canSave(context, _rewardedAd, ref)) {
      _loadAd();
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

    // ローカル動画がある場合、前回中断位置と duration も prefs から hydrate する
    Map<String, dynamic> hydrate(Map<String, dynamic> item) {
      final url = item['url']?.toString();
      if (url == null || url.isEmpty) return item;
      if (item['localVideoPath'] == null) return item;
      final pos = prefs.getInt('offline_pos_$url');
      final dur = prefs.getInt('offline_dur_$url');
      if (pos != null) item['offlinePosSec'] = pos;
      if (dur != null) item['offlineDurSec'] = dur;
      return item;
    }

    setState(() {
      _searchedItems =
          data.map((e) => hydrate(jsonDecode(e) as Map<String, dynamic>)).where((item) {
            //final String url = item['url']?.toString() ?? '';
            final String title = _normalize(item['title']?.toString() ?? '');
            final String rating = item['rating']?.toString() ?? '';
            final String listName = item['listName']?.toString() ?? '';

            // 条件①：searchText で検索 (title + タグ系 + memo を横断)
            if (text.isNotEmpty) {
              const fields = [
                'cast',
                'genre',
                'series',
                'maker',
                'label',
                'memo',
              ];
              if (title.contains(text)) return true;
              for (final k in fields) {
                final v = _normalize(item[k]?.toString() ?? '');
                if (v.contains(text)) return true;
              }
              return false;
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
  Future<void> _moveSelectedToList(
    List<Map<String, dynamic>> itemsToShow,
  ) async {
    if (_selectedIndexes.isEmpty) return;

    final colorScheme = Theme.of(context).colorScheme;
    final prefs = await SharedPreferences.getInstance();
    final allLists = prefs.getStringList('all_lists') ?? [];
    // 「選択なし」も移動先として含める
    final candidates = <String>['選択なし', ...allLists];

    if (!mounted) return;
    final targetList = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Text(L10n.of(ctx)!.grid_page_move_to_list_title),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (_, i) {
                final name = candidates[i];
                final isCurrent = name == widget.listName;
                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  leading: Icon(
                    isCurrent ? Icons.check : Icons.folder_outlined,
                    size: 20,
                    color: isCurrent ? colorScheme.primary : null,
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 14)),
                  enabled: !isCurrent,
                  onTap: () => Navigator.pop(ctx, name),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
              foregroundColor: WidgetStateProperty.all(Colors.black),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            child: Text(L10n.of(ctx)!.cancel),
          ),
        ],
      ),
    );
    if (targetList == null || !mounted) return;

    final selectedUrls =
        _selectedIndexes.map((i) => itemsToShow[i]['url'] as String).toSet();

    // Undo 用：移動前の URL → 元の listName を保存
    final originalListNames = <String, String>{};
    final savedList = prefs.getStringList('saved_metadata') ?? [];
    final updatedList = savedList.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final url = map['url'] as String?;
      if (url != null && selectedUrls.contains(url)) {
        originalListNames[url] = (map['listName'] as String?) ?? '選択なし';
        map['listName'] = targetList;
        SyncService.upsertItem(map);
      }
      return jsonEncode(map);
    }).toList();
    await prefs.setStringList('saved_metadata', updatedList);

    if (!mounted) return;
    final movedCount = selectedUrls.length;
    setState(() {
      _isSelectionMode = false;
      _selectedIndexes.clear();
    });
    await _searchMetadata();
    ref.read(listReloadProvider.notifier).state++;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$movedCount${L10n.of(context)!.grid_page_move_done}',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.grey[300],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: L10n.of(context)!.undo,
          textColor: Colors.black,
          onPressed: () => _undoMove(originalListNames),
        ),
      ),
    );
  }

  /// 直前の移動を元に戻す
  Future<void> _undoMove(Map<String, String> originalListNames) async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_metadata') ?? [];
    final restoredList = savedList.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final url = map['url'] as String?;
      if (url != null && originalListNames.containsKey(url)) {
        map['listName'] = originalListNames[url];
        SyncService.upsertItem(map);
      }
      return jsonEncode(map);
    }).toList();
    await prefs.setStringList('saved_metadata', restoredList);
    if (!mounted) return;
    await _searchMetadata();
    ref.read(listReloadProvider.notifier).state++;
  }

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

    /// オフライン動画ファイル + 位置 prefs を先に削除 (metadata がまだあるうちに)
    await OfflineCleanup.forUrls(selectedUrls.whereType<String>());

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

  // ダウンロード済みかどうか (アイテムのマップから判定)
  bool _hasLocalVideo(Map<String, dynamic> item) {
    final p = item['localVideoPath'] as String?;
    if (p == null || p.isEmpty) return false;
    try {
      return File(p).existsSync();
    } catch (_) {
      return false;
    }
  }

  // オフライン動画のファイルサイズ (URL 単位で結果をキャッシュ)
  final Map<String, int?> _offlineSizeCache = {};
  Future<int?> _getOfflineFileSize(Map<String, dynamic> item) async {
    final url = item['url']?.toString();
    if (url == null || url.isEmpty) return null;
    if (_offlineSizeCache.containsKey(url)) return _offlineSizeCache[url];
    final p = item['localVideoPath'] as String?;
    if (p == null || p.isEmpty) {
      _offlineSizeCache[url] = null;
      return null;
    }
    try {
      final f = File(p);
      if (!await f.exists()) {
        _offlineSizeCache[url] = null;
        return null;
      }
      final len = await f.length();
      _offlineSizeCache[url] = len;
      return len;
    } catch (_) {
      _offlineSizeCache[url] = null;
      return null;
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  // "#a #b #c" 形式のテキストからタグを最大 max 個抽出
  List<String> _firstTags(String? raw, {int max = 2}) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final parts = raw
        .split(RegExp(r'\s*#\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length <= max) return parts;
    return parts.sublist(0, max);
  }

  /// リスト表示の 1 アイテム
  Widget _buildListItem(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
    bool isDark,
    ColorScheme colorScheme,
  ) {
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

    final title = (item['title']?.toString().isNotEmpty ?? false)
        ? item['title'].toString()
        : L10n.of(context)!.grid_page_no_title;
    final tags = <String>[
      ..._firstTags(item['cast']?.toString(), max: 2),
      ..._firstTags(item['genre']?.toString(), max: 1),
    ];
    final hasLocal = _hasLocalVideo(item);
    final selected = _selectedIndexes.contains(index);

    final card = Card(
      elevation: isDark ? 0 : 3,
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.15)
          : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (_isSelectionMode) {
            setState(() {
              if (selected) {
                _selectedIndexes.remove(index);
                if (_selectedIndexes.isEmpty) _isSelectionMode = false;
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
          );
          FocusScope.of(context).unfocus();
          if (result == true) await _searchMetadata();
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedIndexes.add(index);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // サムネ 64x64 正方形
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: item['image'] != null
                      ? CachedNetworkImage(
                          imageUrl: item['image'],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image,
                                size: 24, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image,
                              size: 24, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // 中央: タイトル + タグ + ファイルサイズ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (final t in tags)
                            Text(
                              '#$t',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (hasLocal)
                      FutureBuilder<int?>(
                        future: _getOfflineFileSize(item),
                        builder: (_, snap) {
                          if (snap.data == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download_done,
                                  size: 11,
                                  color: Colors.green.shade500,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _formatBytes(snap.data!),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // 右: 評価アイコン + 再生ボタン
              if (iconPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Image.asset(iconPath, width: 22, height: 22),
                ),
              GestureDetector(
                onTap: () => openPlayer(item['url']),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 選択モード中はスワイプ無効
    if (_isSelectionMode) return card;

    return Dismissible(
      key: ValueKey('list-item-${item['url']}-$index'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.drive_file_move_outline, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // 右スワイプ: 別リストへ移動
          await _moveSingleToList(item);
          return false; // Dismissible は削除しない (再ロード側で反映)
        } else {
          // 左スワイプ: 削除
          return await _confirmDeleteSingle(item);
        }
      },
      child: card,
    );
  }

  Future<void> _moveSingleToList(Map<String, dynamic> item) async {
    final url = item['url']?.toString();
    if (url == null) return;
    final prefs = await SharedPreferences.getInstance();
    final allLists = prefs.getStringList('all_lists') ?? [];
    final candidates = <String>['選択なし', ...allLists];
    if (!mounted) return;
    final target = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.of(ctx)!.grid_page_move_to_list_title),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (_, i) {
                final name = candidates[i];
                final isCurrent = name == widget.listName;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isCurrent ? Icons.check : Icons.folder_outlined,
                    size: 20,
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 14)),
                  enabled: !isCurrent,
                  onTap: () => Navigator.pop(ctx, name),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(L10n.of(ctx)!.cancel)),
        ],
      ),
    );
    if (target == null || !mounted) return;
    final savedList = prefs.getStringList('saved_metadata') ?? [];
    String? originalListName;
    final updated = savedList.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      if (m['url'] == url) {
        originalListName = (m['listName'] as String?) ?? '選択なし';
        m['listName'] = target;
        SyncService.upsertItem(m);
      }
      return jsonEncode(m);
    }).toList();
    await prefs.setStringList('saved_metadata', updated);
    if (!mounted) return;
    await _searchMetadata();
    ref.read(listReloadProvider.notifier).state++;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('1${L10n.of(context)!.grid_page_move_done}'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: originalListName == null
              ? null
              : SnackBarAction(
                  label: L10n.of(context)!.undo,
                  onPressed: () =>
                      _undoMove({url: originalListName!}),
                ),
        ),
      );
  }

  Future<bool> _confirmDeleteSingle(Map<String, dynamic> item) async {
    final url = item['url']?.toString();
    if (url == null) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(L10n.of(dctx)!.detail_page_delete_confirm01),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(L10n.of(dctx)!.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: Text(L10n.of(dctx)!.delete)),
        ],
      ),
    );
    if (ok != true) return false;
    // オフラインファイル削除 + メタデータ削除
    await OfflineCleanup.forUrls([url]);
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];
    final filtered = list.where((s) {
      try {
        return (jsonDecode(s) as Map<String, dynamic>)['url'] != url;
      } catch (_) {
        return true;
      }
    }).toList();
    await prefs.setStringList('saved_metadata', filtered);
    if (mounted) await _searchMetadata();
    ref.read(listReloadProvider.notifier).state++;
    return true;
  }

  //動画再生処理
  void openPlayer(String url) {
    final queue = _sortedItems.isNotEmpty ? _sortedItems : _searchedItems;
    final index = queue.indexWhere((item) => item['url'] == url);
    final safeIndex = index >= 0 ? index : 0;

    // ローカル動画があれば内蔵プレイヤーで再生
    final item = queue[safeIndex];
    if (_hasLocalVideo(item)) {
      final path = item['localVideoPath'] as String;
      // GlobalPlayerLayer で再生開始 (Navigator.push 不使用)
      ref.read(miniPlayerProvider.notifier).start(
            filePath: path,
            title: item['title']?.toString() ?? '',
            itemUrl: item['url']?.toString(),
          );
      return;
    }

    // オンライン動画: 既存のアプリ内ブラウザに新規タブとして開く
    ref.read(browserSessionProvider.notifier).requestOpen(
          queue[safeIndex]['url']?.toString() ?? url,
          title: queue[safeIndex]['title']?.toString() ?? '',
          playlistItems: queue,
          playlistIndex: safeIndex,
        );
  }

  // AppBar に表示するセクション名 (リスト名 / 評価名 / 全てのアイテム)
  String _sectionName() {
    if (widget.listName.isNotEmpty) return widget.listName;
    if (widget.rating.isNotEmpty) {
      final labels = ref.watch(ratingLabelsProvider);
      return ratingLabelOf(context, labels, widget.rating);
    }
    return L10n.of(context)!.all_item_list_name;
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
  Future<void> _openShareDialog(List<Map<String, dynamic>> items) async {
    // Pro 未加入なら、購入を促すダイアログを表示
    final isPro = await ProGate.isPro();
    if (!mounted) return;
    if (!isPro) {
      final shouldPurchase = await _showProRequiredDialog();
      if (shouldPurchase != true || !mounted) return;
      if (!await ProGate.ensureProPurchaseFirst(context)) return;
      if (!mounted) return;
    }

    await showDialog(
      context: context,
      builder: (_) => ShareDialog(
        listName: widget.listName,
        items: items,
      ),
    );
  }

  /// 公開リスト共有が Pro 限定であることを伝えるダイアログ
  Future<bool?> _showProRequiredDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final l = L10n.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Text(
          l.share_pro_required_title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00695C),
          ),
        ),
        content: Text(l.share_pro_required_description),
        actions: [
          TextButton(
            style: ButtonStyle(
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
              foregroundColor: WidgetStateProperty.all(Colors.black),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.of(ctx)!.cancel),
          ),
          TextButton(
            style: ButtonStyle(
              elevation: WidgetStateProperty.all(0),
              backgroundColor:
                  WidgetStateProperty.all(const Color(0xFF00695C)),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.share_pro_required_action),
          ),
        ],
      ),
    );
  }

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
              // 拡張ソート
              const Divider(height: 12),
              _sortModalButton(context,
                  key: 'rating', label: L10n.of(context)!.grid_page_sort_rating),
              _sortModalButton(context,
                  key: 'offlineFirst',
                  label: L10n.of(context)!.grid_page_sort_offline_first),
              _sortModalButton(context,
                  key: 'listName',
                  label: L10n.of(context)!.grid_page_sort_list_name),
              _sortModalButton(context,
                  key: 'byCast',
                  label: L10n.of(context)!.grid_page_sort_by_cast),
              _sortModalButton(context,
                  key: 'random',
                  label: L10n.of(context)!.grid_page_sort_random),
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
      _gridCount = prefs.getInt('gridCount') ?? 3;
      _isYoutubeGrid = prefs.getBool('youtubeGrid') ?? true;
    });
  }

  //ソートされたリストを返す
  Future<void> _sortSearchedItems(String sortType) async {
    _sortKey = sortType;
    final source = List<Map<String, dynamic>>.from(_searchedItems);
    switch (sortType) {
      case 'titleAsc':
        source.sort((a, b) => (a['title'] ?? '')
            .toString()
            .compareTo((b['title'] ?? '').toString()));
        break;
      case 'new':
        // 既存の「_searchedItems の逆順」= 新しい順
        source
          ..clear()
          ..addAll(_searchedItems.reversed);
        break;
      case 'old':
        // _searchedItems のまま = 古い順
        break;
      case 'countDesc':
      case 'countAsc': {
        final prefs = await SharedPreferences.getInstance();
        source.sort((a, b) {
          final ca = prefs.getInt((a['url'] ?? '').toString()) ?? 0;
          final cb = prefs.getInt((b['url'] ?? '').toString()) ?? 0;
          return sortType == 'countDesc' ? cb.compareTo(ca) : ca.compareTo(cb);
        });
        break;
      }
      case 'rating': {
        const order = {'critical': 0, 'normal': 1, 'maniac': 2};
        source.sort((a, b) {
          final ra = order[a['rating']] ?? 99;
          final rb = order[b['rating']] ?? 99;
          return ra.compareTo(rb);
        });
        break;
      }
      case 'offlineFirst':
        source.sort((a, b) {
          final oa = _hasLocalVideo(a) ? 0 : 1;
          final ob = _hasLocalVideo(b) ? 0 : 1;
          return oa.compareTo(ob);
        });
        break;
      case 'listName':
        source.sort((a, b) => (a['listName'] ?? '')
            .toString()
            .compareTo((b['listName'] ?? '').toString()));
        break;
      case 'random':
        source.shuffle();
        break;
      case 'byCast':
        source.sort((a, b) {
          final firstA = _firstTags(a['cast']?.toString(), max: 1);
          final firstB = _firstTags(b['cast']?.toString(), max: 1);
          final ka = firstA.isEmpty ? '￿' : firstA.first;
          final kb = firstB.isEmpty ? '￿' : firstB.first;
          return ka.compareTo(kb);
        });
        break;
      case 'byDate':
        // 既定 = 新しい順 (追加日は _searchedItems の順序で保存されている想定)
        source
          ..clear()
          ..addAll(_searchedItems.reversed);
        break;
    }
    if (!mounted) return;
    setState(() {
      _sortedItems = source;
    });
  }

  /// 拡張ソート用の共通ボタン
  Widget _sortModalButton(BuildContext context,
      {required String key, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = _sortKey == key;
    return TextButton(
      onPressed: () {
        // 既存の _sortedMenuSelected は 5 要素固定なのでクリア (全 false)
        _sortedMenuSelected = [false, false, false, false, false];
        _sortSearchedItems(key);
        Navigator.pop(context);
      },
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(
          active ? colorScheme.primary : Colors.transparent,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 現在のソートキーの表示ラベル
  String _sortLabel() {
    final l = L10n.of(context)!;
    switch (_sortKey) {
      case 'titleAsc':
        return l.grid_page_sort_title;
      case 'new':
        return l.grid_page_sort_new;
      case 'old':
        return l.grid_page_sort_old;
      case 'countDesc':
        return l.grid_page_sort_count_desc;
      case 'countAsc':
        return l.grid_page_sort_count_asc;
      case 'rating':
        return l.grid_page_sort_rating;
      case 'offlineFirst':
        return l.grid_page_sort_offline_first;
      case 'listName':
        return l.grid_page_sort_list_name;
      case 'random':
        return l.grid_page_sort_random;
      case 'byCast':
        return l.grid_page_sort_by_cast;
      case 'byDate':
        return l.grid_page_sort_by_date;
      default:
        return l.grid_page_sort_new;
    }
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

  static Future<bool> _checkPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      // Premium または Pro のどちらでも「有料 = 広告非表示」扱い
      final isPremium =
          customerInfo.entitlements.all['Premium Plan']?.isActive ?? false;
      final isPro =
          customerInfo.entitlements.all['Pro Plan']?.isActive ?? false;
      return isPremium || isPro;
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

class PlayOverlayButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const PlayOverlayButton({super.key, required this.onTap, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size * 0.35),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.play_arrow, size: size, color: Colors.white),
      ),
    );
  }
}
