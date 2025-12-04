import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:convert';
import 'detail_page.dart';
//import 'list_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class GridPage extends StatefulWidget {
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
  State<GridPage> createState() => GridPageState();
}

class GridPageState extends State<GridPage> {
  //検索されたアイテムリスト
  List<Map<String, dynamic>> _searchedItems = [];
  //ソートされたアイテムリスト
  List<Map<String, dynamic>> _sortedItems = [];

  //ソートボタンの選択値
  List<bool> _sortedMenuSelected = [false, false, false, false, false];

  //int _selectedIndex = 0;

  //final GlobalKey<ListPageState> _listPageKey = GlobalKey<ListPageState>();

  //スクロール管理
  final ScrollController _scrollController = ScrollController();

  bool _isGridView = true;
  //bool _showFab = true;

  //bool get _showFab =>
  //    _scrollController.position.userScrollDirection == ScrollDirection.reverse;

  //ローカル画像のパスを URL ごとに保存
  Map<String, List<String>> _localImagesMap = {};

  @override
  void initState() {
    //_scrollController.dispose();
    super.initState();
    _searchMetadata();
    _loadLocalImages();
  }

  /*
    _scrollController.addListener(() {
      final direction = _scrollController.position.userScrollDirection;

      if (direction == ScrollDirection.reverse && _showFab) {
        setState(() {
          _showFab = false;
        });
      } else if (direction == ScrollDirection.forward && !_showFab) {
        setState(() {
          _showFab = true;
        });
      }
    });
    */

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var itemsToShow = _searchedItems;

    if (_sortedItems.isNotEmpty) {
      itemsToShow = _sortedItems;
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        //backgroundColor: Color(0xFF121212),
        appBar: AppBar(
          //backgroundColor: Color(0xFF121212),
          title: Text(
            "${itemsToShow.length}件",
            //style: TextStyle(color: Colors.white),
          ),
          actions:
              widget.listName.isNotEmpty
                  ? [
                    IconButton(
                      //color: Colors.white,
                      onPressed: _showSortModal,
                      icon: Icon(Icons.sort),
                    ),
                  ]
                  : [],
        ),
        body:
            itemsToShow.isEmpty
                ? const Center(child: Text('アイテムがありません'))
                : _isGridView
                ? GridView.builder(
                  controller: _scrollController,
                  itemCount: itemsToShow.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 0.2,
                    crossAxisSpacing: 0.2,
                    childAspectRatio: 0.7,
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
                            /*
                            margin: EdgeInsets.only(
                              top: 0.2,
                              left: 0,
                              right: 0,
                            ),*/
                            color: colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                item['image'] != null
                                    ? Image.network(
                                      item['image'],
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          height: 100,
                                          color: Colors.grey[300],
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                '画像を読み込めません',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                    //サムネイルがない場合、ローカル画像またはプレースホルダーを表示
                                    : (localPaths.isNotEmpty
                                        ? Image.file(
                                          File(localPaths.first),
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          height: 100,
                                          color: Colors.grey[300],
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                '画像を読み込めません',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    item['title'] ?? '（タイトルなし）',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      //color: Colors.white,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                IconButton(
                                  color: colorScheme.onPrimary,
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                  onPressed: () async {
                                    final url = item['url'].toString().trim();
                                    if (url.isNotEmpty &&
                                        await canLaunchUrl(Uri.parse(url))) {
                                      await launchUrl(
                                        Uri.parse(url),
                                        mode: LaunchMode.externalApplication,
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
                                        mode: LaunchMode.externalApplication,
                                      );
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('有効なURLではありません'),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Icon(
                                                    Icons.broken_image,
                                                    size: 30,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    '画像を読み込めません',
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
                                            children: const [
                                              Icon(
                                                Icons.broken_image,
                                                size: 30,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                '画像を読み込めません',
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
                                          item['title'] ?? '（タイトルなし）',
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
                                                item['url'].toString().trim();
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
                                            final encodedUrl = Uri.encodeFull(
                                              url,
                                            );
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
                                              const SnackBar(
                                                content: Text('有効なURLではありません'),
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
          onPressed: (() async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailPage(listName: widget.listName),
              ),
            );
            _searchMetadata();
          }),
          backgroundColor: colorScheme.primary,
          shape: CircleBorder(),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
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
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      size: 32,
                      //color: Colors.white
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        _isGridView ? colorScheme.primary : Colors.transparent,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = true; // 表示モードを切り替える
                      });
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.view_list,
                      size: 32,
                      //color: Colors.white
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        _isGridView ? Colors.transparent : colorScheme.primary,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isGridView = false; // 表示モードを切り替える
                      });
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
                  'タイトル順',
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
                  '追加が新しい順',
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
                  '追加が古い順',
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
                  '視聴数が多い順',
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
                  '視聴数が少ない順',
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
}
