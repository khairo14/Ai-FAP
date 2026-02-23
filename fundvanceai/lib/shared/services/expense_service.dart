import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/core/constants/app_constants.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/shared/models/category.dart';
import 'local_database.dart';
import 'connectivity_service.dart';

/// Service for managing expenses with Supabase
class ExpenseService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();
  bool get _isOnline => ConnectivityService.instance.isOnline;

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

  /// Get all expenses for current user (excluding deleted)
  Future<List<Expense>> getExpenses({
    int limit = 50,
    int offset = 0,
    String? categoryId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // --- Online path ---
    if (_isOnline) {
      try {
        var query = _supabase
            .from(AppConstants.expensesTable)
            .select('''
            *,
            expense_categories(name, icon, color),
            accounts(name, currency)
          ''')
            .eq('user_id', _currentUserId)
            .filter('deleted_at', 'is', null);

        if (categoryId != null) query = query.eq('category_id', categoryId);
        if (accountId != null) query = query.eq('account_id', accountId);
        if (startDate != null) query = query.gte('date', startDate.toIso8601String().split('T')[0]);
        if (endDate != null) query = query.lte('date', endDate.toIso8601String().split('T')[0]);

        final response = await query
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final expenses = (response as List)
            .map((json) => Expense.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache the fresh results (no filter = full cache)
        if (categoryId == null && accountId == null && startDate == null && endDate == null) {
          await LocalDatabase.instance.upsertRows(
            table: 'expenses',
            userId: _currentUserId,
            rows: (response as List).cast<Map<String, dynamic>>(),
            idGetter: (r) => r['id'] as String,
          );
        }

        return expenses;
      } catch (e) {
        // Fall through to cache
      }
    }

    // --- Offline / fallback path ---
    final cached = await LocalDatabase.instance.getRows(
      table: 'expenses',
      userId: _currentUserId,
    );
    return cached.map((j) => Expense.fromJson(j)).toList();
  }

  /// Get single expense by ID (only non-deleted)
  Future<Expense?> getExpense(String id) async {
    try {
      final response = await _supabase
          .from(AppConstants.expensesTable)
          .select()
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      if (response == null) return null;
      return Expense.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new expense
  Future<Expense> createExpense({
    required double amount,
    required DateTime date,
    String? categoryId,
    String? accountId,
    String? merchant,
    String? description,
    String? paymentMethod,
    String? notes,
    bool isRecurring = false,
    String? recurringFrequency,
  }) async {
    final now = DateTime.now();
    final data = {
      'id': _uuid.v4(),
      'user_id': _currentUserId,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'category_id': categoryId,
      'account_id': accountId,
      'merchant': merchant,
      'description': description,
      'payment_method': paymentMethod,
      'notes': notes,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    if (_isOnline) {
      try {
        final response = await _supabase
            .from(AppConstants.expensesTable)
            .insert(data)
            .select()
            .single();
        final expense = Expense.fromJson(response);
        // Cache the created expense
        await LocalDatabase.instance.upsertRow(
          table: 'expenses',
          id: expense.id,
          userId: _currentUserId,
          payload: response,
        );
        return expense;
      } catch (e) {
        // Fall through to offline path
      }
    }

    // Offline: store locally + enqueue
    await LocalDatabase.instance.upsertRow(
      table: 'expenses',
      id: data['id'] as String,
      userId: _currentUserId,
      payload: data,
    );
    await LocalDatabase.instance.enqueuePendingOp(
      operation: 'INSERT',
      tableName: AppConstants.expensesTable,
      recordId: data['id'] as String,
      payload: data,
    );
    return Expense.fromJson(data);
  }

  /// Update existing expense
  Future<Expense> updateExpense({
    required String id,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? accountId,
    String? merchant,
    String? description,
    String? paymentMethod,
    String? notes,
    bool? isRecurring,
    String? recurringFrequency,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (amount != null) data['amount'] = amount;
    if (date != null) data['date'] = date.toIso8601String().split('T')[0];
    if (categoryId != null) data['category_id'] = categoryId;
    if (accountId != null) data['account_id'] = accountId;
    if (merchant != null) data['merchant'] = merchant;
    if (description != null) data['description'] = description;
    if (paymentMethod != null) data['payment_method'] = paymentMethod;
    if (notes != null) data['notes'] = notes;
    if (isRecurring != null) data['is_recurring'] = isRecurring;
    data['recurring_frequency'] = recurringFrequency;

    if (_isOnline) {
      try {
        final response = await _supabase
            .from(AppConstants.expensesTable)
            .update(data)
            .eq('id', id)
            .eq('user_id', _supabase.auth.currentUser!.id)
            .select()
            .single();
        final expense = Expense.fromJson(response);
        await LocalDatabase.instance.upsertRow(
          table: 'expenses',
          id: id,
          userId: _currentUserId,
          payload: response,
        );
        return expense;
      } catch (e) {
        // Fall through to offline path
      }
    }

    // Offline: patch local cache row + enqueue
    final cached = await LocalDatabase.instance.getRow(
      table: 'expenses', id: id, userId: _currentUserId);
    final merged = {...?cached, ...data, 'id': id};
    await LocalDatabase.instance.upsertRow(
      table: 'expenses', id: id, userId: _currentUserId, payload: merged);
    await LocalDatabase.instance.enqueuePendingOp(
      operation: 'UPDATE',
      tableName: AppConstants.expensesTable,
      recordId: id,
      payload: data,
    );
    return Expense.fromJson(merged);
  }

  /// Soft delete expense (move to trash)
  Future<void> deleteExpense(String id) async {
    final deletedAt = DateTime.now().toIso8601String();
    if (_isOnline) {
      try {
        await _supabase
            .from(AppConstants.expensesTable)
            .update({'deleted_at': deletedAt})
            .eq('id', id)
            .eq('user_id', _supabase.auth.currentUser!.id);
        await LocalDatabase.instance.deleteRow(
          table: 'expenses', id: id, userId: _currentUserId);
        return;
      } catch (e) {
        // Fall through
      }
    }
    // Offline: remove from cache + enqueue soft-delete
    await LocalDatabase.instance.deleteRow(
      table: 'expenses', id: id, userId: _currentUserId);
    await LocalDatabase.instance.enqueuePendingOp(
      operation: 'DELETE',
      tableName: AppConstants.expensesTable,
      recordId: id,
      payload: {'deleted_at': deletedAt},
    );
  }

  /// Get deleted expenses (trash)
  Future<List<Expense>> getDeletedExpenses() async {
    try {
      final response = await _supabase
          .from(AppConstants.expensesTable)
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);

      return (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Restore expense from trash
  Future<void> restoreExpense(String id) async {
    try {
      await _supabase
          .from(AppConstants.expensesTable)
          .update({'deleted_at': null})
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently delete expense
  Future<void> permanentlyDeleteExpense(String id) async {
    try {
      await _supabase
          .from(AppConstants.expensesTable)
          .delete()
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Auto-cleanup: Permanently delete expenses older than 30 days in trash
  Future<int> autoCleanupOldDeleted() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final response = await _supabase
          .from(AppConstants.expensesTable)
          .delete()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .not('deleted_at', 'is', null)
          .lte('deleted_at', thirtyDaysAgo.toIso8601String())
          .select();

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all expense categories (default + user custom)
  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .select()
          .or('user_id.is.null,user_id.eq.${_supabase.auth.currentUser!.id}')
          .or('category_type.eq.expense,category_type.eq.both')
          .order('is_default', ascending: false)
          .order('name');

      final categories = (response as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      // Remove duplicates by ID (in case database has duplicates)
      final seen = <String>{};
      return categories.where((category) {
        if (seen.contains(category.id)) {
          return false;
        }
        seen.add(category.id);
        return true;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get expense statistics (excluding deleted)
  Future<Map<String, dynamic>> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from(AppConstants.expensesTable)
          .select('amount, accounts(currency)')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .filter('deleted_at', 'is', null);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query;
      final expenses = response as List;

      if (expenses.isEmpty) {
        return {'count': 0, 'byCurrency': {}};
      }

      // Group expenses by currency
      final Map<String, double> byCurrency = {};
      
      for (final expense in expenses) {
        final amount = (expense['amount'] as num).toDouble();
        final currency = expense['accounts']?['currency'] ?? 'USD';
        
        byCurrency[currency] = (byCurrency[currency] ?? 0.0) + amount;
      }

      return {
        'count': expenses.length,
        'byCurrency': byCurrency,
      };
    } catch (e) {
      return {'count': 0, 'byCurrency': {}};
    }
  }
}
