import 'my_ad_widget_rect.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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

  //final theme = Theme.of(context);

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

    _tabController = TabController(length: 2, vsync: this);

    // Tab → Provider
    _tabController.addListener(() {
      ref.read(listTabIndexProvider.notifier).state = _tabController.index;
    });

    // Provider → Tab（★これが重要）
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
    setState(() {
      _listNames = prefs.getStringList('all_lists') ?? [];
    });
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

  //MainPage から呼び出す用
  void reload() {
    _loadLists();
  }

  @override
  Widget build(BuildContext context) {
    //チュートリアル管理
    final isTutorial = ref.watch(isTutorialModeProvider);
    final step = ref.watch(tutorialStepProvider);

    //ランダム画像更新管理
    final reloadSeed = ref.watch(randomImageReloadProvider);

    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            elevation: 6,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withOpacity(0.2),
            title: Text(
              'ArchiVe',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),

            centerTitle: true,
            //backgroundColor: colorScheme.surface,
            /*
          actions: [
            IconButton(
              onPressed: _loadLists,
              icon: Icon(Icons.refresh),
              color:
                  colorScheme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
            ),
          ],
          */
            bottom: TabBar(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              tabs: [
                Tab(
                  icon: Icon(Icons.folder),
                  text: L10n.of(context)!.list_page_my_list,
                ),
                Tab(
                  icon: Icon(Icons.emoji_events),
                  text: L10n.of(context)!.list_page_my_ranking,
                ),
              ],
              /*
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: colorScheme.primary),
              insets: EdgeInsets.symmetric(horizontal: -95.0),
            ),
            */
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              //unselectedLabelColor: colorScheme.onPrimary,
              unselectedLabelColor:
                  colorScheme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 90,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.7,
                              ),
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            final listNames = [
                              L10n.of(context)!.critical,
                              L10n.of(context)!.normal,
                              L10n.of(context)!.maniac,
                            ];
                            final colors =
                                colorScheme.brightness == Brightness.light
                                    ? [
                                      Colors.red[800]!.withOpacity(1.0),
                                      Colors.yellow[800]!.withOpacity(1.0),
                                      Colors.purple[800]!.withOpacity(1.0),
                                    ]
                                    : [
                                      Colors.red[800]!.withOpacity(0.9),
                                      Colors.yellow[800]!.withOpacity(0.9),
                                      Colors.purple[800]!.withOpacity(0.9),
                                    ];
                            final iconPaths = [
                              'assets/icons/critical.png',
                              'assets/icons/normal.png',
                              'assets/icons/maniac.png',
                            ];
                            final onTapHandlers = [
                              () async {
                                // クリティカル用の処理
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => GridPage(
                                          selectedItems:
                                              <String, List<String>>{},
                                          searchText: '',
                                          rating: 'critical',
                                          listName: '',
                                          onDeleted: () async {
                                            _loadLists();
                                          },
                                        ),
                                  ),
                                );
                              },
                              () async {
                                // ノーマル用の処理
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => GridPage(
                                          selectedItems:
                                              <String, List<String>>{},
                                          searchText: '',
                                          rating: 'normal',
                                          listName: '',
                                          onDeleted: () async {
                                            _loadLists();
                                          },
                                        ),
                                  ),
                                );
                              },
                              () async {
                                // マニアック用の処理
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => GridPage(
                                          selectedItems:
                                              <String, List<String>>{},
                                          searchText: '',
                                          rating: 'maniac',
                                          listName: '',
                                          onDeleted: () async {
                                            _loadLists();
                                          },
                                        ),
                                  ),
                                );
                              },
                            ];
                            return GestureDetector(
                              onTap: () {
                                onTapHandlers[index]();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors[index],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      iconPaths[index],
                                      width: 35,
                                      height: 35,
                                    ),

                                    Text(
                                      listNames[index],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: '',
                                      ),
                                    ),
                                    /*
                                index != 0
                                    ? Image.asset(
                                      iconPaths[index],
                                      width: 20,
                                      height: 20,
                                    )
                                    : const SizedBox.shrink(),
                                    */
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    //プレミアムじゃなければ広告を表示
                    if (!_isPremium) MyAdWidgetRect(),
                    Container(
                      padding: EdgeInsets.all(8.0),
                      alignment: Alignment.bottomCenter,
                      height: 40.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        //color: Color(0xFF121212),
                        color: colorScheme.surface,
                      ),
                      child: Text(
                        L10n.of(context)!.list_page_my_list,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    //const MyNativeAdWidget(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                      /* リストがないときに「全てのアイテム」が表示されないため、削除
                        _listNames.isEmpty
                            ? Center(
                              child: Text(
                                'リストがありません。\nリストを作成してください。',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                ),
                              ),
                            )
                            : 
                            */
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2,
                            ),
                        itemCount:
                            _listNames.length + 1, //+1することで、先頭に「全アイテム」分を追加

                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () async {
                                final isTutorial = ref.read(
                                  isTutorialModeProvider,
                                );
                                final step = ref.read(tutorialStepProvider);

                                if (isTutorial &&
                                    step != TutorialStep.tapList) {
                                  return; // 今はタップさせない
                                }

                                // ここで「全てのアイテム」をタップしたときの処理
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => GridPage(
                                          selectedItems:
                                              <String, List<String>>{},
                                          searchText: '',
                                          rating: '',
                                          listName: '', // ← 特別な値を渡す
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
                                key: ValueKey('all_$reloadSeed'),
                                listName: L10n.of(context)!.all_item_list_name,
                                onDeleted: () async {
                                  await _loadLists();
                                  setState(() {});
                                },
                                onChanged: () async {
                                  await _loadLists();
                                  setState(() {});
                                },
                              ),
                            );
                          }
                          // 1番目以降は通常のリスト表示
                          final listName = _listNames[index - 1]; // -1 でずらす
                          final lastListName = ref.read(
                            tutorialTargetListNameProvider,
                          );

                          // チュートリアル対象なら firstListKey を付与
                          final keyToUse =
                              (listName == lastListName)
                                  ? firstListKey
                                  : ValueKey(listName);

                          return GestureDetector(
                            key: keyToUse,
                            onTap: () async {
                              // GridPageから戻ってきたら続きが実行される
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => GridPage(
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
                              key: ValueKey('${listName}_$reloadSeed'),
                              listName: listName,
                              onDeleted: () async {
                                await _loadLists();
                                setState(() {});
                              },
                              onChanged: () async {
                                await _loadLists();
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Center(child: RankingPage()),
            ],
          ),
          floatingActionButton:
              _tabController.index == 0
                  ? FloatingActionButton(
                    key: fabKey,
                    child: const Icon(Icons.playlist_add, color: Colors.white),
                    /*Text(
                      L10n.of(context)!.list_page_make_list,
                      style: TextStyle(color: Colors.white),
                    ),
                    */
                    onPressed: () {
                      _showAddListModal();
                    },
                  )
                  : null,
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
              // チュートリアルを終了させない
              // GridPage 側で createItem フェーズを進める
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => GridPage(
                        selectedItems: <String, List<String>>{},
                        searchText: '',
                        rating: '',
                        listName:
                            ref
                                .read(tutorialTargetListNameProvider.notifier)
                                .state ??
                            '',
                        onDeleted: () async {
                          await _loadLists();
                        },
                      ),
                ),
              );

              // 戻ってきたらリストを再ロード
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
                backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                foregroundColor: MaterialStateProperty.all(Colors.black),
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

                  if (!existing.contains(listName)) {
                    existing.add(listName);
                    await prefs.setStringList('all_lists', existing);
                  }

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
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
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

    setState(() {
      listRect = offset & box.size;
    });
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

// =======================
// チュートリアル用オーバーレイ（擬似タップ方式）
// =======================
class TutorialOverlayPseudoTap extends StatelessWidget {
  final Rect holeRect;
  final VoidCallback onTap;

  const TutorialOverlayPseudoTap({
    super.key,
    required this.holeRect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}

// =======================
// CustomPainterはそのまま
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
