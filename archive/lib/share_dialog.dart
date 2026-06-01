import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';
import 'share_service.dart';

/// リスト共有ダイアログ
/// 既存共有があればURL表示＋解除ボタン、無ければ共有作成ボタン
class ShareDialog extends StatefulWidget {
  final String listName;
  final List<Map<String, dynamic>> items;

  const ShareDialog({
    super.key,
    required this.listName,
    required this.items,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  bool _loading = true;
  SharedListInfo? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final existing = await ShareService.findShareByListName(widget.listName);
      if (!mounted) return;
      setState(() {
        _existing = existing;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _createShare() async {
    setState(() => _loading = true);
    try {
      final shareId = await ShareService.shareList(
        listName: widget.listName,
        items: widget.items,
      );
      final info = SharedListInfo(
        shareId: shareId,
        listName: widget.listName,
        itemCount: widget.items.length > ShareService.maxItems
            ? ShareService.maxItems
            : widget.items.length,
      );
      if (!mounted) return;
      setState(() {
        _existing = info;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${L10n.of(context)!.share_error}: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _unshare() async {
    if (_existing == null) return;
    final colorScheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.secondary,
        title: Text(L10n.of(ctx)!.share_unshare_confirm),
        actions: [
          _grayButton(
            ctx,
            label: L10n.of(ctx)!.cancel,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          _primaryButton(
            ctx,
            label: L10n.of(ctx)!.ok,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ShareService.unshare(_existing!.shareId);
      if (!mounted) return;
      setState(() {
        _existing = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${L10n.of(context)!.share_error}: $e')),
      );
    }
  }

  Future<void> _copyUrl() async {
    if (_existing == null) return;
    await Clipboard.setData(ClipboardData(text: _existing!.shareUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.of(context)!.share_copied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUrl() async {
    if (_existing == null) return;
    final uri = Uri.parse(_existing!.shareUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _grayButton(
    BuildContext ctx, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
        foregroundColor: WidgetStateProperty.all(Colors.black),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _primaryButton(
    BuildContext ctx, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(ctx).colorScheme;
    return TextButton(
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(colorScheme.primary),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.secondary,
      title: Text(l.share_title),
      content: SizedBox(
        width: 400,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _existing != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.share_description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: SelectableText(
                          _existing!.shareUrl,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _grayButton(
                              context,
                              label: l.share_copy,
                              onPressed: _copyUrl,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _grayButton(
                              context,
                              label: l.share_open_url,
                              onPressed: _openUrl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          onPressed: _unshare,
                          icon: const Icon(
                            Icons.link_off,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: Text(
                            l.share_unshare,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.share_description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.share_limit_notice,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
      ),
      actions: _loading
          ? null
          : _existing != null
              ? [
                  _grayButton(
                    context,
                    label: l.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                ]
              : [
                  _grayButton(
                    context,
                    label: l.cancel,
                    onPressed: () => Navigator.pop(context),
                  ),
                  _primaryButton(
                    context,
                    label: l.share_create_action,
                    onPressed: _createShare,
                  ),
                ],
    );
  }
}
