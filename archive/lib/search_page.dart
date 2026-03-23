import 'dart:math';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
//import 'package:confetti/confetti.dart';

import 'search_result_page.dart';
import 'grid_page.dart';
import 'detail_page.dart';
import 'l10n/app_localizations.dart';
import 'favorite_site_provider.dart';
import 'search_tab_index_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  //String _searchText = '';
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _savedItems = [];

  //final List<String> _categoryNames = ['出演', 'ジャンル', 'シリーズ', 'レーベル', 'メーカー'];
  final List<String> _searchNames = [
    'cast',
    'genre',
    'series',
    'maker',
    'label',
  ];

  Map<String, bool> _showAllByKey = {}; //チョイスチップの「もっと見る」を管理
  /*
  final List<IconData> _icons = [
    Icons.person,
    Icons.article,
    Icons.auto_stories,
    Icons.star,
    Icons.business,
  ];
  */

  Map<String, List<String>> _optionsByKey = {};
  Map<String, List<bool>> _selectedListByKey = {};

  final GlobalKey _searchBarKey = GlobalKey();

  //お気に入りサイトの選択状態
  int? _selectedFavoriteIndex;

  bool _ignoreNextFocus = false;

  @override
  void initState() {
    super.initState();

    //検索履歴を更新
    _loadSearchHistory();

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        if (_ignoreNextFocus) {
          _ignoreNextFocus = false; // ★一度だけ無視
          return;
        }
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  bool _isMetadataLoaded = false;

  bool get isWeb => ref.read(searchTabIndexProvider) == 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedMetadata();
    _isMetadataLoaded = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  void deactivate() {
    _removeOverlay(); // 他の画面に遷移するときも確実に削除
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    //アプリ内・Webタブ管理
    ref.watch(searchTabIndexProvider);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        //backgroundColor: Color(0xFF121212),
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(right: 8),
            //セグメントボタン
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SegmentedButton<bool>(
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(0),
                    visualDensity: VisualDensity.standard,
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    side: MaterialStateProperty.resolveWith((states) {
                      return BorderSide.none; // 枠線を消す
                    }),
                    backgroundColor: MaterialStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return colorScheme.primary;
                      }
                      return Colors.grey[300];
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return Colors.black;
                    }),
                  ),
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(
                        L10n.of(context)!.search_page_segment_button_app, //アプリ内
                      ), //アプリ内
                      icon: Icon(Icons.apps),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(
                        L10n.of(context)!.search_page_segment_button_web, //Web
                      ), //Web
                      icon: Icon(Icons.public),
                    ),
                  ],
                  selected: {isWeb},
                  onSelectionChanged: (value) {
                    ref.read(searchTabIndexProvider.notifier).state =
                        value.first ? 0 : 1;
                  },
                ),

                /// ルーレットボタン
                IconButton(
                  icon: const Icon(
                    IconData(0xea5c, fontFamily: 'FlutterIcon'),
                    size: 24,
                  ),
                  tooltip: "Random",
                  onPressed: () {
                    if (_savedItems.isEmpty) return;

                    _showRouletteModal();
                  },
                ),
              ],
            ),
          ),
          //backgroundColor: Color(0xFF121212),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchTextField(),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    //クリアボタン
                    ElevatedButton(
                      onPressed: _clearAllSelections,
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(0),
                        backgroundColor: MaterialStateProperty.all(
                          Colors.grey[300],
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          Colors.black,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      child: Text(L10n.of(context)!.clear), //クリア
                    ),
                    SizedBox(width: 8),
                    //検索ボタン
                    ElevatedButton(
                      onPressed: () async {
                        _ignoreNextFocus = true;

                        //検索バーへのフォーカスを外す
                        FocusScope.of(context).unfocus();

                        //検索履歴のオーバーレイを非表示
                        _removeOverlay();

                        //検索文字列
                        final text = _searchController.text.trim();

                        /*
                        if (isWeb && text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                L10n.of(context)!.search_page_text_empty,
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          return; //検索欄が空の場合は何もしない
                        }
                        ;
                        */

                        //選択したカテゴリ数をカウント
                        final selectedCategoryCount =
                            _countSelectedCategories();

                        //複数カテゴリ指定はプレミアム限定
                        if (!isWeb && selectedCategoryCount >= 2) {
                          await _showPremiumInfoDialog();
                          return;
                        }

                        // 選択中のお気に入りURL（なければ null）
                        final favorites = ref.read(favoriteSitesProvider);

                        final String? selectedFavoriteUrl =
                            _selectedFavoriteIndex != null
                                ? favorites[_selectedFavoriteIndex!]['url']
                                : null;

                        _addSearchHistory(text);

                        final bool? updated =
                            isWeb
                                ? await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SearchResultPage(
                                          initialUrl: _buildWebSearchUrl(
                                            text,
                                            selectedFavoriteUrl,
                                          ),
                                          title:
                                              L10n.of(
                                                context,
                                              )!.search_page_web_title,
                                        ),
                                  ),
                                )
                                : await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => GridPage(
                                          selectedItems:
                                              getSelectedItemsByKey(),
                                          searchText: text,
                                          rating: '',
                                          listName: '',
                                        ),
                                  ),
                                );

                        //戻ってきたフレームでunFocusを解除
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _ignoreNextFocus = false;
                        });
                      },
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(0),
                        backgroundColor: MaterialStateProperty.all(
                          colorScheme.primary,
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          Colors.white,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      child: Text(L10n.of(context)!.search_page_search), //検索
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                isWeb ? _buildWebSearchSection() : _buildAppSearchSection(),

                const SizedBox(height: 140),
                /*** UI切り替え箇所End ***/
              ],
            ),
          ),
        ),
      ),
    );
  }

  //====================
  //検索バーのウィジェット
  //====================
  Widget _searchTextField() {
    return Row(
      children: [
        Expanded(
          child: Container(
            key: _searchBarKey,
            child: TextField(
              controller: _searchController,
              onChanged: (text) {},
              onSubmitted: (text) async {
                _ignoreNextFocus = true;

                FocusScope.of(context).unfocus();
                _removeOverlay();

                final favorites = ref.read(favoriteSitesProvider);

                final String? selectedFavoriteUrl =
                    _selectedFavoriteIndex != null
                        ? favorites[_selectedFavoriteIndex!]['url']
                        : null;

                _addSearchHistory(text);

                final bool? updated =
                    isWeb
                        ? await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SearchResultPage(
                                  initialUrl: _buildWebSearchUrl(
                                    text,
                                    selectedFavoriteUrl,
                                  ),
                                  title:
                                      L10n.of(context)!.search_page_web_title,
                                ),
                          ),
                        )
                        : await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => GridPage(
                                  selectedItems: <String, List<String>>{},
                                  searchText: text,
                                  rating: '',
                                  listName: '',
                                ),
                          ),
                        );

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _ignoreNextFocus = false;
                });
              },

              autofocus: false,
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
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                        : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText:
                    isWeb
                        ? L10n.of(context)!.search_page_search_word
                        : L10n.of(context)!.search_page_search_title, //タイトルを検索
                hintStyle: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              focusNode: _searchFocusNode,
            ),
          ),
        ),
      ],
    );
  }

  void _addSearchHistory(String term) async {
    if (term.trim() == '') return;

    setState(() {
      _searchHistory.remove(term);
      _searchHistory.insert(0, term);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('search_history', _searchHistory);
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  //====================
  //検索履歴のオーバーレイウィジェット
  //====================
  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox =
        _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: offset.dy + size.height, //検索バーの直下に配置
            left: offset.dx,
            width: size.width,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children:
                      _searchHistory.map((term) {
                        return ListTile(
                          title: Text(
                            term,
                            style: TextStyle(color: Colors.black),
                          ),
                          leading: const Icon(
                            Icons.history,
                            color: Colors.black,
                          ),
                          onTap: () {
                            setState(() {
                              _searchController.text = term;
                            });
                            _addSearchHistory(term);
                            _removeOverlay();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black),
                            onPressed: () {
                              _searchHistory.remove(term);
                              _removeOverlay();
                              _showOverlay();
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  List<String> _extractUniqueValues(String key) {
    final Set<String> uniqueTags = {};

    for (var item in _savedItems) {
      final raw = item[key]?.toString() ?? '';
      final parts = raw
          .split(RegExp(r'\s*#\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      uniqueTags.addAll(parts);
    }

    final list = uniqueTags.toList();
    list.sort();
    return list;
    /*
    return _savedItems
        .map((item) => item[key]?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
      */
  }

  Future<void> _loadSavedMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_metadata') ?? [];

    setState(() {
      _savedItems =
          data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

      _optionsByKey = {
        for (var key in _searchNames) key: _extractUniqueValues(key),
      };

      _selectedListByKey = {
        for (var entry in _optionsByKey.entries)
          entry.key: List.generate(entry.value.length, (_) => false),
      };
    });
  }

  //_selectedListByKeyから選択されたアイテムのマップを返す
  Map<String, List<String>> getSelectedItemsByKey() {
    Map<String, List<String>> selectedItems = {};

    for (var key in _selectedListByKey.keys) {
      final options = _optionsByKey[key] ?? [];
      final selectedFlags = _selectedListByKey[key] ?? [];

      final selectedValues = <String>[];

      for (int i = 0; i < selectedFlags.length && i < options.length; i++) {
        if (selectedFlags[i]) {
          selectedValues.add(options[i]);
        }
      }

      if (selectedValues.isNotEmpty) {
        selectedItems[key] = selectedValues;
      }
    }

    return selectedItems;
  }

  //カテゴリの選択を解除する
  void _clearAllSelections() {
    setState(() {
      _selectedListByKey.updateAll((key, list) {
        return List<bool>.filled(list.length, false);
      });
      _selectedFavoriteIndex = null;

      _searchController.text = '';
    });
  }

  //チョイスチップ表示の最大数を決めるヘルパー関数
  int _maxVisibleChips(int total) {
    const itemsPerLine = 4; // 1行に5個想定
    const maxLines = 2; // 初期は2行分表示
    final maxVisible = itemsPerLine * maxLines;
    return total < maxVisible ? total : maxVisible;
  }

  //================================
  //プレミアム機能(選択するカテゴリ数制限)
  //================================
  //選択したカテゴリ数をカウント
  int _countSelectedCategories() {
    int count = 0;

    for (final entry in _selectedListByKey.entries) {
      if (entry.value.any((selected) => selected)) {
        count++;
      }
    }

    return count;
  }

  //非プレミアムユーザ用説明ウィンドウ
  Future<void> _showPremiumInfoDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(
            L10n.of(context)!.search_page_premium_title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB8860B),
            ),
          ),
          content: Text(L10n.of(context)!.search_page_premium_description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  //*****************
  //アプリ内検索機能
  //*****************
  Widget _buildAppSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context)!.search_page_select_category,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._buildCategoryTiles(),
      ],
    );
  }

  List<Widget> _buildCategoryTiles() {
    return _searchNames.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;

      final label =
          [
            L10n.of(context)!.search_page_cast,
            L10n.of(context)!.search_page_genre,
            L10n.of(context)!.search_page_series,
            L10n.of(context)!.search_page_maker,
            L10n.of(context)!.search_page_label,
          ][index];

      final options = _optionsByKey[key] ?? [];
      final selectedCount =
          _selectedListByKey[key]?.where((e) => e).length ?? 0;
      final colorScheme = Theme.of(context).colorScheme;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:
              colorScheme.brightness == Brightness.light
                  ? Colors.grey[200]
                  : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              '$label ($selectedCount/${options.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  children: List.generate(
                    (_showAllByKey[key] ?? false)
                        ? options.length
                        : _maxVisibleChips(options.length),
                    (i) {
                      return ChoiceChip(
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        label: Text(
                          options[i],
                          style: TextStyle(color: Colors.black),
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: colorScheme.primary,
                        selected: _selectedListByKey[key]?[i] ?? false,
                        onSelected: (selected) {
                          setState(() {
                            _selectedListByKey[key]?[i] = selected;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  //*****************
  //Web検索機能
  //*****************
  /*
  Future<void> _loadFavoriteSites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoriteSitesKey) ?? [];

    setState(() {
      _favoriteSites =
          jsonList.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> _saveFavoriteSites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _favoriteSites.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_favoriteSitesKey, jsonList);
  }
  */

  //Web検索のUI
  Widget _buildWebSearchSection() {
    /*
    if (_favoriteSites.isEmpty) {
      return const Center(child: Text('お気に入りサイトがありません'));
    }
    */

    final favorites = ref.watch(favoriteSitesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.of(context)!.search_page_select_site,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 5 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 50,
                childAspectRatio: isTablet ? 1.3 : 1.2, // iPad少し広め
              ),
              itemCount: favorites.length + 1,
              itemBuilder: (context, index) {
                if (index == favorites.length) {
                  return _buildAddFavoriteGridItem(); // 追加「+」ボタン
                }
                return _buildFavoriteSiteCard(favorites[index], index);
              },
            ),
          ],
        );
      },
    );
  }

  //お気に入りサイト - グリッド用「+」ボタン
  Widget _buildAddFavoriteGridItem() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showAddFavoriteDialog,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Icon(Icons.add, size: 40)),
      ),
    );
  }

  //お気に入りサイトUI
  Widget _buildFavoriteSiteCard(Map<String, String> site, int index) {
    final isSelected = _selectedFavoriteIndex == index;
    final faviconUrl = _faviconUrl(site['url'] ?? '');
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          _selectedFavoriteIndex = isSelected ? null : index;
        });
      },
      onLongPress: () {
        _showFavoriteActionSheet(site, index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// アイコンカード
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Center(
              child: FittedBox(
                child: Image.network(
                  faviconUrl,
                  width: 30,
                  height: 30,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.public, size: 26),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          /// タイトル（カード外）
          SizedBox(
            width: 72,
            child: Text(
              site['title'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? colorScheme.primary
                        : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //お気に入りサイト - 長押し用のメニュー
  void _showFavoriteActionSheet(Map<String, String> site, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      backgroundColor: colorScheme.secondary,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: Text(L10n.of(context)!.search_page_open_site),
                onTap: () {
                  Navigator.pop(context);
                  _openSite(site['url']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(L10n.of(context)!.modify),
                onTap: () {
                  Navigator.pop(context);
                  _showEditFavoriteDialog(site, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  L10n.of(context)!.delete,
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteFavorite(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  //お気に入りサイト - サイトに遷移する処理
  Future<void> _openSite(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');

    if (uri == null) return;

    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('このURLは開けません')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultPage(initialUrl: url, title: url),
      ),
    );

    //await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // お気に入りサイト - 編集ダイアログ
  Future<void> _showEditFavoriteDialog(
    Map<String, String> site,
    int index,
  ) async {
    final titleController = TextEditingController(text: site['title']);
    final urlController = TextEditingController(text: site['url']);

    await showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(
            L10n.of(context)!.search_page_modify_favorite,
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
                  labelStyle: TextStyle(color: colorScheme.onPrimary),
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                style: TextStyle(color: colorScheme.onPrimary),
                decoration: InputDecoration(
                  labelText: L10n.of(context)!.url,
                  labelStyle: TextStyle(color: colorScheme.onPrimary),
                  hintStyle: const TextStyle(color: Colors.grey),
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
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.of(context)!.cancel),
            ),
            TextButton(
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

                ref
                    .read(favoriteSitesProvider.notifier)
                    .update(index, title, url);

                Navigator.pop(context);
              },
              child: Text(L10n.of(context)!.save),
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
  Future<void> _showAddFavoriteDialog() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

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
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context)!.cancel),
            ),
            TextButton(
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

  //お気に入りサイト - favicon用URL生成関数
  String _faviconUrl(String siteUrl) {
    try {
      final uri = Uri.parse(siteUrl);
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (_) {
      return '';
    }
  }

  //お気に入りサイト - 検索URL組み立て
  String _buildWebSearchUrl(String keyword, String? favoriteUrl) {
    final query = Uri.encodeComponent(keyword);

    if (favoriteUrl == null) {
      // 通常の動画検索
      return 'https://www.google.com/search?q=$query&tbm=vid&safe=off';
    }

    final uri = Uri.parse(favoriteUrl);
    final domain = uri.host;

    // site:example.com を付与
    final siteQuery = Uri.encodeComponent('site:$domain $keyword');

    return 'https://www.google.com/search?q=$siteQuery&tbm=vid&safe=off';
  }

  //当たり枠点滅管理
  bool blink = false;
  int blinkCount = 0;

  //タイトル表示管理
  bool showResult = false;

  //スクロール管理
  final ScrollController _rouletteController = ScrollController();

  //ルーレット機能 - モーダル表示
  void _showRouletteModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "",
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        Map<String, dynamic>? rouletteItem;
        Color borderColor = Colors.white;
        bool started = false;
        bool isRunning = true;

        //紙吹雪コントローラー
        /*
        final confettiController = ConfettiController(
          duration: const Duration(seconds: 1),
        );
        */

        return StatefulBuilder(
          builder: (context, setModalState) {
            const cardWidth = 240.0;
            final screenWidth = MediaQuery.of(context).size.width;
            final spacing = (screenWidth - cardWidth) / 2;

            //サムネから色を抽出
            Future<Color> _extractColor(String imageUrl) async {
              final imageProvider = NetworkImage(imageUrl);

              final paletteGenerator = await PaletteGenerator.fromImageProvider(
                imageProvider,
              );

              return paletteGenerator.vibrantColor?.color ??
                  paletteGenerator.dominantColor?.color ??
                  Colors.white;
            }

            Future<void> startRoulette() async {
              //アイテム一覧を更新
              _loadSavedMetadata();

              //ルーレット開始時にタイトルなどを非表示
              setModalState(() {
                showResult = false;
                rouletteItem = null;
              });

              /// スクロール位置リセット
              _rouletteController.jumpTo(0);

              final random = Random();
              final stopIndex = random.nextInt(_savedItems.length);

              //サムネから色を抽出
              final imageUrl = _savedItems[stopIndex]['image'];
              Future<Color> colorFuture = _extractColor(imageUrl);

              final itemWidth = cardWidth + spacing * 2;

              final target =
                  (stopIndex + (_savedItems.length * 10)) * itemWidth;

              await _rouletteController.animateTo(
                target.toDouble(),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.decelerate,
              );

              //回転終了時に色を取得
              final dominantColor = await colorFuture;

              setModalState(() {
                rouletteItem = _savedItems[stopIndex];
                borderColor = dominantColor;
                isRunning = false;
                showResult = true;
                blink = true;
                blinkCount = 0;
              });

              for (int i = 0; i < 6; i++) {
                await Future.delayed(const Duration(milliseconds: 250));

                setModalState(() {
                  blink = !blink;
                });
              }

              //紙吹雪
              //confettiController.play();
            }

            /// 初回のみ開始
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!started) {
                started = true;
                startRoulette();
              }
            });

            return SafeArea(
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //説明ラベル
                      Text(
                        isRunning
                            ? L10n.of(context)!.search_page_random_loading
                            : L10n.of(context)!.search_page_random_this,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: 16),

                      /// ルーレットUI
                      SizedBox(
                        height: 240 * 9 / 16,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            /// 紙吹雪
                            /*
                            ConfettiWidget(
                              confettiController: confettiController,
                              blastDirectionality:
                                  BlastDirectionality.explosive,
                              shouldLoop: false,
                              numberOfParticles: 100,
                              gravity: 0.1,
                              //colors: [colorScheme.onPrimary],
                            ),
                            */

                            /// 当たり枠
                            IgnorePointer(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: blink ? 0.3 : 1,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 1000),
                                  width: cardWidth,
                                  height: cardWidth * 9 / 16,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                          isRunning
                                              ? Colors.transparent
                                              : borderColor,
                                      width: 4,
                                    ),
                                    boxShadow:
                                        isRunning
                                            ? []
                                            : [
                                              BoxShadow(
                                                color: borderColor.withOpacity(
                                                  0.9,
                                                ),
                                                blurRadius: 25,
                                                spreadRadius: 3,
                                              ),
                                            ],
                                  ),
                                ),
                              ),
                            ),

                            /// スロット
                            ListView.builder(
                              controller: _rouletteController,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _savedItems.length * 20,
                              itemBuilder: (context, index) {
                                final item =
                                    _savedItems[index % _savedItems.length];

                                return Container(
                                  width: 240,
                                  height: 240 * (9 / 16),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: spacing,
                                  ),
                                  child: rouletteCard(context, item),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),

                      /// タイトル
                      AnimatedOpacity(
                        opacity: showResult ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            rouletteItem?['title'] ?? "",
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      /// ボタン
                      /*AnimatedOpacity(
                        opacity: showResult ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: */
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //ブラウザで開く
                          IconButton(
                            icon: const Icon(
                              Icons.open_in_new,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              final url = rouletteItem?['url'];
                              if (url != null) {
                                launchUrl(Uri.parse(url));
                              }
                            },
                          ),

                          const SizedBox(width: 20),

                          //リロード
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setModalState(() {
                                rouletteItem = null;
                                isRunning = true;
                                showResult = false;
                              });
                              startRoulette();
                            },
                          ),

                          const SizedBox(width: 20),

                          //閉じる
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              L10n.of(context)!.close,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      //),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  //カードUI
  Widget rouletteCard(BuildContext context, Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 240,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          color:
              colorScheme.brightness == Brightness.light
                  ? Colors.grey[200]
                  : const Color(0xFF2C2C2C),
          child: InkWell(
            onTap: () {
              Navigator.push(
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
            },
            child: Image.network(item['image'], fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
