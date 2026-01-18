//import 'grid_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_page.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class RankingPage extends StatefulWidget {
  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<Map<String, dynamic>> _rankingItems = [];

  //アイテムリスト
  List<Map<String, dynamic>> itemsToShow = [];

  //検索バーのコントローラー
  TextEditingController _searchController = TextEditingController();

  //検索バーのフォーカス管理
  final FocusNode _searchFocusNode = FocusNode();

  //グリッドアイテム全件保持
  List<Map<String, dynamic>> _allItems = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadRanking();

    // 遷移後のビルド完了時にキーボードを閉じる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.unfocus();
    });

    _loadLocalImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadMetadata() async {
    final prefs = await SharedPreferences.getInstance();

    //'saved_metadata'を取得
    final List<String> jsonList = prefs.getStringList('saved_metadata') ?? [];

    //JSON文字列をMapに変換
    setState(() {
      _allItems =
          jsonList
              .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
              .toList();
      itemsToShow = List.from(_allItems);
      _isLoading = false;
      /*
      itemsToShow =
          jsonList.map((jsonStr) {
            return jsonDecode(jsonStr) as Map<String, dynamic>;
          }).toList();
          */
    });
  }

  //==========
  //メインの処理
  //==========
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // ReorderableListView 部分（スクロール可能）
            Expanded(
              child:
                  _rankingItems.isEmpty
                      ? _buildEmptyRankingState()
                      : ReorderableListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 310,
                        ), // ← 高さ分余白を追加
                        onReorderStart: (index) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ドラッグして順番を変更できます'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        itemCount: _rankingItems.length,
                        itemBuilder: (context, index) {
                          final item = _rankingItems[index];

                          return ListTile(
                            key: ValueKey(item['title']),
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
                              _searchFocusNode.unfocus();
                              _loadMetadata();
                              _loadRanking();
                              setState(() {});
                            },
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (index < 3)
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        color:
                                            [
                                              Colors.amber, // 金
                                              Colors.grey, // 銀
                                              Colors.brown, // 銅
                                            ][index],
                                        size: 36,
                                      ),
                                      Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 2,
                                              offset: Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    alignment: Alignment.center,
                                    width: 36,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                const SizedBox(width: 8),
                                _buildItemImageMini(item),
                                /*
                        item['image'] != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                item['image'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            )
                            : const Icon(Icons.image, size: 40),
                            */
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.grey,
                              ),
                              onPressed: () async {
                                setState(() {
                                  _rankingItems.removeAt(index);
                                });
                                await _saveRanking();
                              },
                            ),
                            title: Text(
                              item['title'] ?? '（タイトルなし）',
                              style: TextStyle(color: colorScheme.onPrimary),
                              maxLines: 2,
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) async {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _rankingItems.removeAt(oldIndex);
                            _rankingItems.insert(newIndex, item);
                          });
                          await _saveRanking();
                        },
                      ),
            ),

            // 固定オーバーレイ（検索バー＋グリッド）
            Container(
              height: 310,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _searchTextField(),
                  const SizedBox(height: 12),
                  _ItemListGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //============
  //検索フィールド
  //============
  Widget _searchTextField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            focusNode: _searchFocusNode,
            controller: _searchController,
            autofocus: false,
            onChanged: (text) {},
            onSubmitted: (text) {
              FocusScope.of(context).unfocus();
              setState(() {
                if (text.trim().isEmpty) {
                  itemsToShow = List.from(_allItems); //空欄なら全件表示
                } else {
                  final query = text.trim().toLowerCase();

                  itemsToShow =
                      _allItems.where((item) {
                        final title =
                            (item['title'] ?? '').toString().toLowerCase();
                        return title.contains(query);
                      }).toList();
                }
              });
              if (text.trim().isEmpty) return;
            },
            cursorColor: Colors.black,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.black),

              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: 'タイトルを検索',
              hintStyle: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            //focusNode: _searchFocusNode,
          ),
        ),
      ],
    );
  }

  //==========
  //グリッド表示
  //==========
  Widget _ItemListGrid() {
    return itemsToShow.isEmpty
        ? const Center(child: Text('保存されたアイテムがありません'))
        : Container(
          height: 75,
          child: GridView.builder(
            scrollDirection: Axis.horizontal, //水平スクロール
            itemCount: itemsToShow.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 0.1,
              crossAxisSpacing: 0.1,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final item = itemsToShow[index];

              return GestureDetector(
                onTap: () async {
                  if (_rankingItems.length >= 10) {
                    // SnackBarなどで通知しても良い
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('最大10個までしか追加できません')));
                    return;
                  }

                  final title = item['title'] ?? '(タイトルなし)';
                  final image = item['image'] ?? '';
                  final exists = _rankingItems.any((e) => e['title'] == title);

                  if (!exists) {
                    setState(() {
                      _rankingItems.add({
                        'title': title,
                        'image': image,
                        'url': item['url'] ?? '',
                        'cast': item['cast'] ?? '',
                        'genre': item['genre'] ?? '',
                        'series': item['series'] ?? '',
                        'label': item['label'] ?? '',
                        'maker': item['maker'] ?? '',
                        'rating': item['rating'], // null OK
                        'memo': item['memo'], // null OK
                        'listName': item['listName'] ?? '',
                      });
                    });
                    await _saveRanking();
                  }
                },
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildItemImage(item),
                      /*
                      item['image'] != null
                          ? Image.network(
                            item['image'],
                            height: 67,
                            //width: 90,
                            //width: double.infinity,
                            fit: BoxFit.cover,
                          )
                          : const Placeholder(fallbackHeight: 67),*/
                      //const SizedBox(height: 12),
                      /*
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            item['title'] ?? '（タイトルなし）',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        */
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }

  Future<void> _saveRanking() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _rankingItems.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('saved_ranking', jsonList);
    setState(() {});
  }

  Future<void> _loadRanking() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('saved_ranking') ?? [];

    setState(() {
      _rankingItems =
          jsonList
              .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
              .toList();
    });
  }

  //ローカル画像のパスを URL ごとに保存
  Map<String, List<String>> _localImagesMap = {};

  // ローカル画像の読み込み
  Future<void> _loadLocalImages() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final Map<String, List<String>> tempMap = {};

    for (final item in itemsToShow) {
      final url = item['url'] ?? '';
      if (url.isEmpty) continue;

      final key = 'local_images_$url';
      final fileNames = prefs.getStringList(key) ?? [];

      // Documentsディレクトリと組み合わせて絶対パスを作成
      tempMap[url] =
          fileNames.map((name) => path.join(directory.path, name)).toList();
    }

    if (mounted) {
      setState(() {
        _localImagesMap = tempMap;
      });
    }
  }

  // 表示優先順位: ネット画像 → ローカル画像 → 画像なしプレースホルダー
  Widget _buildItemImage(Map<String, dynamic> item) {
    final imageUrl = item['image'];
    final url = item['url'] ?? '';
    final localImages = _localImagesMap[url] ?? [];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // ネット画像表示
      return Image.network(
        imageUrl,
        height: 67,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // ネット画像エラー → ローカル画像にフォールバック
          if (localImages.isNotEmpty) {
            return Image.file(
              File(localImages.first),
              height: 67,
              fit: BoxFit.cover,
            );
          }
          return _fallbackNoImage();
        },
      );
    }

    // ネット画像なし → ローカル画像表示
    if (localImages.isNotEmpty) {
      return Image.file(File(localImages.first), height: 67, fit: BoxFit.cover);
    }

    // どちらもなし → No Image
    return _fallbackNoImage();
  }

  Widget _fallbackNoImage() {
    return Container(
      height: 67,
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.photo, color: Colors.white70)),
    );
  }

  //入れ替え可能リスト用に小さい画像を表示
  Widget _buildItemImageMini(Map<String, dynamic> item) {
    final imageUrl = item['image'];
    final url = item['url'] ?? '';
    final localImages = _localImagesMap[url] ?? [];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // ネット画像表示
      return Image.network(
        imageUrl,
        height: 40,
        width: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // ネット画像エラー → ローカル画像にフォールバック
          if (localImages.isNotEmpty) {
            return Image.file(
              File(localImages.first),
              height: 67,
              fit: BoxFit.cover,
            );
          }
          return _fallbackNoImageMini();
        },
      );
    }

    // ネット画像なし → ローカル画像表示
    if (localImages.isNotEmpty) {
      return Image.file(
        File(localImages.first),
        height: 40,
        width: 40,
        fit: BoxFit.cover,
      );
    }

    // どちらもなし → No Image
    return _fallbackNoImageMini();
  }

  Widget _fallbackNoImageMini() {
    return Container(
      height: 40,
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.photo, color: Colors.white70)),
    );
  }

  //アイテムがない場合の表示
  Widget _buildEmptyRankingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'ランキングに作品がありません',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '下の一覧から追加してください',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
