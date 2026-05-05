import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'premium_detail.dart';
import 'l10n/app_localizations.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => AnalyticsPageState();
}

class AnalyticsPageState extends State<AnalyticsPage> {
  // ─── State ────────────────────────────────────────────────────
  Map<String, int> ratingCounts = {
    'critical': 0,
    'normal': 0,
    'maniac': 0,
    'unrated': 0,
  };
  Map<String, int> castCounts = {};
  Map<String, int> genreCounts = {};
  Map<String, int> seriesCounts = {};
  Map<String, int> labelCounts = {};
  Map<String, int> makerCounts = {};
  Map<String, int> listCounts = {};

  int totalWorks = 0;
  int totalViewCount = 0;
  List<Map<String, dynamic>> recentItems = [];

  bool _isPremium = false;
  bool _debugBypassPremium = false;

  Map<String, int> viewingCountByRating = {
    'critical': 0,
    'normal': 0,
    'maniac': 0,
    'unrated': 0,
  };
  Map<String, String> urlToTitleMap = {};
  Map<String, String> urlToImageMap = {};
  List<MapEntry<String, int>> top5Viewings = [];

  // ─── カラー定数 ────────────────────────────────────────────────
  static const _ratingColors = <String, Color>{
    'critical': Color(0xFFE53935),
    'normal': Color(0xFFFFD600),
    'maniac': Color(0xFF8E24AA),
    'unrated': Color(0xFF9E9E9E),
  };

  Color _topColor(int index) {
    const palette = [
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFFF44336),
    ];
    return palette[index % palette.length];
  }

  // ─── Init ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadAll();
    _checkSubscriptionStatus();
  }

  void _loadAll() {
    _loadSharedPrefStats();
    _loadViewingCountByRating();
    _loadTop5ViewingStats();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isActive =
          customerInfo.entitlements.all["Premium Plan"]?.isActive ?? false;
      setState(() => _isPremium = isActive);
    } catch (e) {
      debugPrint("Error fetching subscription status: $e");
    }
  }

  Future<void> _loadSharedPrefStats() async {
    ratingCounts = {'critical': 0, 'normal': 0, 'maniac': 0, 'unrated': 0};
    castCounts.clear();
    genreCounts.clear();
    seriesCounts.clear();
    labelCounts.clear();
    makerCounts.clear();
    listCounts.clear();

    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_metadata') ?? [];

    final tempRecent = <Map<String, dynamic>>[];

    for (final item in savedList) {
      final map = jsonDecode(item) as Map<String, dynamic>;

      // 評価
      final rating = map['rating'];
      final validRating =
          ['critical', 'normal', 'maniac'].contains(rating)
              ? rating as String
              : 'unrated';
      ratingCounts[validRating] = (ratingCounts[validRating] ?? 0) + 1;

      // '#' 区切りフィールドを集計するヘルパー
      void countField(String? raw, Map<String, int> target) {
        if (raw == null || raw.trim().isEmpty) return;
        for (final name
            in raw.split('#').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
          target[name] = (target[name] ?? 0) + 1;
        }
      }

      countField(map['cast']?.toString(), castCounts);
      countField(map['genre']?.toString(), genreCounts);
      countField(map['series']?.toString(), seriesCounts);
      countField(map['maker']?.toString(), makerCounts);
      countField(map['label']?.toString(), labelCounts);

      final listName = map['listName']?.toString().trim();
      if (listName != null && listName.isNotEmpty) {
        listCounts[listName] = (listCounts[listName] ?? 0) + 1;
      }

      tempRecent.add(map);
    }

    setState(() {
      totalWorks = savedList.length;
      recentItems = tempRecent.reversed.toList();
    });
  }

  Future<void> _loadViewingCountByRating() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_metadata') ?? [];
    final Map<String, int> tempMap = {
      'critical': 0,
      'normal': 0,
      'maniac': 0,
      'unrated': 0,
    };

    for (final item in savedList) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final url = map['url']?.toString();
      if (url == null || url.isEmpty) continue;
      final rating = (map['rating'] ?? 'unrated').toString().toLowerCase();
      final validRating =
          ['critical', 'normal', 'maniac'].contains(rating)
              ? rating
              : 'unrated';
      final count = prefs.getInt(url) ?? 0;
      tempMap[validRating] = tempMap[validRating]! + count;
    }

    setState(() => viewingCountByRating = tempMap);
  }

  Future<void> _loadTop5ViewingStats() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final viewCounts = <String, int>{};
    int total = 0;

    for (final key in allKeys) {
      final raw = prefs.get(key);
      if (raw is int && raw > 0 && key.startsWith('http')) {
        viewCounts[key] = raw;
        total += raw;
      }
    }

    final savedList = prefs.getStringList('saved_metadata') ?? [];
    for (final item in savedList) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      final url = map['url']?.toString();
      final title = map['title']?.toString();
      final image = map['image']?.toString();
      if (url != null && title != null) {
        urlToTitleMap[url] = title;
        if (image != null) urlToImageMap[url] = image;
      }
    }

    final sorted =
        viewCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      top5Viewings = sorted.take(5).toList();
      totalViewCount = total;
    });
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context)!.analytics),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: Icon(
                _debugBypassPremium ? Icons.lock_open : Icons.lock,
                color: _debugBypassPremium ? Colors.green : null,
              ),
              tooltip: 'Debug: Premium toggle',
              onPressed: () => setState(() => _debugBypassPremium = !_debugBypassPremium),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _buildSummarySection(),
              _buildTop5ViewSection(),
              _buildRatingSection(),
              if (listCounts.isNotEmpty) _buildListCountSection(),
              _buildTagSection(
                title: L10n.of(context)!.analytics_page_cast,
                icon: Icons.person,
                data: castCounts,
                accentColor: const Color(0xFF2196F3),
              ),
              _buildTagSection(
                title: L10n.of(context)!.analytics_page_genre,
                icon: Icons.category,
                data: genreCounts,
                accentColor: const Color(0xFF4CAF50),
              ),
              _buildTagSection(
                title: L10n.of(context)!.analytics_page_series,
                icon: Icons.movie_filter,
                data: seriesCounts,
                accentColor: const Color(0xFFFF9800),
              ),
              _buildTagSection(
                title: L10n.of(context)!.analytics_page_maker,
                icon: Icons.business,
                data: makerCounts,
                accentColor: const Color(0xFF9C27B0),
              ),
              _buildTagSection(
                title: L10n.of(context)!.analytics_page_label,
                icon: Icons.label,
                data: labelCounts,
                accentColor: const Color(0xFFF44336),
              ),
            ],
          ),
          if (!_isPremium && !_debugBypassPremium) ...[
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black26),
            ),
            Center(child: _buildPremiumDialog()),
          ],
        ],
      ),
    );
  }

  // ─── Section wrapper ────────────────────────────────────────────
  Widget _section({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Widget child,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  accentColor.withValues(alpha: isDark ? 0.05 : 0.02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // ─── KPI Card ───────────────────────────────────────────────────
  Widget _kpiCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        elevation: 0,
        color: colorScheme.brightness == Brightness.dark ? Colors.grey.shade800 : colorScheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.55)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Ranked progress row ────────────────────────────────────────
  Widget _rankedRow(
    int rank,
    String name,
    int count,
    int total,
    Color barColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = total > 0 ? count / total : 0.0;
    const badgeColors = [
      Color(0xFFFFD700),
      Color(0xFFB0BEC5),
      Color(0xFFCD7F32),
    ];
    final badgeBg =
        rank <= 3 ? badgeColors[rank - 1] : colorScheme.surfaceContainerHighest;
    final badgeFg = rank <= 3 ? Colors.white : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, color: badgeBg),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeFg,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      L10n.of(context)!.analytics_page_ranked_row_stat((percent * 100).toStringAsFixed(1), count),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(barColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary section ────────────────────────────────────────────
  Widget _buildSummarySection() {
    final ratedCount = totalWorks - (ratingCounts['unrated'] ?? 0);
    final ratingRate =
        totalWorks > 0
            ? '${(ratedCount / totalWorks * 100).toStringAsFixed(0)}%'
            : '-%';

    return _section(
      icon: Icons.inventory_2,
      title: L10n.of(context)!.analytics_page_summary,
      accentColor: const Color(0xFF2196F3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _kpiCard(
                L10n.of(context)!.analytics_page_kpi_saved_count,
                '$totalWorks',
                Icons.video_library,
                const Color(0xFF2196F3),
              ),
              _kpiCard(
                L10n.of(context)!.analytics_page_kpi_total_view_count,
                '$totalViewCount',
                Icons.play_circle,
                const Color(0xFF4CAF50),
              ),
              _kpiCard(
                L10n.of(context)!.analytics_page_kpi_rating_rate,
                ratingRate,
                Icons.star,
                const Color(0xFFFF9800),
              ),
            ],
          ),
          if (top5Viewings.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildMostWatchedCard(),
          ],
          const SizedBox(height: 20),
          Text(
            L10n.of(context)!.analytics_page_recent_additions,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _buildRecentList(),
        ],
      ),
    );
  }

  Widget _buildMostWatchedCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final top = top5Viewings.first;
    final url = top.key;
    final count = top.value;
    final title = urlToTitleMap[url] ?? L10n.of(context)!.analytics_page_no_title;
    final imageUrl = urlToImageMap[url];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withValues(alpha: 0.15),
            const Color(0xFF2196F3).withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                imageUrl != null
                    ? Image.network(
                      imageUrl,
                      width: 56,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 56),
                    )
                    : const Icon(Icons.image_not_supported, size: 56),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      L10n.of(context)!.analytics_page_most_watched,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  L10n.of(context)!.analytics_page_view_times(count),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList() {
    final top3 = recentItems.take(3).toList();
    if (top3.isEmpty) {
      return Center(child: Text(L10n.of(context)!.analytics_page_no_data));
    }

    return Column(
      children:
          top3.map((item) {
            final title = item['title'] ?? '';
            final image = item['image'];
            final rating = item['rating']?.toString();
            final ratingColor = _ratingColors[rating];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        image != null
                            ? Image.network(
                              image,
                              width: 48,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 48),
                            )
                            : const Icon(Icons.image_not_supported, size: 48),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (ratingColor != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ratingColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _ratingLabel(rating),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ratingColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _ratingLabel(String? rating) {
    switch (rating) {
      case 'critical':
        return L10n.of(context)!.critical;
      case 'normal':
        return L10n.of(context)!.normal;
      case 'maniac':
        return L10n.of(context)!.maniac;
      default:
        return L10n.of(context)!.unrated;
    }
  }

  // ─── Top5 view count section ────────────────────────────────────
  Widget _buildTop5ViewSection() {
    return _section(
      icon: Icons.bar_chart,
      title: L10n.of(context)!.analytics_page_view_count_top5,
      subtitle: L10n.of(context)!.analytics_page_total_view_subtitle(totalViewCount),
      accentColor: const Color(0xFF4CAF50),
      child: SizedBox(
        height: 300,
        child:
            top5Viewings.isEmpty
                ? Center(child: Text(L10n.of(context)!.analytics_page_no_data))
                : BarChart(_top5BarChartData()),
      ),
    );
  }

  BarChartData _top5BarChartData() {
    final colorScheme = Theme.of(context).colorScheme;
    final maxY =
        top5Viewings
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() +
        1;

    const barShades = [
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
      Color(0xFF43A047),
      Color(0xFF66BB6A),
      Color(0xFF81C784),
    ];

    return BarChartData(
      maxY: maxY,
      barGroups: List.generate(top5Viewings.length, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: top5Viewings[i].value.toDouble(),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  barShades[i % barShades.length],
                  barShades[i % barShades.length].withValues(alpha: 0.5),
                ],
              ),
              width: 32,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        );
      }),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 80,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index < 0 || index >= top5Viewings.length) {
                return const SizedBox();
              }
              final url = top5Viewings[index].key;
              final imageUrl = urlToImageMap[url];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child:
                        imageUrl != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                    ),
                              ),
                            )
                            : const Icon(
                              Icons.image_not_supported,
                              size: 40,
                            ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 60,
                    child: Text(
                      _shortenTitle(
                        urlToTitleMap[url] ??
                            L10n.of(context)!.analytics_page_no_title,
                      ),
                      style: const TextStyle(fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, _) {
              if (value == 0) {
                return Text(
                  L10n.of(context)!.analytics_page_count,
                  style: const TextStyle(fontSize: 11),
                );
              }
              return Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY / 5).ceilToDouble(),
        getDrawingHorizontalLine:
            (value) => FlLine(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.black87,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              L10n.of(context)!.analytics_page_toolchip_count(
                rod.toY.toInt(),
              ),
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Rating section ────────────────────────────────────────────
  Widget _buildRatingSection() {
    final total = ratingCounts.values.fold(0, (a, b) => a + b);
    final ratedCount = total - (ratingCounts['unrated'] ?? 0);

    return _section(
      icon: Icons.star,
      title: L10n.of(context)!.analytics_page_evaluation,
      subtitle: L10n.of(context)!.analytics_page_rated_subtitle(ratedCount, total),
      accentColor: const Color(0xFFFF9800),
      child:
          total == 0
              ? Center(child: Text(L10n.of(context)!.analytics_page_no_data))
              : Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildRatingDonut(total)),
                  const SizedBox(height: 28),
                  _buildRatingLegend(total),
                  const SizedBox(height: 20),
                  _buildViewingByRatingRows(),
                ],
              ),
    );
  }

  Widget _buildRatingDonut(int total) {
    final colorScheme = Theme.of(context).colorScheme;
    final sections =
        ratingCounts.entries.where((e) => e.value > 0).map((entry) {
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '',
            color: _ratingColors[entry.key],
            radius: 72,
          );
        }).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: 52,
            sectionsSpace: 2,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$total',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              L10n.of(context)!.analytics_page_unit_items,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingLegend(int total) {
    const keys = ['critical', 'normal', 'maniac', 'unrated'];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children:
          keys.map((key) {
            final count = ratingCounts[key] ?? 0;
            if (count == 0) return const SizedBox.shrink();
            final percent =
                total > 0
                    ? (count / total * 100).toStringAsFixed(1)
                    : '0.0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ratingColors[key],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_ratingLabel(key)}  $count件 ($percent%)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildViewingByRatingRows() {
    final colorScheme = Theme.of(context).colorScheme;
    final total = viewingCountByRating.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    const keys = ['critical', 'normal', 'maniac', 'unrated'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context)!.analytics_page_view_count_by_rating,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        ...keys.map((key) {
          final count = viewingCountByRating[key] ?? 0;
          final percent = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ratingColors[key],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 74,
                  child: Text(
                    _ratingLabel(key),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(_ratingColors[key]!),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  L10n.of(context)!.analytics_page_times_unit(count),
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.65)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── List count section (新規) ──────────────────────────────────
  Widget _buildListCountSection() {
    final total = listCounts.values.fold(0, (a, b) => a + b);
    final sorted =
        listCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return _section(
      icon: Icons.folder,
      title: L10n.of(context)!.analytics_page_saved_by_list,
      subtitle: L10n.of(context)!.analytics_page_list_count_subtitle(listCounts.length),
      accentColor: const Color(0xFF00BCD4),
      child: Column(
        children: List.generate(
          top5.length,
          (i) => _rankedRow(
            i + 1,
            top5[i].key,
            top5[i].value,
            total,
            const Color(0xFF00BCD4),
          ),
        ),
      ),
    );
  }

  // ─── Tag sections（出演/ジャンル/シリーズ/メーカー/レーベル）──────
  Widget _buildTagSection({
    required String title,
    required IconData icon,
    required Map<String, int> data,
    required Color accentColor,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.values.fold(0, (a, b) => a + b);
    final sorted =
        data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return _section(
      icon: icon,
      title: title,
      subtitle: L10n.of(context)!.analytics_page_type_count_subtitle(data.length),
      accentColor: accentColor,
      child: Column(
        children: List.generate(
          top5.length,
          (i) => _rankedRow(
            i + 1,
            top5[i].key,
            top5[i].value,
            total,
            _topColor(i),
          ),
        ),
      ),
    );
  }

  // ─── Premium dialog ────────────────────────────────────────────
  Widget _buildPremiumDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.of(context)!.analytics_page_premium_title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB8860B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              L10n.of(context)!.analytics_page_premium_description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              style: ButtonStyle(
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(
                  colorScheme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              icon: const Icon(Icons.star, color: Color(0xFFB8860B)),
              label: Text(
                L10n.of(context)!.analytics_page_premium_button,
                style: const TextStyle(
                  color: Color(0xFFB8860B),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              onPressed: () async {
                if (!await PremiumGate.ensurePremium(context)) return;
                setState(() => _isPremium = true);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _shortenTitle(String title, {int maxLength = 7}) {
    return title.length <= maxLength
        ? title
        : '${title.substring(0, maxLength)}...';
  }
}
