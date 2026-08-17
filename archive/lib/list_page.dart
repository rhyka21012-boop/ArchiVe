import 'dart:convert';
import 'app_group_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'grid_page.dart';
import 'random_image.dart';
import 'floating_button.dart';
import 'ranking_page.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'l10n/app_localizations.dart';
import 'tutorial_page.dart';
import 'list_tab_index_provider.dart';
import 'random_image_reload_provider.dart';
import 'list_reload_provider.dart';
import 'rating_label_provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'theme_provider.dart';

// 一覧画面の外側余白
const double _kListPageHPadding = 20.0;

class ListPage extends ConsumerStatefulWidget {
  const ListPage({super.key});

  @override
  ConsumerState<ListPage> createState() => ListPageState();
}

class ListPageState extends ConsumerState<ListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _listNames = [];
  bool _isPremium = false; //サブスク購入状態を保持
  bool _isPro = false;

  // 保存数バッジ用
  int _savedCount = 0;
  int _saveLimit = 100;

  // 評価別カウント
  int _criticalCount = 0;
  int _normalCount = 0;
  int _maniacCount = 0;

  // 並べ替えモード
  bool _reorderMode = false;

  late final ProviderSubscription<int> _tabSub;

  //FABのグローバルキー
  final fabKey = GlobalKey();
  Rect? fabRect;

  //チュートリアルで作成したリストのグローバルキー
  final GlobalKey firstListKey = GlobalKey();
  Rect? listRect;

  @override
  void initState() {
    super.initState();

    _loadLists();

    //リスト一覧の更新をlisten
    ref.listenManual<int>(listReloadProvider, (prev, next) {
      _loadLists();
    });

    _tabController = TabController(length: 2, vsync: this);

    // Tab → Provider
    _tabController.addListener(() {
      ref.read(listTabIndexProvider.notifier).state = _tabController.index;
    });

    // Provider → Tab
    _tabSub = ref.listenManual<int>(listTabIndexProvider, (prev, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFabRect();
    });

    _checkSubscriptionStatus();
  }

  @override
  void dispose() {
    _tabSub.close();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    final metadata = prefs.getStringList('saved_metadata') ?? [];
    final extra = prefs.getInt('extra_save_limit') ?? 0;

    int cCritical = 0;
    int cNormal = 0;
    int cManiac = 0;
    for (final s in metadata) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final r = map['rating']?.toString() ?? '';
        if (r == 'critical') {
          cCritical++;
        } else if (r == 'normal') {
          cNormal++;
        } else if (r == 'maniac') {
          cManiac++;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _listNames = prefs.getStringList('all_lists') ?? [];
      _savedCount = metadata.length;
      _saveLimit = 100 + extra;
      _criticalCount = cCritical;
      _normalCount = cNormal;
      _maniacCount = cManiac;
    });

    // Share Extension がリスト一覧を読めるよう App Groups に同期する
    AppGroupService.syncAllLists(_listNames);
  }

  /// サブスクリプション状態を確認
  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium =
          customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false;
      final isPro =
          customerInfo.entitlements.all["Pro Plan"]?.isActive ?? false;

      if (!mounted) return;

      setState(() {
        _isPremium = isPremium;
        _isPro = isPro;
      });
    } catch (e) {
      debugPrint("Error fetching subscription status: $e");
    }
  }

  //MainPage から呼び出す用
  void reload() {
    _loadLists();
    _checkSubscriptionStatus();
  }

  /// アプリタイトル（サブスク状態に応じて変化）
  Widget _buildAppTitle(ColorScheme colorScheme) {
    final label = _isPro
        ? 'ArchiVe Pro'
        : _isPremium
            ? 'ArchiVe Premium'
            : 'ArchiVe';

    return Text(
      label,
      style: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  /// 保存数バッジ（右上）
  Widget _buildSaveCountBadge(ColorScheme colorScheme, bool isDark) {
    final label = _isPremium
        ? '${L10n.of(context)!.save} $_savedCount / ∞'
        : '${L10n.of(context)!.save} $_savedCount / $_saveLimit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kListPageHPadding,
        8,
        _kListPageHPadding,
        4,
      ),
      child: Row(
        children: [
          Expanded(child: _buildAppTitle(colorScheme)),
          _buildSaveCountBadge(colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme, bool isDark) {
    // outer padding を 20 に固定、labelPadding は右側のみで
    // 1つ目のタブの文字先頭が ArchiVe タイトル・リストカードと同じ x に揃うようにする
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kListPageHPadding),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.only(right: 24),
        dividerColor: Colors.transparent,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        // 選択中のラベル文字色は他の見出しと同じ黒/白系 (indicator の下線だけがテーマカラー)
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: isDark ? Colors.white70 : Colors.grey[500],
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: L10n.of(context)!.list_page_home),
          Tab(text: L10n.of(context)!.list_page_my_ranking),
        ],
      ),
    );
  }

  Widget _buildRatingCards(ColorScheme colorScheme, bool isDark) {
    // ライト: 濃い彩度のベタ塗り、ダーク: 若干トーンダウンした彩度
    final labels = ref.watch(ratingLabelsProvider);
    final specs = <_RatingSpec>[
      _RatingSpec(
        label: ratingLabelOf(context, labels, kRatingCritical),
        count: _criticalCount,
        rating: kRatingCritical,
        bg: isDark ? const Color(0xFFB0201F) : const Color(0xFFC62828),
      ),
      _RatingSpec(
        label: ratingLabelOf(context, labels, kRatingNormal),
        count: _normalCount,
        rating: kRatingNormal,
        bg: isDark ? const Color(0xFFD08A15) : const Color(0xFFF5A623),
      ),
      _RatingSpec(
        label: ratingLabelOf(context, labels, kRatingManiac),
        count: _maniacCount,
        rating: kRatingManiac,
        bg: isDark ? const Color(0xFF5E1A85) : const Color(0xFF7B1FA2),
      ),
    ];

    return SizedBox(
      height: 80,
      child: Row(
        children: [
          for (int i = 0; i < specs.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _ratingCard(specs[i], colorScheme, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _ratingCard(_RatingSpec spec, ColorScheme colorScheme, bool isDark) {
    return Material(
      color: spec.bg,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.32),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GridPage(
                    selectedItems: <String, List<String>>{},
                    searchText: '',
                    rating: spec.rating,
                    listName: '',
                    onDeleted: () async {
                      await _loadLists();
                    },
                  ),
                ),
              );
              await _loadLists();
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 10, _reorderMode ? 32 : 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    spec.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${spec.count}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: L10n.of(context)!.list_page_item_unit,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_reorderMode)
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showRatingRenameDialog(spec),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRatingRenameDialog(_RatingSpec spec) async {
    final controller = TextEditingController(text: spec.label);
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(
            L10n.of(context)!.list_page_rating_rename_title,
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: colorScheme.onPrimary),
            decoration: InputDecoration(
              hintText: L10n.of(context)!.list_page_input_list_name,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await ref
                    .read(ratingLabelsProvider.notifier)
                    .setLabel(spec.rating, null);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: Text(
                L10n.of(context)!.reset,
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                L10n.of(context)!.cancel,
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(ratingLabelsProvider.notifier)
                    .setLabel(spec.rating, controller.text);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(L10n.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, bool isDark) {
    final userListCount = _listNames.length + 1; // 「全てのアイテム」を含める
    final subColor = colorScheme.onPrimary.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              L10n.of(context)!.list_page_my_list,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          Text(
            L10n.of(context)!.list_page_item_count(userListCount),
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('・', style: TextStyle(fontSize: 12, color: subColor)),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              setState(() {
                _reorderMode = !_reorderMode;
              });
              if (_reorderMode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(L10n.of(context)!.list_page_reorder_hint),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                _reorderMode
                    ? L10n.of(context)!.list_page_reorder_done
                    : L10n.of(context)!.list_page_reorder,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingListCard({
    required Key keyToUse,
    required bool isAllItem,
    required String listName,
    required int reloadSeed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.32),
      child: GestureDetector(
        key: keyToUse,
        onTap: _reorderMode
            ? null
            : () async {
                if (isAllItem) {
                  final isTutorial = ref.read(isTutorialModeProvider);
                  final step = ref.read(tutorialStepProvider);

                  if (isTutorial && step != TutorialStep.tapList) {
                    return;
                  }
                }

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GridPage(
                      selectedItems: <String, List<String>>{},
                      searchText: '',
                      rating: '',
                      listName: listName,
                      onDeleted: () async {
                        await _loadLists();
                      },
                    ),
                  ),
                );

                await _loadLists();
                setState(() {});
              },
        child: RandomImageContainer(
          key: ValueKey('${isAllItem ? "all" : listName}_$reloadSeed'),
          listName:
              isAllItem ? L10n.of(context)!.all_item_list_name : listName,
          onDeleted: () async {
            await _loadLists();
            setState(() {});
          },
          onChanged: () async {
            await _loadLists();
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildListsGrid(
    ColorScheme colorScheme,
    bool isDark,
    int reloadSeed,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
          ),
          itemCount: _listNames.length + 1, //+1で「全てのアイテム」
          itemBuilder: (context, index) {
            final isAllItem = index == 0;
            final listName = isAllItem ? '' : _listNames[index - 1];
            final lastListName = ref.read(tutorialTargetListNameProvider);
            final keyToUse = isAllItem
                ? ValueKey('all_$reloadSeed')
                : (listName == lastListName
                    ? firstListKey
                    : ValueKey(listName));

            return AnimatedDelay(
              delay: Duration(milliseconds: index * 100),
              child: _buildFloatingListCard(
                keyToUse: keyToUse,
                isAllItem: isAllItem,
                listName: listName,
                reloadSeed: reloadSeed,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReorderableLists(
    ColorScheme colorScheme,
    bool isDark,
    int reloadSeed,
  ) {
    // 通常グリッドと同じレイアウト（2列 / タブレット3列）を保ったまま並べ替える。
    // 「全てのアイテム」は先頭固定で、ドラッグしても位置が変わらないよう
    // onReorder 内で index 0 が絡む操作をブロックする。
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        return ReorderableGridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
          ),
          dragWidgetBuilderV2: DragWidgetBuilderV2(
            isScreenshotDragWidget: false,
            builder: (index, child, screenshot) {
              return Material(
                color: Colors.transparent,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                child: child,
              );
            },
          ),
          itemCount: _listNames.length + 1,
          itemBuilder: (context, index) {
            final isAllItem = index == 0;
            final listName = isAllItem ? '' : _listNames[index - 1];
            // ReorderableGridView は itemBuilder が返す最上位 Widget に key を要求する
            return KeyedSubtree(
              key: ValueKey(
                isAllItem ? 'reorder_all_$reloadSeed' : 'reorder_$listName',
              ),
              child: _buildFloatingListCard(
                keyToUse: ValueKey(
                  isAllItem
                      ? 'reorder_all_inner_$reloadSeed'
                      : 'reorder_inner_$listName',
                ),
                isAllItem: isAllItem,
                listName: listName,
                reloadSeed: reloadSeed,
              ),
            );
          },
          onReorder: (oldIndex, newIndex) async {
            // 「全てのアイテム」を動かす／先頭に差し込む操作は無効化しユーザーに通知
            if (oldIndex == 0 || newIndex == 0) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content:
                        Text(L10n.of(context)!.list_page_all_item_fixed),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              return;
            }
            setState(() {
              final item = _listNames.removeAt(oldIndex - 1);
              _listNames.insert(newIndex - 1, item);
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('all_lists', _listNames);
            AppGroupService.syncAllLists(_listNames);
          },
        );
      },
    );
  }

  Widget _buildMyListsTab(
    ColorScheme colorScheme,
    bool isDark,
    int reloadSeed,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: _kListPageHPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _buildRatingCards(colorScheme, isDark),
          const SizedBox(height: 20),
          _buildSectionHeader(colorScheme, isDark),
          const SizedBox(height: 8),
          _reorderMode
              ? _buildReorderableLists(colorScheme, isDark, reloadSeed)
              : _buildListsGrid(colorScheme, isDark, reloadSeed),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //チュートリアル管理
    final isTutorial = ref.watch(isTutorialModeProvider);
    final step = ref.watch(tutorialStepProvider);

    //ランダム画像更新管理
    final reloadSeed = ref.watch(randomImageReloadProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bgColor = isDark ? colorScheme.surface : kHomeSurfaceLight;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(colorScheme, isDark),
                _buildTabBar(colorScheme, isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyListsTab(colorScheme, isDark, reloadSeed),
                      Center(child: RankingPage()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: ListPageFAB(
            fabKey: fabKey,
            onPressed: _showAddListModal,
          ),
          floatingActionButtonLocation: CustomFABLocation(),
        ),
        // ===== チュートリアル用オーバーレイ =====
        //①FAB
        if (isTutorial && step == TutorialStep.createList && fabRect != null)
          TutorialOverlayPseudoTap(
            holeRect: fabRect!,
            onTap: () {
              _startCreateListTutorial();
            },
          ),

        //②リスト
        if (isTutorial && step == TutorialStep.tapList && listRect != null)
          TutorialOverlayPseudoTap(
            holeRect: listRect!,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GridPage(
                    selectedItems: <String, List<String>>{},
                    searchText: '',
                    rating: '',
                    listName: ref
                            .read(tutorialTargetListNameProvider.notifier)
                            .state ??
                        '',
                    onDeleted: () async {
                      await _loadLists();
                    },
                  ),
                ),
              );

              await _loadLists();
              setState(() {});
            },
          ),

        // ===== 説明テキスト =====
        //①FAB
        if (isTutorial && step == TutorialStep.createList)
          Positioned(
            bottom: 250,
            right: 16,
            child: _TutorialBalloon(text: L10n.of(context)!.tutorial_01),
          ),

        //②リスト
        if (isTutorial && step == TutorialStep.tapList && listRect != null)
          Positioned(
            left: listRect!.left,
            top: listRect!.top - 70,
            child: _TutorialBalloon(text: L10n.of(context)!.tutorial_02),
          ),
      ],
    );
  }

  //=== リスト内アイテム操作（必要なら static に） ===

  static Future<void> addItemToList(String listName, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'list_$listName';

    final existingList = prefs.getStringList(key) ?? [];
    if (!existingList.contains(itemId)) {
      existingList.add(itemId);
      await prefs.setStringList(key, existingList);
    }
  }

  static Future<List<String>> getItemsInList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'list_$listName';
    return prefs.getStringList(key) ?? [];
  }

  //====================
  //マイリストの追加モーダル
  //====================
  void _showAddListModal({bool tutorialMode = false}) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _controller = TextEditingController();
        final colorScheme = Theme.of(context).colorScheme;

        if (tutorialMode)
          _controller.text = L10n.of(context)!.tutorial_list_name;

        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(
            L10n.of(context)!.list_page_add_list,
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          content: TextField(
            controller: _controller,
            style: TextStyle(color: colorScheme.onPrimary),
            decoration: InputDecoration(
              hintText: L10n.of(context)!.list_page_input_list_name,
              hintStyle: TextStyle(color: Colors.grey),
            ),
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
              onPressed: () async {
                final listName = _controller.text.trim();
                if (listName.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final existing = prefs.getStringList('all_lists') ?? [];

                  if (existing.contains(listName)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          L10n.of(context)!
                              .search_result_page_list_already_exists,
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  existing.add(listName);
                  await prefs.setStringList('all_lists', existing);

                  Navigator.pop(context);
                  await _loadLists();

                  if (tutorialMode) {
                    ref.read(tutorialTargetListNameProvider.notifier).state =
                        listName;
                    ref.read(tutorialStepProvider.notifier).state =
                        TutorialStep.tapList;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _updateListRect();
                    });
                  }

                  setState(() {});
                }
              },
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
              child: Text(L10n.of(context)!.add),
            ),
          ],
        );
      },
    );
  }

  //チュートリアル用処理
  void _startCreateListTutorial() {
    _showAddListModal(tutorialMode: true);
  }

  //FABの位置計算
  Rect? getWidgetRect(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  void _updateFabRect() {
    final context = fabKey.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    if (!mounted) return;

    setState(() {
      fabRect = offset & box.size;
    });
  }

  //チュートリアル - 追加したリストのサイズ取得
  void _updateListRect() {
    final context = firstListKey.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    if (!mounted) return;

    setState(() {
      listRect = offset & box.size;
    });
  }
}

class _RatingSpec {
  final String label;
  final int count;
  final String rating;
  final Color bg;

  const _RatingSpec({
    required this.label,
    required this.count,
    required this.rating,
    required this.bg,
  });
}

//チュートリアル - 案内コメント
class _TutorialBalloon extends StatelessWidget {
  final String text;

  const _TutorialBalloon({required this.text});

  @override
  Widget build(BuildContext context) {
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

// =======================
// チュートリアル用オーバーレイ（擬似タップ方式）
// =======================
class TutorialOverlayPseudoTap extends ConsumerWidget {
  final Rect holeRect;
  final VoidCallback onTap;

  const TutorialOverlayPseudoTap({
    super.key,
    required this.holeRect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 半透明 + 穴の見た目
        CustomPaint(size: Size.infinite, painter: _HolePainter(holeRect)),

        // 穴の上に透明なボタンを置く
        Positioned(
          left: holeRect.left,
          top: holeRect.top,
          width: holeRect.width,
          height: holeRect.height,
          child: GestureDetector(
            onTap: onTap,
            child: Container(color: Colors.transparent),
          ),
        ),

        // スキップボタン（左上）
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: TextButton(
            onPressed: () => skipTutorial(context, ref),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              L10n.of(context)!.skip,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =======================
// CustomPainter
// =======================
class _HolePainter extends CustomPainter {
  final Rect hole;

  _HolePainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    final holePaint = Paint()..blendMode = BlendMode.clear;
    final holePath =
        Path()..addRRect(
          RRect.fromRectAndRadius(hole.inflate(8), const Radius.circular(32)),
        );
    canvas.drawPath(holePath, holePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

//グリッドアニメーション
class AnimatedDelay extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const AnimatedDelay({super.key, required this.delay, required this.child});

  @override
  State<AnimatedDelay> createState() => _AnimatedDelayState();
}

class _AnimatedDelayState extends State<AnimatedDelay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

//FAB専用クラス
class ListPageFAB extends ConsumerWidget {
  final VoidCallback onPressed;
  final GlobalKey fabKey;

  const ListPageFAB({super.key, required this.onPressed, required this.fabKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(listTabIndexProvider);

    return Visibility(
      visible: tabIndex == 0,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: FloatingActionButton(
        key: fabKey,
        onPressed: onPressed,
        child: const Icon(Icons.playlist_add, color: Colors.white),
      ),
    );
  }
}
