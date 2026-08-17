import 'package:flutter/material.dart';

/// AppBar の leading / actions で使う「丸く縁取ったアイコンボタン」。
/// - 明色モード: 薄い黒の丸背景 + 濃い文字色
/// - 暗色モード: 薄い白の丸背景 + 白アイコン
/// バッジやツールチップも指定可能。
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
    final bg = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.06));
    final fg = iconColor ?? (isDark ? Colors.white : Colors.black87);

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
