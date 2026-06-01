import 'dart:math';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:confetti/confetti.dart';

import 'search_result_page.dart';
import 'grid_page.dart';
import 'detail_page.dart';
import 'l10n/app_localizations.dart';
import 'favorite_site_provider.dart';
import 'search_tab_index_provider.dart';
import 'ai_service.dart';
import 'pro_detail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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

  //AIおすすめキーワード（Pro機能）
  bool _isLoadingAiRecommend = false;
  List<RecommendedKeyword> _aiRecommendations = [];
  String? _aiRecommendError;
  bool _isPro = false;

  // Web 検索バーの hint テキストローテーション
  int _webHintIndex = 0;
  Timer? _webHintTimer;

  @override
  void initState() {
    super.initState();

    //検索履歴を更新
    _loadSearchHistory();
    _checkProStatus();
    _startWebHintRotation();

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

  Future<void> _checkProStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final isPro = info.entitlements.all['Pro Plan']?.isActive ?? false;
      if (!mounted) return;
      setState(() => _isPro = isPro);
    } catch (_) {}
  }

  /// Web 検索バーの hint テキストを 4 秒ごとにローテーション
  void _startWebHintRotation() {
    _webHintTimer?.cancel();
    _webHintTimer =
        Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      // フォーカス中 or 入力中はローテ停止
      if (_searchFocusNode.hasFocus || _searchController.text.isNotEmpty) {
        return;
      }
      setState(() {
        _webHintIndex = (_webHintIndex + 1) % 6;
      });
    });
  }

  /// 現在の Web hint テキストを返す
  String _currentWebHint() {
    final l = L10n.of(context)!;
    switch (_webHintIndex) {
      case 0:
        return l.search_page_hint_web_1;
      case 1:
        return l.search_page_hint_web_2;
      case 2:
        return l.search_page_hint_web_3;
      case 3:
        return l.search_page_hint_web_4;
      case 4:
        return l.search_page_hint_web_5;
      case 5:
        return l.search_page_hint_web_6;
      default:
        return l.search_page_search_word;
    }
  }

  @override
  void dispose() {
    _webHintTimer?.cancel();
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
                prefixIcon: Icon(
                  isWeb ? Icons.public : Icons.search,
                  color: Colors.black,
                ),
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
                // hint は Web タブ時はローテーション表示、App タブ時は固定
                hint: isWeb
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: AlignmentDirectional.centerStart,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Align(
                          key: ValueKey(_webHintIndex),
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            _currentWebHint(),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                    : Text(
                        L10n.of(context)!.search_page_search_title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
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
      final showAll = _showAllByKey[key] ?? false;
      final visibleCount =
          showAll ? options.length : _maxVisibleChips(options.length);
      final hasHiddenOptions = options.length > visibleCount;

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
            onExpansionChanged: (expanded) {
              if (!expanded) {
                setState(() {
                  _showAllByKey[key] = false;
                });
              }
            },
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
                  spacing: 6,
                  runSpacing: 8,
                  children: [
                    ...List.generate(visibleCount, (i) {
                      return ChoiceChip(
                        visualDensity: const VisualDensity(
                          horizontal: -1,
                          vertical: -1,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        side: BorderSide.none,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        label: Text(
                          options[i],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                          ),
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
                    }),
                    if (hasHiddenOptions)
                      ActionChip(
                        visualDensity: const VisualDensity(
                          horizontal: -1,
                          vertical: -1,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        avatar: const Icon(Icons.expand_more, size: 18),
                        label: Text(L10n.of(context)!.search_page_more),
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        labelStyle: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 13,
                        ),
                        onPressed: () {
                          setState(() {
                            _showAllByKey[key] = true;
                          });
                        },
                      ),
                  ],
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
    final favorites = ref.watch(favoriteSitesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final crossCount = isTablet ? 6 : 4;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAiRecommendCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  L10n.of(context)!.search_page_select_site,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  icon: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.55),
                  ),
                  onPressed: _showSelectSiteHelp,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 20,
                childAspectRatio: 0.82,
              ),
              itemCount: favorites.length + 1,
              itemBuilder: (context, index) {
                if (index == favorites.length) {
                  return _buildAddFavoriteGridItem();
                }
                return _buildFavoriteSiteCard(favorites[index], index);
              },
            ),
          ],
        );
      },
    );
  }

  /// 「サイトで絞る」のヘルプダイアログ
  Future<void> _showSelectSiteHelp() {
    final colorScheme = Theme.of(context).colorScheme;
    final l = L10n.of(context)!;
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Row(
          children: [
            Icon(Icons.help_outline, color: colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.search_page_select_site_help_title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l.search_page_select_site_help_description,
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(L10n.of(ctx)!.ok),
          ),
        ],
      ),
    );
  }

  //=========================
  //AIおすすめ（Pro機能）
  //=========================
  /// Pro 未加入向けのコンパクトプレビューカード
  Widget _buildAiRecommendLockedCard() {
    final l = L10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    const tealDeep = Color(0xFF00695C);
    const tealMid = Color(0xFF00897B);

    return InkWell(
      onTap: _generateAiRecommendations,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A1A)
              : tealDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tealMid.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: tealMid),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l.search_page_ai_recommend_title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: tealMid.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: tealMid),
                            const SizedBox(width: 3),
                            Text(
                              l.pro_locked_badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tealMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.search_page_ai_recommend_subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiRecommendCard() {
    // Pro 未加入はコンパクトプレビューカードでトーンダウン
    if (!_isPro) return _buildAiRecommendLockedCard();

    final l = L10n.of(context)!;
    const tealDeep = Color(0xFF00695C);
    const tealLight = Color(0xFF26A69A);
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [tealDeep, tealLight, tealDeep],
      stops: [0.0, 0.5, 1.0],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: tealLight.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.search_page_ai_recommend_title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l.search_page_ai_recommend_subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (_aiRecommendations.isNotEmpty && !_isLoadingAiRecommend)
                IconButton(
                  tooltip: l.search_page_ai_recommend_refresh,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _generateAiRecommendations,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingAiRecommend)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l.search_page_ai_recommend_loading,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            )
          else if (_aiRecommendations.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _aiRecommendations
                  .map((kw) => _buildRecommendChip(kw, tealDeep))
                  .toList(),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _aiRecommendError ?? l.search_page_ai_recommend_intro,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateAiRecommendations,
                    icon: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: tealDeep,
                    ),
                    label: Text(
                      l.search_page_ai_recommend_generate,
                      style: const TextStyle(
                        color: tealDeep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendChip(RecommendedKeyword kw, Color tealDeep) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _openAiRecommendation(kw.keyword),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: tealDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kw.keyword,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tealDeep,
                        ),
                      ),
                      if (kw.reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          kw.reason,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: tealDeep),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAiRecommendation(String keyword) {
    if (keyword.isEmpty) return;
    _addSearchHistory(keyword);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultPage(
          initialUrl: _buildWebSearchUrl(keyword, null),
          title: L10n.of(context)!.search_page_web_title,
        ),
      ),
    );
  }

  Future<void> _generateAiRecommendations() async {
    if (_isLoadingAiRecommend) return;

    // Pro限定（購入先行型: 未加入ユーザーにサインインを促さず購入画面を表示）
    if (!await ProGate.ensureProPurchaseFirst(context)) return;
    if (!mounted) return;

    final l = L10n.of(context)!;

    // ライブラリ集約
    final agg = _aggregateLibrary();
    if (agg.itemCount == 0) {
      setState(() {
        _aiRecommendError = l.search_page_ai_recommend_empty;
      });
      return;
    }

    setState(() {
      _isLoadingAiRecommend = true;
      _aiRecommendError = null;
    });

    try {
      final result = await AiService.recommendKeywords(
        topGenres: agg.topGenres,
        topCasts: agg.topCasts,
        topMakers: agg.topMakers,
        topSeries: agg.topSeries,
        topLabels: agg.topLabels,
        recentTitles: agg.recentTitles,
        itemCount: agg.itemCount,
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() {
        _aiRecommendations = result;
        if (result.isEmpty) {
          _aiRecommendError = l.search_page_ai_recommend_empty;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.search_page_ai_recommend_error}: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAiRecommend = false);
    }
  }

  _LibraryAggregation _aggregateLibrary() {
    final genreCount = <String, int>{};
    final castCount = <String, int>{};
    final makerCount = <String, int>{};
    final seriesCount = <String, int>{};
    final labelCount = <String, int>{};

    void count(String? raw, Map<String, int> target) {
      if (raw == null || raw.trim().isEmpty) return;
      for (final part in raw
          .split(RegExp(r'\s*#\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)) {
        target[part] = (target[part] ?? 0) + 1;
      }
    }

    for (final item in _savedItems) {
      count(item['genre']?.toString(), genreCount);
      count(item['cast']?.toString(), castCount);
      count(item['maker']?.toString(), makerCount);
      count(item['series']?.toString(), seriesCount);
      count(item['label']?.toString(), labelCount);
    }

    List<String> sortedKeys(Map<String, int> m, int limit) {
      final list = m.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return list.take(limit).map((e) => e.key).toList();
    }

    final recentTitles = _savedItems
        .reversed
        .take(5)
        .map((e) => (e['title'] ?? '').toString())
        .where((t) => t.isNotEmpty)
        .toList();

    return _LibraryAggregation(
      itemCount: _savedItems.length,
      topGenres: sortedKeys(genreCount, 10),
      topCasts: sortedKeys(castCount, 10),
      topMakers: sortedKeys(makerCount, 10),
      topSeries: sortedKeys(seriesCount, 10),
      topLabels: sortedKeys(labelCount, 10),
      recentTitles: recentTitles,
    );
  }

  //お気に入りサイト - グリッド用「+」ボタン
  Widget _buildAddFavoriteGridItem() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: _showAddFavoriteDialog,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.add,
                size: 26,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            L10n.of(context)!.add,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  //お気に入りサイトUI（Edge モバイル風）
  Widget _buildFavoriteSiteCard(Map<String, String> site, int index) {
    final isSelected = _selectedFavoriteIndex == index;
    final faviconUrl = _faviconUrl(site['url'] ?? '');
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return GestureDetector(
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
          // ─── アイコンコンテナ ───────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  isSelected
                      ? Border.all(color: colorScheme.primary, width: 2.5)
                      : Border.all(
                        color: Colors.grey.withValues(alpha: 0.15),
                        width: 1,
                      ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.15 : (isDark ? 0.25 : 0.07),
                  ),
                  blurRadius: isSelected ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ファビコン
                Center(
                  child: Image.network(
                    faviconUrl,
                    width: 36,
                    height: 36,
                    errorBuilder:
                        (_, __, ___) => Icon(
                          Icons.public,
                          size: 34,
                          color:
                              isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                        ),
                  ),
                ),
                // 選択チェックバッジ
                if (isSelected)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ─── サイト名 ──────────────────────────────
          Text(
            site['title'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color:
                  isSelected
                      ? colorScheme.primary
                      : (isDark ? Colors.white70 : Colors.black87),
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L10n.of(context)!.search_page_url_cant_open)));
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

  //ルーレット機能 - モーダル表示
  void _showRouletteModal() {
    if (_savedItems.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _RouletteModal(items: _savedItems),
    );
  }

}

class _LibraryAggregation {
  final int itemCount;
  final List<String> topGenres;
  final List<String> topCasts;
  final List<String> topMakers;
  final List<String> topSeries;
  final List<String> topLabels;
  final List<String> recentTitles;

  _LibraryAggregation({
    required this.itemCount,
    required this.topGenres,
    required this.topCasts,
    required this.topMakers,
    required this.topSeries,
    required this.topLabels,
    required this.recentTitles,
  });
}

// =====================================================================
// ルーレットモーダル（改善版）
// =====================================================================
class _RouletteModal extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const _RouletteModal({required this.items});

  @override
  State<_RouletteModal> createState() => _RouletteModalState();
}

class _RouletteModalState extends State<_RouletteModal>
    with TickerProviderStateMixin {
  static const _cardWidth = 240.0;

  final ScrollController _scrollController = ScrollController();
  late final ConfettiController _confettiController;
  late final AnimationController _pulseController;
  Timer? _tickTimer;

  Map<String, dynamic>? _resultItem;
  Color _accent = Colors.white;
  bool _isRunning = true;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _confettiController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Color> _extractColor(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return Colors.white;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
      );
      return palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          Colors.white;
    } catch (_) {
      return Colors.white;
    }
  }

  Future<void> _start() async {
    if (widget.items.isEmpty) return;

    setState(() {
      _showResult = false;
      _resultItem = null;
      _isRunning = true;
    });

    HapticFeedback.mediumImpact();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);

    final stopIndex = Random().nextInt(widget.items.length);
    final colorFuture = _extractColor(widget.items[stopIndex]['image']);

    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = (screenWidth - _cardWidth) / 2;
    final itemWidth = _cardWidth + spacing * 2;
    final fullTarget =
        (stopIndex + (widget.items.length * 10)) * itemWidth;
    final nearMissTarget = fullTarget - itemWidth * 0.6;

    // 触覚 tick（スピン中の小刻みなフィードバック）
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      HapticFeedback.selectionClick();
    });

    // Phase 1: 高速回転（70%地点まで一気に）
    await _scrollController.animateTo(
      fullTarget * 0.75,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeIn,
    );
    if (!mounted) return;

    // Phase 2: 減速してニアミス位置まで
    await _scrollController.animateTo(
      nearMissTarget,
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
    );
    if (!mounted) return;

    _tickTimer?.cancel();

    // Phase 3: ニアミス後、ゆっくり最終位置へ
    await _scrollController.animateTo(
      fullTarget,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutQuart,
    );

    final accent = await colorFuture;
    if (!mounted) return;

    HapticFeedback.heavyImpact();
    _confettiController.play();

    setState(() {
      _resultItem = widget.items[stopIndex];
      _accent = accent;
      _isRunning = false;
      _showResult = true;
    });
  }

  Future<void> _spinAgain() async {
    HapticFeedback.lightImpact();
    await _start();
  }

  void _openInBrowser() {
    final url = _resultItem?['url']?.toString();
    if (url == null || url.isEmpty) return;
    launchUrl(Uri.parse(url));
  }

  void _openDetail() {
    final item = _resultItem;
    if (item == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
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
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = (screenWidth - _cardWidth) / 2;

    return PopScope(
      canPop: true,
      child: Stack(
        children: [
          // 当選サムネのドミナントカラーで背景をふんわり彩色
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  _accent.withValues(alpha: _showResult ? 0.35 : 0.0),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isRunning
                          ? l.search_page_random_loading
                          : l.search_page_random_this,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // スロット
                    SizedBox(
                      height: _cardWidth * 9 / 16,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 当選リング（パルス）
                          IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, __) {
                                final t = _showResult
                                    ? _pulseController.value
                                    : 0.0;
                                final width = _cardWidth + (t * 10);
                                final height = (_cardWidth * 9 / 16) + (t * 6);
                                return AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 500),
                                  width: width,
                                  height: height,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _isRunning
                                          ? Colors.transparent
                                          : _accent,
                                      width: 4,
                                    ),
                                    boxShadow: _isRunning
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: _accent.withValues(
                                                alpha: 0.6 + (t * 0.3),
                                              ),
                                              blurRadius: 25 + (t * 15),
                                              spreadRadius: 2 + (t * 4),
                                            ),
                                          ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // スロット本体
                          ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: widget.items.length * 20,
                            itemBuilder: (context, index) {
                              final item = widget
                                  .items[index % widget.items.length];
                              return Container(
                                width: _cardWidth,
                                height: _cardWidth * (9 / 16),
                                margin: EdgeInsets.symmetric(
                                  horizontal: spacing,
                                ),
                                child: _RouletteCard(
                                  item: item,
                                  colorScheme: colorScheme,
                                ),
                              );
                            },
                          ),

                          // 紙吹雪
                          Align(
                            alignment: Alignment.center,
                            child: ConfettiWidget(
                              confettiController: _confettiController,
                              blastDirectionality:
                                  BlastDirectionality.explosive,
                              shouldLoop: false,
                              numberOfParticles: 30,
                              maxBlastForce: 18,
                              minBlastForce: 6,
                              gravity: 0.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // タイトル
                    AnimatedOpacity(
                      opacity: _showResult ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: _openDetail,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _resultItem?['title']?.toString() ?? '',
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
                    ),
                    const SizedBox(height: 16),

                    // ボタン
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new,
                              color: Colors.white),
                          onPressed: _showResult ? _openInBrowser : null,
                          tooltip: l.detail_page_access,
                        ),
                        const SizedBox(width: 8),
                        // もう一度（テキスト＋アイコン）
                        ElevatedButton.icon(
                          onPressed: _isRunning ? null : _spinAgain,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(l.search_page_random_again),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l.close,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouletteCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final ColorScheme colorScheme;
  const _RouletteCard({required this.item, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _RouletteModalState._cardWidth,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          color: colorScheme.brightness == Brightness.light
              ? Colors.grey[200]
              : const Color(0xFF2C2C2C),
          child: item['image'] != null
              ? Image.network(item['image'], fit: BoxFit.cover)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
