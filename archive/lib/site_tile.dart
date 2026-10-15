import 'package:flutter/material.dart';

/// サイトを表すタイルとグリッド。
///
/// ブラウザホームの実装 (browser_home_page.dart の private 版) と同一の見た目を
/// 共有するために切り出したもの。ホーム画面のウィジェットからも使う。
/// 片方だけ手を入れて見た目がずれるのを防ぐため、定義はここに一本化する。

/// favicon の取得 URL を組み立てる
String faviconUrlFor(String siteUrl) {
  try {
    final uri = Uri.parse(
      siteUrl.startsWith('http') ? siteUrl : 'https://$siteUrl',
    );
    return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
  } catch (_) {
    return '';
  }
}

/// グリッドに並べる 1 件分
class SiteGridEntry {
  final String title;
  final String url;
  const SiteGridEntry({required this.title, required this.url});
}

/// サイトタイルのグリッド。
/// 画面幅に応じて列数を切り替える (タブレットでは多く並べる)。
class SiteGrid extends StatelessWidget {
  final List<SiteGridEntry> items;
  final ValueChanged<SiteGridEntry> onTap;
  final void Function(SiteGridEntry entry, int index)? onLongPress;
  final Widget? trailing;

  const SiteGrid({
    super.key,
    required this.items,
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
            return SiteTile(
              title: e.title,
              url: e.url,
              faviconUrl: faviconUrlFor(e.url),
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

/// favicon + タイトルのサイトタイル
class SiteTile extends StatelessWidget {
  final String title;
  final String url;
  final String faviconUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// 小型版。ホーム画面のウィジェットのように高さが限られる場所で使う。
  /// ブラウザホームは従来サイズのままにするため、既定は false。
  final bool compact;

  const SiteTile({
    super.key,
    required this.title,
    required this.url,
    required this.faviconUrl,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final box = compact ? 44.0 : 56.0;
    final icon = compact ? 28.0 : 36.0;
    final fallbackIcon = compact ? 26.0 : 34.0;
    final labelSize = compact ? 10.0 : 11.0;
    final labelWidth = compact ? 56.0 : 68.0;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.15),
                width: 1,
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
              child: faviconUrl.isEmpty
                  ? Icon(Icons.public,
                      size: fallbackIcon,
                      color: isDark ? Colors.white54 : Colors.grey.shade500)
                  : Image.network(
                      faviconUrl,
                      width: icon,
                      height: icon,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.public,
                        size: fallbackIcon,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          SizedBox(
            width: labelWidth,
            child: Text(
              title.isEmpty ? (Uri.tryParse(url)?.host ?? url) : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: labelSize,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
