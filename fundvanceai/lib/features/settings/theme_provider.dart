import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fundvanceai/core/theme/app_themes.dart';

/// Manages the user's selected app theme, persisted in SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_id';

  String _themeId = 'light';

  String get themeId => _themeId;
  ThemeData get themeData => AppThemes.themeFor(_themeId);
  ThemeMode get themeMode =>
      AppThemes.isDark(_themeId) ? ThemeMode.dark : ThemeMode.light;

  /// Load persisted theme on startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = prefs.getString(_key) ?? 'light';
    notifyListeners();
  }

  /// Apply and persist a new theme by id.
  Future<void> setTheme(String id) async {
    if (_themeId == id) return;
    _themeId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }

  /// Whether the given theme id requires a premium subscription.
  static bool isPremiumTheme(String id) =>
      AppThemes.premiumThemeIds.contains(id);
}
