import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tax_preset.dart';

/// Service for tax presets and user default tax rates
class TaxSettingsService {
  final _supabase = Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  // ─── Tax Presets ───────────────────────────────────────────────────────────

  /// Get all active tax presets, optionally filtered by country code
  Future<List<TaxPreset>> getPresets({String? countryCode}) async {
    try {
      var query = _supabase.from('tax_presets').select().eq('is_active', true);
      if (countryCode != null) {
        query = query.eq('country_code', countryCode);
      }
      final response = await query.order('country_code').order('tax_name');
      return (response as List)
          .map((json) => TaxPreset.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tax presets: $e');
    }
  }

  // ─── User Default Tax Rates ────────────────────────────────────────────────

  /// Get all of the current user's active default tax rates
  Future<List<UserDefaultTaxRate>> getUserDefaults() async {
    try {
      final response = await _supabase
          .from('default_tax_rates')
          .select('*, income_categories(name)')
          .eq('user_id', _userId)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) =>
              UserDefaultTaxRate.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load default tax rates: $e');
    }
  }

  /// Save a tax preset as a user default rate.
  /// [categoryId] null = applies to all categories.
  Future<UserDefaultTaxRate> savePresetAsDefault({
    required TaxPreset preset,
    String? categoryId,
    bool setAsDefault = true,
  }) async {
    try {
      final response = await _supabase
          .from('default_tax_rates')
          .insert({
            'user_id': _userId,
            'income_category_id': categoryId,
            'tax_type': preset.taxType,
            'tax_percentage': preset.taxPercentage,
            'tax_fixed_amount': preset.taxFixedAmount,
            'currency': preset.currency,
            'tax_name': preset.taxName,
            'description': preset.description,
            'is_mandatory': preset.isMandatory,
            'is_default_for_category': setAsDefault,
            'apply_automatically': true,
            'minimum_income_threshold': preset.minimumIncomeThreshold,
            'maximum_tax_cap': preset.maximumTaxCap,
            'tax_authority': preset.taxAuthority,
          })
          .select('*, income_categories(name)')
          .single();

      return UserDefaultTaxRate.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to save default tax rate: $e');
    }
  }

  /// Soft-delete a user default tax rate
  Future<void> deleteDefault(String id) async {
    try {
      await _supabase
          .from('default_tax_rates')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'is_active': false,
          })
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (e) {
      throw Exception('Failed to delete default tax rate: $e');
    }
  }

  /// Get the active default tax rate for a specific income category (if any)
  Future<UserDefaultTaxRate?> getDefaultForCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('default_tax_rates')
          .select('*, income_categories(name)')
          .eq('user_id', _userId)
          .eq('income_category_id', categoryId)
          .eq('is_active', true)
          .eq('is_default_for_category', true)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return UserDefaultTaxRate.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
