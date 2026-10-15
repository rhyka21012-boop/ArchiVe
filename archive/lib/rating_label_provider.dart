import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

const String kRatingCritical = 'critical';
const String kRatingNormal = 'normal';
const String kRatingManiac = 'maniac';

class RatingLabels {
  final String? critical;
  final String? normal;
  final String? maniac;

  const RatingLabels({this.critical, this.normal, this.maniac});
}

class RatingLabelsNotifier extends StateNotifier<RatingLabels> {
  RatingLabelsNotifier() : super(const RatingLabels());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = RatingLabels(
      critical: prefs.getString('rating_label_critical'),
      normal: prefs.getString('rating_label_normal'),
      maniac: prefs.getString('rating_label_maniac'),
    );
  }

  Future<void> setLabel(String rating, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name?.trim();
    final effective = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    final prefsKey = 'rating_label_$rating';
    if (effective == null) {
      await prefs.remove(prefsKey);
    } else {
      await prefs.setString(prefsKey, effective);
    }
    switch (rating) {
      case kRatingCritical:
        state = RatingLabels(
          critical: effective,
          normal: state.normal,
          maniac: state.maniac,
        );
        break;
      case kRatingNormal:
        state = RatingLabels(
          critical: state.critical,
          normal: effective,
          maniac: state.maniac,
        );
        break;
      case kRatingManiac:
        state = RatingLabels(
          critical: state.critical,
          normal: state.normal,
          maniac: effective,
        );
        break;
    }
  }
}

final ratingLabelsProvider =
    StateNotifierProvider<RatingLabelsNotifier, RatingLabels>((ref) {
  return RatingLabelsNotifier();
});

/// カスタム名が設定されていればそれを返し、なければ L10n の既定を返す
String ratingLabelOf(
  BuildContext context,
  RatingLabels labels,
  String rating,
) {
  switch (rating) {
    case kRatingCritical:
      return labels.critical ?? L10n.of(context)!.critical;
    case kRatingNormal:
      return labels.normal ?? L10n.of(context)!.normal;
    case kRatingManiac:
      return labels.maniac ?? L10n.of(context)!.maniac;
    default:
      return '';
  }
}

// ===== タグ名 (出演・ジャンル・シリーズ・メーカー・レーベル) =====

const String kTagCast = 'cast';
const String kTagGenre = 'genre';
const String kTagSeries = 'series';
const String kTagMaker = 'maker';
const String kTagLabel = 'label';

/// 並び順は入力画面・設定画面の表示順と合わせる
const List<String> kTagCategories = [
  kTagCast,
  kTagGenre,
  kTagSeries,
  kTagMaker,
  kTagLabel,
];

/// 利用者が付け替えたタグ名。未設定のカテゴリは保持しない。
class TagLabels {
  final Map<String, String> byCategory;

  const TagLabels(this.byCategory);

  String? operator [](String category) => byCategory[category];
}

class TagLabelsNotifier extends StateNotifier<TagLabels> {
  TagLabelsNotifier() : super(const TagLabels({}));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, String>{};
    for (final category in kTagCategories) {
      final value = prefs.getString('tag_label_$category');
      if (value != null && value.isNotEmpty) map[category] = value;
    }
    state = TagLabels(map);
  }

  Future<void> setLabel(String category, String? name) async {
    if (!kTagCategories.contains(category)) return;
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name?.trim();
    final effective = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    final prefsKey = 'tag_label_$category';
    if (effective == null) {
      await prefs.remove(prefsKey);
    } else {
      await prefs.setString(prefsKey, effective);
    }
    final next = Map<String, String>.from(state.byCategory);
    if (effective == null) {
      next.remove(category);
    } else {
      next[category] = effective;
    }
    state = TagLabels(next);
  }
}

final tagLabelsProvider =
    StateNotifierProvider<TagLabelsNotifier, TagLabels>((ref) {
  return TagLabelsNotifier();
});

/// カスタム名があればそれを返し、無ければ [fallback] を返す。
///
/// 既定値を引数で受けるのは、同じタグでも画面ごとに別の訳語が割り当てられて
/// いるため (例: ドイツ語の maker は詳細画面が "Hersteller"、検索/分析画面が
/// "Produzent")。どちらか一方に寄せると、名前を変えていない利用者の表示まで
/// 変わってしまう。
String tagLabelOr(TagLabels labels, String category, String fallback) =>
    labels[category] ?? fallback;
