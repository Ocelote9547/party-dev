import 'package:flutter/material.dart';

import 'theme_notifier.dart';

class PartyColors {
  static bool get _isDark => themeNotifier.value != ThemeMode.light;

  static Color get background =>
      _isDark ? const Color(0xFF1A0A0A) : const Color(0xFFFFF3E0);
  static Color get backgroundLight =>
      _isDark ? const Color(0xFF2D1B0E) : const Color(0xFFFFE0B2);
  static Color get surface =>
      _isDark ? const Color(0xFF2D1B0E) : const Color(0xFFFFFFFF);
  static Color get surfaceLight =>
      _isDark ? const Color(0xFF3E2723) : const Color(0xFFFBE9E7);

  static const Color primary = Color(0xFFFF3D00);
  static const Color primaryLight = Color(0xFFFF6D00);
  static const Color primaryDark = Color(0xFFDD2C00);

  /// Text/icon color on primary buttons (always light for contrast on lava).
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color danger = Color(0xFFD50000);
  static const Color accentGreen = Color(0xFFFF9100);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF3E2723);
  static const Color love = Color(0xFFFF3D00);
  static const Color purple = Color(0xFFFF3D00);

  static Color get text =>
      _isDark ? const Color(0xFFFFCCBC) : const Color(0xFF3E2723);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFFFAB91) : const Color(0xFF4E342E);
  static Color get textMuted =>
      _isDark ? const Color(0xFFBCAAA4) : const Color(0xFF8D6E63);

  static Color get border =>
      _isDark ? const Color(0xFF4E342E) : const Color(0xFFFFCCBC);

  static Color get navBar =>
      _isDark ? const Color(0xF21A0A0A) : const Color(0xF2FFF3E0);

  static List<Color> get scaffoldGradient => _isDark
      ? const [
          Color(0xFF1A0A0A),
          Color(0xFF2D1B0E),
          Color(0xFF0F0A1E),
          Color(0xFF3E2723),
        ]
      : const [
          Color(0xFFFFF3E0),
          Color(0xFFFFE0B2),
          Color(0xFFFFCCBC),
          Color(0xFFFBE9E7),
        ];
}

class PartyTheme {
  // Fuente explícita para evitar fallback Noto missing en símbolos raros.
  static const String _fontFamily = 'Roboto';
  static const List<String> _fallback = ['Roboto', 'Noto Color Emoji', 'Segoe UI Emoji'];

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A0A0A),
      useMaterial3: true,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fallback,
      colorScheme: const ColorScheme.dark(
        primary: PartyColors.primary,
        secondary: PartyColors.primaryLight,
        surface: Color(0xFF2D1B0E),
        onPrimary: PartyColors.onPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFFFFCCBC),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFFFCCBC)),
        bodyMedium: TextStyle(color: Color(0xFFFFAB91)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PartyColors.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PartyColors.primary.withValues(alpha: 0.35);
          }
          return null;
        }),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF3E0),
      useMaterial3: true,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fallback,
      colorScheme: const ColorScheme.light(
        primary: PartyColors.primary,
        secondary: PartyColors.primaryDark,
        surface: Colors.white,
        onPrimary: PartyColors.onPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF3E2723),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF3E2723)),
        bodyMedium: TextStyle(color: Color(0xFF4E342E)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PartyColors.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PartyColors.primary.withValues(alpha: 0.35);
          }
          return null;
        }),
      ),
    );
  }
}
