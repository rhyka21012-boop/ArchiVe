import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

enum ThemeColorType { orange, green, blue, white, red, yellow }

final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, ThemeColorType>((ref) {
      return ThemeColorNotifier();
    });

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
  ThemeColorNotifier() : super(ThemeColorType.orange);

  Future<void> loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('color');
    state = ThemeColorType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeColorType.orange,
    );
  }

  Future<void> setColor(ThemeColorType newColor) async {
    final prefs = await SharedPreferences.getInstance();
    state = newColor;
    await prefs.setString('color', newColor.name);
  }
}

ThemeData getThemeData(ThemeColorType type, bool isDark) {
  final primaryColor = switch (type) {
    ThemeColorType.green => Colors.lightGreen,
    ThemeColorType.blue => Colors.lightBlue,
    ThemeColorType.white => Colors.grey,
    ThemeColorType.red => Colors.red,
    ThemeColorType.yellow => Colors.yellow,
    ThemeColorType.orange => Colors.orange[600]!,
  };

  final colorScheme =
      isDark
          ? ColorScheme.dark(
            primary: primaryColor,
            onPrimary: Colors.white,
            surface: const Color(0xFF121212),
            secondary: const Color(0xFF2C2C2C),
          )
          : ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.black,
            surface: Colors.white,
            secondary: Colors.white,
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
    case ThemeColorType.orange:
    default:
      return l10n.settings_page_theme_color_orange;
  }
}
