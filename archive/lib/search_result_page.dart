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
import 'package:cached_network_image/cached_network_image.dart';

import 'l10n/app_localizations.dart';
import 'favorite_site_provider.dart';
import 'list_reload_provider.dart';
import 'save_limit_helper.dart';

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
  late final WebViewController _controller;
  bool _canGoBack = false;

  String? _currentUrl;
  String _pageTitle = '';

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

  //検索履歴リスト
  List<WebHistoryItem> _history = [];

  //プログレスバーの表示
  int _progress = 0;

  //URLバー
  final TextEditingController _urlBarController = TextEditingController();
  final FocusNode _urlBarFocus = FocusNode();
  bool _isUrlBarEditing = false;

  // Twitter風 AppBar/FAB 自動隠し
  bool _showChrome = true;

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

    _controller =
        WebViewController.fromPlatformCreationParams(params)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'FlutterScroll',
            onMessageReceived: (msg) {
              if (msg.message == 'down' && _showChrome) {
                setState(() => _showChrome = false);
              } else if ((msg.message == 'up' || msg.message == 'top') &&
                  !_showChrome) {
                setState(() => _showChrome = true);
              }
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (progress) {
                setState(() {
                  _progress = progress;
                });
              },

              // YouTubeアプリ等の外部アプリへの遷移をブロックし、WebView内に留める
              onNavigationRequest: (NavigationRequest request) {
                final uri = Uri.tryParse(request.url);
                if (uri == null) return NavigationDecision.prevent;
                // http(s)以外のスキーム(youtube://, vnd.youtube://, intent://など)を全て拒否
                if (uri.scheme != 'http' && uri.scheme != 'https') {
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },

              onPageFinished: (url) async {
                // 悪質な広告・ポップアップをブロック
                await _injectAdBlocker();
                // スクロール方向検知 JS を注入
                await _injectScrollDetector();

                final title = await _getPageTitle();

                //検索履歴を追加
                if (_history.isEmpty || _history.last != url) {
                  _history.add(WebHistoryItem(url, title));
                }

                final canBack = await _controller.canGoBack();

                setState(() {
                  _canGoBack = canBack;
                  _currentUrl = url;
                  _pageTitle = title;
                  // URLバーを編集中でなければ最新URLに同期
                  if (!_isUrlBarEditing) {
                    _urlBarController.text = url;
                  }
                });
              },
            ),
          )
          ..loadRequest(Uri.parse(initialUrl));

    // iOS WKWebView：エッジスワイプで戻る・進むを有効化
    if (Platform.isIOS && _controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

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

  @override
  void dispose() {
    _urlBarController.dispose();
    _urlBarFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isFav = ref.watch(
      favoriteSitesProvider.select(
        (list) => list.any((e) => _host(e["url"]) == _host(_currentUrl)),
      ),
    );

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_canGoBack) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          offset: _showChrome ? Offset.zero : const Offset(0, -1.5),
          child: AppBar(
        elevation: 6,
        backgroundColor: colorScheme.surface,

        // 戻る専用
        leading: GestureDetector(
          onTap: () async {
            if (_canGoBack) {
              await _controller.goBack();
            } else {
              Navigator.pop(context);
            }
          },
          onLongPress: () {
            _showHistoryDialog(); // ← 履歴表示
          },
          child: const Padding(
            padding: EdgeInsets.all(12), // タップ領域を確保
            child: Icon(Icons.arrow_back),
          ),
        ),

        title: _buildUrlBar(colorScheme),
        titleSpacing: 0,

        actions: [
          IconButton(
            tooltip: L10n.of(context)!.favorite,
            icon: Icon(isFav ? Icons.star : Icons.star_border),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: _shareCurrentUrl,
          ),
          IconButton(
            tooltip: L10n.of(context)!.close,
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child:
              _progress < 100
                  ? LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 2,
                  )
                  : const SizedBox.shrink(),
        ),
      ),
        ),
      ),

      body: Listener(
        // WebView タップで URLバーのフォーカスを外す
        onPointerDown: (_) {
          if (_urlBarFocus.hasFocus) _urlBarFocus.unfocus();
        },
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            top: _showChrome
                ? MediaQuery.of(context).padding.top + kToolbarHeight
                : 0,
          ),
          child: _hasPlaylist
              ? Stack(
                  children: [
                    Positioned.fill(child: WebViewWidget(controller: _controller)),
                    Positioned(
                      bottom: MediaQuery.of(context).padding.bottom,
                      left: 0,
                      right: 0,
                      child: _buildPlaylistPanel(colorScheme),
                    ),
                  ],
                )
              : WebViewWidget(controller: _controller),
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        offset: _showChrome ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _showChrome ? 1.0 : 0.0,
          child: _buildSaveFab(colorScheme),
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

  /// URLバー：タップで編集可能、Enter で遷移
  Widget _buildUrlBar(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2C) : Colors.grey[200];

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          prefixIcon: Icon(
            (_currentUrl?.startsWith('https://') ?? false)
                ? Icons.lock
                : Icons.public,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _isUrlBarEditing
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => _urlBarController.clear(),
                )
              : IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () => _controller.reload(),
                ),
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
    if (uri != null) await _controller.loadRequest(uri);
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

  /// 悪質な広告・ポップアップをブロックする JavaScript を注入（v2 強化版）
  /// - window.open / showModalDialog による無断ポップアップを抑止
  /// - 既知の広告ネットワーク iframe を網羅的に非表示
  /// - 全画面オーバーレイ広告を非表示
  /// - MutationObserver で動的追加された広告も即時非表示
  /// - body scroll lock を解除（ポップアップが scroll を止めるパターン対策）
  /// - 広告ドメインへの click を抑制
  Future<void> _injectAdBlocker() async {
    const js = r'''
(function() {
  if (window.__archive_adblock_v2) return;
  window.__archive_adblock_v2 = true;

  // ───────────────────────────────────────────
  // 1. ポップアップAPIをブロック
  // ───────────────────────────────────────────
  try { window.open = function() { return null; }; } catch (e) {}
  try { window.showModalDialog = function() { return null; }; } catch (e) {}

  // ───────────────────────────────────────────
  // 2. 広告セレクタ網羅
  // ───────────────────────────────────────────
  var adSelectors = [
    // iframe
    'iframe[src*="googleads"]',
    'iframe[src*="googlesyndication"]',
    'iframe[src*="doubleclick"]',
    'iframe[src*="adsystem"]',
    'iframe[src*="adservice"]',
    'iframe[src*="adnxs"]',
    'iframe[src*="taboola"]',
    'iframe[src*="outbrain"]',
    'iframe[src*="popads"]',
    'iframe[src*="propellerads"]',
    'iframe[src*="mgid"]',
    'iframe[src*="exoclick"]',
    'iframe[src*="trafficjunky"]',
    'iframe[id*="google_ads"]',
    'iframe[id*="ad_iframe"]',
    'iframe[class*="ad-frame"]',
    'iframe[name*="google_ads"]',
    // ad container
    'div[id^="google_ads_"]',
    'div[id^="div-gpt-ad"]',
    'div[id^="ad-"]',
    'div[id*="-ad-"]',
    'ins.adsbygoogle',
    'div[class*="popup-ad"]',
    'div[class*="overlay-ad"]',
    'div[class*="interstitial"]',
    'div[id*="interstitial"]',
    'div[class*="popup-container"]',
    'div[class*="modal-overlay"]',
    'div[class*="banner-ad"]',
    'div[class*="advertisement"]',
    'div[id*="modal-overlay"]',
    'div[class*="popup-mask"]',
    'div[class*="lightbox-overlay"]',
    'div[class*="sticky-ad"]',
    'div[class*="floating-ad"]',
    'div[class*="bottom-banner"]',
    'div[id*="cookie-notice"]',
    'div[class*="cookie-banner"]',
    'div[class*="newsletter-popup"]',
    'div[class*="subscribe-popup"]',
    'aside[class*="ad"]',
    'section[class*="ad-container"]'
  ];
  var selectorStr = adSelectors.join(',');

  // ───────────────────────────────────────────
  // 3. ホワイトリスト（誤検知防止）
  // ───────────────────────────────────────────
  function isSafeElement(el) {
    var id = (el.id || '').toLowerCase();
    var cls = (el.className || '').toString().toLowerCase();
    // header / footer / navigation などは保護
    if (/header|footer|nav|menu|comment|video|player/.test(id + ' ' + cls)) {
      return true;
    }
    return false;
  }

  // ───────────────────────────────────────────
  // 4. 広告非表示処理
  // ───────────────────────────────────────────
  function hideAds() {
    try {
      // セレクタ一致
      document.querySelectorAll(selectorStr).forEach(function(el) {
        el.style.setProperty('display', 'none', 'important');
        el.style.setProperty('visibility', 'hidden', 'important');
      });

      // 全画面オーバーレイ検出
      var vw = window.innerWidth;
      var vh = window.innerHeight;
      document.querySelectorAll('div,section,aside').forEach(function(el) {
        if (isSafeElement(el)) return;
        var s = getComputedStyle(el);
        if (s.position !== 'fixed' && s.position !== 'absolute') return;
        if (s.display === 'none' || s.visibility === 'hidden') return;
        var z = parseInt(s.zIndex, 10) || 0;
        if (z < 100) return;
        var r = el.getBoundingClientRect();
        if (r.width >= vw * 0.85 && r.height >= vh * 0.7) {
          el.style.setProperty('display', 'none', 'important');
        }
      });

      // body scroll lock 解除（ポップアップが scroll を止める対策）
      if (document.body) {
        document.body.style.removeProperty('overflow');
        document.body.style.removeProperty('position');
        if (getComputedStyle(document.body).overflow === 'hidden') {
          document.body.style.setProperty('overflow', 'auto', 'important');
        }
      }
      if (document.documentElement) {
        if (getComputedStyle(document.documentElement).overflow === 'hidden') {
          document.documentElement.style.setProperty('overflow', 'auto', 'important');
        }
      }
    } catch (e) {}
  }

  // ───────────────────────────────────────────
  // 5. 初回 + 動的監視
  // ───────────────────────────────────────────
  hideAds();
  try {
    var observer = new MutationObserver(function(mutations) {
      // 新しく追加された要素があれば再スキャン
      for (var i = 0; i < mutations.length; i++) {
        if (mutations[i].addedNodes && mutations[i].addedNodes.length > 0) {
          hideAds();
          break;
        }
      }
    });
    observer.observe(document.documentElement || document.body, {
      childList: true,
      subtree: true
    });
  } catch (e) {}
  // 定期チェック（Shadow DOM などの取りこぼし対策）
  setInterval(hideAds, 2500);

  // ───────────────────────────────────────────
  // 6. 広告ドメインへの click をブロック
  // ───────────────────────────────────────────
  document.addEventListener('click', function(e) {
    try {
      var t = e.target;
      for (var d = 0; t && d < 6; d++) {
        if (t.tagName === 'A' && t.href) {
          var href = (t.href || '').toLowerCase();
          if (/doubleclick|googleads|googlesyndication|adservice|amazon-adsystem|popads|propellerads|exoclick|trafficjunky/.test(href)) {
            e.preventDefault();
            e.stopPropagation();
            return false;
          }
        }
        t = t.parentElement;
      }
    } catch (err) {}
  }, true);
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
    const js = r'''
(function() {
  if (window.__archive_scroll_detector) return;
  window.__archive_scroll_detector = true;
  var lastY = window.scrollY || 0;
  var ticking = false;
  function onScroll() {
    var y = window.scrollY || 0;
    var dy = y - lastY;
    if (y <= 30) {
      try { FlutterScroll.postMessage('top'); } catch(e) {}
    } else if (Math.abs(dy) > 6) {
      try {
        FlutterScroll.postMessage(dy > 0 ? 'down' : 'up');
      } catch(e) {}
    }
    lastY = y;
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

  //URL生成メソッド
  //初期表示時にGoogl動画タブを開く
  String _buildGoogleVideoSearchUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://www.google.com/search?q=$encoded&tbm=vid&safe=off';
  }

  //initialUrlがURLの場合に分岐
  String _resolveInitialUrl(String input) {
    if (input.startsWith('http')) {
      return input; // そのまま表示
    }
    return _buildGoogleVideoSearchUrl(input); // 検索語 → 動画検索
  }

  //作品として保存するダイアログ
  Future<void> _showSaveWorkDialog() async {
    //評価をリセット
    selectedRating = null;

    final url = await _controller.currentUrl();
    if (url == null) return;

    final title = await _getPageTitle();

    final prefs = await SharedPreferences.getInstance();

    // リスト一覧取得
    final allLists = prefs.getStringList('all_lists') ?? [];

    String selectedList = 'none';
    final titleController = TextEditingController(text: title);
    final urlController = TextEditingController(text: url);
    final colorScheme = Theme.of(context).colorScheme;

    // サムネを事前取得（ダイアログ表示と並行）
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
                          label: L10n.of(context)!.critical,
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
                          label: L10n.of(context)!.normal,
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
                          label: L10n.of(context)!.maniac,
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

                    await _saveWorkFromWebView(
                      url: urlController.text,
                      title: titleController.text,
                      listName: selectedList == 'none' ? '' : selectedList,
                      thumbnailUrl: thumbnailUrl,
                    );
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
  Future<void> _saveWorkFromWebView({
    required String url,
    required String title,
    required String listName,
    String? thumbnailUrl,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.search_result_page_url_already_saved),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!exists) {
      savedList.add(jsonEncode(data));
      await prefs.setStringList('saved_metadata', savedList);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L10n.of(context)!.search_result_page_has_saved)),
    );

    //広告表示処理
    await _maybeShowAd();
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

                        _history = _history.sublist(0, reversedIndex + 1);

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

  //広告表示処理
  Future<void> _maybeShowAd() async {
    if (_isPremium) return;

    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt("save_ad_count") ?? 0;

    count++;
    await prefs.setInt("save_ad_count", count);

    // 初回保護（2回未満は広告なし）
    if (count < 2) return;

    final remainder = count % 3;

    // ⭐ 予告（3の倍数の1つ前）
    if (remainder == 2) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.search_result_page_ad_remainder01),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // ⭐ 3回目（広告表示）
    if (remainder == 0 && _interstitialAd != null) {
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.removeCurrentSnackBar();

      final snackBarController = messenger.showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.search_result_page_ad_remainder02),
          duration: Duration(milliseconds: 1200),
        ),
      );

      await snackBarController.closed;
      if (!mounted) return;

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
      final isActive =
          customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false;
      setState(() {
        _isPremium = isActive;
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
