import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'notification_settings_service.dart';

/// 通知が拒否されている場合に、理由を説明して設定画面へ誘導する。
///
/// Android では通知を掲示できないと前景サービスが成立せず、OS から背景アプリ
/// 扱いのままになるため、従量制 (モバイル) 回線でダウンロード中のソケットが
/// 遮断される。Android は一度拒否された権限を再要求しても再表示しないので、
/// 設定画面へ送るしか手がない。
///
/// ダウンロード自体は妨げない。開始前に案内し、「あとで」を選んでも続行する。
/// iOS は通知が無くてもバックグラウンド転送が継続するため何もしない
/// (サービス側の [NotificationSettingsService.isNotificationDenied] で判定)。
Future<void> warnIfNotificationsBlockBackgroundDownload(
  BuildContext context,
) async {
  if (!await NotificationSettingsService.isNotificationDenied()) return;
  if (!context.mounted) return;
  final l = L10n.of(context)!;
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(l.download_notification_permission_title),
      content: Text(l.download_notification_permission_body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx, false),
          child: Text(l.main_page_update_later),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dctx, true),
          child: Text(l.main_page_settings),
        ),
      ],
    ),
  );
  if (openSettings == true) {
    await NotificationSettingsService.openNotificationSettings();
  }
}

/// オフラインダウンロードの解像度選択肢。null = ダウンロードしない
const List<int> kOfflineQualityHeights = [1080, 720, 480, 360, 240];

/// 「前回の選択」を prefs に int で保存する際の特別な値。
/// 解像度は正の値なので、負値・0 を状態の表現に使う。
const int kOfflinePrefNone = 0; // ダウンロードしない
const int kOfflinePrefAudioOnly = -2; // 音声のみ

/// オフライン保存の選択結果。
///
/// 解像度と「音声のみ」は排他なので、int? では表現できない。
/// 「キャンセル」と「ダウンロードしない」は既存実装と同様に区別しない
/// (どちらも呼び出し側では null として扱う)。
class OfflineChoice {
  /// 希望解像度。[audioOnly] が true の場合は null。
  final int? height;

  /// 音声のみとして保存するか。
  final bool audioOnly;

  const OfflineChoice.height(int this.height) : audioOnly = false;
  const OfflineChoice.audio()
      : height = null,
        audioOnly = true;

  /// prefs 保存用の int 表現
  int toPrefValue() => audioOnly ? kOfflinePrefAudioOnly : (height ?? kOfflinePrefNone);

  /// prefs の int 表現から復元する。該当しなければ null (= 未選択/なし)。
  static OfflineChoice? fromPrefValue(int? v) {
    if (v == null) return null;
    if (v == kOfflinePrefAudioOnly) return const OfflineChoice.audio();
    if (v > 0) return OfflineChoice.height(v);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is OfflineChoice &&
      other.height == height &&
      other.audioOnly == audioOnly;

  @override
  int get hashCode => Object.hash(height, audioOnly);
}

/// 横スクロール型の解像度選択チップ列。
/// [selected] が null の場合は「オフラインダウンロードなし」。
class OfflineQualityChips extends StatelessWidget {
  final OfflineChoice? selected;
  final ValueChanged<OfflineChoice?> onChanged;

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
            isSelected: selected?.height == h,
            onTap: () => onChanged(OfflineChoice.height(h)),
          ),
        _PickerChip(
          label: l.offline_quality_audio_only,
          icon: Icons.music_note,
          isSelected: selected?.audioOnly ?? false,
          onTap: () => onChanged(const OfflineChoice.audio()),
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

Future<OfflineChoice?> showOfflineQualitySheet(
  BuildContext context, {
  OfflineChoice? initial,
  bool showNoneOption = true,
  Set<int>? availableHeights,
}) async {
  final l = L10n.of(context)!;
  return await showModalBottomSheet<OfflineChoice?>(
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
                      isSelected: initial?.height == h,
                      enabled: availableHeights == null ||
                          availableHeights.contains(h),
                      onTap: () =>
                          Navigator.pop(bctx, OfflineChoice.height(h)),
                    ),
                  _PickerChip(
                    label: l.offline_quality_audio_only,
                    icon: Icons.music_note,
                    isSelected: initial?.audioOnly ?? false,
                    onTap: () =>
                        Navigator.pop(bctx, const OfflineChoice.audio()),
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
