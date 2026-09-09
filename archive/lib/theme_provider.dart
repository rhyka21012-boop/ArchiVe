import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

/// ホーム画面などライトモードで使用する暖かみのある下地色
const Color kHomeSurfaceLight = Color(0xFFF5F3EE);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

enum ThemeColorType {
  orange,
  green,
  blue,
  white,
  red,
  yellow,
  pink,
  purple,
  gold, // Premium UI色
  teal, // Pro 限定
  random, // 起動毎に無料枠からランダム
}

/// [random] 選択時に使う候補: 無料枠のカラー
const List<ThemeColorType> _randomPool = [
  ThemeColorType.orange,
  ThemeColorType.green,
  ThemeColorType.blue,
  ThemeColorType.white,
  ThemeColorType.red,
  ThemeColorType.yellow,
  ThemeColorType.pink,
  ThemeColorType.purple,
];

/// Pro 限定のテーマカラー判定
bool isProOnlyThemeColor(ThemeColorType type) {
  return type == ThemeColorType.teal;
}

/// Premium 限定のテーマカラー判定（gold）
bool isPremiumOnlyThemeColor(ThemeColorType type) {
  return type == ThemeColorType.gold;
}

final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, ThemeColorType>((ref) {
      return ThemeColorNotifier(ref);
    });

/// ユーザーが実際に選択した値 (random 時も random のまま)。
/// 設定画面のドロップダウン表示等に使用。
final themeColorSavedProvider =
    StateNotifierProvider<_ThemeColorSavedNotifier, ThemeColorType>((ref) {
  return _ThemeColorSavedNotifier();
});

class _ThemeColorSavedNotifier extends StateNotifier<ThemeColorType> {
  _ThemeColorSavedNotifier() : super(ThemeColorType.orange);
  void set(ThemeColorType v) => state = v;
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> updateTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

class ThemeColorNotifier extends StateNotifier<ThemeColorType> {
  final Ref ref;
  ThemeColorNotifier(this.ref) : super(ThemeColorType.orange);

  Future<void> loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('color');
    final saved = ThemeColorType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeColorType.orange,
    );
    ref.read(themeColorSavedProvider.notifier).set(saved);
    if (saved == ThemeColorType.random) {
      state = _pickRandom();
    } else {
      state = saved;
    }
  }

  Future<void> setColor(ThemeColorType newColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color', newColor.name);
    ref.read(themeColorSavedProvider.notifier).set(newColor);
    if (newColor == ThemeColorType.random) {
      state = _pickRandom();
    } else {
      state = newColor;
    }
  }

  ThemeColorType _pickRandom() {
    final r = Random();
    return _randomPool[r.nextInt(_randomPool.length)];
  }
}

/// 各テーマカラーの実色を返す
Color themeColorSwatch(ThemeColorType type) {
  return switch (type) {
    ThemeColorType.green => Colors.lightGreen,
    ThemeColorType.blue => Colors.lightBlue,
    ThemeColorType.white => Colors.grey,
    ThemeColorType.red => Colors.red,
    ThemeColorType.yellow => Colors.yellow[700]!,
    ThemeColorType.orange => Colors.orange[600]!,
    ThemeColorType.pink => Colors.pink[300]!,
    ThemeColorType.purple => Colors.deepPurple[300]!,
    ThemeColorType.gold => const Color(0xFFB8860B),
    ThemeColorType.teal => Colors.teal[400]!,
    // ランダム選択時のプレビュー用色 (ThemeData 生成には使われない — state 側で実色が入る)
    ThemeColorType.random => Colors.orange[600]!,
  };
}

ThemeData getThemeData(ThemeColorType type, bool isDark) {
  final primaryColor = themeColorSwatch(type);

  final colorScheme =
      isDark
          ? ColorScheme.dark(
            primary: primaryColor, //テーマカラー
            onPrimary: Colors.white, //文字やアイコン
            surface: const Color(0xFF121212), //カードなどの色
            secondary: const Color(0xFF2C2C2C), //背景色
          )
          : ColorScheme.light(
            primary: primaryColor, //テーマカラー
            onPrimary: Colors.black, //文字やアイコン
            surface: Colors.white, //カードなどの色
            secondary: Colors.white, //背景色
          );

  return ThemeData(
    fontFamily: 'NotoSansJP',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
    ),
  );
}

String themeColorLabel(BuildContext context, ThemeColorType type) {
  final l10n = L10n.of(context)!;
  switch (type) {
    case ThemeColorType.green:
      return l10n.settings_page_theme_color_green;
    case ThemeColorType.blue:
      return l10n.settings_page_theme_color_blue;
    case ThemeColorType.white:
      return l10n.settings_page_theme_color_white;
    case ThemeColorType.red:
      return l10n.settings_page_theme_color_red;
    case ThemeColorType.yellow:
      return l10n.settings_page_theme_color_yellow;
    case ThemeColorType.pink:
      return l10n.settings_page_theme_color_pink;
    case ThemeColorType.purple:
      return l10n.settings_page_theme_color_purple;
    case ThemeColorType.gold:
      return l10n.settings_page_theme_color_gold;
    case ThemeColorType.teal:
      return l10n.settings_page_theme_color_teal;
    case ThemeColorType.random:
      return l10n.settings_page_theme_color_random;
    case ThemeColorType.orange:
    default:
      return l10n.settings_page_theme_color_orange;
  }
}
