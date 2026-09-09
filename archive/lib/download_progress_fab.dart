import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'download_queue_provider.dart';
import 'l10n/app_localizations.dart';

/// ダウンロードキューのボトムシートを開く共通関数 (他画面からも呼び出せる)。
void showDownloadQueueSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (bctx) {
      return Consumer(
        builder: (_, wref, __) {
          final tasks = wref.watch(downloadQueueProvider);
          return SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.download_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          L10n.of(context)!.download_queue_title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          wref
                              .read(downloadQueueProvider.notifier)
                              .clearFinished();
                        },
                        child:
                            Text(L10n.of(context)!.download_clear_finished),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(L10n.of(context)!.download_empty),
                      ),
                    )
                  else
                    ...tasks.map((t) => _TaskRow(task: t)),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// ダウンロード進捗をボトムに常駐する薄いステータスバー。
/// - active/failed タスクが 1件以上ある時のみスライドイン表示
/// - 上端に細い LinearProgressIndicator
/// - 左: アイコン (+ 件数バッジ)、中央: タイトル + 進捗、右: パーセント + ×
/// - タップで詳細ボトムシート、× タップで全キャンセル確認
class DownloadStatusBar extends ConsumerWidget {
  const DownloadStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadQueueProvider);
    final active = tasks.where(
      (t) =>
          t.status == DownloadStatus.downloading ||
          t.status == DownloadStatus.queued,
    ).toList();
    final failed =
        tasks.where((t) => t.status == DownloadStatus.failed).toList();
    final visible = active.isNotEmpty || failed.isNotEmpty;

    final cs = Theme.of(context).colorScheme;
    final l = L10n.of(context)!;
    final showFailedOnly = active.isEmpty && failed.isNotEmpty;
    final progress = active.isNotEmpty
        ? active.fold<double>(0.0, (a, t) => a + t.progress) / active.length
        : 1.0;
    final pct = (progress * 100).round();
    final count = active.length + failed.length;
    // 表示中の代表タスク: 進行中優先、なければ失敗の先頭
    final current = active.isNotEmpty
        ? active.first
        : (failed.isNotEmpty ? failed.first : null);
    final title = (current?.title.isNotEmpty ?? false)
        ? current!.title
        : l.download_queue_title;
    final accent = showFailedOnly ? Colors.red : cs.primary;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1.4),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: visible ? 1.0 : 0.0,
        child: Material(
          color: cs.surface,
          elevation: 6,
          child: InkWell(
            onTap: () => showDownloadQueueSheet(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 2.5,
                  child: LinearProgressIndicator(
                    value: active.isNotEmpty && progress > 0 ? progress : null,
                    minHeight: 2.5,
                    color: accent,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // 左: アイコン (件数バッジは重ねる)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              showFailedOnly
                                  ? Icons.error_outline
                                  : Icons.download_rounded,
                              size: 20,
                              color: accent,
                            ),
                          ),
                          if (count > 1)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                      color: cs.surface, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 16),
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // 中央: タイトル + サブテキスト
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              showFailedOnly
                                  ? l.download_status_failed
                                  : (active.length > 1
                                      ? '$pct% · ${active.length}'
                                      : '$pct%'),
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 右: × (キャンセル)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: l.cancel,
                        color: cs.onSurfaceVariant,
                        onPressed: () => _confirmCancelAll(
                            context, ref, [...active, ...failed]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancelAll(
      BuildContext context, WidgetRef ref, List<DownloadTask> targets) async {
    if (targets.isEmpty) return;
    final l = L10n.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(l.download_cancel_all_confirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: Text(l.ok)),
        ],
      ),
    );
    if (ok != true) return;
    final notifier = ref.read(downloadQueueProvider.notifier);
    for (final t in targets) {
      notifier.cancel(t.id);
    }
  }
}

class _TaskRow extends ConsumerWidget {
  final DownloadTask task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData icon;
    Color? iconColor;
    switch (task.status) {
      case DownloadStatus.queued:
        icon = Icons.schedule;
        iconColor = colorScheme.onSurface.withValues(alpha: 0.6);
        break;
      case DownloadStatus.downloading:
        icon = Icons.downloading;
        iconColor = colorScheme.primary;
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case DownloadStatus.failed:
        icon = Icons.error;
        iconColor = Colors.red;
        break;
      case DownloadStatus.canceled:
        icon = Icons.cancel;
        iconColor = Colors.orange;
        break;
    }
    final subtitle = _subtitleFor(context, task);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title.isEmpty ? task.url : task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (task.status == DownloadStatus.downloading ||
                    task.status == DownloadStatus.queued) ...[
                  LinearProgressIndicator(
                    value: task.progress > 0 ? task.progress : null,
                    minHeight: 4,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                if (task.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      task.error!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (task.status == DownloadStatus.failed ||
              task.status == DownloadStatus.canceled)
            IconButton(
              tooltip: L10n.of(context)!.download_retry,
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () {
                ref.read(downloadQueueProvider.notifier).retry(task.id);
              },
            ),
          IconButton(
            icon: Icon(
              task.status == DownloadStatus.downloading ||
                      task.status == DownloadStatus.queued
                  ? Icons.close
                  : Icons.delete_outline,
              size: 18,
            ),
            onPressed: () async {
              final inProgress =
                  task.status == DownloadStatus.downloading ||
                      task.status == DownloadStatus.queued;
              if (inProgress) {
                final l = L10n.of(context)!;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: Text(l.download_cancel_confirm_title),
                    content: Text(l.download_cancel_confirm_body),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: Text(l.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        child: Text(l.ok),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
              }
              ref.read(downloadQueueProvider.notifier).cancel(task.id);
            },
          ),
        ],
      ),
    );
  }

  String _subtitleFor(BuildContext context, DownloadTask task) {
    final l = L10n.of(context)!;
    switch (task.status) {
      case DownloadStatus.queued:
        return l.download_status_queued;
      case DownloadStatus.downloading:
        final pct = (task.progress * 100).round();
        final mb = task.received / 1024 / 1024;
        final totalMb = task.total != null ? task.total! / 1024 / 1024 : null;
        return totalMb != null
            ? '$pct%  (${mb.toStringAsFixed(1)} / ${totalMb.toStringAsFixed(1)} MB)'
            : '$pct%  (${mb.toStringAsFixed(1)} MB)';
      case DownloadStatus.completed:
        final totalMb = task.total != null ? task.total! / 1024 / 1024 : null;
        return totalMb != null
            ? '${l.download_status_completed}  (${totalMb.toStringAsFixed(1)} MB)'
            : l.download_status_completed;
      case DownloadStatus.failed:
        return l.download_status_failed;
      case DownloadStatus.canceled:
        return l.download_status_canceled;
    }
  }
}
