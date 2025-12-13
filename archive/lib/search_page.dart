import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'grid_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  String _searchText = '';
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _savedItems = [];

  final List<String> _categoryNames = ['出演', 'ジャンル', 'シリーズ', 'レーベル', 'メーカー'];
  final List<String> _searchNames = [
    'cast',
    'genre',
    'series',
    'label',
    'maker',
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

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    //_loadSavedMetadata();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  bool _isMetadataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //if (!_isMetadataLoaded) {
    _loadSavedMetadata();
    //  _isMetadataLoaded = true;
    //}
  }

  @override
  void dispose() {
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        //backgroundColor: Color(0xFF121212),
        appBar: AppBar(
          title: _searchTextField(),
          //backgroundColor: Color(0xFF121212),
        ),
        body: //Center(
        //child:
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'カテゴリを選択',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        //color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 30),
                    ElevatedButton(
                      onPressed: _clearAllSelections,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Colors.grey[300],
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          Colors.black,
                        ),
                      ),
                      child: const Text('クリア'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => GridPage(
                                  selectedItems: getSelectedItemsByKey(),
                                  searchText: '',
                                  rating: '',
                                  listName: '',
                                ),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          colorScheme.primary,
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          Colors.white,
                        ),
                      ),
                      child: const Text('検索'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                //const Divider(height: 1, thickness: 1, color: Colors.grey),
                ..._searchNames.asMap().entries.map((entry) {
                  int index = entry.key;
                  String key = entry.value;
                  String label = _categoryNames[index];
                  List<String> options = _optionsByKey[key] ?? [];
                  final selectedCount =
                      _selectedListByKey[key]
                          ?.where((isSelected) => isSelected)
                          .length ??
                      0;
                  final colorScheme = Theme.of(context).colorScheme;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        //horizontal: BorderSide(color: Colors.grey),
                      ),
                      //borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                colorScheme.brightness == Brightness.light
                                    ? Colors.grey[200]
                                    : Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              splashColor: Colors.transparent,
                            ),

                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Text(
                                    '${label}  (${selectedCount}/${options.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),

                              iconColor: colorScheme.onPrimary,
                              collapsedIconColor: colorScheme.onPrimary,
                              //leading: Icon(_icons[index]),
                              //trailing: Text('(${options.length})件'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 0.0,
                                        children: List<Widget>.generate(
                                          (_showAllByKey[key] ?? false)
                                              ? options.length
                                              : _maxVisibleChips(
                                                options.length,
                                              ), //表示数を制御
                                          (i) {
                                            return ChoiceChip(
                                              side: BorderSide.none,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              label: Text(
                                                options[i],
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              backgroundColor: Colors.white,
                                              selectedColor:
                                                  colorScheme.primary,
                                              selected:
                                                  _selectedListByKey[key]?[i] ??
                                                  false,
                                              onSelected: (bool selected) {
                                                setState(() {
                                                  _selectedListByKey[key]?[i] =
                                                      selected;
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      if (!(_showAllByKey[key] ?? false) &&
                                          options.length >
                                              _maxVisibleChips(options.length))
                                        Center(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _showAllByKey[key] = true;
                                              });
                                            },
                                            child: Text('もっと見る'),
                                          ),
                                        ),
                                      if (!(_showAllByKey[key] ?? false) &&
                                          options.length <=
                                              _maxVisibleChips(options.length))
                                        Center(
                                          child: TextButton(
                                            onPressed: () {},
                                            child: Text(
                                              '',
                                            ), //もっと見るが表示されない場合に空白を表示する。（Alignの制御のため）
                                          ),
                                        ),
                                      if ((_showAllByKey[key] ?? false))
                                        Center(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _showAllByKey[key] = false;
                                              });
                                            },
                                            child: Text('折りたたむ'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10.0),
                        /*
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey,
                        ),
                        */
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
        //),
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
          child: TextField(
            controller: _searchController,
            onChanged: (text) {},
            onSubmitted: (text) {
              if (text.trim().isEmpty) return;
              FocusScope.of(context).unfocus();
              setState(() {
                _searchText = text;
                _addSearchHistory(text);
                Navigator.push(
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
                  _searchText.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchText = '';
                          });
                        },
                      )
                      : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: 'タイトルを検索',
              hintStyle: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            focusNode: _searchFocusNode,
          ),
        ),
      ],
    );
  }

  void _addSearchHistory(String term) async {
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

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children:
                      _searchHistory.map((term) {
                        return ListTile(
                          title: Text(
                            term,
                            style: TextStyle(color: Colors.black),
                          ),
                          leading: const Icon(
                            Icons.search,
                            color: Colors.black,
                          ),
                          onTap: () {
                            setState(() {
                              _searchController.text = term;
                              _searchText = term;
                            });
                            _addSearchHistory(term);
                            _removeOverlay();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black),
                            onPressed: () {
                              _searchHistory.remove(term);
                              setState(() {});
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
    });
  }

  //チョイスチップ表示の最大数を決めるヘルパー関数
  int _maxVisibleChips(int total) {
    const itemsPerLine = 4; // 1行に5個想定
    const maxLines = 2; // 初期は2行分表示
    final maxVisible = itemsPerLine * maxLines;
    return total < maxVisible ? total : maxVisible;
  }
}
