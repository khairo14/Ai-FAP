import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fundvanceai/core/theme/app_themes.dart';

/// Manages the user's selected app theme.
///
/// Source-of-truth priority:
///   1. Supabase `profiles.theme_id`  (syncs across devices)
///   2. SharedPreferences             (offline fallback / instant read)
///
/// On [setTheme]: SharedPreferences is written synchronously so the UI
/// responds immediately; Supabase is updated in the background.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_id';

  String _themeId = 'light';

  String get themeId => _themeId;
  ThemeData get themeData => AppThemes.themeFor(_themeId);
  ThemeMode get themeMode =>
      AppThemes.isDark(_themeId) ? ThemeMode.dark : ThemeMode.light;

  /// Load theme on startup.
  /// Tries Supabase first (so cross-device changes are picked up), then falls
  /// back to the locally-cached value from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try remote first
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('theme_id')
            .eq('id', uid)
            .maybeSingle();
        final remoteId = row?['theme_id'] as String?;
        if (remoteId != null && AppThemes.allThemeIds.contains(remoteId)) {
          _themeId = remoteId;
          // Keep local cache in sync
          await prefs.setString(_key, _themeId);
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Network error — fall through to local cache
    }

    // 2. Offline fallback
    _themeId = prefs.getString(_key) ?? 'light';
    notifyListeners();
  }

  /// Apply and persist a new theme by id.
  /// Writes to SharedPreferences synchronously, then syncs to Supabase in the
  /// background so the selection survives offline usage and new-device logins.
  Future<void> setTheme(String id) async {
    if (_themeId == id) return;
    _themeId = id;
    notifyListeners();

    // Local write first — instant, works offline
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);

    // Remote write in background — best-effort
    _syncThemeToSupabase(id).catchError((_) {});
  }

  Future<void> _syncThemeToSupabase(String id) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'theme_id': id}).eq('id', uid);
  }

  /// Whether the given theme id requires a premium subscription.
  static bool isPremiumTheme(String id) =>
      AppThemes.premiumThemeIds.contains(id);
}
