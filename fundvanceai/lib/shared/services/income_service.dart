import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/core/constants/app_constants.dart';
import '../models/income.dart';
import 'local_database.dart';
import 'connectivity_service.dart';

/// Service for managing income with Supabase
class IncomeService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();
  bool get _isOnline => ConnectivityService.instance.isOnline;

  static bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('errno = 7') ||
        msg.contains('no address associated') ||
        msg.contains('authretryable') ||
        msg.contains('clientexception');
  }

  /// Get current user or throw auth error
  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please login again.');
    }
    return user.id;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Joins a list of raw income row maps with locally-cached income_categories
  /// so that [Income.fromJson] can resolve [categoryName] when offline.
  Future<List<Map<String, dynamic>>> _enrichWithCategories(
      List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return rows;
    final catRows = await LocalDatabase.instance.getRows(
      table: 'income_categories',
      userId: '_system_',
    );
    final catMap = {for (final c in catRows) c['id'] as String: c};
    return rows.map((row) {
      final catId = row['category_id'] as String?;
      if (catId != null && catMap.containsKey(catId)) {
        final cat = catMap[catId]!;
        return <String, dynamic>{
          ...row,
          'income_categories': {
            'name': cat['name'],
            'icon': cat['icon'],
            'color': cat['color'],
          },
        };
      }
      return row;
    }).toList();
  }

  /// Get all income for current user (excluding deleted)
  Future<List<Income>> getIncome({
    int limit = 50,
    int offset = 0,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_isOnline) {
      try {
        var query = _supabase
            .from(AppConstants.incomeTable)
            .select('*, income_categories(name, icon, color), accounts(name)')
            .eq('user_id', _currentUserId)
            .filter('deleted_at', 'is', null);

        if (categoryId != null) query = query.eq('category_id', categoryId);
        if (startDate != null) {
          query = query.gte(
              'income_date', startDate.toIso8601String().split('T')[0]);
        }
        if (endDate != null) {
          query =
              query.lte('income_date', endDate.toIso8601String().split('T')[0]);
        }

        final response = await query
            .order('income_date', ascending: false)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final incomes = (response as List)
            .map((json) => Income.fromJson(json as Map<String, dynamic>))
            .toList();

        if (categoryId == null && startDate == null && endDate == null) {
          await LocalDatabase.instance.upsertRows(
            table: 'income_records',
            userId: _currentUserId,
            rows: (response as List).cast<Map<String, dynamic>>(),
            idGetter: (r) => r['id'] as String,
          );
        }
        return incomes;
      } catch (_) {}
    }

    final cached = await LocalDatabase.instance
        .getRows(table: 'income_records', userId: _currentUserId);
    final enriched = await _enrichWithCategories(cached);
    return enriched.map((j) => Income.fromJson(j)).toList();
  }

  /// Get single income by ID
  Future<Income?> getIncomeById(String id) async {
    try {
      final response = await _supabase
          .from(AppConstants.incomeTable)
          .select('*, income_categories(name, icon, color), accounts(name)')
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      if (response == null) return null;
      return Income.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new income
  Future<Income> createIncome({
    required double amount,
    required String currency,
    required String categoryId,
    required DateTime incomeDate,
    String? description,
    String? taxType,
    double? taxPercentage,
    double? taxFixedAmount,
    bool isRecurring = false,
    String? recurrencePattern,
    String? accountId,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();

    double taxCalculated = 0;
    if (taxType != null) {
      if (taxType == 'percentage' && taxPercentage != null) {
        taxCalculated = amount * (taxPercentage / 100);
      } else if (taxType == 'fixed' && taxFixedAmount != null) {
        taxCalculated = taxFixedAmount;
      } else if (taxType == 'hybrid' &&
          taxPercentage != null &&
          taxFixedAmount != null) {
        taxCalculated = (amount * (taxPercentage / 100)) + taxFixedAmount;
      }
    }
    final netAmount = amount - taxCalculated;

    final data = <String, dynamic>{
      'id': _uuid.v4(),
      'user_id': _currentUserId,
      'amount': amount,
      'currency': currency,
      'category_id': categoryId,
      'income_date': incomeDate.toIso8601String().split('T')[0],
      'description': description,
      'tax_type': taxType,
      'tax_percentage': taxPercentage,
      'tax_fixed_amount': taxFixedAmount,
      'tax_calculated': taxCalculated,
      'net_amount': netAmount,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'account_id': accountId,
      'tags': tags,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    if (_isOnline) {
      try {
        final response = await _supabase
            .from(AppConstants.incomeTable)
            .insert(data)
            .select('*, income_categories(name, icon, color), accounts(name)')
            .single();
        await LocalDatabase.instance.upsertRow(
          table: 'income_records',
          id: response['id'] as String,
          userId: _currentUserId,
          payload: response,
        );
        return Income.fromJson(response);
      } catch (_) {}
    }

    // Offline path
    await LocalDatabase.instance.upsertRow(
      table: 'income_records',
      id: data['id'] as String,
      userId: _currentUserId,
      payload: data,
    );
    await LocalDatabase.instance.enqueuePendingOp(
      operation: 'INSERT',
      tableName: AppConstants.incomeTable,
      recordId: data['id'] as String,
      payload: data,
    );
    // Enrich with cached category name so UI shows the correct label immediately
    final enriched = await _enrichWithCategories([data]);
    return Income.fromJson(enriched.first);
  }

  /// Update existing income
  Future<Income> updateIncome({
    required String id,
    double? amount,
    String? currency,
    String? categoryId,
    DateTime? incomeDate,
    String? description,
    String? taxType,
    double? taxPercentage,
    double? taxFixedAmount,
    bool? isRecurring,
    String? recurrencePattern,
    String? accountId,
    List<String>? tags,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (amount != null) data['amount'] = amount;
      if (currency != null) data['currency'] = currency;
      if (categoryId != null) data['category_id'] = categoryId;
      if (incomeDate != null) {
        data['income_date'] = incomeDate.toIso8601String().split('T')[0];
      }
      if (description != null) data['description'] = description;
      if (taxType != null) data['tax_type'] = taxType;
      if (taxPercentage != null) data['tax_percentage'] = taxPercentage;
      if (taxFixedAmount != null) data['tax_fixed_amount'] = taxFixedAmount;
      if (isRecurring != null) data['is_recurring'] = isRecurring;
      if (recurrencePattern != null) {
        data['recurrence_pattern'] = recurrencePattern;
      }
      if (accountId != null) data['account_id'] = accountId;
      if (tags != null) data['tags'] = tags;

      // Recalculate tax and net if amount or tax parameters changed
      if (amount != null ||
          taxType != null ||
          taxPercentage != null ||
          taxFixedAmount != null) {
        final currentIncome = await getIncomeById(id);
        if (currentIncome != null) {
          final finalAmount = amount ?? currentIncome.amount;
          final finalTaxType = taxType ?? currentIncome.taxType;
          final finalTaxPercentage =
              taxPercentage ?? currentIncome.taxPercentage;
          final finalTaxFixedAmount =
              taxFixedAmount ?? currentIncome.taxFixedAmount;

          double taxCalculated = 0;
          if (finalTaxType != null) {
            if (finalTaxType == 'percentage' && finalTaxPercentage != null) {
              taxCalculated = finalAmount * (finalTaxPercentage / 100);
            } else if (finalTaxType == 'fixed' && finalTaxFixedAmount != null) {
              taxCalculated = finalTaxFixedAmount;
            } else if (finalTaxType == 'hybrid' &&
                finalTaxPercentage != null &&
                finalTaxFixedAmount != null) {
              taxCalculated = (finalAmount * (finalTaxPercentage / 100)) +
                  finalTaxFixedAmount;
            }
          }

          data['tax_calculated'] = taxCalculated;
          data['net_amount'] = finalAmount - taxCalculated;
        }
      }

      final response = await _supabase
          .from(AppConstants.incomeTable)
          .update(data)
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .select('*, income_categories(name, icon, color), accounts(name)')
          .single();

      return Income.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Soft delete income
  Future<void> deleteIncome(String id) async {
    final deletedAt = DateTime.now().toIso8601String();
    if (_isOnline) {
      try {
        await _supabase
            .from(AppConstants.incomeTable)
            .update({'deleted_at': deletedAt})
            .eq('id', id)
            .eq('user_id', _currentUserId);
        await LocalDatabase.instance
            .deleteRow(table: 'income_records', id: id, userId: _currentUserId);
        return;
      } catch (_) {}
    }
    await LocalDatabase.instance
        .deleteRow(table: 'income_records', id: id, userId: _currentUserId);
    await LocalDatabase.instance.enqueuePendingOp(
      operation: 'DELETE',
      tableName: AppConstants.incomeTable,
      recordId: id,
      payload: {'deleted_at': deletedAt},
    );
  }

  /// Permanently delete income
  Future<void> permanentlyDeleteIncome(String id) async {
    try {
      await _supabase
          .from(AppConstants.incomeTable)
          .delete()
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (e) {
      rethrow;
    }
  }

  /// Restore soft-deleted income
  Future<Income> restoreIncome(String id) async {
    try {
      final response = await _supabase
          .from(AppConstants.incomeTable)
          .update({
            'deleted_at': null,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .select('*, income_categories(name, icon, color), accounts(name)')
          .single();

      return Income.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get deleted income (trash)
  Future<List<Income>> getDeletedIncome() async {
    try {
      final response = await _supabase
          .from(AppConstants.incomeTable)
          .select('*, income_categories(name, icon, color), accounts(name)')
          .eq('user_id', _currentUserId)
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);

      return (response as List)
          .map((json) => Income.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get income categories
  Future<List<IncomeCategory>> getIncomeCategories() async {
    // Income categories are system-wide — cache under a sentinel key.
    const cacheKey = '_system_';

    if (_isOnline) {
      try {
        final response = await _supabase
            .from(AppConstants.incomeCategoriesTable)
            .select()
            .eq('is_active', true)
            .filter('deleted_at', 'is', null)
            .order('name');

        final rows = (response as List).cast<Map<String, dynamic>>();

        // Cache for offline use
        await LocalDatabase.instance.upsertRows(
          table: 'income_categories',
          userId: cacheKey,
          rows: rows,
          idGetter: (r) => r['id'] as String,
        );

        return rows.map((j) => IncomeCategory.fromJson(j)).toList();
      } catch (e) {
        if (!_isNetworkError(e)) rethrow;
        // Fall through to cache
      }
    }

    // Offline or network error — serve from local cache
    final cached = await LocalDatabase.instance.getRows(
      table: 'income_categories',
      userId: cacheKey,
    );
    return cached.map((j) => IncomeCategory.fromJson(j)).toList();
  }

  /// Get income statistics
  Future<Map<String, dynamic>> getIncomeStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final response = await _supabase
          .from(AppConstants.incomeTable)
          .select('amount, net_amount, tax_calculated, currency')
          .eq('user_id', _currentUserId)
          .filter('deleted_at', 'is', null)
          .gte('income_date', start.toIso8601String().split('T')[0])
          .lte('income_date', end.toIso8601String().split('T')[0]);

      final incomeList = response as List;

      double totalGrossIncome = 0;
      double totalNetIncome = 0;
      double totalTax = 0;
      final incomeByCurrency = <String, Map<String, double>>{};

      for (final income in incomeList) {
        final amount = (income['amount'] as num).toDouble();
        final netAmount = (income['net_amount'] as num).toDouble();
        final tax = (income['tax_calculated'] as num?)?.toDouble() ?? 0;
        final currency = income['currency'] as String? ?? 'USD';

        totalGrossIncome += amount;
        totalNetIncome += netAmount;
        totalTax += tax;

        if (!incomeByCurrency.containsKey(currency)) {
          incomeByCurrency[currency] = {
            'gross': 0,
            'net': 0,
            'tax': 0,
          };
        }

        incomeByCurrency[currency]!['gross'] =
            (incomeByCurrency[currency]!['gross'] ?? 0) + amount;
        incomeByCurrency[currency]!['net'] =
            (incomeByCurrency[currency]!['net'] ?? 0) + netAmount;
        incomeByCurrency[currency]!['tax'] =
            (incomeByCurrency[currency]!['tax'] ?? 0) + tax;
      }

      return {
        'totalGrossIncome': totalGrossIncome,
        'totalNetIncome': totalNetIncome,
        'totalTax': totalTax,
        'incomeCount': incomeList.length,
        'incomeByCurrency': incomeByCurrency,
        'startDate': start,
        'endDate': end,
      };
    } catch (e) {
      rethrow;
    }
  }
}
