import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'view_counter.dart';
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'premium_detail.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DetailPage extends StatefulWidget {
  final String? listName;
  final String? url;
  final String? title;
  final String? image;
  final String? cast;
  final String? genre;
  final String? series;
  final String? label;
  final String? maker;
  final String? memo;
  final String? rating;
  final bool isReadOnly;
  final VoidCallback? onCreated;

  const DetailPage({
    super.key,
    this.listName,
    this.url,
    this.title,
    this.image,
    this.cast,
    this.genre,
    this.series,
    this.label,
    this.maker,
    this.memo,
    this.rating,
    this.isReadOnly = false,
    this.onCreated,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late TextEditingController _urlController;
  late TextEditingController _titleController;
  late TextEditingController _castController;
  late TextEditingController _genreController;
  late TextEditingController _seriesController;
  late TextEditingController _labelController;
  late TextEditingController _makerController;
  late TextEditingController _memoController;

  //サムネイル画像のURL
  String? _thumbnailUrl;

  //編集モードの有効無効
  bool isEditing = false;
  String? selectedRating;

  //背景の初期色
  Color _dominantColor = Colors.transparent;

  //視聴数カウント
  int count = 0;

  //新旧比較用のURL
  late String _originalUrl;

  //メモ欄
  // {'type': 'text'|'image', 'content': String}
  List<Map<String, dynamic>> memoItems = [];

  //final FocusNode _focusNode = FocusNode();

  bool _isPremium = false;

  //ローカル画像
  //表示されているページ数保持
  int _localImageCorrentIndex = 1;
  //最大ページ数保持
  int _localImageMaxIndex = 1;

  //リスト一覧
  List<String> _listNames = [];
  String? isSelectedValue;

  //隠しWebView用のコントローラ
  InAppWebViewController? _hiddenWebViewController;

  //選択なし
  static const String noneListValue = '__none__';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    //_initializeFirebase();

    if ((widget.image == null || widget.image!.isEmpty) && widget.url != null) {
      _initializeThumbnail(widget.url!); //URLから取得
    } else {
      _thumbnailUrl = widget.image; //保存済み画像を使う
    }
    _updatePalette();

    _originalUrl = widget.url ?? '';
    _urlController.text = _originalUrl;
    _controllers['cast'] = _castController;
    _controllers['genre'] = _genreController;
    _controllers['series'] = _seriesController;
    _controllers['label'] = _labelController;
    _controllers['maker'] = _makerController;

    for (final key in _controllers.keys) {
      _controllers[key]!.addListener(() => _onFieldChanged(key));
    }

    _checkSubscriptionStatus();

    _loadLists();

    _loadLocalImages();
  }

  void _initializeControllers() {
    _urlController = TextEditingController(text: widget.url ?? '');
    _titleController = TextEditingController(text: widget.title ?? '');
    _castController = TextEditingController(text: widget.cast ?? '');
    _genreController = TextEditingController(text: widget.genre ?? '');
    _seriesController = TextEditingController(text: widget.series ?? '');
    _labelController = TextEditingController(text: widget.label ?? '');
    _makerController = TextEditingController(text: widget.maker ?? '');
    _memoController = TextEditingController(text: widget.memo ?? '');
    selectedRating = widget.rating;
    isEditing = !widget.isReadOnly;
  }

  /*
  Future<void> _initializeFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }
  */

  bool _isLoadingThumbnail = false;

  Future<void> _initializeThumbnail(String url) async {
    setState(() {
      _isLoadingThumbnail = true;
    });

    final thumb = await fetchThumbnailByWebView(url);

    if (!mounted) return;

    if (thumb != null) {
      setState(() {
        _thumbnailUrl = thumb;
        _isLoadingThumbnail = false;
      });
      await _saveChanges(exitEditMode: false);
    } else {
      setState(() {
        _isLoadingThumbnail = false;
      });
    }
  }

  Future<String?> fetchThumbnailByWebView(String url) async {
    final Completer<String?> completer = Completer();

    // Invisible WebView を作る
    final InAppWebView webView = InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
      ),
      onLoadStop: (controller, uri) async {
        try {
          final js = """
          (function() {
            var og = document.querySelector('meta[property="og:image"]');
            if (og && og.content) return og.content;

            var item = document.querySelector('meta[itemprop="image"]');
            if (item && item.content) return item.content;

            var video = document.querySelector('video');
            if (video && video.poster) return video.poster;

            var link = document.querySelector('link[rel="image_src"]');
            if (link && link.href) return link.href;

            var imgs = document.querySelectorAll('img');
            for (var i = 0; i < imgs.length; i++) {
              var s = imgs[i].src;
              if (s.includes("/wp-content/uploads")) return s;
            }

            var img = document.querySelector('img');
            if (img && img.src) return img.src;

            return null;
          })();
        """;

          final result = await controller.evaluateJavascript(source: js);

          if (!completer.isCompleted) {
            if (result == null || result == "null") {
              completer.complete(null);
            } else {
              String resolved =
                  Uri.parse(url).resolve(result.toString()).toString();
              completer.complete(resolved);
            }
          }
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      },
    );

    // WebView を非表示で画面に追加する
    OverlayEntry entry = OverlayEntry(
      builder: (_) {
        return Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: Opacity(opacity: 0.0, child: webView),
        );
      },
    );

    Overlay.of(context).insert(entry);

    // タイムアウト 10秒
    return completer.future
        .timeout(
          Duration(seconds: 10),
          onTimeout: () {
            entry.remove();
            return null;
          },
        )
        .whenComplete(() {
          entry.remove();
        });
  }

  //入力情報を保存
  Future<void> _saveChanges({bool exitEditMode = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final newUrl = _urlController.text.trim();
    final colorScheme = Theme.of(context).colorScheme;

    // URLが入力されているかチェック
    if (newUrl.isEmpty) {
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: colorScheme.secondary,
              title: Text(
                L10n.of(context)!.detail_page_url_empty,
                textAlign: TextAlign.center,
              ),
              content: Text(
                L10n.of(context)!.detail_page_input_url,
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      colorScheme.primary,
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                  ),
                  child: Text(L10n.of(context)!.ok),
                ),
              ],
            ),
      );
      return; // 保存処理を中断
    }

    // URLが変更されているかチェック
    if (widget.url != null && _originalUrl.trim() != newUrl) {
      //最大保存数
      final limit = await _countSaveLimit();

      //作品数
      final savedCount = await _countSavedItems();

      //プレミアムプランか判定
      _isPremium = await _checkPremium();

      //作品数 > 最大数かつ、非プレミアムユーザーであれば、ポップアップ表示
      if (!_isPremium && savedCount >= limit) {
        //if (true) {
        //デバッグ用切り替え箇所
        await _showSaveLimitDialog(savedCount, limit);
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: colorScheme.secondary,
              title: Text(L10n.of(context)!.detail_page_url_changed),
              content: Text(L10n.of(context)!.detail_page_url_changed_note),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Colors.grey[300],
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                  ),
                  child: Text(L10n.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      colorScheme.primary,
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  child: Text(L10n.of(context)!.ok),
                ),
              ],
            ),
      );

      if (confirmed != true) return; // キャンセルされた場合は保存しない

      //URLを変更させて次回からは比較しないようにする。
      _originalUrl = newUrl;
    }

    String? toSaveListName;

    if (isSelectedValue == noneListValue) {
      toSaveListName = '';
    } else {
      toSaveListName = isSelectedValue;
    }

    final data = {
      'listName': toSaveListName,
      'url': _urlController.text,
      'title': _titleController.text,
      'image': widget.image ?? _thumbnailUrl,
      'cast': _castController.text,
      'genre': _genreController.text,
      'series': _seriesController.text,
      'label': _labelController.text,
      'maker': _makerController.text,
      'memo': _memoController.text,
      'rating': selectedRating,
    };

    final savedList = prefs.getStringList('saved_metadata') ?? [];
    final updatedList = <String>[];
    bool found = false;

    for (final item in savedList) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      if (map['url'] == _urlController.text) {
        updatedList.add(jsonEncode(data));
        found = true;
      } else {
        updatedList.add(item);
      }
    }

    if (!found) updatedList.add(jsonEncode(data));
    bool success = await prefs.setStringList('saved_metadata', updatedList);

    if (exitEditMode) {
      setState(() => isEditing = false);
      _initializeThumbnail(_urlController.text);
    }
    if (success) {
      widget.onCreated?.call(); //作成処理の最後に親に通知

      // 保存完了後にレビュー促進
      await _maybeShowReviewPrompt();
    } else {}

    await _saveLocalImages();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _castController.dispose();
    _genreController.dispose();
    _seriesController.dispose();
    _labelController.dispose();
    _makerController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Widget _ratingButton(
    String type,
    String label,
    String imagePath,
    String grayPath,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedRating == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedRating == type) {
            selectedRating = null; //もう一度押すとクリア
          } else {
            selectedRating = type;
          }
        });
        _saveChanges(exitEditMode: false); //保存しても編集モードを継続
      },
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            Image.asset(
              isSelected ? imagePath : grayPath,
              width: 40,
              height: 40,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  //========
  //メイン画面
  //========
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //_dominantColor = colorScheme.secondary;

    return Scaffold(
      //backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212).withOpacity(0.3),
        title: Text(
          L10n.of(context)!.detail_page_item_detail,
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _buildIconWithLabel(
            Icons.delete,
            L10n.of(context)!.detail_page_delete,
            _confirmDelete,
          ),
          _buildIconWithLabel(
            Icons.open_in_new,
            L10n.of(context)!.detail_page_access,
            _launchUrl,
          ),
          if (!isEditing)
            _buildIconWithLabel(
              Icons.edit,
              L10n.of(context)!.detail_page_modify,
              () => setState(() => isEditing = true),
            ),
          if (isEditing)
            _buildIconWithLabel(
              Icons.save,
              L10n.of(context)!.detail_page_save,
              _saveChanges,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_dominantColor, colorScheme.secondary],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              /*
              if ((widget.image ?? _thumbnailUrl) != null) ...[
                SizedBox(height: 100),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Image.network(
                        widget.image ?? _thumbnailUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const SizedBox(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ViewingCounterWidget(url: widget.url),
                      ),
                    ],
                  ),
                ),
              ] else
                SizedBox(
                  height: 300,
                  child: const Align(
                    alignment: Alignment.bottomCenter,
                    child: Text('保存するとサムネイルが表示されます'),
                  ),
                ),
                */
              const SizedBox(height: 100),
              //if (_localImagePaths.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount:
                      _localImagePaths.length + 1, //1ページ目：サムネ、2ページ目以降：ローカル画像
                  onPageChanged: (index) {
                    setState(() {
                      _localImageCorrentIndex = index + 1;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      //サムネ取得中
                      if (_isLoadingThumbnail) {
                        return Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ViewingCounterWidget(url: widget.url),
                            ),
                          ],
                        );
                      }

                      //サムネ表示
                      if ((widget.image ?? _thumbnailUrl) != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image.network(
                                widget.image ?? _thumbnailUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const SizedBox(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ViewingCounterWidget(url: widget.url),
                              ),
                            ],
                          ),
                        );
                      } else {
                        //サムネ未取得
                        return Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            SizedBox(
                              height: 300,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  L10n.of(
                                    context,
                                  )!.detail_page_thumbnail_placeholder,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ViewingCounterWidget(url: widget.url),
                            ),
                          ],
                        );
                        /*
                        return SizedBox(
                          height: 300,
                          child: const Align(
                            alignment: Alignment.bottomCenter,
                            child: Text('保存するとサムネイルが表示されます'),
                          ),
                        );
                        */
                      }
                    } else {
                      final imageIndex = index - 1;
                      final imageWidget = Image.file(
                        File(_localImagePaths[imageIndex]),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageWidget,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _removeLocalImage(imageIndex),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              width: 0,
                              height: 0,
                              child: InAppWebView(
                                initialSettings: InAppWebViewSettings(
                                  javaScriptEnabled: true,
                                  transparentBackground: true,
                                ),
                                onWebViewCreated: (controller) {
                                  _hiddenWebViewController = controller;
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),

              //],
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEditing) ...[
                      SizedBox(
                        height: 23,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!await PremiumGate.ensurePremium(context))
                              return;

                            setState(() {
                              _isPremium = true;
                            });
                            _isPremium ? _addLocalImage : null;
                          },
                          icon: const Icon(
                            Icons.add_photo_alternate,
                            color: Color(0xFFB8860B),
                          ),
                          label: Text(
                            L10n.of(context)!.detail_page_add_image,
                            style: TextStyle(
                              color: Color(0xFFB8860B),
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            //backgroundColor: Colors.black.withOpacity(0.5),
                            backgroundColor: Color(0xFF121212),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: 8),
                    Container(
                      margin: EdgeInsets.only(top: 2.0),
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          Text(
                            '$_localImageCorrentIndex/$_localImageMaxIndex',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.of(context)!.detail_page_rate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ratingButton(
                        'critical',
                        L10n.of(context)!.critical,
                        'assets/icons/critical.png',
                        'assets/icons/critical_gray.png',
                      ),
                      _ratingButton(
                        'normal',
                        L10n.of(context)!.normal,
                        'assets/icons/normal.png',
                        'assets/icons/normal_gray.png',
                      ),
                      _ratingButton(
                        'maniac',
                        L10n.of(context)!.maniac,
                        'assets/icons/maniac.png',
                        'assets/icons/maniac_gray.png',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              _buildListDropdownButton(),

              _buildTextField(_urlController, 'URL', 'https://...'),
              _buildTextField(
                _titleController,
                L10n.of(context)!.detail_page_title,
                L10n.of(context)!.detail_page_title_placeholder,
                withFetchTitle: true,
              ),
              _buildTextField(
                _castController,
                L10n.of(context)!.detail_page_cast,
                L10n.of(context)!.detail_page_cast_placeholder,
                autocompleteKey: 'cast',
              ),
              _buildTextField(
                _genreController,
                L10n.of(context)!.detail_page_genre,
                L10n.of(context)!.detail_page_genre_placeholder,
                autocompleteKey: 'genre',
              ),
              _buildTextField(
                _seriesController,
                L10n.of(context)!.detail_page_series,
                L10n.of(context)!.detail_page_series_placeholder,
                autocompleteKey: 'series',
              ),
              _buildTextField(
                _labelController,
                L10n.of(context)!.detail_page_label,
                L10n.of(context)!.detail_page_label_placeholder,
                autocompleteKey: 'label',
              ),
              _buildTextField(
                _makerController,
                L10n.of(context)!.detail_page_maker,
                L10n.of(context)!.detail_page_maker_placeholder,
                autocompleteKey: 'maker',
              ),
              _buildMemoTextField(),

              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  //===============
  //テキストフィールド
  //===============
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hintLabel, {
    bool withFetchTitle = false,
    String? autocompleteKey,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),

            /// 右側ボタン群
            Row(
              children: [
                /// URL用：ペーストボタン
                if (isEditing && controller == _urlController)
                  TextButton.icon(
                    icon: Icon(
                      Icons.paste,
                      size: 20,
                      color: colorScheme.onPrimary,
                    ),
                    label: Text(
                      L10n.of(context)!.detail_page_paste_url,
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data?.text != null) {
                        controller.text = data!.text!;
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      }
                    },
                  ),

                //URLからタイトル取得
                if (isEditing && withFetchTitle)
                  TextButton.icon(
                    onPressed: _fetchTitleFromUrl,
                    icon: Icon(
                      Icons.download,
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                    label: Text(
                      L10n.of(context)!.detail_page_fetch_title,
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 4),

        CompositedTransformTarget(
          link:
              autocompleteKey != null
                  ? _layerLinks[autocompleteKey]!
                  : LayerLink(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              controller: controller,
              readOnly: !isEditing,
              decoration: InputDecoration(
                hintText: hintLabel,
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: isEditing ? Colors.white : Colors.grey[300],
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  //オートコンプリート関連
  final _layerLinks = {
    'cast': LayerLink(),
    'genre': LayerLink(),
    'series': LayerLink(),
    'label': LayerLink(),
    'maker': LayerLink(),
  };

  OverlayEntry? _autocompleteOverlay;
  List<String> _suggestions = [];
  String _activeFieldKey = '';
  final Map<String, TextEditingController> _controllers = {};

  void _onFieldChanged(String fieldKey) async {
    final controller = _controllers[fieldKey]!;
    final text = controller.text;
    final cursorPos = controller.selection.base.offset;

    // カーソル位置の直前にある「#未確定文字列」を抽出
    final regex = RegExp(r'(?:^|\s)#([^\s#]*)$');
    final match = regex.firstMatch(text.substring(0, cursorPos));
    if (match == null) {
      _removeAutocompleteOverlay();
      return;
    }

    final inputTag = match.group(1)!; // 例: "あ" （"#"なし）
    if (inputTag.isEmpty && !text.endsWith('#')) {
      _removeAutocompleteOverlay();
      return;
    }

    // 候補を収集
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_metadata') ?? [];
    final Set<String> allTags = {};

    for (final item in savedList) {
      final map = jsonDecode(item);
      final field = map[fieldKey];
      if (field != null && field is String) {
        allTags.addAll(
          field.split('#').map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
      }
    }

    // 入力に部分一致するタグだけ抽出（大文字・小文字無視）
    final lowerInput = inputTag.toLowerCase();
    final filtered =
        allTags.where((tag) => tag.toLowerCase().contains(lowerInput)).toList();

    if (filtered.isEmpty) {
      _removeAutocompleteOverlay();
      return;
    }

    setState(() {
      _suggestions = filtered;
      _activeFieldKey = fieldKey;
    });

    _showAutocompleteOverlay(fieldKey);
  }

  void _showAutocompleteOverlay(String fieldKey) {
    _removeAutocompleteOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _autocompleteOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width - 32,
            //height: 300,
            child: CompositedTransformFollower(
              link: _layerLinks[fieldKey]!,
              showWhenUnlinked: false,
              offset: const Offset(0.0, 40.0),
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  height: (_suggestions.length * 60).clamp(0, 240).toDouble(),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    //shrinkWrap: true,
                    children:
                        _suggestions.map((suggestion) {
                          return ListTile(
                            title: Text(suggestion),
                            onTap: () {
                              final controller = _controllers[fieldKey]!;
                              final text = controller.text;
                              final cursorPos =
                                  controller.selection.base.offset;

                              // 置換対象の「#未確定文字列」を探す
                              final regex = RegExp(r'(?:^|\s)#([^\s#]*)$');
                              final match = regex.firstMatch(
                                text.substring(0, cursorPos),
                              );
                              if (match == null) return;

                              final start = match.start;
                              final newText = text.replaceRange(
                                start,
                                cursorPos,
                                '#$suggestion ',
                              );
                              controller.text = newText;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: start + suggestion.length + 2,
                                ),
                              );
                              _removeAutocompleteOverlay();
                            },
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(_autocompleteOverlay!);
  }

  void _removeAutocompleteOverlay() {
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
  }

  //===========================
  // リスト選択のドロップダウンリスト
  //===========================
  Widget _buildListDropdownButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context)!.detail_page_list,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isEditing ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                dropdownColor: Colors.white,

                items: [
                  DropdownMenuItem<String>(
                    value: noneListValue, // '選択なし'
                    child: Text(
                      L10n.of(context)!.detail_page_no_selected,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  ..._listNames.map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],

                value: isSelectedValue,

                onChanged:
                    !isEditing
                        ? null
                        : (String? value) {
                          if (value == null) return;
                          setState(() {
                            isSelectedValue = value;
                          });
                        },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();

    final loadedLists = prefs.getStringList('all_lists') ?? [];

    setState(() {
      _listNames = loadedLists; // ← ★ noneListValue を入れない

      if (widget.listName == null || widget.listName!.isEmpty) {
        isSelectedValue = noneListValue;
      } else if (_listNames.contains(widget.listName)) {
        isSelectedValue = widget.listName;
      } else {
        isSelectedValue = noneListValue;
      }
    });
  }

  //======================
  //メモ欄のテキストフィールド
  //======================
  Widget _buildMemoTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context)!.detail_page_memo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            //color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: _memoController,
            readOnly: !isEditing,
            keyboardType: TextInputType.multiline,
            maxLines: 15,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              hintText: L10n.of(context)!.detail_page_memo,
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: isEditing ? Colors.white : Colors.grey[300],
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 12.0, left: 12.0),
            ),
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
      ],
    );
  }

  //メタデータからタイトルを取得
  Future<void> _fetchTitleFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parse(response.body);

        final titleTag = document.getElementsByTagName('title').firstOrNull;
        if (titleTag != null) {
          setState(() {
            _titleController.text = titleTag.text.trim();
          });
        } else {
          _showMessage(L10n.of(context)!.detail_page_fetch_title_fail);
        }
      } else {
        _showMessage(L10n.of(context)!.detail_page_fetch_page_fail);
      }
    } catch (e) {
      _showMessage(L10n.of(context)!.detail_page_ex);
    }
  }

  //削除確認と削除処理
  void _confirmDelete() async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.secondary,
            title: Center(
              child: Text(
                L10n.of(context)!.detail_page_delete_confirm01,
                textAlign: TextAlign.center,
              ),
            ),
            content: Text(
              L10n.of(context)!.detail_page_delete_confirm02,
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                  foregroundColor: MaterialStateProperty.all(Colors.black),
                ),
                child: Text(L10n.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    colorScheme.primary,
                  ),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
                child: Text(L10n.of(context)!.delete),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('saved_metadata') ?? [];
      final rankingList = prefs.getStringList('saved_ranking') ?? [];

      final updatedList =
          savedList.where((item) {
            final map = jsonDecode(item) as Map<String, dynamic>;
            return map['url'] != widget.url;
          }).toList();

      final updatedRanking =
          rankingList
              .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
              .where((item) => item['url'] != widget.url)
              .map((item) => jsonEncode(item))
              .toList();

      await prefs.remove('saved_metadata');
      await prefs.setStringList('saved_metadata', updatedList);
      await prefs.setStringList('saved_ranking', updatedRanking);
      //final confirm = prefs.getStringList('saved_metadata');
      //print('saved: $confirm');

      Navigator.pop(context, true);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  //画像から色を取得
  Future<void> _updatePalette() async {
    //final colorScheme = Theme.of(context).colorScheme;

    try {
      final imageUrl = widget.image ?? _thumbnailUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        // URLがnullまたは空文字列の場合は早期リターン
        return;
      }

      final imageProvider = NetworkImage(imageUrl);

      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(imageProvider);

      setState(() {
        _dominantColor =
            paletteGenerator.dominantColor?.color ?? const Color(0xFF2C2C2C);
      });
    } catch (e) {
      // エラー発生時はデフォルト色を設定
      setState(() {
        //_dominantColor = colorScheme.secondary;
      });
      debugPrint('Failed to generate palette: $e');
    }
  }

  Widget _buildIconWithLabel(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl() async {
    final url = _urlController.text.trim();

    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }

    final encodedUrl = Uri.encodeFull(url);
    if (await canLaunch(encodedUrl)) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L10n.of(context)!.detail_page_url_unable)),
    );
  }

  //============
  //画像の保存機能
  //============

  //ローカル画像リストを定義
  List<String> _localImagePaths = [];

  //SharedPreferencesから画像パスを読み込み／保存
  Future<void> _loadLocalImages() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'local_images_${_urlController.text}';
    final fileNames = prefs.getStringList(key) ?? [];

    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      //_localImagePaths = paths;
      _localImagePaths =
          fileNames.map((name) => path.join(directory.path, name)).toList();
      _localImageMaxIndex = _localImagePaths.length + 1;
    });
  }

  //保存処理
  Future<void> _saveLocalImages() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'local_images_${_urlController.text}';
    final fileNames = _localImagePaths.map((p) => path.basename(p)).toList();
    await prefs.setStringList(key, fileNames);
  }

  //追加処理
  Future<void> _addLocalImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    // アプリ内にコピー
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
    final savedPath = path.join(directory.path, fileName);
    await File(pickedFile.path).copy(savedPath);

    setState(() {
      _localImagePaths.add(savedPath);
      _localImageMaxIndex = _localImagePaths.length + 1;
    });
  }

  //削除処理
  void _removeLocalImage(int index) async {
    final pathToRemove = _localImagePaths[index];

    setState(() {
      _localImagePaths.removeAt(index);
    });

    final file = File(pathToRemove);
    if (await file.exists()) {
      await file.delete(); // 実際にファイルも削除
    }

    await _saveLocalImages();
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

  /*
  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              Text(
                'ArchiVe プレミアム',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '• 広告なし\n• 好みの傾向がわかる統計機能\n• URLからタイトルを自動入力',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              Text(
                '¥170/月',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル', style: TextStyle(color: Colors.black)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                Navigator.pop(context);
                _startPurchase();
              },
              child: const Text('購入する', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _startPurchase() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (offering != null && offering.availablePackages.isNotEmpty) {
        final package = offering.availablePackages.first;

        // 購入処理（PurchaseResultを受け取る）
        final purchaseResult = await Purchases.purchasePackage(package);

        // 最新のCustomerInfoを取得
        final customerInfo = await Purchases.getCustomerInfo();

        // RevenueCatのEntitlement IDを確認（例: "premium"）
        if (customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('プレミアムを購入しました！')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('購入は完了しましたが、プレミアムが有効化されませんでした')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('購入可能なプランが見つかりません')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('購入エラー: $e')));
    }
  }
  */

  //*************
  //保存数の上限管理
  //*************
  //保存数の上限をカウント
  Future<int> _countSaveLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final extraSaveLimit = prefs.getInt('extra_save_limit') ?? 0;
    return 100 + extraSaveLimit;
  }

  //作品数カウント
  Future<int> _countSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];
    return list.length;
  }

  //作品数上限オーバー時の案内ダイアログ
  Future<void> _showSaveLimitDialog(int count, int limit) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(L10n.of(context)!.save_limit_dialog_title),
          content: Text(
            L10n.of(context)!.save_limit_dialog_description(limit, count),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context)!.back),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!await PremiumGate.ensurePremium(context)) return;

                setState(() {
                  _isPremium = true;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      L10n.of(context)!.save_limit_dialog_already_purchased,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.star, color: Color(0xFFB8860B)),
              label: Text(
                L10n.of(context)!.save_limit_dialog_premium_detail,
                style: TextStyle(
                  color: Color(0xFFB8860B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),

                backgroundColor: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> _checkPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['Premium Plan']?.isActive ?? false;
    } catch (e) {
      debugPrint('Subscription check error: $e');
      return false;
    }
  }

  //レビュー促進画面
  Future<void> showReviewPrompt(BuildContext context) async {
    final inAppReview = InAppReview.instance;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(L10n.of(context)!.detail_page_review_confirm01),
          content: Text(L10n.of(context)!.detail_page_review_confirm02),
          actions: [
            TextButton(
              child: Text(L10n.of(context)!.no),
              onPressed: () {
                Navigator.pop(context);
                _openSupport(); // 下で定義
              },
            ),
            ElevatedButton(
              child: Text(L10n.of(context)!.yes),
              onPressed: () async {
                Navigator.pop(context);

                if (await inAppReview.isAvailable()) {
                  await inAppReview.requestReview();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'walkinggoblins@gmail.com',
      query: Uri.encodeQueryComponent(
        L10n.of(context)!.detail_page_mail_subject,
      ),
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _maybeShowReviewPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    final alreadyReviewed = prefs.getBool('review_prompted') ?? false;
    final saveCount = prefs.getInt('save_count') ?? 0;

    await prefs.setInt('save_count', saveCount + 1);

    // 例：10件目で1回だけ表示
    if (!alreadyReviewed && saveCount + 1 >= 10) {
      await prefs.setBool('review_prompted', true);
      if (!mounted) return;
      await showReviewPrompt(context);
    }
  }
}
