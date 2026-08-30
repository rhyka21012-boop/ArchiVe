import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import 'circle_app_bar_icon.dart';
import 'theme_provider.dart';

/// 開発者向け: サーバの user_activity 集計を閲覧する画面。
/// 呼び出しは Cloud Function `getActivityStats` を経由し、admin uid のみ許可。
class DevStatsPage extends StatefulWidget {
  const DevStatsPage({super.key});

  @override
  State<DevStatsPage> createState() => _DevStatsPageState();
}

class _DevStatsPageState extends State<DevStatsPage> {
  bool _loading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
      final result = await functions
          .httpsCallable('getActivityStats')
          .call<Map<dynamic, dynamic>>({});
      if (!mounted) return;
      setState(() {
        _stats = Map<String, dynamic>.from(result.data);
        _loading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${e.code}: ${e.message}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bg = isDark ? colorScheme.surface : kHomeSurfaceLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '開発者統計',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: CircleAppBarIcon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          CircleAppBarIcon(
            icon: Icons.refresh,
            tooltip: 'Reload',
            onPressed: _load,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[400], size: 48),
                        const SizedBox(height: 12),
                        Text('取得に失敗しました\n$_error',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : _buildContent(colorScheme, isDark),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, bool isDark) {
    final s = _stats!;
    final planBreak = Map<String, dynamic>.from(s['planBreakdown'] ?? {});
    final platBreak = Map<String, dynamic>.from(s['platformBreakdown'] ?? {});
    final topSavers =
        (s['topSavers'] as List? ?? []).cast<Map<dynamic, dynamic>>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '生成時刻: ${s['generatedAt']}',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 16),
        _row([
          _kpi('総ユーザー', '${s['totalUsers']}', isDark),
          _kpi('DAU', '${s['dau']}', isDark),
          _kpi('WAU', '${s['wau']}', isDark),
          _kpi('MAU', '${s['mau']}', isDark),
        ]),
        const SizedBox(height: 12),
        _row([
          _kpi('総保存', '${s['totalSaves']}', isDark),
          _kpi('総起動', '${s['totalLaunches']}', isDark),
          _kpi('AI回数', '${s['totalAiSuggests']}', isDark),
          _kpi('平均保存', '${s['avgSavesPerUser']}', isDark),
        ]),
        const SizedBox(height: 20),
        _section('プラン内訳', isDark, [
          _kv('Free', '${planBreak['free'] ?? 0}'),
          _kv('Premium', '${planBreak['premium'] ?? 0}'),
          _kv('Pro', '${planBreak['pro'] ?? 0}'),
        ]),
        const SizedBox(height: 12),
        _section('プラットフォーム内訳', isDark, [
          _kv('iOS', '${platBreak['ios'] ?? 0}'),
          _kv('Android', '${platBreak['android'] ?? 0}'),
          _kv('その他', '${platBreak['other'] ?? 0}'),
        ]),
        const SizedBox(height: 12),
        _section(
          'TOP 20 保存数',
          isDark,
          topSavers
              .map((row) => _kv(
                    '${row['uid']} (${row['plan'] ?? 'free'})',
                    '${row['saveCount']}',
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _row(List<Widget> children) => Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      );

  Widget _kpi(String label, String value, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, height: 1.1)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                )),
          ],
        ),
      );

  Widget _section(String title, bool isDark, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(k,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
