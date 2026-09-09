import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
//import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'l10n/app_localizations.dart';
import 'favorite_site_provider.dart';
import 'list_reload_provider.dart';
import 'save_limit_helper.dart';
import 'rating_label_provider.dart';
import 'circle_app_bar_icon.dart';
import 'offline_quality_picker.dart';
import 'browser_home_page.dart';
import 'browser_session_provider.dart';
import 'browser_scroll_top_provider.dart';
import 'download_queue_provider.dart';

class SearchResultPage extends ConsumerStatefulWidget {
  final String initialUrl;
  final String title;
  // プレイリスト再生モード（任意）
  final List<Map<String, dynamic>>? playlistItems;
  final int? playlistIndex;

  const SearchResultPage({
    super.key,
    required this.initialUrl,
    required this.title,
    this.playlistItems,
    this.playlistIndex,
  });

  @override
  ConsumerState<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends ConsumerState<SearchResultPage> {
  // ===== タブ管理 (方式A: IndexedStack、上限 6) =====
  final List<_BrowserTab> _tabs = [];
  int _activeTabIndex = 0;
  static const int _maxTabs = 6;

  _BrowserTab get _activeTab => _tabs[_activeTabIndex];

  // 既存コード互換のためのゲッタ/セッタ (アクティブタブに委譲)
  WebViewController get _controller => _activeTab.controller;
  bool get _canGoBack => _activeTab.canGoBack;
  set _canGoBack(bool v) => _activeTab.canGoBack = v;
  String? get _currentUrl => _activeTab.currentUrl;
  set _currentUrl(String? v) => _activeTab.currentUrl = v;
  String get _pageTitle => _activeTab.pageTitle;
  set _pageTitle(String v) => _activeTab.pageTitle = v;
  int get _progress => _activeTab.progress;
  set _progress(int v) => _activeTab.progress = v;
  List<WebHistoryItem> get _history => _activeTab.history;

  //プレミアム判定
  bool _isPremium = false;

  //選択中の評価
  String? selectedRating;

  //ダイアログ専用の評価状態
  String? dialogSelectedRating;

  String? _host(String? url) {
    if (url == null) return null;
    return Uri.tryParse(url)?.host;
  }

  //サムネイル用変数
  String? thumbnailUrl;

  //インターステイシャル広告
  InterstitialAd? _interstitialAd;
  int _saveCount = 0;

  RewardedAd? _rewardedAd;

  // (履歴/progress はアクティブタブに委譲済み)

  //URLバー
  final TextEditingController _urlBarController = TextEditingController();
  final FocusNode _urlBarFocus = FocusNode();
  bool _isUrlBarEditing = false;

  // Twitter風 AppBar/FAB 自動隠し
  bool _showChrome = true;
  int _lastChromeToggleMs = 0;

  // (検知動画リストはアクティブタブに委譲済み)

  // プレイリスト
  int _playlistIndex = 0;
  bool _playlistPanelExpanded = false;
  static const _panelExpandedHeight = 240.0;
  static const _panelCollapsedHeight = 56.0;
  bool get _hasPlaylist => (widget.playlistItems?.isNotEmpty ?? false);

  //リワード広告のロード
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

          /// ⭐ 見終わったら自動再ロード
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
  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
    _checkSubscriptionStatus();
    _loadAd();

    // プレイリストモードの初期化
    if (_hasPlaylist) {
      _playlistIndex = (widget.playlistIndex ?? 0).clamp(
        0,
        widget.playlistItems!.length - 1,
      );
    }
    final initialUrl = _hasPlaylist
        ? (widget.playlistItems![_playlistIndex]['url']?.toString() ??
            widget.initialUrl)
        : _resolveInitialUrl(widget.initialUrl);

    late final PlatformWebViewControllerCreationParams params;

    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const {},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    // 最初のタブを作成
    _tabs.add(_createTab(initialUrl));

    // アプリ内ブラウザ外 (grid/detail 等) からの新規タブ追加リクエストを受信
    ref.listenManual<BrowserOpenRequest?>(browserSessionProvider,
        (prev, next) {
      if (next == null) return;
      if (prev?.seq == next.seq) return;
      // 唯一のタブがホームタブの場合、新規タブは作らずそのホームタブを WebView 化
      if (_tabs.length == 1 && _tabs.first.isHome) {
        _handleHomeOpen(next.url);
        return;
      }
      // 既に同じ URL が開かれている場合はスキップ
      if (_tabs.length == 1 && _tabs.first.currentUrl == next.url) return;
      _addNewTab(url: next.url);
    });

    _urlBarFocus.addListener(() {
      if (!_urlBarFocus.hasFocus && _isUrlBarEditing) {
        setState(() {
          _isUrlBarEditing = false;
          // 編集をキャンセルしたら現在のURLに戻す
          _urlBarController.text = _currentUrl ?? '';
        });
      }
    });
  }

  /// 新規タブを作成し、初期 URL を読み込む。
  /// state に追加はしないので呼び出し側で行うこと。
  /// [initialUrl] が空文字ならホームタブ扱いで WebView 読み込みをスキップする。
  _BrowserTab _createTab(String initialUrl) {
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const {},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    late final _BrowserTab tab;
    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterScroll',
        onMessageReceived: (msg) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          if (nowMs - _lastChromeToggleMs < 400) return;
          if (msg.message == 'down' && _showChrome) {
            _lastChromeToggleMs = nowMs;
            setState(() => _showChrome = false);
          } else if ((msg.message == 'up' || msg.message == 'top') &&
              !_showChrome) {
            _lastChromeToggleMs = nowMs;
            setState(() => _showChrome = true);
          }
        },
      )
      // window.open / target="_blank" を新規タブに転送 (ポップアップブロック解除)
      ..addJavaScriptChannel(
        'FlutterPopup',
        onMessageReceived: (msg) {
          final url = msg.message.trim();
          if (url.isEmpty) return;
          if (!url.startsWith('http')) return;
          if (!mounted) return;
          _addNewTab(url: url);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => tab.progress = progress);
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            // http/https は WebView 内で遷移
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }
            // それ以外のスキーム (tel:/mailto:/intent:/カスタム 等) は
            // 外部アプリで開く。WebView 自身は遷移しない。
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } catch (_) {}
            return NavigationDecision.prevent;
          },
          onPageFinished: (url) async {
            // 新規タブは _addNewTab 内で即 active になるので、
            // 既存の _controller ベースの inject 関数がそのまま使える
            await _injectAdBlocker();
            await _injectScrollDetector();
            final title = await _getPageTitle();
            if (tab.history.isEmpty || tab.history.last.url != url) {
              tab.history.add(WebHistoryItem(url, title));
            }
            // ブラウザホーム画面用の閲覧履歴を SharedPreferences に永続化
            unawaited(_saveVisitHistory(url, title));
            final canBack = await tab.controller.canGoBack();
            setState(() {
              tab.canGoBack = canBack;
              tab.currentUrl = url;
              tab.pageTitle = title;
              if (identical(tab, _activeTab) && !_isUrlBarEditing) {
                _urlBarController.text = url;
              }
            });
          },
        ),
      );
    if (initialUrl.isNotEmpty) {
      controller.loadRequest(Uri.parse(initialUrl));
    }
    if (Platform.isIOS && controller.platform is WebKitWebViewController) {
      (controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
    tab = _BrowserTab(controller, isHome: initialUrl.isEmpty);
    return tab;
  }

  /// 新規タブを追加してアクティブ化。
  /// [url] が null の場合はホームタブとして開く。
  void _addNewTab({String? url}) {
    if (_tabs.length >= _maxTabs) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.browser_tab_max_reached),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final start = (url != null && url.isNotEmpty)
        ? _resolveInitialUrl(url)
        : ''; // 空 = ホームタブ
    setState(() {
      _tabs.add(_createTab(start));
      _activeTabIndex = _tabs.length - 1;
      _urlBarController.text = start;
    });
  }

  /// タブを閉じる
  void _closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    if (_tabs.length == 1) {
      // 最後のタブは閉じずにホーム化 (URL クリア + isHome:true)
      setState(() {
        _tabs[0].isHome = true;
        _tabs[0].currentUrl = null;
        _tabs[0].pageTitle = '';
        _tabs[0].canGoBack = false;
        _urlBarController.text = '';
      });
      return;
    }
    setState(() {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      } else if (_activeTabIndex > index) {
        _activeTabIndex -= 1;
      }
      _urlBarController.text = _activeTab.currentUrl ?? '';
    });
  }

  /// タブ切替
  void _switchToTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() {
      _activeTabIndex = index;
      _urlBarController.text = _activeTab.currentUrl ?? '';
    });
  }

  /// IndexedStack で全タブの WebView を保持しつつアクティブだけ表示
  Widget _buildTabsStack() {
    return IndexedStack(
      index: _activeTabIndex,
      children: [
        for (final tab in _tabs)
          tab.isHome
              ? BrowserHomeBody(
                  onOpenUrl: (u) => _handleHomeOpen(u),
                )
              : WebViewWidget(controller: tab.controller),
      ],
    );
  }

  /// ホームタブから URL / 検索が投げられた時: 現在のタブを WebView 化して遷移
  void _handleHomeOpen(String url) {
    final resolved = _resolveInitialUrl(url);
    setState(() {
      _activeTab.isHome = false;
      _urlBarController.text = resolved;
    });
    _controller.loadRequest(Uri.parse(resolved));
  }

  /// ホームボタン: 現在のタブをホーム画面に戻す
  void _resetActiveTabToHome() {
    setState(() {
      _activeTab.isHome = true;
      _activeTab.currentUrl = null;
      _activeTab.pageTitle = '';
      _urlBarController.text = '';
    });
  }

  /// AppBar 右端に置く「タブ数バッジ」(Chrome スタイル: 角丸四角の中に数字)
  Widget _buildTabCountBadge(ColorScheme cs) {
    final count = _tabs.length;
    // Chrome の tab-count と同じく数字はモノスペース風 & 太字。
    // 桁数によってフォントサイズを微調整して枠内に収める。
    final label = count > 99 ? ':D' : '$count';
    final fontSize = count >= 10 ? 11.0 : 13.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: _showTabsSheet,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.onSurface, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// タブ切替シート (Chrome スタイル)
  /// Chrome モバイル風のタブスイッチャー: フルスクリーン相当の 2 列グリッド。
  Future<void> _showTabsSheet() async {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    // ボトムナビと同じグレー
    final sheetBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200;
    final cardBg = isDark ? const Color(0xFF3A3A3A) : Colors.white;
    // AppBar 相当の高さ分だけ上部に余白を残す (status bar + toolbar)
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - topInset,
      ),
      builder: (bctx) {
        return StatefulBuilder(
          builder: (bctx, setSheet) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l.browser_tabs_title} (${_tabs.length}/$_maxTabs)',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l.browser_new_tab),
                          onPressed: _tabs.length >= _maxTabs
                              ? null
                              : () {
                                  Navigator.pop(bctx);
                                  _addNewTab();
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _tabs.length,
                        itemBuilder: (_, i) {
                          final tab = _tabs[i];
                          final active = i == _activeTabIndex;
                          final host =
                              Uri.tryParse(tab.currentUrl ?? '')?.host ?? '';
                          final title = tab.pageTitle.isNotEmpty
                              ? tab.pageTitle
                              : host;
                          return _TabGridCard(
                            title: title.isEmpty ? l.browser_new_tab : title,
                            host: host,
                            url: tab.currentUrl ?? '',
                            active: active,
                            accentColor: cs.primary,
                            cardBg: cardBg,
                            onTap: () {
                              _switchToTab(i);
                              Navigator.pop(bctx);
                            },
                            onClose: () {
                              final wasLast = _tabs.length == 1;
                              setSheet(() {
                                _closeTab(i);
                              });
                              // 最後の 1 タブを閉じたら (home 化された) sheet も閉じてホームへ戻る
                              if (wasLast) Navigator.pop(bctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _urlBarController.dispose();
    _urlBarFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ボトムナビの「ブラウザ」タブ再タップで WebView をトップへスクロール
    ref.listen<int>(browserScrollToTopProvider, (prev, next) {
      try {
        _controller.runJavaScript(
          "window.scrollTo({top: 0, behavior: 'smooth'});",
        );
      } catch (_) {}
    });

    final colorScheme = Theme.of(context).colorScheme;

    final isFav = ref.watch(
      favoriteSitesProvider.select(
        (list) => list.any((e) => _host(e["url"]) == _host(_currentUrl)),
      ),
    );

    return PopScope(
      // 常に Navigator の pop を防ぐ (ネスト Navigator に 1 ルートしか無いので pop すると例外)。
      // WebView に履歴があれば goBack、それ以外は何もしない (ホーム/履歴なしタブ)。
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final tab = _activeTab;
        if (!tab.isHome && _canGoBack) {
          await _controller.goBack();
        }
        // ホーム or 履歴無しの場合は何もしない (browserTab 離脱を防ぐ)
      },
      child: Scaffold(
      // AppBar は廃止し、ボトム側 (ボトムナビ直上) に URL バー + アクションを配置
      body: Listener(
        // WebView タップで URLバーのフォーカスを外す
        onPointerDown: (_) {
          if (_urlBarFocus.hasFocus) _urlBarFocus.unfocus();
        },
        child: SafeArea(
          top: true,
          bottom: false,
          child: _hasPlaylist
              ? Stack(
                  children: [
                    Positioned.fill(child: _buildTabsStack()),
                    Positioned(
                      bottom: MediaQuery.of(context).padding.bottom,
                      left: 0,
                      right: 0,
                      child: _buildPlaylistPanel(colorScheme),
                    ),
                  ],
                )
              : _buildTabsStack(),
        ),
      ),
      // URL バー: ブラウザタブ識別のためグレー背景に。スクロール中も常時表示。
      bottomNavigationBar: Material(
        color: colorScheme.brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.grey.shade200,
        elevation: 6,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_progress < 100)
                LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    // 戻る (長押しで履歴) — ホームタブでは非表示
                    if (!_activeTab.isHome)
                      GestureDetector(
                        onLongPress: _showHistoryDialog,
                        child: CircleAppBarIcon(
                          icon: Icons.arrow_back,
                          onPressed: () async {
                            if (_canGoBack) {
                              await _controller.goBack();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    Expanded(child: _buildUrlBar(colorScheme)),
                    // ホームボタン: WebView タブ表示中のみ
                    if (!_activeTab.isHome)
                      CircleAppBarIcon(
                        icon: Icons.home_outlined,
                        tooltip: 'Home',
                        onPressed: _resetActiveTabToHome,
                      ),
                    _buildTabCountBadge(colorScheme),
                    // メニュー (お気に入り / 共有): WebView タブのみ表示
                    if (!_activeTab.isHome)
                      CircleAppBarIcon(
                        icon: Icons.more_vert,
                        tooltip: 'Menu',
                        onPressed: () => _showBrowserMenu(isFav),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // ホームタブでは「保存」FAB を非表示 (保存対象のページが無いため)
      floatingActionButton: _activeTab.isHome
          ? null
          : AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: _showChrome ? Offset.zero : const Offset(0, 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showChrome ? 1.0 : 0.0,
                // 再生リストパネルとの重なりを避けるため、
                // playlist 表示時はパネル高 + マージンだけ FAB を上に浮かせる
                child: _hasPlaylist
                    ? Padding(
                        padding: EdgeInsets.only(
                          bottom: (_playlistPanelExpanded
                                  ? _panelExpandedHeight
                                  : _panelCollapsedHeight) +
                              8,
                        ),
                        child: _buildSaveFab(colorScheme),
                      )
                    : _buildSaveFab(colorScheme),
              ),
            ),
      ),
    );
  }

  // ===== プレイリスト =====

  Future<void> _navigateToPlaylistIndex(int index) async {
    if (!_hasPlaylist) return;
    final items = widget.playlistItems!;
    if (index < 0 || index >= items.length) return;
    final url = items[index]['url']?.toString() ?? '';
    if (url.isEmpty) return;
    setState(() => _playlistIndex = index);
    await _controller.loadRequest(Uri.parse(url));
    await _incrementViewCount(url);
  }

  Future<void> _incrementViewCount(String url) async {
    if (url.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(url) ?? 0;
    await prefs.setInt(url, current + 1);
  }

  Widget _buildPlaylistPanel(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: _playlistPanelExpanded ? _panelExpandedHeight : _panelCollapsedHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: _playlistPanelExpanded
            ? _buildPlaylistExpanded(colorScheme)
            : _buildPlaylistCollapsed(colorScheme),
      ),
    );
  }

  Widget _buildPlaylistCollapsed(ColorScheme colorScheme) {
    final items = widget.playlistItems!;
    final hasPrev = _playlistIndex > 0;
    final hasNext = _playlistIndex < items.length - 1;
    final currentTitle =
        items[_playlistIndex]['title']?.toString() ?? '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) {
        if (d.delta.dy < -6) {
          setState(() => _playlistPanelExpanded = true);
        }
      },
      child: SizedBox(
        height: _panelCollapsedHeight,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.skip_previous,
                color: hasPrev ? colorScheme.primary : Colors.grey.shade400,
              ),
              onPressed: hasPrev
                  ? () => _navigateToPlaylistIndex(_playlistIndex - 1)
                  : null,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _playlistPanelExpanded = true),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (items.length > 1)
                      Text(
                        '${_playlistIndex + 1} / ${items.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.skip_next,
                color: hasNext ? colorScheme.primary : Colors.grey.shade400,
              ),
              onPressed: hasNext
                  ? () => _navigateToPlaylistIndex(_playlistIndex + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistExpanded(ColorScheme colorScheme) {
    final items = widget.playlistItems!;
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _playlistPanelExpanded = false),
          onVerticalDragUpdate: (d) {
            if (d.delta.dy > 6) {
              setState(() => _playlistPanelExpanded = false);
            }
          },
          child: SizedBox(
            height: 32,
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isCurrent = index == _playlistIndex;
              final image = item['image']?.toString();
              final title =
                  item['title']?.toString() ?? item['url']?.toString() ?? '';
              return InkWell(
                onTap: () => _navigateToPlaylistIndex(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  color: isCurrent
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : null,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: image != null && image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: image,
                                width: 52,
                                height: 36,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _playlistPlaceholder(),
                              )
                            : _playlistPlaceholder(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Icon(
                          Icons.play_arrow,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _playlistPlaceholder() => Container(
        width: 52,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.white38,
          size: 16,
        ),
      );

  /// 現在のページを他のアプリへ共有
  Future<void> _shareCurrentUrl() async {
    final url = _currentUrl ?? widget.initialUrl;
    if (url.isEmpty) return;
    final text = _pageTitle.isNotEmpty ? '$_pageTitle\n$url' : url;
    await Share.share(text);
  }

  /// ブラウザメニュー (お気に入り / 共有 等) のボトムシート
  Future<void> _showBrowserMenu(bool isFav) async {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    // ボトムナビと同じグレーで塗って統一感を出す
    final sheetBg =
        isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(isFav ? Icons.star : Icons.star_border,
                  color: isFav ? Colors.amber : null),
              title: Text(l.favorite),
              onTap: () {
                Navigator.pop(bctx);
                _toggleFavorite();
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(bctx);
                _shareCurrentUrl();
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  /// URLバー：タップで編集可能、Enter で遷移
  Widget _buildUrlBar(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    // 周囲のグレー背景と区別するため、URL 入力部分は反対トーンで塗る
    final bg = isDark ? Colors.white12 : Colors.white;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _urlBarController,
        focusNode: _urlBarFocus,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: _activeTab.isHome
              ? L10n.of(context)!.browser_home_url_hint
              : null,
          hintStyle: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          prefixIcon: Icon(
            _activeTab.isHome
                ? Icons.search
                : ((_currentUrl?.startsWith('https://') ?? false)
                    ? Icons.lock
                    : Icons.public),
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          // ホームタブでは reload/clear のサフィックスも非表示
          suffixIcon: _activeTab.isHome
              ? null
              : (_isUrlBarEditing
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _urlBarController.clear(),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: () => _controller.reload(),
                    )),
        ),
        onTap: () {
          if (!_isUrlBarEditing) {
            setState(() => _isUrlBarEditing = true);
            // 全選択して編集しやすく
            _urlBarController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _urlBarController.text.length,
            );
          }
        },
        onSubmitted: (text) {
          setState(() => _isUrlBarEditing = false);
          _urlBarFocus.unfocus();
          _navigateToInput(text);
        },
      ),
    );
  }

  /// URLバーから入力されたテキストを判定して遷移
  /// URLっぽければ直接、そうでなければ Web 検索
  Future<void> _navigateToInput(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    Uri? uri;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      uri = Uri.tryParse(trimmed);
    } else if (trimmed.contains('.') && !trimmed.contains(' ')) {
      uri = Uri.tryParse('https://$trimmed');
    } else {
      uri = Uri.tryParse(
        'https://www.google.com/search?q=${Uri.encodeQueryComponent(trimmed)}',
      );
    }
    if (uri != null) {
      // ホームタブなら WebView 表示に切り替え
      if (_activeTab.isHome) {
        setState(() => _activeTab.isHome = false);
      }
      await _controller.loadRequest(uri);
    }
  }

  Widget _buildSaveFab(ColorScheme colorScheme) {
    final isLoaded = _progress >= 100;
    final l = L10n.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isLoaded ? colorScheme.primary : Colors.grey,
        borderRadius: BorderRadius.circular(isLoaded ? 28 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isLoaded ? 28 : 8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoaded ? _showSaveWorkDialog : null,
          borderRadius: BorderRadius.circular(isLoaded ? 28 : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: isLoaded
                ? [
                    const Icon(Icons.add, color: Colors.white, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      l.save,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                : [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.search_result_loading,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  // =========================
  // アクション
  // =========================

  /// ブラウザに注入する JavaScript。
  /// 現在は広告ブロックは一切行わず、以下のみを実装している:
  ///   - window.open() を Flutter 側にリレーし、新規タブで開く
  ///   - target="_blank" のリンククリックも同様に新規タブで開く
  Future<void> _injectAdBlocker() async {
    const js = r'''
(function() {
  if (window.__archive_popup_handler) return;
  window.__archive_popup_handler = true;

  // window.open を新規タブに転送 (ポップアップブロック解除)
  try {
    window.open = function(url, name, features) {
      try {
        var abs = url ? new URL(url, document.baseURI).href : '';
        if (abs && /^https?:/i.test(abs)) {
          FlutterPopup.postMessage(abs);
        }
      } catch (e) {}
      return null;
    };
  } catch (e) {}

  // target="_blank" のリンククリックも新規タブへ
  try {
    document.addEventListener('click', function(ev) {
      var a = ev.target;
      while (a && a.tagName !== 'A') a = a.parentNode;
      if (!a || !a.href) return;
      var t = (a.target || '').toLowerCase();
      if (t === '_blank' || t === 'blank') {
        try {
          var abs = new URL(a.href, document.baseURI).href;
          if (/^https?:/i.test(abs)) {
            ev.preventDefault();
            ev.stopPropagation();
            FlutterPopup.postMessage(abs);
          }
        } catch (e) {}
      }
    }, true);
  } catch (e) {}
})();
''';
    try {
      await _controller.runJavaScript(js);
    } catch (e) {
      // ページによっては JS 実行失敗するが致命的ではない
    }
  }

  /// Twitter風 自動隠し用：WebView のスクロール方向を Flutter へ通知
  Future<void> _injectScrollDetector() async {
    // 頻繁な AppBar の出入りでガタつくのを避けるため:
    //  - 同じ方向に大きく (150px) 累積してから切替
    //  - 直近の切替から 500ms 以内は再切替を抑制 (クールダウン)
    //  - lastSent と同じメッセージは送信しない
    const js = r'''
(function() {
  if (window.__archive_scroll_detector) return;
  window.__archive_scroll_detector = true;
  var lastY = window.scrollY || 0;
  var accum = 0;
  var lastDirection = 0;
  var lastSent = '';
  var lastSentAt = 0;
  var ticking = false;
  var THRESHOLD = 150;   // 150px 累積で切替
  var COOLDOWN_MS = 500; // 切替後 500ms は再切替しない
  function onScroll() {
    var y = window.scrollY || 0;
    var dy = y - lastY;
    lastY = y;
    var nowMs = Date.now();
    // ページ最上部近く: 常に表示 (クールダウン無視)
    if (y <= 20) {
      accum = 0;
      lastDirection = 0;
      if (lastSent !== 'top') {
        try { FlutterScroll.postMessage('top'); } catch(e) {}
        lastSent = 'top';
        lastSentAt = nowMs;
      }
      ticking = false;
      return;
    }
    if (dy === 0) { ticking = false; return; }
    var dir = dy > 0 ? 1 : -1;
    if (dir !== lastDirection) {
      accum = 0;
      lastDirection = dir;
    }
    accum += Math.abs(dy);
    if (accum >= THRESHOLD) {
      accum = 0;
      var msg = dir > 0 ? 'down' : 'up';
      // クールダウン中は同じ方向でも送らない
      if (msg !== lastSent && (nowMs - lastSentAt) >= COOLDOWN_MS) {
        try { FlutterScroll.postMessage(msg); } catch(e) {}
        lastSent = msg;
        lastSentAt = nowMs;
      }
    }
    ticking = false;
  }
  window.addEventListener('scroll', function() {
    if (!ticking) {
      window.requestAnimationFrame(onScroll);
      ticking = true;
    }
  }, { passive: true });
})();
''';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  Future<String> _getPageTitle() async {
    final result = await _controller.runJavaScriptReturningResult(
      'document.title',
    );
    return result.toString().replaceAll('"', '');
  }

  /*
  Future<String> _getFaviconUrl(String pageUrl) async {
    final uri = Uri.parse(pageUrl);
    return '${uri.scheme}://${uri.host}/favicon.ico';
  }
  */

  //お気にいりボタン押下時処理
  void _toggleFavorite() {
    final url = _currentUrl;
    if (url == null) return;

    final favorites = ref.read(favoriteSitesProvider);
    final index = favorites.indexWhere((e) => _host(e["url"]) == _host(url));

    if (index != -1) {
      _showDeleteFavoriteDialog(index);
    } else {
      _showAddFavoriteDialog(initialUrl: url);
    }
  }

  //お気に入りサイト削除ダイアログ
  Future<void> _showDeleteFavoriteDialog(int index) async {
    final colorScheme = Theme.of(context).colorScheme;
    final favorites = ref.read(favoriteSitesProvider);
    final siteName = favorites[index]["title"] ?? "";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.secondary,
          title: Text(
            L10n.of(context)!.favorite,
            style: TextStyle(color: colorScheme.onPrimary),
          ),
          content: Text(
            L10n.of(context)!.search_result_page_delete_site(siteName),
            style: TextStyle(color: colorScheme.onPrimary),
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
              child: Text(L10n.of(context)!.cancel),
              onPressed: () => Navigator.pop(context),
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
              child: Text(L10n.of(context)!.delete),
              onPressed: () {
                ref.read(favoriteSitesProvider.notifier).remove(index);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// ブラウザホーム画面の「履歴」用に閲覧履歴を保存する。
  /// 最新順、重複 URL は詰めて先頭に、最大 20 件。
  Future<void> _saveVisitHistory(String url, String title) async {
    if (url.isEmpty || !url.startsWith('http')) return;
    // Google 検索結果ページや about:blank などは履歴から除外
    if (url.startsWith('https://www.google.com/search')) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('browser_history') ?? [];
      // 既存の同一 URL を除去
      list.removeWhere((s) {
        try {
          return (jsonDecode(s) as Map)['url'] == url;
        } catch (_) {
          return false;
        }
      });
      list.insert(
        0,
        jsonEncode({
          'url': url,
          'title': title,
          'ts': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      if (list.length > 20) list.removeRange(20, list.length);
      await prefs.setStringList('browser_history', list);
    } catch (_) {}
  }

  //URL生成メソッド
  //Google 通常検索 (動画タブ自動選択はしない)
  String _buildGoogleSearchUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://www.google.com/search?q=$encoded&safe=off';
  }

  //initialUrlがURLの場合に分岐
  String _resolveInitialUrl(String input) {
    if (input.startsWith('http')) {
      return input; // そのまま表示
    }
    return _buildGoogleSearchUrl(input); // 検索語 → 通常検索
  }

  //作品として保存するダイアログ
  Future<void> _showSaveWorkDialog() async {
    //評価をリセット
    selectedRating = null;

    final url = await _controller.currentUrl();
    if (url == null) return;

    final title = await _getPageTitle();

    final prefs = await SharedPreferences.getInstance();

    // 既に保存済みの URL の場合は保存ダイアログを開かず、
    // オフライン保存確認フローに直接切り替える
    final savedList = prefs.getStringList('saved_metadata') ?? [];
    final alreadySaved = savedList.any((e) {
      try {
        return (jsonDecode(e) as Map<String, dynamic>)['url'] == url;
      } catch (_) {
        return false;
      }
    });
    if (alreadySaved) {
      if (!mounted) return;
      await _promptOfflineForExisting(url: url, title: title);
      return;
    }

    // リスト一覧取得
    final allLists = prefs.getStringList('all_lists') ?? [];

    String selectedList = 'none';
    // 前回の解像度選択を復元 (null = 「ダウンロードなし」も記憶)
    // prefs には int を保存、キー未設定 = 未選択、値 -1 = 「なし」を明示
    int? offlineHeight;
    final storedH = prefs.getInt('last_offline_height');
    if (storedH != null && storedH > 0) {
      offlineHeight = storedH;
    } else {
      offlineHeight = null; // 「ダウンロードなし」または未設定
    }
    final titleController = TextEditingController(text: title);
    final urlController = TextEditingController(text: url);
    final colorScheme = Theme.of(context).colorScheme;

    // 前回の保存ダイアログの残像をクリアしてから新規取得
    thumbnailUrl = null;
    // サムネを事前取得（ダイアログ表示と並行)
    String? pendingThumb;
    _getThumbnailFromPage().then((t) {
      pendingThumb = t;
    });

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 並行取得のサムネが反映されてなければ少し待ってからリビルド
            if (pendingThumb != null && thumbnailUrl != pendingThumb) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => thumbnailUrl = pendingThumb);
              });
            }
            return AlertDialog(
              backgroundColor: colorScheme.secondary,
              title: Text(L10n.of(context)!.search_result_page_saving_as_item),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 保存予告プレビュー（サムネ + タイトル）
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 72,
                              height: 54,
                              child: thumbnailUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              titleController.text.isEmpty ? url : titleController.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 評価
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ratingButton(
                          isSelected: dialogSelectedRating == 'critical',
                          label: ratingLabelOf(
                            context,
                            ref.watch(ratingLabelsProvider),
                            kRatingCritical,
                          ),
                          imagePath: 'assets/icons/critical.png',
                          grayPath: 'assets/icons/critical_gray.png',
                          onTap: () {
                            setState(() {
                              dialogSelectedRating =
                                  dialogSelectedRating == 'critical'
                                      ? null
                                      : 'critical';
                            });
                          },
                        ),
                        _ratingButton(
                          isSelected: dialogSelectedRating == 'normal',
                          label: ratingLabelOf(
                            context,
                            ref.watch(ratingLabelsProvider),
                            kRatingNormal,
                          ),
                          imagePath: 'assets/icons/normal.png',
                          grayPath: 'assets/icons/normal_gray.png',
                          onTap: () {
                            setState(() {
                              dialogSelectedRating =
                                  dialogSelectedRating == 'normal'
                                      ? null
                                      : 'normal';
                            });
                          },
                        ),
                        _ratingButton(
                          isSelected: dialogSelectedRating == 'maniac',
                          label: ratingLabelOf(
                            context,
                            ref.watch(ratingLabelsProvider),
                            kRatingManiac,
                          ),
                          imagePath: 'assets/icons/maniac.png',
                          grayPath: 'assets/icons/maniac_gray.png',
                          onTap: () {
                            setState(() {
                              dialogSelectedRating =
                                  dialogSelectedRating == 'maniac'
                                      ? null
                                      : 'maniac';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // URL（読み取り専用）
                    TextField(
                      controller: urlController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: L10n.of(context)!.url,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // タイトル
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: L10n.of(context)!.title,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // リスト選択
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedList,
                            decoration: InputDecoration(
                              labelText:
                                  L10n.of(
                                    context,
                                  )!.search_result_page_saving_list,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'none',
                                child: Text(L10n.of(context)!.no_select),
                              ),
                              ...allLists.map(
                                (list) => DropdownMenuItem(
                                  value: list,
                                  child: Text(list),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedList = value ?? 'none';
                              });
                            },
                          ),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            elevation: MaterialStateProperty.all(0),
                            backgroundColor: MaterialStateProperty.all(
                              Colors.grey[300],
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              Colors.black,
                            ),
                          ),
                          onPressed: () async {
                            final nameController = TextEditingController();

                            await showDialog(
                              context:
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).context,
                              builder: (_) {
                                return AlertDialog(
                                  backgroundColor: colorScheme.secondary,
                                  title: Text(
                                    L10n.of(
                                      context,
                                    )!.search_result_page_new_list,
                                  ),
                                  content: TextField(
                                    controller: nameController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText:
                                          L10n.of(
                                            context,
                                          )!.search_result_page_input_list_name,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      style: ButtonStyle(
                                        elevation: MaterialStateProperty.all(0),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                              Colors.grey[300],
                                            ),
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                              Colors.black,
                                            ),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(L10n.of(context)!.cancel),
                                    ),
                                    TextButton(
                                      style: ButtonStyle(
                                        elevation: MaterialStateProperty.all(0),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                              colorScheme.primary,
                                            ),
                                        foregroundColor:
                                            MaterialStateProperty.all(
                                              Colors.white,
                                            ),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final name = nameController.text.trim();
                                        if (name.isEmpty) return;

                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        final lists =
                                            prefs.getStringList('all_lists') ??
                                            [];

                                        // ★ 重複チェック（追加）
                                        if (lists.contains(name)) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                L10n.of(
                                                  context,
                                                )!.search_result_page_list_already_exists,
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          return;
                                        }

                                        // リスト追加
                                        lists.add(name);
                                        await prefs.setStringList(
                                          'all_lists',
                                          lists,
                                        );
                                        // リスト画面に通知
                                        ref
                                            .read(listReloadProvider.notifier)
                                            .state++;

                                        // 評価確定
                                        selectedRating = dialogSelectedRating;

                                        //サムネ取得
                                        thumbnailUrl =
                                            await _getThumbnailFromPage();

                                        // 保存実行
                                        await _saveWorkFromWebView(
                                          url: urlController.text,
                                          title: titleController.text,
                                          listName: name,
                                          thumbnailUrl: thumbnailUrl,
                                        );

                                        if (!context.mounted) return;

                                        Navigator.pop(context); // 新規リスト
                                        Navigator.pop(context); // 保存ダイアログ
                                      },

                                      child: Text(L10n.of(context)!.ok),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            L10n.of(context)!.search_result_page_new_list,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // オフライン保存: 解像度チップ (Premium 以上のみ選択可)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        L10n.of(context)!.offline_quality_title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        L10n.of(context)!.offline_quality_desc,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OfflineQualityChips(
                      selected: offlineHeight,
                      onChanged: (h) {
                        // 動画ダウンロードは無料化 (Premium ゲート撤去)
                        setState(() => offlineHeight = h);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.of(context)!.cancel), //保存キャンセルボタン
                ),
                TextButton(
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
                  onPressed: () async {
                    selectedRating = dialogSelectedRating;

                    //サムネ取得
                    thumbnailUrl = await _getThumbnailFromPage();

                    // 選択した解像度を次回用に保存
                    // (null = ダウンロードなしも記憶したいので 0 で表現)
                    final savePrefs = await SharedPreferences.getInstance();
                    await savePrefs.setInt(
                        'last_offline_height', offlineHeight ?? 0);

                    final startingDl = offlineHeight != null &&
                        urlController.text.trim().isNotEmpty;
                    await _saveWorkFromWebView(
                      url: urlController.text,
                      title: titleController.text,
                      listName: selectedList == 'none' ? '' : selectedList,
                      thumbnailUrl: thumbnailUrl,
                      // DL 開始時は保存 SnackBar を抑制し、後で
                      // 「ダウンロードを開始しました」を出す
                      suppressToast: startingDl,
                    );
                    // オフライン解像度が選択されている場合はダウンロード開始
                    if (startingDl) {
                      await ref
                          .read(downloadQueueProvider.notifier)
                          .start(
                            url: urlController.text.trim(),
                            title: titleController.text.trim().isNotEmpty
                                ? titleController.text.trim()
                                : urlController.text.trim(),
                            itemUrl: urlController.text.trim(),
                            preferredHeight: offlineHeight,
                            wasFromNewSave: true,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(L10n.of(context)!
                                .browser_video_download_started),
                          ),
                        );
                      }
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(L10n.of(context)!.save), //保存ボタン
                ),
              ],
            );
          },
        );
      },
    );
  }

  //評価ボタンのウィジェット
  Widget _ratingButton({
    required bool isSelected,
    required VoidCallback onTap,
    required String label,
    required String imagePath,
    required String grayPath,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Image.asset(
              isSelected ? imagePath : grayPath,
              width: 35,
              height: 35,
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

  Future<String?> _getThumbnailFromPage() async {
    final url = await _controller.currentUrl();
    if (url == null) return null;

    // ⭐ YouTube専用
    final ytThumb = _extractYoutubeThumbnail(url);
    if (ytThumb != null) return ytThumb;

    // ⭐ DOM完全読み込み待ち
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final result = await _controller.runJavaScriptReturningResult("""
    (function() {

      function abs(u){
        try { return new URL(u, location.href).href; }
        catch(e){ return u; }
      }

      // ① og:image
      let el = document.querySelector('meta[property="og:image"]');
      if(el?.content) return abs(el.content);

      // ② twitter:image
      el = document.querySelector('meta[name="twitter:image"]');
      if(el?.content) return abs(el.content);

      // ③ itemprop image
      el = document.querySelector('meta[itemprop="image"]');
      if(el?.content) return abs(el.content);

      // ④ video poster
      let v = document.querySelector('video');
      if(v?.poster) return abs(v.poster);

      // ⑤ link image_src
      let link = document.querySelector('link[rel="image_src"]');
      if(link?.href) return abs(link.href);

      // ⑥ 大きい画像優先取得
      let imgs = [...document.images]
        .filter(i => i.width > 200 && i.height > 200)
        .sort((a,b)=> (b.width*b.height)-(a.width*a.height));

      if(imgs.length) return abs(imgs[0].src);

      // ⑦ 最終fallback
      let img = document.querySelector('img');
      if(img?.src) return abs(img.src);

      return null;
    })();
    """);

      if (result == null || result == 'null') return null;

      return result.toString().replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }

  String? _extractYoutubeThumbnail(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    String? id;

    if (uri.host.contains('youtu.be')) {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (uri.host.contains('youtube.com')) {
      id = uri.queryParameters['v'];

      // shorts
      if (id == null && uri.pathSegments.contains('shorts')) {
        id = uri.pathSegments.last;
      }

      // embed
      if (id == null && uri.pathSegments.contains('embed')) {
        id = uri.pathSegments.last;
      }
    }

    if (id == null) return null;

    return "https://img.youtube.com/vi/$id/hqdefault.jpg";
  }

  //追加作品の保存
  /// 既に保存済みの URL の場合に、「オフライン保存もしますか？」と確認する
  Future<void> _promptOfflineForExisting({
    required String url,
    required String title,
  }) async {
    final l = L10n.of(context)!;
    // 既にローカル DL 済みかチェック
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_metadata') ?? [];
    String? localPath;
    for (final s in list) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        if (map['url'] == url) {
          localPath = map['localVideoPath'] as String?;
          break;
        }
      } catch (_) {}
    }
    if (localPath != null && localPath.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.search_result_page_url_already_saved_and_downloaded),
        duration: const Duration(seconds: 2),
      ));
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.search_result_page_url_already_saved),
        content: Text(l.search_result_page_url_already_saved_offline_prompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(l.search_result_page_offline),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // 動画ダウンロードは無料機能なので Premium ゲート撤去
    await ref.read(downloadQueueProvider.notifier).start(
          url: url,
          title: title.isNotEmpty ? title : url,
          itemUrl: url,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.browser_video_download_started),
      ));
    }
  }

  Future<void> _saveWorkFromWebView({
    required String url,
    required String title,
    required String listName,
    String? thumbnailUrl,
    bool suppressToast = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    //作品数上限チェック
    if (!await SaveLimitHelper.canSave(context, _rewardedAd, ref)) {
      _loadAd();
      return;
    }

    final data = {
      'listName': listName,
      'url': url,
      'title': title,
      'image': thumbnailUrl,
      'memo': '',
      'rating': selectedRating,
    };

    final savedList = prefs.getStringList('saved_metadata') ?? [];

    // 重複URL防止
    final exists = savedList.any((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['url'] == url;
    });

    if (exists) {
      if (!mounted) return;
      await _promptOfflineForExisting(url: url, title: title);
      return;
    }

    if (!exists) {
      savedList.add(jsonEncode(data));
      await prefs.setStringList('saved_metadata', savedList);
    }

    if (!mounted) return;
    if (!suppressToast) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context)!.search_result_page_has_saved)),
      );
    }

    //広告表示処理
    await _maybeShowAd();
  }

  static Future<bool> _checkPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium =
          customerInfo.entitlements.all['Premium Plan']?.isActive ?? false;
      final isPro =
          customerInfo.entitlements.all['Pro Plan']?.isActive ?? false;
      return isPremium || isPro;
    } catch (e) {
      debugPrint('Subscription check error: $e');
      return false;
    }
  }

  //お気に入りサイト追加ダイアログ
  Future<void> _showAddFavoriteDialog({required String initialUrl}) async {
    final titleController = TextEditingController(
      text: getBaseDomain(initialUrl),
    );
    final urlController = TextEditingController(text: getOrigin(initialUrl));

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
                decoration: InputDecoration(
                  labelText: L10n.of(context)!.search_page_site_name,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                readOnly: true,
                decoration: InputDecoration(labelText: L10n.of(context)!.url),
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
              onPressed: () {
                ref
                    .read(favoriteSitesProvider.notifier)
                    .add(
                      titleController.text.trim(),
                      urlController.text.trim(),
                    );
                Navigator.pop(context);
              },
              child: Text(L10n.of(context)!.add),
            ),
          ],
        );
      },
    );
  }

  //URL正規化関数
  String getBaseDomain(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;

    final parts = uri.host.split('.');
    if (parts.length < 2) return uri.host;

    return "${parts[parts.length - 2]}.${parts[parts.length - 1]}";
  }

  String getOrigin(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return "${uri.scheme}://${uri.host}";
  }

  //検索履歴を表示
  // 履歴を表示
  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 上部タイトル
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  L10n.of(context)!.search_result_page_history,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),

              // 🔹 履歴リスト
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = _history.length - 1 - index;
                    final item = _history[reversedIndex];

                    return ListTile(
                      title: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        item.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _controller.loadRequest(Uri.parse(item.url));

                        // sublist は新規リストを返すため、タブの mutable list を書き換え
                        final trimmed =
                            _history.sublist(0, reversedIndex + 1);
                        _history
                          ..clear()
                          ..addAll(trimmed);

                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //=========
  //広告関連
  //=========
  //インターステイシャル広告のロード
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  // 保存 (FAB 保存ボタン) を押下した回数をカウントし、3 回に 1 回インターステイシャル。
  // オフラインダウンロードの有無に関係なくカウント。Premium/Pro はスキップ。
  Future<void> _maybeShowAd() async {
    if (_isPremium) return;

    final prefs = await SharedPreferences.getInstance();
    int count = (prefs.getInt("save_ad_count") ?? 0) + 1;
    await prefs.setInt("save_ad_count", count);

    if (count % 3 != 0) return;
    if (_interstitialAd == null) return;

    final ad = _interstitialAd!;
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );
    ad.show();
  }

  String get _adUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-8268997781284735/8554245309"; //本番用
      //return "ca-app-pub-3940256099942544/1033173712"; //テスト用
    } else {
      return "ca-app-pub-8268997781284735/2906478597";
    }
  }

  /// サブスクリプション状態を確認
  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      // Premium または Pro のどちらでも「有料 = 広告非表示」扱い
      final isPremium =
          customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false;
      final isPro =
          customerInfo.entitlements.all["Pro Plan"]?.isActive ?? false;
      setState(() {
        _isPremium = isPremium || isPro;
      });
    } catch (e) {
      debugPrint("Error fetching subscription status: $e");
    }
  }
}

//検索履歴を管理するクラス
class WebHistoryItem {
  final String url;
  final String title;

  WebHistoryItem(this.url, this.title);
}

/// アプリ内ブラウザの 1 タブ分の状態。
class _BrowserTab {
  final WebViewController controller;
  bool canGoBack = false;
  String? currentUrl;
  String pageTitle = '';
  int progress = 0;
  final List<WebHistoryItem> history = [];
  /// ホームタブ (URL 未入力状態) — WebView は描画せずホームコンテンツを表示
  bool isHome;
  _BrowserTab(this.controller, {this.isHome = false});
}

/// Chrome モバイル風タブグリッドの 1 カード。
/// - 上部: ファビコン + タイトル + × 閉じる
/// - 大部分: ホスト頭文字 + URL のプレビュー領域 (画像スナップショットは未対応)
/// - active 時は primary の枠線でハイライト
class _TabGridCard extends StatelessWidget {
  final String title;
  final String host;
  final String url;
  final bool active;
  final Color accentColor;
  final Color cardBg;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabGridCard({
    required this.title,
    required this.host,
    required this.url,
    required this.active,
    required this.accentColor,
    required this.cardBg,
    required this.onTap,
    required this.onClose,
  });

  static const _palette = [
    Color(0xFF5B8DEF),
    Color(0xFFEF6C6C),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
    Color(0xFFEC407A),
    Color(0xFF7E57C2),
  ];

  Color _colorFor(String h) {
    if (h.isEmpty) return _palette[0];
    final hash = h.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final letter =
        (title.isNotEmpty ? title : host).characters.firstOrNull ?? '?';
    final tint = _colorFor(host);
    return Material(
      color: cardBg,
      elevation: active ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? accentColor : Colors.transparent,
          width: active ? 2 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダ: favicon + title + close
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 4),
              child: Row(
                children: [
                  host.isEmpty
                      ? Icon(
                          Icons.public,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.grey,
                        )
                      : ClipOval(
                          child: Image.network(
                            'https://www.google.com/s2/favicons?domain=$host&sz=32',
                            width: 16,
                            height: 16,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.public,
                              size: 16,
                              color:
                                  isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // プレビュー領域 (ページスクショの代替: ホスト頭文字プレースホルダ)
            Expanded(
              child: Container(
                color: tint.withValues(alpha: isDark ? 0.25 : 0.14),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tint,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (host.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          host,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
