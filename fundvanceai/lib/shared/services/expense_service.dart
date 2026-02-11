import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/core/constants/app_constants.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/shared/models/category.dart';

/// Service for managing expenses with Supabase
class ExpenseService {
  final SupabaseClient _supabase = SupabaseConfig.client;

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
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from(AppConstants.expensesTable)
          .select()
          .eq('user_id', _currentUserId)
          .filter('deleted_at', 'is', null); // Exclude soft-deleted items

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
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
    String? merchant,
    String? description,
    String? paymentMethod,
    String? notes,
    bool isRecurring = false,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'user_id': _currentUserId,
        'amount': amount,
        'date': date.toIso8601String().split('T')[0],
        'category_id': categoryId,
        'merchant': merchant,
        'description': description,
        'payment_method': paymentMethod,
        'notes': notes,
        'is_recurring': isRecurring,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from(AppConstants.expensesTable)
          .insert(data)
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update existing expense
  Future<Expense> updateExpense({
    required String id,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? merchant,
    String? description,
    String? paymentMethod,
    String? notes,
    bool? isRecurring,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (amount != null) data['amount'] = amount;
      if (date != null) data['date'] = date.toIso8601String().split('T')[0];
      if (categoryId != null) data['category_id'] = categoryId;
      if (merchant != null) data['merchant'] = merchant;
      if (description != null) data['description'] = description;
      if (paymentMethod != null) data['payment_method'] = paymentMethod;
      if (notes != null) data['notes'] = notes;
      if (isRecurring != null) data['is_recurring'] = isRecurring;

      final response = await _supabase
          .from(AppConstants.expensesTable)
          .update(data)
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id)
          .select()
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Soft delete expense (move to trash)
  Future<void> deleteExpense(String id) async {
    try {
      await _supabase
          .from(AppConstants.expensesTable)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      rethrow;
    }
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

  /// Get all categories (default + user custom)
  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from(AppConstants.categoriesTable)
          .select()
          .or('user_id.is.null,user_id.eq.${_supabase.auth.currentUser!.id}')
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
          .select('amount')
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
        return {'total': 0.0, 'count': 0, 'average': 0.0};
      }

      final total = expenses.fold<double>(
        0,
        (sum, item) => sum + (item['amount'] as num).toDouble(),
      );

      return {
        'total': total,
        'count': expenses.length,
        'average': total / expenses.length,
      };
    } catch (e) {
      return {'total': 0.0, 'count': 0, 'average': 0.0};
    }
  }
}
