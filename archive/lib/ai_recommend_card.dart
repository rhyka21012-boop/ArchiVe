import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';
import 'l10n/app_localizations.dart';
import 'subscription_prompt_dialog.dart';

/// AI おすすめキーワード カード。
/// ブラウザタブのホーム画面等、任意の場所に配置可能。
/// タップ時は [onOpenKeyword] にキーワード文字列を渡す (呼び出し側で
/// Google 検索 / WebView 遷移など好きな挙動を実装できる)。
class AiRecommendCard extends ConsumerStatefulWidget {
  final ValueChanged<String> onOpenKeyword;
  const AiRecommendCard({super.key, required this.onOpenKeyword});

  @override
  ConsumerState<AiRecommendCard> createState() => _AiRecommendCardState();
}

class _AiRecommendCardState extends ConsumerState<AiRecommendCard> {
  bool _isPro = false;
  bool _isLoading = false;
  List<RecommendedKeyword> _recommendations = [];
  String? _error;
  List<Map<String, dynamic>> _savedItems = [];

  @override
  void initState() {
    super.initState();
    _checkProStatus();
    _loadSavedMetadata();
  }

  Future<void> _checkProStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final isPro = info.entitlements.all['Pro Plan']?.isActive ?? false;
      if (!mounted) return;
      setState(() => _isPro = isPro);
    } catch (_) {}
  }

  Future<void> _loadSavedMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_metadata') ?? [];
    if (!mounted) return;
    setState(() {
      _savedItems =
          data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  _LibraryAggregation _aggregateLibrary() {
    final genreCount = <String, int>{};
    final castCount = <String, int>{};
    final makerCount = <String, int>{};
    final seriesCount = <String, int>{};
    final labelCount = <String, int>{};

    void count(String? raw, Map<String, int> target) {
      if (raw == null || raw.trim().isEmpty) return;
      for (final part in raw
          .split(RegExp(r'\s*#\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)) {
        target[part] = (target[part] ?? 0) + 1;
      }
    }

    for (final item in _savedItems) {
      count(item['genre']?.toString(), genreCount);
      count(item['cast']?.toString(), castCount);
      count(item['maker']?.toString(), makerCount);
      count(item['series']?.toString(), seriesCount);
      count(item['label']?.toString(), labelCount);
    }

    List<String> sortedKeys(Map<String, int> m, int limit) {
      final list = m.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return list.take(limit).map((e) => e.key).toList();
    }

    final recentTitles = _savedItems.reversed
        .take(5)
        .map((e) => (e['title'] ?? '').toString())
        .where((t) => t.isNotEmpty)
        .toList();

    return _LibraryAggregation(
      itemCount: _savedItems.length,
      topGenres: sortedKeys(genreCount, 10),
      topCasts: sortedKeys(castCount, 10),
      topMakers: sortedKeys(makerCount, 10),
      topSeries: sortedKeys(seriesCount, 10),
      topLabels: sortedKeys(labelCount, 10),
      recentTitles: recentTitles,
    );
  }

  Future<void> _generate() async {
    if (_isLoading) return;
    if (!_isPro) {
      final bought = await promptAndOpenPurchase(
        context: context,
        tier: SubscriptionTier.pro,
        featureLabel: L10n.of(context)!.purchase_feature_ai_recommend,
        imageAsset: 'assets/subscription/ai_recommend.png',
        icon: Icons.auto_awesome,
      );
      if (!bought) return;
      if (!mounted) return;
      setState(() => _isPro = true);
    }

    final l = L10n.of(context)!;
    // ライブラリ読み直し (直近保存を確実に反映)
    await _loadSavedMetadata();
    final agg = _aggregateLibrary();
    if (agg.itemCount == 0) {
      setState(() => _error = l.search_page_ai_recommend_empty);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AiService.recommendKeywords(
        topGenres: agg.topGenres,
        topCasts: agg.topCasts,
        topMakers: agg.topMakers,
        topSeries: agg.topSeries,
        topLabels: agg.topLabels,
        recentTitles: agg.recentTitles,
        itemCount: agg.itemCount,
        locale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() {
        _recommendations = result;
        if (result.isEmpty) _error = l.search_page_ai_recommend_empty;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.search_page_ai_recommend_error}: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPro) return _buildLockedCard();
    return _buildProCard();
  }

  Widget _buildLockedCard() {
    final l = L10n.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    const tealDeep = Color(0xFF00695C);
    const tealMid = Color(0xFF00897B);

    return InkWell(
      onTap: _generate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A1A)
              : tealDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tealMid.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: tealMid),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l.search_page_ai_recommend_title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: tealMid.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: tealMid),
                            const SizedBox(width: 3),
                            Text(
                              l.pro_locked_badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tealMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.search_page_ai_recommend_subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProCard() {
    final l = L10n.of(context)!;
    const tealDeep = Color(0xFF00695C);
    const tealLight = Color(0xFF26A69A);
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [tealDeep, tealLight, tealDeep],
      stops: [0.0, 0.5, 1.0],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: tealLight.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.search_page_ai_recommend_title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l.search_page_ai_recommend_subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (_recommendations.isNotEmpty && !_isLoading)
                IconButton(
                  tooltip: l.search_page_ai_recommend_refresh,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _generate,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l.search_page_ai_recommend_loading,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            )
          else if (_recommendations.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  _recommendations.map((kw) => _buildChip(kw, tealDeep)).toList(),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error ?? l.search_page_ai_recommend_intro,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: tealDeep,
                    ),
                    label: Text(
                      l.search_page_ai_recommend_generate,
                      style: const TextStyle(
                        color: tealDeep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChip(RecommendedKeyword kw, Color tealDeep) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (kw.keyword.isEmpty) return;
            widget.onOpenKeyword(kw.keyword);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: tealDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kw.keyword,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tealDeep,
                        ),
                      ),
                      if (kw.reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          kw.reason,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: tealDeep),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryAggregation {
  final int itemCount;
  final List<String> topGenres;
  final List<String> topCasts;
  final List<String> topMakers;
  final List<String> topSeries;
  final List<String> topLabels;
  final List<String> recentTitles;

  _LibraryAggregation({
    required this.itemCount,
    required this.topGenres,
    required this.topCasts,
    required this.topMakers,
    required this.topSeries,
    required this.topLabels,
    required this.recentTitles,
  });
}
