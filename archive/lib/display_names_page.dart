import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'rating_label_provider.dart';

/// 3 つの評価名と 5 つのタグ名を 1 画面で付け替える設定画面。
///
/// 評価名は list_page のカード長押しからも変更できるが、タグ名の導線が
/// 無かったため、両方をここに集約する。保存先は既存の
/// [ratingLabelsProvider] / [tagLabelsProvider] と同じなので、
/// どちらの導線から変えても同じ値を見る。
class DisplayNamesPage extends ConsumerStatefulWidget {
  const DisplayNamesPage({super.key});

  @override
  ConsumerState<DisplayNamesPage> createState() => _DisplayNamesPageState();
}

/// 評価 1 件分の見た目と対応する保存キー
class _RatingField {
  final String rating;
  final String iconPath;
  final Color color;

  const _RatingField(this.rating, this.iconPath, this.color);
}

class _DisplayNamesPageState extends ConsumerState<DisplayNamesPage> {
  /// 並び順は list_page の評価カードと同じ (クリティカル → ノーマル → マニアック)
  static const List<_RatingField> _ratings = [
    _RatingField(
        kRatingCritical, 'assets/icons/critical.png', Color(0xFFC62828)),
    _RatingField(kRatingNormal, 'assets/icons/normal.png', Color(0xFFF5A623)),
    _RatingField(kRatingManiac, 'assets/icons/maniac.png', Color(0xFF7B1FA2)),
  ];

  final Map<String, TextEditingController> _ratingControllers = {};
  final Map<String, TextEditingController> _tagControllers = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    for (final field in _ratings) {
      _ratingControllers[field.rating] = TextEditingController();
    }
    for (final category in kTagCategories) {
      _tagControllers[category] = TextEditingController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // 保存済みのカスタム名だけを入れる。
    // 既定名を入れてしまうと「空欄なら既定に戻す」の判定ができなくなり、
    // 言語を切り替えても前の言語の名前が固定されてしまう。
    final ratingLabels = ref.read(ratingLabelsProvider);
    _ratingControllers[kRatingCritical]!.text = ratingLabels.critical ?? '';
    _ratingControllers[kRatingNormal]!.text = ratingLabels.normal ?? '';
    _ratingControllers[kRatingManiac]!.text = ratingLabels.maniac ?? '';
    final tagLabels = ref.read(tagLabelsProvider);
    for (final category in kTagCategories) {
      _tagControllers[category]!.text = tagLabels[category] ?? '';
    }
  }

  @override
  void dispose() {
    for (final controller in _ratingControllers.values) {
      controller.dispose();
    }
    for (final controller in _tagControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 未設定時に表示する既定のタグ名。
  /// 詳細画面の短い表記に合わせる (最も目にする表記のため)。
  String _defaultTagName(String category) {
    final l = L10n.of(context)!;
    switch (category) {
      case kTagCast:
        return l.detail_page_cast_short;
      case kTagGenre:
        return l.detail_page_genre_short;
      case kTagSeries:
        return l.detail_page_series_short;
      case kTagMaker:
        return l.detail_page_maker_short;
      case kTagLabel:
        return l.detail_page_label_short;
      default:
        return '';
    }
  }

  String _defaultRatingName(String rating) {
    final l = L10n.of(context)!;
    switch (rating) {
      case kRatingCritical:
        return l.critical;
      case kRatingNormal:
        return l.normal;
      case kRatingManiac:
        return l.maniac;
      default:
        return '';
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final saved = L10n.of(context)!.settings_page_display_names_saved;

    // 空欄は null として渡す。notifier 側が prefs から削除し、既定名に戻る。
    for (final field in _ratings) {
      await ref
          .read(ratingLabelsProvider.notifier)
          .setLabel(field.rating, _ratingControllers[field.rating]!.text);
    }
    for (final category in kTagCategories) {
      await ref
          .read(tagLabelsProvider.notifier)
          .setLabel(category, _tagControllers[category]!.text);
    }

    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(saved)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings_page_display_names)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            l.settings_page_display_names_desc,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _ratings.length; i++) ...[
            _field(
              label: l.settings_page_rating_name_n(i + 1),
              controller: _ratingControllers[_ratings[i].rating]!,
              hint: _defaultRatingName(_ratings[i].rating),
              leading: Image.asset(
                _ratings[i].iconPath,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              accent: _ratings[i].color,
            ),
            const SizedBox(height: 16),
          ],
          for (var i = 0; i < kTagCategories.length; i++) ...[
            _field(
              label: l.settings_page_tag_name_n(i + 1),
              controller: _tagControllers[kTagCategories[i]]!,
              hint: _defaultTagName(kTagCategories[i]),
              leading: Icon(Icons.sell_outlined, size: 24, color: cs.primary),
              accent: cs.primary,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _save,
              child: Text(l.save, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  /// 1 項目分の入力行。
  /// hint に既定名を出すので、空欄のまま保存すると何に戻るかが分かる。
  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Widget leading,
    required Color accent,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(width: 32, child: Center(child: leading)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.38),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: cs.onSurface.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
