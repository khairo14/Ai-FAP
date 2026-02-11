import 'package:flutter/foundation.dart';
import 'package:fundvanceai/shared/models/budget.dart';
import 'package:fundvanceai/shared/services/budget_service.dart';

/// Provider for budget management state
class BudgetProvider extends ChangeNotifier {
  final BudgetService _budgetService = BudgetService();

  List<Budget> _budgets = [];
  List<Map<String, dynamic>> _budgetStatuses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Budget> get budgets => _budgets;
  List<Map<String, dynamic>> get budgetStatuses => _budgetStatuses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get over budget count
  int get overBudgetCount {
    return _budgetStatuses.where((status) => status['status'] == 'over').length;
  }

  /// Get warning count (90%+)
  int get warningCount {
    return _budgetStatuses.where((status) => status['status'] == 'warning').length;
  }

  /// Get total budgeted amount
  double get totalBudgetAmount {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.amount);
  }

  /// Get total spent amount
  double get totalSpentAmount {
    return _budgetStatuses.fold(
      0.0,
      (sum, status) => sum + (status['spent_amount'] as double? ?? 0.0),
    );
  }

  /// Initialize provider - load budgets and statuses
  Future<void> initialize() async {
    try {
      // Check if user is authenticated before proceeding
      if (!_budgetService.isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      await loadBudgets();
    } on Exception catch (e) {
      _errorMessage = e.toString();
      print('BudgetProvider initialization error: $e');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize: Unexpected error occurred';
      print('BudgetProvider unexpected error: $e');
      notifyListeners();
    }
  }

  /// Load budgets with statuses
  Future<void> loadBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _budgets = await _budgetService.getBudgets();
      _budgetStatuses = await _budgetService.getAllBudgetStatuses();
      _errorMessage = null;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _budgets = [];
      _budgetStatuses = [];
      print('Budget loading error: $e');
    } catch (e) {
      _errorMessage = 'Failed to load budgets: Unexpected error occurred';
      _budgets = [];
      _budgetStatuses = [];
      print('Budget unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new budget
  Future<bool> addBudget({
    required double amount,
    required String period,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final budget = await _budgetService.createBudget(
        amount: amount,
        period: period,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );

      // Add to list
      _budgets.insert(0, budget);

      // Reload statuses
      await loadBudgets();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add budget: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing budget
  Future<bool> updateBudget({
    required String id,
    double? amount,
    String? period,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedBudget = await _budgetService.updateBudget(
        id: id,
        amount: amount,
        period: period,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );

      // Update in list
      final index = _budgets.indexWhere((b) => b.id == id);
      if (index != -1) {
        _budgets[index] = updatedBudget;
      }

      // Reload statuses
      await loadBudgets();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update budget: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete budget (soft delete)
  Future<bool> deleteBudget(String id) async {
    // Optimistically remove from list immediately for smooth UI
    final budgetToDelete = _budgets.firstWhere((b) => b.id == id);
    final statusToDelete = _budgetStatuses.firstWhere((status) => status['budget'].id == id);
    _budgets.removeWhere((b) => b.id == id);
    _budgetStatuses.removeWhere((status) => status['budget'].id == id);
    notifyListeners();

    try {
      await _budgetService.deleteBudget(id);

      _errorMessage = null;
      return true;
    } catch (e) {
      // Restore the budget if delete failed
      _budgets.add(budgetToDelete);
      _budgetStatuses.add(statusToDelete);
      _errorMessage = 'Failed to delete budget: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Get deleted budgets (trash)
  Future<List<Budget>> getDeletedBudgets() async {
    try {
      return await _budgetService.getDeletedBudgets();
    } catch (e) {
      _errorMessage = 'Failed to load deleted budgets: ${e.toString()}';
      return [];
    }
  }

  /// Restore budget from trash
  Future<bool> restoreBudget(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _budgetService.restoreBudget(id);

      // Reload budgets to include restored item
      await loadBudgets();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to restore budget: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Permanently delete budget
  Future<bool> permanentlyDeleteBudget(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _budgetService.permanentlyDeleteBudget(id);

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to permanently delete budget: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Auto-cleanup old deleted budgets (30+ days in trash)
  Future<int> autoCleanupOldDeleted() async {
    try {
      return await _budgetService.autoCleanupOldDeleted();
    } catch (e) {
      return 0;
    }
  }

  /// Get budget status by ID
  Map<String, dynamic>? getBudgetStatus(String budgetId) {
    try {
      return _budgetStatuses.firstWhere(
        (status) => (status['budget'] as Budget).id == budgetId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get budget status by category ID
  Map<String, dynamic>? getBudgetStatusByCategory(String categoryId) {
    try {
      return _budgetStatuses.firstWhere(
        (status) => (status['budget'] as Budget).categoryId == categoryId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if category already has budget
  bool categoryHasBudget(String categoryId) {
    return _budgets.any((budget) => budget.categoryId == categoryId);
  }

  /// Get alerts (over budget)
  Future<List<Map<String, dynamic>>> getAlerts() async {
    try {
      return await _budgetService.getOverBudgetAlerts();
    } catch (e) {
      return [];
    }
  }

  /// Get warnings (approaching limit)
  Future<List<Map<String, dynamic>>> getWarnings() async {
    try {
      return await _budgetService.getBudgetWarnings();
    } catch (e) {
      return [];
    }
  }
}
