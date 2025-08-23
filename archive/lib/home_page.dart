import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  final String listName;

  const HomePage({required this.listName, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  //全アイテム
  //List<Map<String, dynamic>> _allItems = [];
  //List<Map<String, dynamic>> _listItems = [];

  //保存されたアイテムリスト
  List<Map<String, dynamic>> _savedItems = [];

  //検索する文字列
  String _searchText = '';

  final TextEditingController _searchController = TextEditingController();

  //検索履歴リスト
  List<String> _searchHistory = [];

  //フィルター
  Map<String, String> _advancedFilters = {};

  //検索バーのフォーカス管理
  final FocusNode _searchFocusNode = FocusNode();

  //オーバーレイ
  OverlayEntry? _overlayEntry;

  //オーバーレイの削除
  @override
  void dispose() {
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  //オーバーレイの初期化
  @override
  void initState() {
    super.initState();
    _loadSavedMetadata();
    _loadSearchHistory();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  //==================
  //検索バーのウィジェット
  //==================
  Widget _searchTextField() {
    //String tempSearch;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (text) {
              //tempSearch = text;
            },
            onSubmitted: (text) {
              FocusScope.of(context).unfocus();
              setState(() {
                _searchText = text;
                _addSearchHistory(text);
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
              prefixIcon: Icon(Icons.search),
              suffixIcon:
                  _searchText.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchText = '';
                          });
                        },
                      )
                      : null,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              hintText: 'タイトルを検索',
              hintStyle: TextStyle(color: Colors.black, fontSize: 16),
            ),
            focusNode: _searchFocusNode,
          ),
        ),
        IconButton(
          //フィルターアイコン
          icon: const Icon(Icons.filter_alt, color: Colors.black),
          onPressed: _showAdvancedSearchModal,
        ),
      ],
    );
  }

  //============
  //検索履歴の追加
  //============
  void _addSearchHistory(String term) async {
    setState(() {
      _searchHistory.remove(term); //重複を削除
      _searchHistory.insert(0, term); //先頭に追加
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast(); //履歴が10個を超える場合は削除
      }
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('search_history', _searchHistory);
  }

  //=========================
  //検索履歴を表示するオーバーレイ
  //=========================
  void _showOverlay() {
    if (_overlayEntry != null) return; //多重表示の防止

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
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children:
                      _searchHistory.map((term) {
                        return ListTile(
                          title: Text(term),
                          leading: Icon(Icons.search),
                          onTap: () {
                            setState(() {
                              _searchController.text = term;
                              _searchText = term;
                            });
                            _addSearchHistory(term); //再選択でも検索履歴を更新
                            _removeOverlay();
                          },
                          trailing: IconButton(
                            icon: Icon(Icons.clear),
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

  //オーバーレイの削除
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  //========================
  //フィルター選択のモーダル表示
  //========================
  void _showAdvancedSearchModal() {
    // 各選択肢を_savedItemsから取得
    final List<String> castOptions = _extractUniqueValues('cast');
    final List<String> genreOptions = _extractUniqueValues('genre');
    final List<String> seriesOptions = _extractUniqueValues('series');
    final List<String> labelOptions = _extractUniqueValues('label');
    final List<String> makerOptions = _extractUniqueValues('maker');

    //現在のフィルター選択状態を初期化
    String? selectedCast = _advancedFilters['cast'];
    String? selectedGenre = _advancedFilters['genre'];
    String? selectedSeries = _advancedFilters['series'];
    String? selectedLabel = _advancedFilters['label'];
    String? selectedMaker = _advancedFilters['maker'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdownField(
                  label: '出演',
                  selectedValue: selectedCast,
                  options: castOptions,
                  onChanged: (val) => selectedCast = val,
                ),
                _buildDropdownField(
                  label: 'ジャンル',
                  selectedValue: selectedGenre,
                  options: genreOptions,
                  onChanged: (val) => selectedGenre = val,
                ),
                _buildDropdownField(
                  label: 'シリーズ',
                  selectedValue: selectedSeries,
                  options: seriesOptions,
                  onChanged: (val) => selectedSeries = val,
                ),
                _buildDropdownField(
                  label: 'レーベル',
                  selectedValue: selectedLabel,
                  options: labelOptions,
                  onChanged: (val) => selectedLabel = val,
                ),
                _buildDropdownField(
                  label: 'メーカー',
                  selectedValue: selectedMaker,
                  options: makerOptions,
                  onChanged: (val) => selectedMaker = val,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('検索'),
                      onPressed: () {
                        Navigator.pop(context);
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _searchText = '';
                          _advancedFilters = {
                            if (selectedCast != null &&
                                selectedCast!.isNotEmpty)
                              'cast': selectedCast!,
                            if (selectedGenre != null &&
                                selectedGenre!.isNotEmpty)
                              'genre': selectedGenre!,
                            if (selectedSeries != null &&
                                selectedSeries!.isNotEmpty)
                              'series': selectedSeries!,
                            if (selectedLabel != null &&
                                selectedLabel!.isNotEmpty)
                              'label': selectedLabel!,
                            if (selectedMaker != null &&
                                selectedMaker!.isNotEmpty)
                              'maker': selectedMaker!,
                          };
                        });
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('リセット'),
                      onPressed: () {
                        Navigator.pop(context);
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _advancedFilters.clear();
                          _searchText = '';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _extractUniqueValues(String key) {
    return _savedItems
        .map((item) => item[key]?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Widget _buildDropdownField({
    required String label,
    required String? selectedValue,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items:
            options.map((value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _loadSavedMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_metadata') ?? [];

    setState(() {
      _savedItems =
          data
              .map((e) => jsonDecode(e) as Map<String, dynamic>)
              .where((item) => item['listName'] == widget.listName)
              .toList();
    });
    /*
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_metadata') ?? [];
    setState(() {
      _savedItems =
          data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
    */
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPage(listName: widget.listName),
        ),
      );
      _loadSavedMetadata();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  //全角→半角変換や、ひらがな→カタカナ変換などを行う
  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '') //空白削除
        .replaceAllMapped(
          RegExp(r'[\u3041-\u3096]'), //ひらがな→カタカナ
          (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 0x60),
        );
  }

  //===============================
  //検索・フィルタリング後のGridView表示
  //===============================
  List<Map<String, dynamic>> _filteredItems() {
    final query = _normalize(_searchText);

    return _savedItems.where((item) {
      final matchText =
          _searchText.isNotEmpty
              ? [
                item['title'],
                item['cast'],
                item['genre'],
                item['series'],
                item['label'],
                item['maker'],
              ].any(
                (field) => _normalize(field?.toString() ?? '').contains(query),
              )
              : true;
      final matchFilters = _advancedFilters.entries.every((entry) {
        final field = item[entry.key]?.toString() ?? '';
        return _normalize(field).contains(_normalize(entry.value));
      });

      return matchText && matchFilters;
    }).toList();
  }

  //============
  //メイン画面
  //============
  @override
  Widget build(BuildContext context) {
    final itemsToShow = _filteredItems();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.listName),
          //_searchTextField(),
          backgroundColor: Colors.white,
          actions: [
            IconButton(onPressed: _showAddListModal, icon: Icon(Icons.sort)),
          ],
        ),
        body:
            itemsToShow.isEmpty
                ? const Center(child: Text('保存されたアイテムがありません'))
                : GridView.builder(
                  itemCount: itemsToShow.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 0.1,
                    crossAxisSpacing: 0.1,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final item = itemsToShow[index];
                    //final Uri? uri = Uri.tryParse(item['url']);
                    //final String? domain = uri?.host;
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
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => DetailPage(
                                  listName: widget.listName,
                                  url: item['url'],
                                  title: item['title'],
                                  image: item['image'],
                                  cast: item['cast'] ?? '',
                                  genre: item['genre'] ?? '',
                                  series: item['series'] ?? '',
                                  label: item['label'] ?? '',
                                  maker: item['maker'] ?? '',
                                  rating: item['rating'],
                                  isReadOnly: true,
                                ),
                          ),
                        );
                        // 戻ってきたタイミングでフォーカスを外す
                        FocusScope.of(context).unfocus();
                        _loadSavedMetadata();
                      },
                      child: Stack(
                        children: [
                          Card(
                            color: Colors.white,
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
                                    )
                                    : const Placeholder(fallbackHeight: 100),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    item['title'] ?? '（タイトルなし）',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                  onPressed: () async {
                                    final url = item['url']?.toString().trim();
                                    if (url != null &&
                                        url.isNotEmpty &&
                                        await canLaunchUrl(Uri.parse(url))) {
                                      await launchUrl(
                                        Uri.parse(url),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('有効なURLではありません'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.add), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.whatshot), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.black,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  //====================
  //ソートのモーダルウィンドウ
  //====================
  void _showAddListModal() {
    showModalBottomSheet(
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
                    icon: Icon(Icons.grid_view, size: 32),
                    onPressed: () {
                      setState(() {
                        //isGrid = !isGrid; // 表示モードを切り替える
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.view_list, size: 32),
                    onPressed: () {
                      setState(() {
                        //isGrid = !isGrid; // 表示モードを切り替える
                      });
                    },
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  print('ボタンが押下されました');
                },
                child: Text(
                  'タイトル順',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  print('ボタンが押下されました');
                },
                child: Text(
                  '追加が新しい順',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  print('ボタンが押下されました');
                },
                child: Text(
                  '追加が古い順',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  print('ボタンが押下されました');
                },
                child: Text(
                  '視聴数が多い順',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  print('ボタンが押下されました');
                },
                child: Text(
                  '視聴数が少ない順',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /*
  //listNameによってアイテムをフィルターする
  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.listName != null) {
      final ids = prefs.getStringList('list_${widget.listName}') ?? [];
      _listItems = _allItems.where((item) => ids.contains(item['id'])).toList();
    } else {
      _listItems = _allItems;
    }
    setState(() {});
  }
  */
}
