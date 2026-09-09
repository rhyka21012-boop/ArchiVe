import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// アイテムがローカル動画を持つか判定
bool hasLocalVideoFor(Map<String, dynamic> item) {
  final p = item['localVideoPath'] as String?;
  return p != null && p.isNotEmpty && File(p).existsSync();
}

/// サムネ上端に表示する「前回中断位置」のシークバー。
/// オフラインでない/位置情報無しの場合は 0px の SizedBox を返す (レイアウト無影響)。
///
/// **必ず [Positioned] などで親 Stack 内の位置を指定してから使うこと**
/// (自身は Positioned を返さないので、条件分岐で Stack のレイアウトを壊さない)。
class OfflineProgressBar extends StatelessWidget {
  final Map<String, dynamic> item;
  const OfflineProgressBar({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (!hasLocalVideoFor(item)) return const SizedBox.shrink();
    final pos = item['offlinePosSec'] as int?;
    final dur = item['offlineDurSec'] as int?;
    if (pos == null || dur == null || dur <= 0) return const SizedBox.shrink();
    final ratio = (pos / dur).clamp(0.0, 1.0);
    return SizedBox(
      height: 3,
      child: Stack(
        children: [
          Container(color: Colors.black.withValues(alpha: 0.35)),
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

/// サムネ以外の場所 (再生ボタン横 / リスト行内) に並べる、
/// コンパクトな「favicon + サイズチップ + DL 済みアイコン」ユニット。
/// オフラインでなければ何も描画しない (SizedBox.shrink)。
class OfflineInlineChips extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool overlayStyle; // true = サムネ上に重ねる用 (黒背景・白文字)
  final bool showDownloadedIcon;

  const OfflineInlineChips({
    super.key,
    required this.item,
    this.overlayStyle = true,
    this.showDownloadedIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasLocalVideoFor(item)) return const SizedBox.shrink();
    final size = item['localVideoSize'] as int?;
    final url = item['url']?.toString() ?? '';
    final host = Uri.tryParse(url)?.host;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FaviconSizeChip(
          host: host,
          size: size,
          overlayStyle: overlayStyle,
        ),
        if (showDownloadedIcon) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: overlayStyle
                  ? Colors.black54
                  : Colors.green.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_done,
              size: 12,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

class _FaviconSizeChip extends StatelessWidget {
  final String? host;
  final int? size;
  final bool overlayStyle;
  const _FaviconSizeChip({this.host, this.size, this.overlayStyle = true});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = size != null ? _formatSize(size!) : null;
    final bg = overlayStyle
        ? Colors.black.withValues(alpha: 0.6)
        : cs.surfaceContainerHighest;
    final fg = overlayStyle ? Colors.white : cs.onSurfaceVariant;
    final fallbackIconColor =
        overlayStyle ? Colors.white70 : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (host != null && host!.isNotEmpty) ...[
            ClipOval(
              child: CachedNetworkImage(
                imageUrl:
                    'https://www.google.com/s2/favicons?domain=$host&sz=32',
                width: 12,
                height: 12,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.public, size: 12, color: fallbackIconColor),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (label != null)
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
