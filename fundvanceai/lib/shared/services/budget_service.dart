import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/core/constants/app_constants.dart';
import 'package:fundvanceai/shared/models/budget.dart';
import 'connectivity_service.dart';
import 'local_database.dart';

/// Service for managing budgets with Supabase
class BudgetService {
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

  /// Get all budgets for current user (excluding deleted)
  Future<List<Budget>> getBudgets({
    bool activeOnly = false,
  }) async {
    final userId = _currentUserId;

    if (_isOnline) {
      try {
        var query = _supabase
            .from(AppConstants.budgetsTable)
            .select()
            .eq('user_id', userId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false);

        final response = await query;

        final budgets = (response as List)
            .map((json) => Budget.fromJson(json as Map<String, dynamic>))
            .toList();

        // Cache to local DB
        await LocalDatabase.instance.upsertRows(
          table: 'budgets',
          userId: userId,
          rows: (response as List).cast<Map<String, dynamic>>(),
          idGetter: (row) => row['id'] as String,
        );

        if (activeOnly) {
          return budgets.where((b) => b.isActive()).toList();
        }
        return budgets;
      } catch (e) {
        if (!_isNetworkError(e)) rethrow;
        // Fall through to cache on network errors
      }
    }

    // Offline or network error — serve from local cache
    final cached = await LocalDatabase.instance.getRows(
      table: 'budgets',
      userId: userId,
    );
    final budgets = cached.map((json) => Budget.fromJson(json)).toList();
    if (activeOnly) return budgets.where((b) => b.isActive()).toList();
    return budgets;
  }

  /// Get single budget by ID (only non-deleted)
  Future<Budget?> getBudget(String id) async {
    try {
      final response = await _supabase
          .from(AppConstants.budgetsTable)
          .select()
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      if (response == null) return null;
      return Budget.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get budget for a specific category (only non-deleted)
  Future<Budget?> getBudgetForCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from(AppConstants.budgetsTable)
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('category_id', categoryId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return Budget.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new budget
  Future<Budget> createBudget({
    required double amount,
    required String period,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final userId = _currentUserId;

    final data = <String, dynamic>{
      'id': _uuid.v4(),
      'user_id': userId,
      'amount': amount,
      'period': period,
      'category_id': categoryId,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'created_at': now.toIso8601String(),
    };

    if (_isOnline) {
      try {
        final response = await _supabase
            .from(AppConstants.budgetsTable)
            .insert(data)
            .select()
            .single();

        final budget = Budget.fromJson(response);
        await LocalDatabase.instance.upsertRow(
          table: 'budgets',
          id: budget.id,
          userId: userId,
          payload: Map<String, dynamic>.from(response),
        );
        return budget;
      } catch (e) {
        if (!_isNetworkError(e)) rethrow;
        // Fall through to offline path
      }
    }

    // Offline: store locally + enqueue for sync
    await LocalDatabase.instance.upsertRow(
      table: 'budgets',
      id: data['id'] as String,
      userId: userId,
      payload: data,
    );
    await LocalDatabase.instance.enqueuePendingOp(
      operation: 'INSERT',
      tableName: AppConstants.budgetsTable,
      recordId: data['id'] as String,
      payload: data,
    );
    return Budget.fromJson(data);
  }

  /// Update existing budget
  Future<Budget> updateBudget({
    required String id,
    double? amount,
    String? period,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (amount != null) data['amount'] = amount;
      if (period != null) data['period'] = period;
      if (categoryId != null) data['category_id'] = categoryId;
      if (startDate != null) {
        data['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        data['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _supabase
          .from(AppConstants.budgetsTable)
          .update(data)
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .select()
          .single();

      return Budget.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Soft delete budget (move to trash)
  Future<void> deleteBudget(String id) async {
    try {
      await _supabase
          .from(AppConstants.budgetsTable)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get deleted budgets (trash)
  Future<List<Budget>> getDeletedBudgets() async {
    try {
      final response = await _supabase
          .from(AppConstants.budgetsTable)
          .select()
          .eq('user_id', _currentUserId)
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);

      return (response as List)
          .map((json) => Budget.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Restore budget from trash
  Future<void> restoreBudget(String id) async {
    try {
      await _supabase
          .from(AppConstants.budgetsTable)
          .update({'deleted_at': null})
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently delete budget
  Future<void> permanentlyDeleteBudget(String id) async {
    try {
      await _supabase
          .from(AppConstants.budgetsTable)
          .delete()
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (e) {
      rethrow;
    }
  }

  /// Auto-cleanup: Permanently delete budgets older than 30 days in trash
  Future<int> autoCleanupOldDeleted() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final response = await _supabase
          .from(AppConstants.budgetsTable)
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

  /// Get budget status with spent amount and percentage
  Future<Map<String, dynamic>> getBudgetStatus(
    String budgetId, {
    String? categoryId,
    String? period,
  }) async {
    try {
      // Get budget
      final budget = await getBudget(budgetId);
      if (budget == null) {
        return {
          'budget_amount': 0.0,
          'spent_amount': 0.0,
          'percentage': 0.0,
          'remaining': 0.0,
          'status': 'unknown',
        };
      }

      // Calculate date range based on period
      DateTime startDate;
      DateTime endDate;

      if (budget.startDate != null && budget.endDate != null) {
        startDate = budget.startDate!;
        endDate = budget.endDate!;
      } else {
        final now = DateTime.now();
        switch (budget.period.toLowerCase()) {
          case 'daily':
            startDate = DateTime(now.year, now.month, now.day);
            endDate = startDate;
            break;
          case 'weekly':
            startDate = now.subtract(Duration(days: now.weekday - 1));
            endDate = startDate.add(const Duration(days: 6));
            break;
          case 'yearly':
            startDate = DateTime(now.year, 1, 1);
            endDate = DateTime(now.year, 12, 31);
            break;
          case 'monthly':
          default:
            startDate = DateTime(now.year, now.month, 1);
            endDate = DateTime(now.year, now.month + 1, 0);
            break;
        }
      }

      // Get spent amount from expenses
      var query = _supabase
          .from(AppConstants.expensesTable)
          .select('amount')
          .eq('user_id', _currentUserId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      if (budget.categoryId != null) {
        query = query.eq('category_id', budget.categoryId!);
      }

      final response = await query;
      final expenses = response as List;

      final spentAmount = expenses.isEmpty
          ? 0.0
          : expenses.fold<double>(
              0,
              (sum, item) => sum + (item['amount'] as num).toDouble(),
            );

      final percentage =
          budget.amount > 0 ? (spentAmount / budget.amount) * 100 : 0.0;
      final remaining = budget.amount - spentAmount;

      String status;
      if (percentage > 100) {
        status = 'over';
      } else if (percentage >= 90) {
        status = 'warning';
      } else {
        status = 'ok';
      }

      return {
        'budget_amount': budget.amount,
        'spent_amount': spentAmount,
        'percentage': percentage,
        'remaining': remaining,
        'status': status,
        'start_date': startDate,
        'end_date': endDate,
      };
    } catch (e) {
      return {
        'budget_amount': 0.0,
        'spent_amount': 0.0,
        'percentage': 0.0,
        'remaining': 0.0,
        'status': 'error',
      };
    }
  }

  /// Get all budgets with their status
  Future<List<Map<String, dynamic>>> getAllBudgetStatuses({
    bool activeOnly = false,
  }) async {
    try {
      final budgets = await getBudgets(activeOnly: activeOnly);
      final statuses = <Map<String, dynamic>>[];

      for (final budget in budgets) {
        final status = await getBudgetStatus(budget.id);
        statuses.add({
          'budget': budget,
          ...status,
        });
      }

      return statuses;
    } catch (e) {
      rethrow;
    }
  }

  /// Get budgets that are over limit
  Future<List<Map<String, dynamic>>> getOverBudgetAlerts() async {
    try {
      final statuses = await getAllBudgetStatuses(activeOnly: true);
      return statuses.where((status) => status['status'] == 'over').toList();
    } catch (e) {
      return [];
    }
  }

  /// Get budgets approaching limit (90%+)
  Future<List<Map<String, dynamic>>> getBudgetWarnings() async {
    try {
      final statuses = await getAllBudgetStatuses(activeOnly: true);
      return statuses.where((status) => status['status'] == 'warning').toList();
    } catch (e) {
      return [];
    }
  }
}
