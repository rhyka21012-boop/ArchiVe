import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

final themeColorProvider = StateNotifierProvider<ThemeColorNotifier, String>((
  ref,
) {
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

class ThemeColorNotifier extends StateNotifier<String> {
  ThemeColorNotifier() : super('オレンジ');

  Future<void> loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('color') ?? 'オレンジ';
  }

  Future<void> setColor(String newColor) async {
    final prefs = await SharedPreferences.getInstance();
    state = newColor;
    await prefs.setString('color', newColor);
  }
}

ThemeData getThemeData(String colorName, bool isDark) {
  final base = isDark ? ThemeData.dark() : ThemeData.light();
  Color primaryColor;
  switch (colorName) {
    case 'グリーン':
      primaryColor = Colors.lightGreen;
      break;
    case 'ブルー':
      primaryColor = Colors.lightBlue;
      break;
    case 'ホワイト':
      primaryColor = Colors.grey;
      break;
    case 'レッド':
      primaryColor = Colors.red;
      break;
    case 'オレンジ':
    default:
      primaryColor = Colors.orange[600]!;
      break;
  }

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(primary: primaryColor),
    primaryColor: primaryColor,
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
    ),
  );
}
