import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// AI関連のCloud Function呼び出しラッパー
class AiService {
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'asia-northeast1',
  );

  /// URL + タイトルから AI でタグ候補（ジャンル、出演者、シリーズ、レーベル、制作者）を取得
  /// 失敗時は空のSuggestedTagsを返す
  static Future<SuggestedTags> suggestTags({
    required String url,
    required String title,
  }) async {
    if (url.isEmpty && title.isEmpty) return SuggestedTags.empty();

    final user = FirebaseAuth.instance.currentUser;
    debugPrint('AI call: user=${user?.uid}, email=${user?.email}');
    if (user != null) {
      try {
        final token = await user.getIdToken(true); // force refresh
        debugPrint('AI call: token length=${token?.length}');
      } catch (e) {
        debugPrint('AI call: token refresh error: $e');
      }
    }

    try {
      final callable = _functions.httpsCallable('suggestTags');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'url': url,
        'title': title,
      });
      return SuggestedTags.fromMap(Map<String, dynamic>.from(result.data));
    } on FirebaseFunctionsException catch (e) {
      debugPrint('suggestTags FunctionsException: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('suggestTags error: $e');
      rethrow;
    }
  }

  /// 今月のアーカイブ活動をまとめた AI レポートを取得
  /// [force] が true なら 24h キャッシュを無視して再生成
  static Future<MonthlyReport> getMonthlyReport({bool force = false}) async {
    try {
      final callable = _functions.httpsCallable('generateMonthlyReport');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'force': force,
      });
      return MonthlyReport.fromMap(Map<String, dynamic>.from(result.data));
    } on FirebaseFunctionsException catch (e) {
      debugPrint('getMonthlyReport FunctionsException: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('getMonthlyReport error: $e');
      rethrow;
    }
  }

  /// ライブラリ全体の傾向から、次に検索すべき関連キーワードを AI に提案させる
  static Future<List<RecommendedKeyword>> recommendKeywords({
    required List<String> topGenres,
    required List<String> topCasts,
    required List<String> topMakers,
    required List<String> topSeries,
    required List<String> topLabels,
    required List<String> recentTitles,
    required int itemCount,
    String locale = 'ja',
  }) async {
    try {
      final callable = _functions.httpsCallable('recommendKeywords');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'topGenres': topGenres,
        'topCasts': topCasts,
        'topMakers': topMakers,
        'topSeries': topSeries,
        'topLabels': topLabels,
        'recentTitles': recentTitles,
        'itemCount': itemCount,
        'locale': locale,
      });
      final raw = result.data['keywords'];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((m) => RecommendedKeyword.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('recommendKeywords FunctionsException: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('recommendKeywords error: $e');
      rethrow;
    }
  }
}

/// AI が提案する検索キーワード
class RecommendedKeyword {
  final String keyword;
  final String reason;

  RecommendedKeyword({required this.keyword, required this.reason});

  factory RecommendedKeyword.fromMap(Map<String, dynamic> map) =>
      RecommendedKeyword(
        keyword: map['keyword'] as String? ?? '',
        reason: map['reason'] as String? ?? '',
      );
}

/// AI月次レポート
class MonthlyReport {
  final String report;
  final int itemCount;
  final bool cached;
  final int year;
  final int month;

  MonthlyReport({
    required this.report,
    required this.itemCount,
    required this.cached,
    required this.year,
    required this.month,
  });

  factory MonthlyReport.fromMap(Map<String, dynamic> map) => MonthlyReport(
        report: map['report'] as String? ?? '',
        itemCount: (map['itemCount'] as num?)?.toInt() ?? 0,
        cached: map['cached'] as bool? ?? false,
        year: (map['year'] as num?)?.toInt() ?? 0,
        month: (map['month'] as num?)?.toInt() ?? 0,
      );
}

/// AI が返したタグ候補
class SuggestedTags {
  final List<String> genre;
  final List<String> cast;
  final List<String> series;
  final List<String> label;
  final List<String> maker;

  SuggestedTags({
    required this.genre,
    required this.cast,
    required this.series,
    required this.label,
    required this.maker,
  });

  factory SuggestedTags.empty() => SuggestedTags(
        genre: const [],
        cast: const [],
        series: const [],
        label: const [],
        maker: const [],
      );

  factory SuggestedTags.fromMap(Map<String, dynamic> map) {
    List<String> parse(dynamic v) {
      if (v is! List) return [];
      return v.whereType<String>().toList();
    }

    return SuggestedTags(
      genre: parse(map['genre']),
      cast: parse(map['cast']),
      series: parse(map['series']),
      label: parse(map['label']),
      maker: parse(map['maker']),
    );
  }

  bool get isEmpty =>
      genre.isEmpty &&
      cast.isEmpty &&
      series.isEmpty &&
      label.isEmpty &&
      maker.isEmpty;
}
