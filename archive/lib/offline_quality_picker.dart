import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// オフラインダウンロードの解像度選択肢。null = ダウンロードしない
const List<int> kOfflineQualityHeights = [1080, 720, 480, 360, 240];

/// 横スクロール型の解像度選択チップ列。
/// [selected] が null の場合は「オフラインダウンロードなし」。
class OfflineQualityChips extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onChanged;

  const OfflineQualityChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final h in kOfflineQualityHeights)
          _PickerChip(
            label: '${h}p',
            icon: Icons.high_quality,
            isSelected: selected == h,
            onTap: () => onChanged(h),
          ),
        _PickerChip(
          label: l.offline_quality_none,
          icon: Icons.cloud_off_outlined,
          isSelected: selected == null,
          onTap: () => onChanged(null),
        ),
      ],
    );
  }
}


/// 解像度をボトムシートで選択する共通関数。
/// 戻り値: 選択された解像度 (null = 「ダウンロードなし」, キャンセルは -1 相当を返さず null)
/// キャンセル (バリア外タップ等) 時は "canceled" を意味する Result を返す。
enum QualitySheetResult { picked1080, picked720, picked480, picked360, picked240, none, canceled }

Future<int?> showOfflineQualitySheet(
  BuildContext context, {
  int? initial,
  bool showNoneOption = true,
  Set<int>? availableHeights,
}) async {
  final l = L10n.of(context)!;
  return await showModalBottomSheet<int?>(
    context: context,
    showDragHandle: true,
    builder: (bctx) {
      final cs = Theme.of(bctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.offline_quality_title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                l.offline_quality_desc,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in kOfflineQualityHeights)
                    _PickerChip(
                      label: '${h}p',
                      icon: Icons.high_quality,
                      isSelected: initial == h,
                      enabled: availableHeights == null ||
                          availableHeights.contains(h),
                      onTap: () => Navigator.pop(bctx, h),
                    ),
                  if (showNoneOption)
                    _PickerChip(
                      label: l.offline_quality_none,
                      icon: Icons.cloud_off_outlined,
                      isSelected: initial == null,
                      onTap: () => Navigator.pop(bctx, null),
                      neutral: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 汎用ピッカーチップ (このモジュール & 他モジュールから流用)
class PickerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool neutral;

  const PickerChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) => _PickerChip(
        label: label,
        icon: icon,
        isSelected: isSelected,
        onTap: onTap,
        neutral: neutral,
      );
}

class _PickerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool neutral;
  final bool enabled;

  const _PickerChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.neutral = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isSelected
        ? (neutral ? cs.surfaceContainerHighest : cs.primary)
        : Colors.transparent;
    final fg = isSelected
        ? (neutral ? cs.onSurface : cs.onPrimary)
        : cs.onSurfaceVariant;
    final border = isSelected
        ? Colors.transparent
        : cs.outline.withValues(alpha: 0.5);
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: BorderSide(color: border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle : icon,
                  size: 16,
                  color: fg,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
