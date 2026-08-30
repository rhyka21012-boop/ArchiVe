import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'activity_service.dart';

import 'view_counter.dart';
import 'premium_detail.dart';
import 'pro_detail.dart';
import 'ai_service.dart';
import 'l10n/app_localizations.dart';
import 'tutorial_page.dart';
import 'random_image_reload_provider.dart';
import 'search_result_page.dart';
import "save_limit_helper.dart";
import 'rating_label_provider.dart';
import 'circle_app_bar_icon.dart';

class DetailPage extends ConsumerStatefulWidget {
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
  // true の時、URL から自動でタイトルを取得して埋める (クリップボードフックからの遷移用)
  final bool autoFetchTitle;

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
    this.autoFetchTitle = false,
  });

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
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

  //選択中の評価
  String? selectedRating;

  //背景の初期色
  Color _dominantColor = Colors.transparent;

  //視聴数カウント
  int count = 0;

  //新旧比較用のURL
  late String _originalUrl;

  //サムネ押下時のアニメーション
  bool _isPressed = false;

  //メモ欄
  // {'type': 'text'|'image', 'content': String}
  List<Map<String, dynamic>> memoItems = [];

  //final FocusNode _focusNode = FocusNode();

  bool _isPremium = false;
  bool _isPro = false;
  // 非 Pro 向けに「AI タグ提案 FAB」を今日だけ非表示にするフラグ
  // (ユーザーが FAB 右上の × を押した日付を prefs に保存し翌日には自動復帰)
  bool _aiFabHiddenToday = false;
  // 非 Pro 向けの AI タグ提案 1日1回制限用: 最終利用日 (yyyy-MM-dd)
  String? _aiLastUsedDate;
  static const _kPrefAiFabHiddenDate = 'ai_fab_hidden_date';
  static const _kPrefAiLastUsedDate = 'ai_last_used_date';

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

  //チュートリアル用
  final GlobalKey _urlFieldKey = GlobalKey();
  final GlobalKey _fetchTitleKey = GlobalKey();
  final GlobalKey _saveIconKey = GlobalKey();
  Rect? _urlRect;
  Rect? _fetchRect;
  Rect? _saveRect;

  //スクロールコントローラ
  //final ScrollController _scrollController = ScrollController();

  //タイトルフェチ中判定
  bool _isFetchingTitle = false;
  bool _isFetchingAi = false;

  // AppBar/FAB: Twitter風 - 下スクロールで隠す、上スクロールで表示
  final ScrollController _detailScrollController = ScrollController();
  bool _showChrome = true;
  double _lastScrollOffset = 0;

  RewardedAd? _rewardedAd;

  bool _isLoadingThumbnail = false;
  bool _showSkipButton = false;
  // バックグラウンド (init / URL focus-out) 起点の非表示フェッチと
  // 保存時起点のフェッチを1本のフューチャで管理し、二重発火を防ぐ
  Future<void>? _thumbnailFetchFuture;
  // 既に取得済み or 取得試行済みの URL (URL 変更時に再取得を許可するために比較)
  String? _thumbnailUrlSource;
  // URL 欄フォーカス変化を検知するためのフォーカスノード
  final FocusNode _urlFocusNode = FocusNode();
  bool _cancelThumbnailFetch = false;
  Timer? _skipTimer;

  void _loadAd() {
    String adUnitId;

    const bool isTest = false; // ←テスト時だけtrueにする

    if (isTest) {
      adUnitId = 'ca-app-pub-3940256099942544/1712485313';
    } else if (Platform.isAndroid) {
      adUnitId = 'ca-app-pub-8268997781284735/8948638186';
    } else if (Platform.isIOS) {
      adUnitId = 'ca-app-pub-8268997781284735/5356923320';
    } else {
      return;
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;

          /// ⭐ 見終わったら自動再ロード（超重要）
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    // Twitter風スクロール検知：下スクロールで隠す、上スクロール（または最上部）で表示
    _detailScrollController.addListener(() {
      final offset = _detailScrollController.offset;
      if (offset <= 40) {
        if (!_showChrome) setState(() => _showChrome = true);
      } else if (offset > _lastScrollOffset + 8 && _showChrome) {
        setState(() => _showChrome = false);
      } else if (offset < _lastScrollOffset - 8 && !_showChrome) {
        setState(() => _showChrome = true);
      }
      _lastScrollOffset = offset;
    });
    //_initializeFirebase();

    if ((widget.image == null || widget.image!.isEmpty) && widget.url != null) {
      //_initializeThumbnail(widget.url!); //URLから取得
    } else {
      _thumbnailUrl = widget.image; //保存済み画像を使う
    }
    _updatePalette();

    _loadAd();

    _originalUrl = widget.url ?? '';
    _urlController.text = _originalUrl;
    _controllers['cast'] = _castController;
    _controllers['genre'] = _genreController;
    _controllers['series'] = _seriesController;
    _controllers['label'] = _labelController;
    _controllers['maker'] = _makerController;

    for (final key in _controllers.keys) {
      _focusNodes[key] = FocusNode();
      _hashButtonFocusNodes[key] = FocusNode(
        skipTraversal: true,
        canRequestFocus: false,
      );
    }

    for (final key in _controllers.keys) {
      _controllers[key]!.addListener(() => _onFieldChanged(key));
    }

    _checkSubscriptionStatus();
    _loadAiFabHiddenState();

    _loadLists();

    _loadLocalImages();

    // クリップボードフックからの遷移時など、URL のみ渡された場合に
    // タイトルも自動でフェッチしてフィールドに埋める
    if (widget.autoFetchTitle &&
        (widget.title == null || widget.title!.trim().isEmpty) &&
        (widget.url != null && widget.url!.trim().isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchTitleFromUrl();
      });
    }

    // URL 欄のフォーカスが外れたタイミングで、まだ未取得ならサムネを
    // バックグラウンドでフェッチしておく (保存押下時の待ち時間短縮)
    _urlFocusNode.addListener(() {
      if (_urlFocusNode.hasFocus) return;
      if (!isEditing) return;
      final url = _urlController.text.trim();
      if (url.isEmpty) return;
      _startBackgroundThumbnailFetch(url);
    });

    // URL があらかじめ入っている場合は開いた直後にバックグラウンドで取得開始
    if (widget.url != null &&
        widget.url!.trim().isNotEmpty &&
        (widget.image == null || widget.image!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startBackgroundThumbnailFetch(widget.url!);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final step = ref.read(tutorialStepProvider);

      if (step == TutorialStep.createItem) {
        ref.read(tutorialStepProvider.notifier).state = TutorialStep.inputUrl;
      }

      if (ref.read(tutorialStepProvider.notifier).state ==
          TutorialStep.inputUrl) {
        _urlController.text =
            'https://www.youtube.com/watch?v=sPyAQQklc1s';
      }

      final ctx = _urlFieldKey.currentContext;
      if (ctx != null) {
        _urlRect = getRectFromKey(_urlFieldKey, context);
        _fetchRect = getRectFromKey(_fetchTitleKey, context);
        _saveRect = getRectFromKey(_saveIconKey, context);
        setState(() {});
      }
    });
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

  /// 保存ボタン押下時に呼ばれるエントリ。
  /// - 既にサムネ取得済み → 即 return
  /// - バックグラウンドフェッチが実行中 → その future をローディングUI付きで await
  /// - どちらでもなければ、ローディングUI付きで新規フェッチ
  Future<void> _initializeThumbnail(String url) async {
    if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty) return;

    if (_thumbnailFetchFuture != null) {
      // 進行中のバックグラウンドフェッチを、ローディングUIを出しつつ待つ
      _cancelThumbnailFetch = false;
      setState(() {
        _isLoadingThumbnail = true;
        _showSkipButton = false;
      });
      _skipTimer?.cancel();
      _skipTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _showSkipButton = true;
        });
      });
      try {
        await _thumbnailFetchFuture;
      } catch (_) {}
      _skipTimer?.cancel();
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
          _showSkipButton = false;
        });
      }
      // フェッチ成功でサムネがセットされた場合は永続化
      if (mounted &&
          _thumbnailUrl != null &&
          _thumbnailUrl!.isNotEmpty) {
        await _saveChanges(exitEditMode: false);
      }
      return;
    }

    // 通常フロー: 表示付き + 永続化
    await _runThumbnailFetch(url, showUi: true, persist: true);
  }

  /// URL 入力直後や URL 欄フォーカスアウト時に呼ぶバックグラウンドフェッチ。
  /// - ローディングUIは出さない
  /// - フェッチ結果は _thumbnailUrl にセットするのみで、prefs への永続化はしない
  ///   (ユーザーが保存ボタンを押した時に既存の保存フローで書き込まれる)
  void _startBackgroundThumbnailFetch(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    // 既存の画像 (widget.image) がある場合はフェッチしない
    if (widget.image != null && widget.image!.isNotEmpty) return;
    // このURLで既にサムネ取得済み
    if (_thumbnailUrl != null &&
        _thumbnailUrl!.isNotEmpty &&
        _thumbnailUrlSource == trimmed) {
      return;
    }
    // 既にフェッチ中
    if (_thumbnailFetchFuture != null) return;
    _thumbnailFetchFuture =
        _runThumbnailFetch(trimmed, showUi: false, persist: false);
  }

  /// サムネフェッチ本体。showUi/persist で挙動を切り替える。
  Future<void> _runThumbnailFetch(
    String url, {
    required bool showUi,
    required bool persist,
  }) async {
    _cancelThumbnailFetch = false;
    if (showUi) {
      setState(() {
        _isLoadingThumbnail = true;
        _showSkipButton = false;
      });
      _skipTimer?.cancel();
      _skipTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _showSkipButton = true;
        });
      });
    }
    try {
      final thumb = await fetchThumbnailByWebView(url);
      if (!mounted || _cancelThumbnailFetch) return;
      if (thumb != null && thumb.isNotEmpty) {
        setState(() {
          _thumbnailUrl = thumb;
          _thumbnailUrlSource = url;
        });
        if (persist) {
          await _saveChanges(exitEditMode: false);
        }
      } else {
        // 空 URL でも「この URL は試した」記録は残さない
        // (失敗時は次回同一 URL でも再フェッチできるようにする)
      }
    } finally {
      _thumbnailFetchFuture = null;
      _skipTimer?.cancel();
      if (mounted && showUi) {
        setState(() {
          _isLoadingThumbnail = false;
          _showSkipButton = false;
        });
      }
    }
  }

  //サムネ取得をスキップ
  void _skipThumbnail() async {
    _cancelThumbnailFetch = true;
    _skipTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _isLoadingThumbnail = false;
      _showSkipButton = false;
    });

    // サムネなしで保存
    await _saveChanges(exitEditMode: false);
  }

  //****サムネイル取得処理****
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
          Duration(seconds: 30),
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
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all(
                      colorScheme.primary,
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: Text(L10n.of(context)!.ok),
                ),
              ],
            ),
      );
      return; // 保存処理を中断
    }

    // URLが変更されている場合の処理
    if (widget.url != null && _originalUrl.trim() != newUrl) {
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
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all(
                      Colors.grey[300],
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.black),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: Text(L10n.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all(
                      colorScheme.primary,
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: Text(L10n.of(context)!.ok),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      /// 作品数上限チェック
      if (!await SaveLimitHelper.canSave(context, _rewardedAd, ref)) {
        _loadAd();
        return;
      }

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
      await _initializeThumbnail(_urlController.text);
      setState(() => isEditing = false);
    }

    //保存完了時
    if (success) {
      // 新規保存 (URL 一致なし = 追加) のみ ActivityService に記録
      if (!found) {
        // ignore: unawaited_futures
        ActivityService.incrementSaveCount();
      }
      //RandomImageを更新
      ref.read(randomImageReloadProvider.notifier).state++;

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
    _detailScrollController.dispose();
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    for (final focusNode in _hashButtonFocusNodes.values) {
      focusNode.dispose();
    }
    _urlFocusNode.dispose();
    _skipTimer?.cancel();
    super.dispose();
  }

  // 編集モード時の AppBar (削除 / ブラウザ / 保存など従来のアクション)
  AppBar _buildEditingAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipBg = Colors.white.withValues(alpha: 0.9);
    return AppBar(
      backgroundColor: const Color(0xFF121212).withOpacity(0.3),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: CircleAppBarIcon(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).maybePop(),
        backgroundColor: chipBg,
      ),
      title: Text(
        L10n.of(context)!.detail_page_item_detail,
        style: const TextStyle(color: Colors.white),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        CircleAppBarIcon(
          icon: Icons.delete,
          tooltip: L10n.of(context)!.detail_page_delete,
          onPressed: _confirmDelete,
          backgroundColor: chipBg,
        ),
        Padding(
          key: _saveIconKey,
          padding:
              const EdgeInsets.only(right: 12, top: 6, bottom: 6, left: 4),
          child: _pillButton(
            label: L10n.of(context)!.detail_page_save,
            bg: colorScheme.primary,
            fg: Colors.white,
            onTap: _saveChanges,
          ),
        ),
      ],
    );
  }

  // 閲覧モード時の AppBar (円形バック / タイトル / 共有ピル / 編集ピル)
  AppBar _buildReadOnlyAppBar(BuildContext context, ColorScheme colorScheme) {
    // パレット由来の背景に対しても読みやすい文字色を選ぶ
    final headerTextColor = _dominantColor == Colors.transparent
        ? Colors.black87
        : (_dominantColor.computeLuminance() > 0.5
            ? Colors.black87
            : Colors.white);
    final chipBg = headerTextColor == Colors.white
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.white;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
        child: Material(
          color: chipBg,
          shape: const CircleBorder(),
          elevation: 1,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back, size: 20, color: Colors.black87),
            ),
          ),
        ),
      ),
      title: Text(
        L10n.of(context)!.detail_page_item_detail,
        style: TextStyle(
          color: headerTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        CircleAppBarIcon(
          icon: Icons.ios_share,
          tooltip: L10n.of(context)!.detail_page_share,
          onPressed: _shareItem,
          backgroundColor: chipBg,
        ),
        CircleAppBarIcon(
          icon: Icons.open_in_new,
          tooltip: L10n.of(context)!.detail_page_access,
          onPressed: _launchUrl,
          backgroundColor: chipBg,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6, left: 4),
          child: _pillButton(
            label: L10n.of(context)!.detail_page_modify,
            bg: colorScheme.primary,
            fg: Colors.white,
            onTap: () => setState(() => isEditing = true),
          ),
        ),
      ],
    );
  }

  Widget _pillButton({
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 評価アイコン3種 (編集/閲覧モード共通)
  Widget _buildRatingSection(ColorScheme colorScheme, {bool showLabel = true}) {
    final labels = ref.watch(ratingLabelsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Text(
            L10n.of(context)!.detail_page_rate,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        // 3等分の Expanded スロットに割り当てることで、評価名の長さに関わらず
        // ボタン位置が固定される。長い名前は省略表示。
        Row(
          children: [
            Expanded(
              child: _ratingButton(
                'critical',
                ratingLabelOf(context, labels, kRatingCritical),
                'assets/icons/critical.png',
                'assets/icons/critical_gray.png',
              ),
            ),
            Expanded(
              child: _ratingButton(
                'normal',
                ratingLabelOf(context, labels, kRatingNormal),
                'assets/icons/normal.png',
                'assets/icons/normal_gray.png',
              ),
            ),
            Expanded(
              child: _ratingButton(
                'maniac',
                ratingLabelOf(context, labels, kRatingManiac),
                'assets/icons/maniac.png',
                'assets/icons/maniac_gray.png',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 閲覧モードのタイトル (太字大 - サブタイトルは廃止)
  Widget _buildReadOnlyTitle(ColorScheme colorScheme) {
    final title = _titleController.text.trim().isEmpty
        ? (widget.url ?? '')
        : _titleController.text.trim();
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimary,
          height: 1.3,
        ),
      ),
    );
  }

  // 閲覧モードの情報カード (リスト / URL / 出演 / ジャンル / シリーズ / メーカー / レーベル)
  Widget _buildReadOnlyInfoCard(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final url = _urlController.text.trim();
    final rows = <_InfoRowSpec>[
      if ((widget.listName ?? '').isNotEmpty)
        _InfoRowSpec(L10n.of(context)!.detail_page_list, widget.listName!),
      if (url.isNotEmpty)
        _InfoRowSpec(
          'URL',
          url,
          trailing: _CopyIconButton(
            value: url,
            iconColor: isDark ? Colors.white70 : Colors.grey.shade500,
            copiedLabel: L10n.of(context)!.detail_page_copied,
          ),
        ),
      if (_castController.text.trim().isNotEmpty)
        _InfoRowSpec(
          L10n.of(context)!.detail_page_cast_short,
          _castController.text.trim(),
        ),
      if (_genreController.text.trim().isNotEmpty)
        _InfoRowSpec(
          L10n.of(context)!.detail_page_genre_short,
          _genreController.text.trim(),
        ),
      if (_seriesController.text.trim().isNotEmpty)
        _InfoRowSpec(
          L10n.of(context)!.detail_page_series_short,
          _seriesController.text.trim(),
        ),
      if (_makerController.text.trim().isNotEmpty)
        _InfoRowSpec(
          L10n.of(context)!.detail_page_maker_short,
          _makerController.text.trim(),
        ),
      if (_labelController.text.trim().isNotEmpty)
        _InfoRowSpec(
          L10n.of(context)!.detail_page_label_short,
          _labelController.text.trim(),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final labelColor = isDark ? Colors.white60 : Colors.grey.shade500;
    final valueColor = isDark ? Colors.white : Colors.black87;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: dividerColor),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(
                        rows[i].label,
                        style: TextStyle(fontSize: 13, color: labelColor),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rows[i].value,
                        style: TextStyle(
                          fontSize: 14,
                          color: valueColor,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (rows[i].trailing != null) ...[
                      const SizedBox(width: 8),
                      rows[i].trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
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

    final tutorialStep = ref.watch(tutorialStepProvider);

    return Stack(
      children: [
        WillPopScope(
          onWillPop: () async => !_isLoadingThumbnail,
          child: Scaffold(
            //backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                offset: _showChrome ? Offset.zero : const Offset(0, -1.5),
                child: isEditing
                    ? _buildEditingAppBar(context)
                    : _buildReadOnlyAppBar(context, colorScheme),
              ),
            ),
            floatingActionButton: isEditing &&
                    !(!_isPro && _aiFabHiddenToday)
                ? _buildAiTagFab(colorScheme)
                : null,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_dominantColor, colorScheme.secondary],
                ),
              ),
              child: SingleChildScrollView(
                controller: _detailScrollController,
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
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      //height: 200,
                      child: PageView.builder(
                        itemCount:
                            _localImagePaths.length +
                            1, //1ページ目：サムネ、2ページ目以降：ローカル画像
                        onPageChanged: (index) {
                          setState(() {
                            _localImageCorrentIndex = index + 1;
                          });
                        },
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            /*
                          //サムネ取得中
                          if (_isLoadingThumbnail) {
                            return Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ViewingCounterWidget(url: widget.url),
                                ),
                              ],
                            );
                          }
                          */

                            //サムネ表示
                            if ((widget.image ?? _thumbnailUrl) != null) {
                              return AnimatedScale(
                                scale: _isPressed ? 0.94 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
                                child: GestureDetector(
                                  onTapDown:
                                      (_) => setState(() => _isPressed = true),
                                  onTapUp:
                                      (_) => setState(() => _isPressed = false),
                                  onTapCancel:
                                      () => setState(() => _isPressed = false),
                                  onTap: () => openPlayer(widget.url!),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        /// 背景画像
                                        Image.network(
                                          widget.image ?? _thumbnailUrl!,
                                          width: double.infinity,
                                          //height: 200,
                                          fit: BoxFit.cover,
                                        ),

                                        /// ⭐ ファビコン（左下）
                                        Positioned(
                                          left: 8,
                                          bottom: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Image.network(
                                              _getFaviconUrl(
                                                _urlController.text,
                                              ),
                                              width: 20,
                                              height: 20,
                                              errorBuilder:
                                                  (_, __, ___) =>
                                                      const SizedBox(),
                                            ),
                                          ),
                                        ),

                                        /// 再生ボタン
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),

                                        /// 下部情報バー
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          right: 8,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              /// 再生時間（後程実装する）
                                              /*
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                "00:32",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ), */
                                              SizedBox(),

                                              /// 閲覧数
                                              ViewingCounterWidget(
                                                url: widget.url,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              //サムネ未取得
                              return GestureDetector(
                                onTap: () {
                                  if (widget.url != null &&
                                      widget.url!.isNotEmpty) {
                                    openPlayer(widget.url!);
                                  }
                                },
                                child: Stack(
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
                                      child: ViewingCounterWidget(
                                        url: widget.url,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else {
                            final imageIndex = index - 1;
                            final imageWidget = Image.file(
                              File(_localImagePaths[imageIndex]),
                              fit: BoxFit.contain,
                              width: double.infinity,
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
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
                                      onTap:
                                          () => _removeLocalImage(imageIndex),
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
                    SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          //ローカル画像追加
                          if (isEditing) ...[
                            TextButton.icon(
                              onPressed: () async {
                                //プレミアム判定
                                if (!await PremiumGate.ensurePremium(context))
                                  return;

                                setState(() {
                                  _isPremium = true;
                                });
                                _isPremium ? _addLocalImage() : null;

                                //_addLocalImage(); //デバッグ用切り替え箇所
                              },
                              icon: const Icon(
                                Icons.add_photo_alternate,
                                color: Color(0xFFB8860B),
                              ),
                              label: Text(
                                L10n.of(context)!.detail_page_add_image, //画像を追加
                                style: TextStyle(
                                  color: Color(0xFFB8860B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(width: 8),

                          //ローカル画像の枚数
                          _localImageMaxIndex > 1
                              ? Container(
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : SizedBox(),
                        ],
                      ),
                    ),

                    SizedBox(height: isEditing ? 10 : 4),
                    if (isEditing) ...[
                      _buildRatingSection(colorScheme),
                      //リスト一覧
                      _buildListDropdownButton(),

                      //URL入力欄
                      _buildTextField(_urlController, 'URL', 'https://...'),

                      //タイトル入力欄
                      _buildTextField(
                        _titleController,
                        L10n.of(context)!.detail_page_title,
                        L10n.of(context)!.detail_page_title_placeholder,
                        withFetchTitle: true,
                      ),

                      //出演入力欄
                      _buildTextField(
                        _castController,
                        L10n.of(context)!.detail_page_cast,
                        L10n.of(context)!.detail_page_cast_placeholder,
                        autocompleteKey: 'cast',
                      ),

                      //ジャンル入力欄
                      _buildTextField(
                        _genreController,
                        L10n.of(context)!.detail_page_genre,
                        L10n.of(context)!.detail_page_genre_placeholder,
                        autocompleteKey: 'genre',
                      ),

                      //シリーズ入力欄
                      _buildTextField(
                        _seriesController,
                        L10n.of(context)!.detail_page_series,
                        L10n.of(context)!.detail_page_series_placeholder,
                        autocompleteKey: 'series',
                      ),

                      //メーカー入力欄
                      _buildTextField(
                        _makerController,
                        L10n.of(context)!.detail_page_maker,
                        L10n.of(context)!.detail_page_maker_placeholder,
                        autocompleteKey: 'maker',
                      ),

                      //レーベル入力欄
                      _buildTextField(
                        _labelController,
                        L10n.of(context)!.detail_page_label,
                        L10n.of(context)!.detail_page_label_placeholder,
                        autocompleteKey: 'label',
                      ),

                      //メモ欄
                      _buildMemoTextField(),
                    ] else ...[
                      _buildReadOnlyTitle(colorScheme),
                      const SizedBox(height: 14),
                      _buildRatingSection(colorScheme, showLabel: false),
                      const SizedBox(height: 16),
                      _buildReadOnlyInfoCard(colorScheme),
                    ],

                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ===== チュートリアル：createItem =====
        //チュートリアル：URLを入力
        if (tutorialStep == TutorialStep.inputUrl) ...[
          TutorialOverlayPseudoTap(
            holeRect: _urlRect ?? Rect.zero,
            onTap: () {
              //タイトル取得ボタンはスクロールのため、別途関数を呼び出す
              startFetchTitleTutorial();
            },
          ),
          // 説明バルーン
          _buildBalloonFromRect(
            _urlRect ?? Rect.zero,
            L10n.of(context)!.tutorial_04,
            offsetY: -60,
          ),
        ],

        //チュートリアル：タイトルを取得
        if (tutorialStep == TutorialStep.fetchTitle) ...[
          TutorialOverlayPseudoTap(
            holeRect: getRectFromKey(_fetchTitleKey, context),
            onTap: () async {
              await _fetchTitleFromUrl();
              if (!mounted) return;
              // 保存ボタンまで確実にスクロールしてAppBarを表示
              await startSaveTutorial();
            },
          ),
          _buildBalloonFromRect(
            getRectFromKey(_fetchTitleKey, context),
            L10n.of(context)!.tutorial_05,
            offsetX: -140,
            offsetY: -60,
          ),
        ],

        //チュートリアル：アイテムを保存
        if (tutorialStep == TutorialStep.saveItem) ...[
          TutorialOverlayPseudoTap(
            holeRect: getRectFromKey(_saveIconKey, context),
            onTap: () async {
              await _saveChanges();
              ref.read(tutorialStepProvider.notifier).state = TutorialStep.done;
            },
          ),
          _buildBalloonFromRect(
            getRectFromKey(_saveIconKey, context),
            L10n.of(context)!.tutorial_06,
            offsetX: -190,
            offsetY: 70,
          ),
        ],
        if (tutorialStep == TutorialStep.done)
          TutorialCompleteOverlay(
            onFinished: () async {
              final navigator = Navigator.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isFirstLaunch', false);

              ref.read(isTutorialModeProvider.notifier).state = false;
              ref.read(tutorialStepProvider.notifier).state = TutorialStep.none;

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const PostTutorialPremiumPromptPage(),
                ),
                (_) => false,
              );
            },
          ),

        if (_isLoadingThumbnail)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    L10n.of(context)!.detail_page_fetching_thumbnail,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_showSkipButton)
                    ElevatedButton(
                      onPressed: _skipThumbnail,
                      child: Text(L10n.of(context)!.skip),
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
                    ),
                ],
              ),
            ),
          ),
      ],
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
    final hashHintLabel =
        autocompleteKey == null ? null : _hashHintLabel(label);
    final focusNode =
        autocompleteKey == null ? null : _focusNodes[autocompleteKey];
    final hashButtonFocusNode =
        autocompleteKey == null ? null : _hashButtonFocusNodes[autocompleteKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _baseLabel(label),
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
                        // ペースト直後にバックグラウンドでサムネ取得を開始
                        _startBackgroundThumbnailFetch(controller.text);
                      }
                    },
                  ),

                //URLからタイトル取得
                if (isEditing && withFetchTitle)
                  TextButton.icon(
                    key: _fetchTitleKey,
                    onPressed: _fetchTitleFromUrl,
                    icon:
                        _isFetchingTitle
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(
                              Icons.download,
                              size: 18,
                              color: colorScheme.onPrimary,
                            ),
                    label: Text(
                      L10n.of(context)!.detail_page_fetch_title,
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                  ),


                if (isEditing &&
                    hashHintLabel != null &&
                    focusNode != null &&
                    hashButtonFocusNode != null)
                  TextButton.icon(
                    focusNode: hashButtonFocusNode,
                    onPressed: () => _insertHash(controller, focusNode),
                    icon: Icon(
                      Icons.tag,
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                    label: Text(
                      hashHintLabel,
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 4),

        CompositedTransformTarget(
          key: controller == _urlController ? _urlFieldKey : null,
          link:
              autocompleteKey != null
                  ? _layerLinks[autocompleteKey]!
                  : LayerLink(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              controller: controller,
              // URL 欄はフォーカス変化を検知したいので専用のノードを渡す
              focusNode:
                  controller == _urlController ? _urlFocusNode : focusNode,
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
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, FocusNode> _hashButtonFocusNodes = {};

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

  String _baseLabel(String label) {
    final match = RegExp(r'^(.*?)\s*\((#[^)]+)\)$').firstMatch(label);
    return match?.group(1) ?? label;
  }

  String? _hashHintLabel(String label) {
    final match = RegExp(r'^(.*?)\s*\((#[^)]+)\)$').firstMatch(label);
    return match?.group(2);
  }

  void _insertHash(TextEditingController controller, FocusNode focusNode) {
    if (!isEditing) return;

    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : controller.text.length;

    final newText = controller.text.replaceRange(start, end, '#');
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 1),
    );

    focusNode.requestFocus();
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
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isEditing ? Colors.white : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  menuMaxHeight: 300,
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

  /// AI タグ提案 FAB（Twitter風：下スクロールで隠す、上で表示）
  Widget _buildAiTagFab(ColorScheme colorScheme) {
    const tealDeep = Color(0xFF00695C);
    const tealLight = Color(0xFF26A69A);
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [tealDeep, tealLight, tealDeep],
      stops: [0.0, 0.5, 1.0],
    );
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      offset: _showChrome ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: _showChrome ? 1.0 : 0.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: tealLight.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _isFetchingAi ? null : _aiSuggestTags,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isFetchingAi
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.auto_awesome,
                                size: 20,
                                color: Colors.white,
                              ),
                        const SizedBox(width: 8),
                        Text(
                          L10n.of(context)!.detail_page_ai_suggest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 非 Pro ユーザー向けの「今日だけ非表示」× ボタン
            if (!_isPro)
              Positioned(
                top: -8,
                right: -8,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _hideAiFabForToday,
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// AI でタグを提案し、確認ダイアログでユーザーが採用チップを選んでから反映。
  /// - Pro: 無制限
  /// - 無料 / Premium: 1 日 1 回まで。上限到達時は Pro 誘導ダイアログ
  Future<void> _aiSuggestTags() async {
    if (_isFetchingAi) return;

    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    if (url.isEmpty && title.isEmpty) return;

    // 非 Pro は 1日1回制限。今日既に使っていたら Pro 案内を出して return
    if (!_isPro && _aiLastUsedDate == _todayKey()) {
      await _showAiDailyLimitDialog();
      return;
    }

    setState(() => _isFetchingAi = true);
    SuggestedTags? tags;
    bool serverDailyLimit = false;
    try {
      tags = await AiService.suggestTags(
        url: url,
        title: title,
        isPro: _isPro,
      );
    } on FirebaseFunctionsException catch (e) {
      // サーバ側の 1日1回制限に到達
      if (e.code == 'resource-exhausted') {
        serverDailyLimit = true;
      } else if (mounted) {
        _showMessage('${L10n.of(context)!.detail_page_ai_error}: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('${L10n.of(context)!.detail_page_ai_error}: $e');
      }
    } finally {
      if (mounted) setState(() => _isFetchingAi = false);
    }

    if (!mounted) return;

    if (serverDailyLimit) {
      // サーバ側でも今日の利用が確認されたので、ローカルも同期
      if (!_isPro) {
        final prefs = await SharedPreferences.getInstance();
        final today = _todayKey();
        await prefs.setString(_kPrefAiLastUsedDate, today);
        if (mounted) setState(() => _aiLastUsedDate = today);
      }
      await _showAiDailyLimitDialog();
      return;
    }
    if (tags == null) return;

    // 呼び出し成功時のみ、非 Pro の利用日をローカルにも記録
    if (!_isPro) {
      final prefs = await SharedPreferences.getInstance();
      final today = _todayKey();
      await prefs.setString(_kPrefAiLastUsedDate, today);
      if (mounted) setState(() => _aiLastUsedDate = today);
    }

    // AI 提案の実行回数を Firestore に記録 (Pro / 非 Pro 問わず)
    // ignore: unawaited_futures
    ActivityService.incrementAiSuggestCount();

    if (tags.isEmpty) {
      _showMessage(L10n.of(context)!.detail_page_ai_no_suggestions);
      return;
    }
    await _showAiTagSuggestionDialog(tags);
  }

  /// 1日 1回の上限に達した時の Pro 誘導ダイアログ
  Future<void> _showAiDailyLimitDialog() async {
    final l = L10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final upgrade = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Text(l.detail_page_ai_daily_limit_title),
        content: Text(l.detail_page_ai_daily_limit_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l.close),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(l.detail_page_ai_upgrade_pro),
          ),
        ],
      ),
    );
    if (upgrade != true || !mounted) return;
    // Pro 購入導線 (既存 ProGate を再利用)
    final bought = await ProGate.ensureProPurchaseFirst(context);
    if (bought && mounted) {
      setState(() => _isPro = true);
    }
  }

  Future<void> _showAiTagSuggestionDialog(SuggestedTags tags) async {
    final l = L10n.of(context)!;
    // カテゴリごとの提案タグとキー・コントローラのマップ
    final sections = <_AiTagSection>[
      _AiTagSection(l.detail_page_cast_short, tags.cast, _castController),
      _AiTagSection(l.detail_page_genre_short, tags.genre, _genreController),
      _AiTagSection(l.detail_page_series_short, tags.series, _seriesController),
      _AiTagSection(l.detail_page_maker_short, tags.maker, _makerController),
      _AiTagSection(l.detail_page_label_short, tags.label, _labelController),
    ].where((s) => s.suggestions.isNotEmpty).toList();

    // 初期は全て採用 (true) にしておき、ユーザーは外したいものだけタップ
    final selected = <String, Set<String>>{
      for (final s in sections) s.label: {...s.suggestions},
    };

    final applied = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final colorScheme = Theme.of(dialogCtx).colorScheme;
        return StatefulBuilder(
          builder: (_, setDlg) => AlertDialog(
            backgroundColor: colorScheme.secondary,
            title: Text(l.detail_page_ai_suggest_dialog_title),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.detail_page_ai_suggest_dialog_hint,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final section in sections) ...[
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 6, bottom: 6),
                        child: Text(
                          section.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: section.suggestions.map((tag) {
                          final isOn =
                              selected[section.label]!.contains(tag);
                          return FilterChip(
                            label: Text('#$tag'),
                            selected: isOn,
                            showCheckmark: false,
                            visualDensity: const VisualDensity(
                              horizontal: -1,
                              vertical: -1,
                            ),
                            labelStyle: TextStyle(
                              color: isOn
                                  ? Colors.white
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.75),
                              fontWeight: isOn
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            selectedColor: colorScheme.primary,
                            backgroundColor: colorScheme.onSurface
                                .withValues(alpha: 0.08),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (v) {
                              setDlg(() {
                                if (v) {
                                  selected[section.label]!.add(tag);
                                } else {
                                  selected[section.label]!.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: TextButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l.detail_page_ai_apply),
              ),
            ],
          ),
        );
      },
    );

    if (applied != true || !mounted) return;

    // 既存タグに採用チップを追加し、重複除去して再セット
    setState(() {
      for (final s in sections) {
        final chosen = selected[s.label] ?? const <String>{};
        if (chosen.isEmpty) continue;
        final existing = _parseHashtags(s.controller.text);
        final merged = <String>[
          ...existing,
          ...chosen.where((t) => !existing.contains(t)),
        ];
        s.controller.text = merged.map((t) => '#$t').join(' ');
      }
    });
  }

  /// "#foo #bar" → ["foo", "bar"] にパース (# なしテキストにも寛容)
  List<String> _parseHashtags(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(RegExp(r'\s*#\s*'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  //メタデータからタイトルを取得
  Future<void> _fetchTitleFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    if (_isFetchingTitle) return; // 二重押下防止

    setState(() {
      _isFetchingTitle = true;
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

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
      if (mounted) {
        _showMessage(L10n.of(context)!.detail_page_ex);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingTitle = false;
        });
      }
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
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
                  foregroundColor: MaterialStateProperty.all(Colors.black),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: Text(L10n.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.all(
                    colorScheme.primary,
                  ),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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

      ref.read(randomImageReloadProvider.notifier).state++;

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
    VoidCallback onPressed, {
    Key? key,
  }) {
    return Padding(
      key: key, // ← ここが重要
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

  // 閲覧モードのヘッダーから呼び出す共有アクション
  Future<void> _shareItem() async {
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    final text = title.isNotEmpty && url.isNotEmpty
        ? '$title\n$url'
        : (url.isNotEmpty ? url : title);
    if (text.isEmpty) return;
    await Share.share(text);
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
      final isPremium =
          customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false;
      final isPro =
          customerInfo.entitlements.all["Pro Plan"]?.isActive ?? false;
      if (!mounted) return;
      setState(() {
        _isPremium = isPremium;
        _isPro = isPro;
      });
    } catch (e) {
      debugPrint("Error fetching subscription status: $e");
    }
  }

  /// AI FAB の「今日は非表示」フラグ + 最終利用日を prefs から読み込む
  Future<void> _loadAiFabHiddenState() async {
    final prefs = await SharedPreferences.getInstance();
    final hiddenSaved = prefs.getString(_kPrefAiFabHiddenDate);
    final lastUsed = prefs.getString(_kPrefAiLastUsedDate);
    if (!mounted) return;
    setState(() {
      if (hiddenSaved == _todayKey()) {
        _aiFabHiddenToday = true;
      }
      _aiLastUsedDate = lastUsed;
    });
  }

  /// 今日の日付キー (yyyy-MM-dd)
  String _todayKey() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  /// FAB 右上 × タップ: 今日の日付を prefs に保存し、即座に非表示
  Future<void> _hideAiFabForToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefAiFabHiddenDate, _todayKey());
    if (!mounted) return;
    setState(() => _aiFabHiddenToday = true);
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
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(L10n.of(context)!.detail_page_review_confirm01),
          content: Text(L10n.of(context)!.detail_page_review_confirm02),
          actions: [
            // 不具合報告
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
              onPressed: () {
                Navigator.pop(context);
                _openSupport();
              },
              child: Text(L10n.of(context)!.detail_page_review_contact_support),
            ),

            // レビューする
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);

                if (await inAppReview.isAvailable()) {
                  await inAppReview.requestReview();
                }
              },
              child: Text(L10n.of(context)!.detail_page_review_now),
            ),

            // あとで
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.of(context)!.detail_page_review_later),
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

    // 初回: 10件目で表示
    if (!alreadyReviewed && saveCount + 1 >= 10) {
      await prefs.setBool('review_prompted', true);
      await prefs.setInt('review_last_prompted_ms', DateTime.now().millisecondsSinceEpoch);
      if (!mounted) return;
      await showReviewPrompt(context);
      return;
    }

    // 2ヶ月ごとの再表示
    if (alreadyReviewed) {
      final now = DateTime.now();
      final lastMs = prefs.getInt('review_last_prompted_ms');
      if (lastMs == null) {
        // 既存ユーザー移行時: 今日を起点にセットして今回はスキップ
        await prefs.setInt('review_last_prompted_ms', now.millisecondsSinceEpoch);
        return;
      }
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final twoMonthsLater = DateTime(lastDate.year, lastDate.month + 2, lastDate.day);
      if (now.isAfter(twoMonthsLater)) {
        await prefs.setInt('review_last_prompted_ms', now.millisecondsSinceEpoch);
        if (!mounted) return;
        await showReviewPrompt(context);
      }
    }
  }

  //ファビコン作成
  String _getFaviconUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return "";
    return "${uri.scheme}://${uri.host}/favicon.ico";
  }

  //チュートリアル - フォーカス位置を推定
  Rect getRectFromKey(GlobalKey key, BuildContext context) {
    final box = key.currentContext!.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox;

    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    return pos & box.size;
  }

  //チュートリアル - 説明バルーン
  Positioned _buildBalloonFromRect(
    Rect rect,
    String text, {
    double offsetX = 0,
    double offsetY = -72,
  }) {
    return Positioned(
      left: rect.left + offsetX,
      top: rect.top + offsetY,
      child: _TutorialBalloon(text: text),
    );
  }

  //チュートリアル - タイトル取得ボタンの表示処理
  Future<void> startFetchTitleTutorial() async {
    final context = _fetchTitleKey.currentContext;
    if (context == null) return;

    // ① スクロールして表示
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.5, // 画面中央寄せ
    );

    // ② レイアウトが安定するのを待つ
    await Future.delayed(const Duration(milliseconds: 50));

    // ③ チュートリアルステップへ
    ref.read(tutorialStepProvider.notifier).state = TutorialStep.fetchTitle;
  }

  //チュートリアル - 保存ボタンの表示処理（最上部までスクロールして AppBar を表示）
  Future<void> startSaveTutorial() async {
    // AppBar を確実に表示
    if (!_showChrome) setState(() => _showChrome = true);

    // 最上部までスクロール
    if (_detailScrollController.hasClients &&
        _detailScrollController.offset > 0) {
      await _detailScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // レイアウトが安定するのを待つ
    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;
    ref.read(tutorialStepProvider.notifier).state = TutorialStep.saveItem;
  }

  //サムネクリック時の処理
  Future<void> openPlayer(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('saved_metadata') ?? [];
    final allItems = jsonList
        .map((s) {
          try {
            return Map<String, dynamic>.from(jsonDecode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    final List<Map<String, dynamic>> queue;
    if (widget.listName != null && widget.listName!.isNotEmpty) {
      final filtered = allItems
          .where((item) => item['listName'] == widget.listName)
          .toList();
      queue = filtered.isNotEmpty ? filtered : allItems;
    } else {
      queue = allItems;
    }

    final index = queue.indexWhere((item) => item['url'] == url);
    final safeIndex = index >= 0 ? index : 0;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultPage(
          initialUrl: queue[safeIndex]['url']?.toString() ?? url,
          title: queue[safeIndex]['title']?.toString() ?? '',
          playlistItems: queue,
          playlistIndex: safeIndex,
        ),
      ),
    );
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

class _InfoRowSpec {
  final String label;
  final String value;
  final Widget? trailing;
  const _InfoRowSpec(this.label, this.value, {this.trailing});
}

class _AiTagSection {
  final String label;
  final List<String> suggestions;
  final TextEditingController controller;
  const _AiTagSection(this.label, this.suggestions, this.controller);
}

class _CopyIconButton extends StatelessWidget {
  final String value;
  final Color iconColor;
  final String copiedLabel;

  const _CopyIconButton({
    required this.value,
    required this.iconColor,
    required this.copiedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(copiedLabel),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(Icons.copy_rounded, size: 18, color: iconColor),
      ),
    );
  }
}
