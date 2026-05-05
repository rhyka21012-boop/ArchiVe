import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PlaylistPlayerPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int initialIndex;

  const PlaylistPlayerPage({
    required this.items,
    required this.initialIndex,
    super.key,
  });

  @override
  State<PlaylistPlayerPage> createState() => _PlaylistPlayerPageState();
}

class _PlaylistPlayerPageState extends State<PlaylistPlayerPage> {
  late int _currentIndex;
  bool _panelExpanded = false;
  late WebViewController _webController;
  int _progress = 0;

  static const _panelExpandedHeight = 240.0;
  static const _panelCollapsedHeight = 56.0;

  String get _currentUrl => widget.items[_currentIndex]['url']?.toString() ?? '';
  String get _currentTitle => widget.items[_currentIndex]['title']?.toString() ?? _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _initWebController();
    _incrementViewCount(_currentUrl);
  }

  void _initWebController() {
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const {},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  Future<void> _navigateTo(int index) async {
    if (index < 0 || index >= widget.items.length) return;
    final url = widget.items[index]['url']?.toString() ?? '';
    if (url.isEmpty) return;
    setState(() => _currentIndex = index);
    await _webController.loadRequest(Uri.parse(url));
    await _incrementViewCount(url);
  }

  Future<void> _incrementViewCount(String url) async {
    if (url.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(url) ?? 0;
    await prefs.setInt(url, current + 1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final panelH = _panelExpanded ? _panelExpandedHeight : _panelCollapsedHeight;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // WebView + top/bottom spacers
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: topInset + 44 + (_progress < 100 ? 2 : 0)),
                Expanded(child: WebViewWidget(controller: _webController)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  height: panelH + bottomInset,
                ),
              ],
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(colorScheme, topInset),
          ),

          // Bottom panel
          Positioned(
            bottom: bottomInset,
            left: 0,
            right: 0,
            child: _buildBottomPanel(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme, double topInset) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(top: topInset),
      height: topInset + 44,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _currentTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          if (widget.items.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${_currentIndex + 1} / ${widget.items.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: _panelExpanded ? _panelExpandedHeight : _panelCollapsedHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: _panelExpanded
            ? _buildExpandedPanel(colorScheme)
            : _buildCollapsedBar(colorScheme),
      ),
    );
  }

  Widget _buildCollapsedBar(ColorScheme colorScheme) {
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.items.length - 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) {
        if (d.delta.dy < -6) setState(() => _panelExpanded = true);
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
              onPressed: hasPrev ? () => _navigateTo(_currentIndex - 1) : null,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _panelExpanded = true),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (widget.items.length > 1)
                      Text(
                        '${_currentIndex + 1} / ${widget.items.length}',
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
              onPressed: hasNext ? () => _navigateTo(_currentIndex + 1) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(ColorScheme colorScheme) {
    return Column(
      children: [
        // ハンドル（タップ or 下スワイプで閉じる）
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _panelExpanded = false),
          onVerticalDragUpdate: (d) {
            if (d.delta.dy > 6) setState(() => _panelExpanded = false);
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

        // キュー一覧
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isCurrent = index == _currentIndex;
              final image = item['image']?.toString();
              final title = item['title']?.toString() ?? item['url']?.toString() ?? '';

              return InkWell(
                onTap: () => _navigateTo(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: isCurrent
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : null,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: image != null
                            ? Image.network(
                                image,
                                width: 52,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Icon(Icons.play_arrow, color: colorScheme.primary, size: 18),
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

  Widget _placeholder() => Container(
        width: 52,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 16),
      );
}
