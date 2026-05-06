import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_page.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'l10n/app_localizations.dart';
import 'my_flutter_app_icons.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<Map<String, dynamic>> _rankingItems = [];
  List<Map<String, dynamic>> itemsToShow = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _allItems = [];
  bool _isLoading = true;
  Map<String, List<String>> _localImagesMap = {};
  bool _panelExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadRanking();
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
    final List<String> jsonList = prefs.getStringList('saved_metadata') ?? [];
    setState(() {
      _allItems =
          jsonList
              .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
              .toList();
      itemsToShow = List.from(_allItems);
      _isLoading = false;
    });
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

  Future<void> _loadLocalImages() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final Map<String, List<String>> tempMap = {};
    for (final item in itemsToShow) {
      final url = item['url'] ?? '';
      if (url.isEmpty) continue;
      final key = 'local_images_$url';
      final fileNames = prefs.getStringList(key) ?? [];
      tempMap[url] =
          fileNames.map((name) => path.join(directory.path, name)).toList();
    }
    if (mounted) {
      setState(() {
        _localImagesMap = tempMap;
      });
    }
  }

  // ─── カラー定数 ────────────────────────────────────────────────
  static const _goldColor = Color(0xFFFFD700);
  static const _silverColor = Color(0xFFB0BEC5);
  static const _bronzeColor = Color(0xFFCD7F32);

  Color _rankColor(int index) {
    if (index == 0) return _goldColor;
    if (index == 1) return _silverColor;
    if (index == 2) return _bronzeColor;
    return Colors.grey.shade400;
  }

  // ─── ビルド ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Builder(
          builder: (context) {
            final bottomInset = MediaQuery.of(context).padding.bottom;
            final panelHeight = _panelExpanded ? _panelExpandedHeight : _panelCollapsedHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.only(bottom: panelHeight + bottomInset),
                    child: _rankingItems.isEmpty ? _buildEmptyState() : _buildList(),
                  ),
                ),
                Positioned(
                  bottom: bottomInset,
                  left: 0,
                  right: 0,
                  child: _buildBottomPanel(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── リスト ────────────────────────────────────────────────────
  Widget _buildList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      onReorderStart: (index) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.ranking_page_dragable),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      itemCount: _rankingItems.length,
      itemBuilder: (context, index) => _buildRankCard(index),
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _rankingItems.removeAt(oldIndex);
          _rankingItems.insert(newIndex, item);
        });
        await _saveRanking();
      },
    );
  }

  Widget _buildRankCard(int index) {
    final item = _rankingItems[index];
    final isTop3 = index < 3;
    final color = _rankColor(index);
    const imgW = 72.0;
    const imgH = 64.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      key: ValueKey('rank_${item['title']}_$index'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: colorScheme.brightness == Brightness.light
          ? Colors.grey[200]
          : const Color(0xFF2C2C2C),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
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
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ─── 左アクセントバー（1〜3位のみ）──────────────
              if (isTop3)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
              // ─── メインコンテンツ ────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // 順位バッジ（1位はクラウン付き）
                      _buildRankBadge(index, color),
                      const SizedBox(width: 10),
                      // サムネイル
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImage(item, imgW, imgH),
                      ),
                      const SizedBox(width: 12),
                      // タイトル・評価
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['title'] ??
                                  L10n.of(context)!.ranking_page_no_title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 削除ボタン
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () async {
                          setState(() => _rankingItems.removeAt(index));
                          await _saveRanking();
                        },
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
  }

  Widget _buildRankBadge(int index, Color color) {
    if (index < 3) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-2, 0),
              child: Icon(MyFlutterApp.crown, size: 20, color: color),
            ),
            Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: 36,
      child: Text(
        '${index + 1}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }


  // ─── 画像ビルダー ──────────────────────────────────────────────
  Widget _buildImage(Map<String, dynamic> item, double width, double height) {
    final imageUrl = item['image'];
    final url = item['url'] ?? '';
    final localImages = _localImagesMap[url] ?? [];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (localImages.isNotEmpty) {
            return Image.file(
              File(localImages.first),
              width: width,
              height: height,
              fit: BoxFit.cover,
            );
          }
          return _noImage(width, height);
        },
      );
    }
    if (localImages.isNotEmpty) {
      return Image.file(
        File(localImages.first),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    return _noImage(width, height);
  }

  Widget _noImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.photo, color: Colors.white70)),
    );
  }

  // ─── 下部パネル（折りたたみ対応）──────────────────────────────
  static const _panelExpandedHeight = 270.0;
  static const _panelCollapsedHeight = 44.0;

  Widget _buildBottomPanel() {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: _panelExpanded ? _panelExpandedHeight : _panelCollapsedHeight,
      decoration: BoxDecoration(
        color: _panelExpanded ? colorScheme.surfaceContainerHigh : Colors.grey.shade200,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── ハンドル（常時表示）──────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _panelExpanded = !_panelExpanded),
              child: SizedBox(
                height: _panelCollapsedHeight,
                child:
                    _panelExpanded
                        // 展開中: ドラッグハンドルバー
                        ? Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )
                        // 折りたたみ中: 「アイテムを追加」ヒント
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              L10n.of(context)!.ranking_page_add_item,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_up,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
              ),
            ),
            // ─── 展開コンテンツ ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildPickerGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      focusNode: _searchFocusNode,
      controller: _searchController,
      autofocus: false,
      onSubmitted: (text) {
        FocusScope.of(context).unfocus();
        setState(() {
          if (text.trim().isEmpty) {
            itemsToShow = List.from(_allItems);
          } else {
            final query = text.trim().toLowerCase();
            itemsToShow =
                _allItems.where((item) {
                  final title = (item['title'] ?? '').toString().toLowerCase();
                  return title.contains(query);
                }).toList();
          }
        });
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
        hintText: L10n.of(context)!.ranking_page_search_title,
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
      ),
    );
  }

  Widget _buildPickerGrid() {
    if (itemsToShow.isEmpty) {
      return Center(
        child: Text(L10n.of(context)!.ranking_page_no_grid_item),
      );
    }
    return SizedBox(
      height: 75,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(L10n.of(context)!.ranking_page_limit_error),
                  ),
                );
                return;
              }
              final title =
                  item['title'] ?? L10n.of(context)!.ranking_page_no_title;
              final exists = _rankingItems.any((e) => e['title'] == title);
              if (!exists) {
                setState(() {
                  _rankingItems.add({
                    'title': title,
                    'image': item['image'] ?? '',
                    'url': item['url'] ?? '',
                    'cast': item['cast'] ?? '',
                    'genre': item['genre'] ?? '',
                    'series': item['series'] ?? '',
                    'label': item['label'] ?? '',
                    'maker': item['maker'] ?? '',
                    'rating': item['rating'],
                    'memo': item['memo'],
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
              child: _buildImage(item, double.infinity, 67),
            ),
          );
        },
      ),
    );
  }

  // ─── 空状態 ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              L10n.of(context)!.ranking_page_no_ranking_item,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.of(context)!.ranking_page_no_ranking_item_description,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
