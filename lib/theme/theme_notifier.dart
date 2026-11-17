import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'party_theme_mode';

final ThemeController themeController = ThemeController();

/// Prefer [themeController]; kept for compatibility with [PartyColors].
ValueNotifier<ThemeMode> get themeNotifier => themeController;

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.dark);

  bool get isDark => value == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    if (stored == 'light') {
      value = ThemeMode.light;
    } else if (stored == 'dark') {
      value = ThemeMode.dark;
    }
  }

  Future<void> setDark(bool dark) async {
    value = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, dark ? 'dark' : 'light');
  }

  Future<void> toggle() => setDark(!isDark);
}
