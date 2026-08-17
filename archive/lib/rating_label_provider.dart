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
