import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browser_scroll_top_provider.dart';
import 'favorite_site_provider.dart';
import 'l10n/app_localizations.dart';
import 'search_result_page.dart';

/// ブラウザタブのホーム画面。
/// - AppBar: URL / 検索バー (submit で SearchResultPage へ push)
/// - Body:
///   - 履歴セクション (最近訪問した URL のグリッド)
///   - お気に入りサイトセクション (favoriteSitesProvider 由来のグリッド)
///   末尾に「+」タイル
///   長押しで編集/削除
class BrowserHomePage extends ConsumerStatefulWidget {
  const BrowserHomePage({super.key});

  @override
  ConsumerState<BrowserHomePage> createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends ConsumerState<BrowserHomePage> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<_HistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('browser_history') ?? [];
      final items = <_HistoryItem>[];
      for (final s in raw) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          items.add(_HistoryItem(
            url: m['url']?.toString() ?? '',
            title: m['title']?.toString() ?? '',
          ));
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _history = items);
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('browser_history');
    if (!mounted) return;
    setState(() => _history = []);
  }

  void _submitUrl(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return;
    _openUrl(_resolveUrl(input));
  }

  String _resolveUrl(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    if (!input.contains(' ') && input.contains('.')) {
      return 'https://$input';
    }
    return 'https://www.google.com/search?q=${Uri.encodeComponent(input)}&safe=off';
  }

  Future<void> _openUrl(String url) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultPage(initialUrl: url, title: ''),
      ),
    );
    if (mounted) _loadHistory();
  }

  String _faviconUrl(String siteUrl) {
    try {
      final uri = Uri.parse(siteUrl.startsWith('http')
          ? siteUrl
          : 'https://$siteUrl');
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (_) {
      return '';
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // スクロール要求 (ボトムナビの「ブラウザ」タブ再タップ) を監視
    ref.listen<int>(browserScrollToTopProvider, (prev, next) {
      _scrollToTop();
    });

    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final l = L10n.of(context)!;
    final favorites = ref.watch(favoriteSitesProvider);
    final pageBg = isDark ? cs.surface : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: pageBg,
      // AppBar なし: URL バーは Edge モバイル風に下部 (ボトムナビ直上) に配置
      // ブラウザタブ識別のためグレー背景バー内に、URL 入力欄は白/白12 で明示
      bottomNavigationBar: Material(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
        elevation: 6,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: TextField(
              controller: _urlController,
              focusNode: _urlFocus,
              textInputAction: TextInputAction.go,
              onSubmitted: _submitUrl,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: l.browser_home_url_hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 34, minHeight: 20),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _urlController,
                  builder: (_, v, __) => v.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _urlController.clear(),
                        ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        // 他タブ (AppBar あり) と縦位置を揃えるため、上に AppBar 相当の余白を確保
        padding: const EdgeInsets.fromLTRB(16, 16 + kToolbarHeight, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 履歴セクション
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.browser_home_history,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_history.isNotEmpty)
                  TextButton(
                    onPressed: _confirmClearHistory,
                    child: Text(l.browser_home_history_clear),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l.browser_home_history_empty,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
              )
            else
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (_, i) {
                    final h = _history[i];
                    return _SiteTile(
                      title: h.title.isNotEmpty
                          ? h.title
                          : Uri.tryParse(h.url)?.host ?? h.url,
                      url: h.url,
                      faviconUrl: _faviconUrl(h.url),
                      onTap: () => _openUrl(h.url),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            // お気に入りサイトセクション
            Text(
              l.browser_home_favorites,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _SiteGrid(
              items: [
                for (final f in favorites)
                  _GridEntry(title: f['title'] ?? '', url: f['url'] ?? ''),
              ],
              faviconOf: _faviconUrl,
              onTap: (e) => _openUrl(e.url),
              onLongPress: (e, i) => _showFavoriteActionSheet(favorites[i], i),
              trailing: _AddFavoriteTile(onTap: _showAddFavoriteDialog),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final l = L10n.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.browser_home_history_clear_confirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true), child: Text(l.ok)),
        ],
      ),
    );
    if (ok == true) await _clearHistory();
  }

  Future<void> _showAddFavoriteDialog() async {
    final l = L10n.of(context)!;
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.search_page_add_favorite),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: l.title),
            ),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty ||
                    urlCtrl.text.trim().isEmpty) return;
                ref.read(favoriteSitesProvider.notifier).add(
                      titleCtrl.text.trim(),
                      urlCtrl.text.trim(),
                    );
                Navigator.pop(dctx, true);
              },
              child: Text(l.add)),
        ],
      ),
    );
    if (added == true && mounted) setState(() {});
  }

  void _showFavoriteActionSheet(Map<String, String> site, int index) {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: Text(l.search_page_open_site),
              onTap: () {
                Navigator.pop(bctx);
                _openUrl(site['url'] ?? '');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l.modify),
              onTap: () async {
                Navigator.pop(bctx);
                await _showEditFavoriteDialog(site, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l.delete,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(favoriteSitesProvider.notifier).remove(index);
                Navigator.pop(bctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditFavoriteDialog(
      Map<String, String> site, int index) async {
    final l = L10n.of(context)!;
    final titleCtrl = TextEditingController(text: site['title'] ?? '');
    final urlCtrl = TextEditingController(text: site['url'] ?? '');
    await showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.modify),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: l.title),
            ),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () {
                ref.read(favoriteSitesProvider.notifier).update(
                      index,
                      titleCtrl.text.trim(),
                      urlCtrl.text.trim(),
                    );
                Navigator.pop(dctx);
              },
              child: Text(l.ok)),
        ],
      ),
    );
  }
}

class _HistoryItem {
  final String url;
  final String title;
  const _HistoryItem({required this.url, required this.title});
}

class _GridEntry {
  final String title;
  final String url;
  const _GridEntry({required this.title, required this.url});
}

class _SiteGrid extends StatelessWidget {
  final List<_GridEntry> items;
  final String Function(String url) faviconOf;
  final ValueChanged<_GridEntry> onTap;
  final void Function(_GridEntry entry, int index)? onLongPress;
  final Widget? trailing;

  const _SiteGrid({
    required this.items,
    required this.faviconOf,
    required this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final crossCount = isTablet ? 7 : 5;
        final itemCount = items.length + (trailing != null ? 1 : 0);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.82,
          ),
          itemCount: itemCount,
          itemBuilder: (_, i) {
            if (trailing != null && i == items.length) return trailing!;
            final e = items[i];
            return _SiteTile(
              title: e.title,
              url: e.url,
              faviconUrl: faviconOf(e.url),
              onTap: () => onTap(e),
              onLongPress:
                  onLongPress == null ? null : () => onLongPress!(e, i),
            );
          },
        );
      },
    );
  }
}

/// お気に入り / 履歴共通のサイトタイル (favicon + タイトル)
class _SiteTile extends StatelessWidget {
  final String title;
  final String url;
  final String faviconUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _SiteTile({
    required this.title,
    required this.url,
    required this.faviconUrl,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                color: Colors.grey.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: isDark ? 0.25 : 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: faviconUrl.isEmpty
                  ? Icon(Icons.public,
                      size: 34,
                      color: isDark ? Colors.white54 : Colors.grey.shade500)
                  : Image.network(
                      faviconUrl,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.public,
                        size: 34,
                        color:
                            isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 68,
            child: Text(
              title.isEmpty ? (Uri.tryParse(url)?.host ?? url) : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFavoriteTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFavoriteTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: isDark ? 0.25 : 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.add, size: 26, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            L10n.of(context)!.add,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// ブラウザのホーム画面の「本体」(履歴 + お気に入り) だけを描画する
/// リユーザブル widget。URL バーを持たない場所 (SearchResultPage のホームタブ等)
/// に埋め込んで使う。
class BrowserHomeBody extends ConsumerStatefulWidget {
  final ValueChanged<String> onOpenUrl;
  const BrowserHomeBody({super.key, required this.onOpenUrl});

  @override
  ConsumerState<BrowserHomeBody> createState() => _BrowserHomeBodyState();
}

class _BrowserHomeBodyState extends ConsumerState<BrowserHomeBody> {
  List<_HistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('browser_history') ?? [];
      final items = <_HistoryItem>[];
      for (final s in raw) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          items.add(_HistoryItem(
            url: m['url']?.toString() ?? '',
            title: m['title']?.toString() ?? '',
          ));
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _history = items);
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('browser_history');
    if (!mounted) return;
    setState(() => _history = []);
  }

  String _faviconUrl(String siteUrl) {
    try {
      final uri = Uri.parse(
          siteUrl.startsWith('http') ? siteUrl : 'https://$siteUrl');
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
    } catch (_) {
      return '';
    }
  }

  Future<void> _confirmClearHistory() async {
    final l = L10n.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.browser_home_history_clear_confirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true), child: Text(l.ok)),
        ],
      ),
    );
    if (ok == true) await _clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = L10n.of(context)!;
    final favorites = ref.watch(favoriteSitesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.browser_home_history,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              if (_history.isNotEmpty)
                TextButton(
                  onPressed: _confirmClearHistory,
                  child: Text(l.browser_home_history_clear),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l.browser_home_history_empty,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
            )
          else
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (_, i) {
                  final h = _history[i];
                  return _SiteTile(
                    title: h.title.isNotEmpty
                        ? h.title
                        : Uri.tryParse(h.url)?.host ?? h.url,
                    url: h.url,
                    faviconUrl: _faviconUrl(h.url),
                    onTap: () => widget.onOpenUrl(h.url),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          Text(
            l.browser_home_favorites,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _SiteGrid(
            items: [
              for (final f in favorites)
                _GridEntry(title: f['title'] ?? '', url: f['url'] ?? ''),
            ],
            faviconOf: _faviconUrl,
            onTap: (e) => widget.onOpenUrl(e.url),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
