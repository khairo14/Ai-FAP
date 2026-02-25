import 'package:flutter/material.dart';

/// All theme definitions for FundVance AI.
///
/// Free themes:   light, dark, cream
/// Premium themes: midnight, forest, rose
class AppThemes {
  AppThemes._();

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
    },
  );

  static const _appBarTheme = AppBarTheme(
    centerTitle: true,
    elevation: 0,
  );

  // ── Theme metadata ────────────────────────────────────────────────────────

  static const List<ThemeMeta> allThemes = [
    ThemeMeta(
      id: 'light',
      name: 'Light',
      isPremium: false,
      isDark: false,
      swatchColors: [Color(0xFF4ECDC4), Color(0xFFFFFFFF), Color(0xFF80CBC4)],
    ),
    ThemeMeta(
      id: 'dark',
      name: 'Dark',
      isPremium: false,
      isDark: true,
      swatchColors: [Color(0xFF4ECDC4), Color(0xFF121212), Color(0xFF1E1E1E)],
    ),
    ThemeMeta(
      id: 'cream',
      name: 'Cream',
      isPremium: false,
      isDark: false,
      swatchColors: [Color(0xFFC8956C), Color(0xFFFAF7F2), Color(0xFFE8D5B7)],
    ),
    ThemeMeta(
      id: 'midnight',
      name: 'Midnight',
      isPremium: true,
      isDark: true,
      swatchColors: [Color(0xFFC9A84C), Color(0xFF0D1B2A), Color(0xFF1B2A4A)],
    ),
    ThemeMeta(
      id: 'forest',
      name: 'Forest',
      isPremium: true,
      isDark: true,
      swatchColors: [Color(0xFF81C784), Color(0xFF1A2E1A), Color(0xFF2D4A2D)],
    ),
    ThemeMeta(
      id: 'rose',
      name: 'Rose',
      isPremium: true,
      isDark: false,
      swatchColors: [Color(0xFFD4637A), Color(0xFFFFF0F3), Color(0xFFECC5CE)],
    ),
  ];

  static List<String> get allThemeIds => allThemes.map((t) => t.id).toList();

  static List<String> get premiumThemeIds =>
      allThemes.where((t) => t.isPremium).map((t) => t.id).toList();

  static ThemeMeta metaFor(String id) =>
      allThemes.firstWhere((t) => t.id == id, orElse: () => allThemes.first);

  static bool isDark(String id) => metaFor(id).isDark;

  // ── ThemeData builders ────────────────────────────────────────────────────

  static ThemeData themeFor(String id) {
    switch (id) {
      case 'dark':
        return _dark();
      case 'cream':
        return _cream();
      case 'midnight':
        return _midnight();
      case 'forest':
        return _forest();
      case 'rose':
        return _rose();
      case 'light':
      default:
        return _light();
    }
  }

  // Light — current default
  static ThemeData _light() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4ECDC4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: _appBarTheme,
        pageTransitionsTheme: _pageTransitions,
      );

  // Dark — deep dark with teal accent
  static ThemeData _dark() => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4ECDC4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: _appBarTheme,
        pageTransitionsTheme: _pageTransitions,
      );

  // Cream — warm off-white, amber/terracotta tones
  static ThemeData _cream() {
    const seed = Color(0xFFC8956C);
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFAF7F2),
      surfaceContainerHighest: const Color(0xFFF0EAE0),
    );
    return ThemeData(
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFFAF7F2),
      useMaterial3: true,
      appBarTheme: _appBarTheme,
      pageTransitionsTheme: _pageTransitions,
    );
  }

  // Midnight (Premium) — deep navy + gold
  static ThemeData _midnight() {
    const seed = Color(0xFFC9A84C); // gold seed
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0D1B2A),
      surfaceContainerHighest: const Color(0xFF1B2A4A),
      primary: const Color(0xFFC9A84C),
      onPrimary: Colors.black,
    );
    return ThemeData(
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      useMaterial3: true,
      appBarTheme: _appBarTheme,
      pageTransitionsTheme: _pageTransitions,
    );
  }

  // Forest (Premium) — deep green + earthy
  static ThemeData _forest() {
    const seed = Color(0xFF2E7D32); // deep green
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1A2E1A),
      surfaceContainerHighest: const Color(0xFF2D4A2D),
    );
    return ThemeData(
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF1A2E1A),
      useMaterial3: true,
      appBarTheme: _appBarTheme,
      pageTransitionsTheme: _pageTransitions,
    );
  }

  // Rose (Premium) — blush + mauve
  static ThemeData _rose() {
    const seed = Color(0xFFD4637A); // blush rose
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFFF0F3),
      surfaceContainerHighest: const Color(0xFFFFDDE4),
    );
    return ThemeData(
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFFFF0F3),
      useMaterial3: true,
      appBarTheme: _appBarTheme,
      pageTransitionsTheme: _pageTransitions,
    );
  }
}

/// Metadata for a single theme option.
class ThemeMeta {
  final String id;
  final String name;
  final bool isPremium;
  final bool isDark;

  /// Three representative colors for the preview swatch:
  /// [0] = primary/accent, [1] = background/surface, [2] = container
  final List<Color> swatchColors;

  const ThemeMeta({
    required this.id,
    required this.name,
    required this.isPremium,
    required this.isDark,
    required this.swatchColors,
  });
}
