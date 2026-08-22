import 'package:flutter/material.dart';

/// AppBar の leading / actions で使う「丸く縁取ったアイコンボタン」。
/// - 明色モード（既定）: 薄い黒の丸背景 + 濃いアイコン
/// - 暗色モード（既定）: 薄い白の丸背景 + 白アイコン
/// - `backgroundColor` を明示指定した場合はその明度から自動的に読める色を選ぶ
///   （例: 白背景を渡すとダークモードでも暗色アイコンに切り替わる）
class CircleAppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final Key? buttonKey;

  const CircleAppBarIcon({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.size = 40,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    if (backgroundColor != null) {
      // 明示指定された背景色は透過も含めて実色として扱い、
      // その明度からコントラストの取れるアイコン色を選ぶ
      bg = backgroundColor!;
      fg = iconColor ??
          (bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white);
    } else {
      // 既定は AppBar 背景に薄く重なる半透明の丸
      bg = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.06);
      fg = iconColor ?? (isDark ? Colors.white : Colors.black87);
    }

    Widget button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        key: buttonKey,
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 20, color: fg),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
