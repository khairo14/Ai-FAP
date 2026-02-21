import 'package:fundvanceai/core/config/supabase_config.dart';

/// Personalization engine for expense auto-categorization.
///
/// Learns from user corrections: when a user explicitly changes the
/// auto-suggested category for a merchant, the new mapping is stored in
/// [merchant_category_overrides] and applied on the next entry for that
/// merchant — improving accuracy over time without any ML model.
class PersonalizationService {
  static final PersonalizationService _instance =
      PersonalizationService._internal();
  factory PersonalizationService() => _instance;
  PersonalizationService._internal();

  final _supabase = SupabaseConfig.client;

  // ── In-memory cache so we don't re-query Supabase on every keystroke ─────
  final Map<String, String?> _cache = {}; // merchant_normalized → category_id

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Normalize a raw merchant string exactly as the DB stores it.
  static String normalizeMerchant(String raw) {
    if (raw.trim().isEmpty) return '';
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Look up a personalized category override for [merchant].
  ///
  /// Returns the category ID string if an override exists, otherwise null.
  /// Results are cached in memory for the session.
  Future<String?> getOverride(String merchant) async {
    final key = normalizeMerchant(merchant);
    if (key.isEmpty) return null;

    if (_cache.containsKey(key)) return _cache[key];

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final result = await _supabase
          .from('merchant_category_overrides')
          .select('category_id')
          .eq('user_id', userId)
          .eq('merchant_normalized', key)
          .maybeSingle();

      final categoryId = result?['category_id'] as String?;
      _cache[key] = categoryId;
      return categoryId;
    } catch (_) {
      return null;
    }
  }

  /// Save (or update) a user-defined override for [merchant] → [categoryId].
  ///
  /// Call this whenever the user manually changes the category for an expense
  /// that had a non-null merchant. The service uses an upsert so repeated
  /// corrections for the same merchant just update the row and bump use_count.
  Future<void> saveOverride(String merchant, String categoryId) async {
    final key = normalizeMerchant(merchant);
    if (key.isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Update cache immediately for snappy UX
    _cache[key] = categoryId;

    try {
      // Check if a row already exists
      final existing = await _supabase
          .from('merchant_category_overrides')
          .select('id, use_count')
          .eq('user_id', userId)
          .eq('merchant_normalized', key)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('merchant_category_overrides')
            .update({
              'category_id': categoryId,
              'use_count': (existing['use_count'] as int) + 1,
            })
            .eq('id', existing['id']);
      } else {
        await _supabase.from('merchant_category_overrides').insert({
          'user_id': userId,
          'merchant_normalized': key,
          'category_id': categoryId,
          'use_count': 1,
        });
      }
    } catch (_) {
      // Silently ignore — personalization is a best-effort feature
    }
  }

  /// Pre-warm the in-memory cache by fetching all overrides for the current user.
  ///
  /// Call this once at app start or when the user opens the expense form for
  /// the first time to avoid per-keystroke DB round-trips.
  Future<void> preload() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final rows = await _supabase
          .from('merchant_category_overrides')
          .select('merchant_normalized, category_id')
          .eq('user_id', userId);

      for (final row in (rows as List)) {
        _cache[row['merchant_normalized'] as String] =
            row['category_id'] as String?;
      }
    } catch (_) {}
  }

  /// Remove a specific override (e.g., user "resets" personalization for a merchant).
  Future<void> deleteOverride(String merchant) async {
    final key = normalizeMerchant(merchant);
    if (key.isEmpty) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _cache.remove(key);

    try {
      await _supabase
          .from('merchant_category_overrides')
          .delete()
          .eq('user_id', userId)
          .eq('merchant_normalized', key);
    } catch (_) {}
  }

  /// Clear the in-memory cache (e.g., on sign-out).
  void clearCache() => _cache.clear();
}
