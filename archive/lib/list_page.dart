import 'my_ad_widget_rect.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'grid_page.dart';
import 'random_image.dart';
import 'floating_button.dart';
import 'detail_page.dart';
import 'ranking_page.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
//import 'my_native_ad_widget.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => ListPageState();
}

class ListPageState extends State<ListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _listNames = [];
  bool _isPremium = false; //サブスク購入状態を保持

  //final theme = Theme.of(context);

  @override
  void initState() {
    super.initState();
    _loadLists();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // タブ変更時に再描画してFAB切り替え
    });
    _checkSubscriptionStatus();
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
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'ArchiVe',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),

          centerTitle: true,
          backgroundColor: colorScheme.surface,
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
            tabs: [
              Tab(icon: Icon(Icons.folder), text: 'マイリスト'),
              Tab(icon: Icon(Icons.emoji_events), text: 'マイランキング'),
            ],
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: colorScheme.primary),
              insets: EdgeInsets.symmetric(horizontal: -95.0),
            ),
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            //unselectedLabelColor: colorScheme.onPrimary,
            unselectedLabelColor:
                colorScheme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
          ),
          elevation: 0,
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
                          final listNames = ['クリティカル', 'ノーマル', 'マニアック'];
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
                                        selectedItems: <String, List<String>>{},
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
                                        selectedItems: <String, List<String>>{},
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
                                        selectedItems: <String, List<String>>{},
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
                      'マイリスト',
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
                      itemCount: _listNames.length + 1, //+1することで、先頭に「全アイテム」分を追加
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return GestureDetector(
                            onTap: () async {
                              // ここで「全てのアイテム」をタップしたときの処理
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => GridPage(
                                        selectedItems: <String, List<String>>{},
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
                              listName: '全てのアイテム',
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
                        return GestureDetector(
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
                            key: ValueKey(listName),
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
                ? SpeedDial(
                  animatedIcon: AnimatedIcons.menu_close,
                  //iconTheme: IconThemeData(color: Colors.white),
                  animatedIconTheme: IconThemeData(color: Colors.white),
                  backgroundColor: colorScheme.primary,
                  overlayColor: colorScheme.secondary,
                  overlayOpacity: 0.5,
                  spacing: 12,
                  spaceBetweenChildren: 8,
                  children: [
                    SpeedDialChild(
                      child: Icon(
                        Icons.playlist_add,
                        color: colorScheme.primary,
                      ),
                      label: 'リストを作成',
                      labelBackgroundColor: colorScheme.secondary,
                      labelShadow: [],
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                      backgroundColor: Colors.white,
                      shape: CircleBorder(),
                      elevation: 2,
                      //labelShadow: ,
                      onTap: () => _showAddListModal(),
                    ),
                    /*
                    SpeedDialChild(
                      child: Icon(Icons.add, color: colorScheme.primary),
                      label: 'アイテムを追加',
                      labelBackgroundColor: colorScheme.secondary,
                      labelShadow: [],
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                      backgroundColor: Colors.white,
                      shape: CircleBorder(),
                      elevation: 2,
                      onTap: () => _showAddItemModal(),
                    ),
                    */
                  ],
                )
                : null,
        floatingActionButtonLocation: CustomFABLocation(),
      ),
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
  void _showAddListModal() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _controller = TextEditingController();
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text('リストを追加', style: TextStyle(color: colorScheme.onPrimary)),
          content: TextField(
            controller: _controller,
            style: TextStyle(color: colorScheme.onPrimary),
            decoration: InputDecoration(
              hintText: 'リスト名を入力',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                foregroundColor: MaterialStateProperty.all(Colors.black),
              ),
              child: Text('キャンセル'),
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
                  setState(() {});
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: Text('追加'),
            ),
          ],
        );
      },
    );
  }

  //====================
  //作品の追加モーダル
  //====================
  void _showAddItemModal() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      backgroundColor: colorScheme.secondary,
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'リストを選択',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            //const Divider(color: Colors.white54, height: 1),
            _listNames.isEmpty
                ? SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      'リストがありません。',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                  ),
                )
                : Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _listNames.length,
                    itemBuilder: (context, index) {
                      final name = _listNames[index];
                      return ListTile(
                        title: Text(
                          name,
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(context, name);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => DetailPage(
                                    listName: name,
                                    onCreated: () async {
                                      _loadLists();
                                    },
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          ],
        );
      },
    );
  }
}
