import 'package:flutter/foundation.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/shared/models/category.dart' as models;
import 'package:fundvanceai/shared/services/expense_service.dart';

/// Provider for expense management state
class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _stats;

  // Filters
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedTag;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<Expense> get expenses {
    if (_selectedTag == null) return _expenses;
    return _expenses.where((e) => e.tags.contains(_selectedTag)).toList();
  }

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get stats => _stats;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedAccountId => _selectedAccountId;
  String? get selectedTag => _selectedTag;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  /// All distinct tags used across loaded expenses, sorted alphabetically
  List<String> get allTags {
    final seen = <String>{};
    for (final e in _expenses) {
      seen.addAll(e.tags);
    }
    return seen.toList()..sort();
  }

  /// Returns up to 10 recently used distinct merchant names (most recent first)
  List<String> get recentMerchants {
    final seen = <String>{};
    final result = <String>[];
    for (final e in _expenses) {
      final m = e.merchant?.trim();
      if (m != null && m.isNotEmpty && seen.add(m.toLowerCase())) {
        result.add(m);
        if (result.length == 10) break;
      }
    }
    return result;
  }

  /// Returns the most recently used category ID for a given merchant name
  String? getCategoryForMerchant(String merchant) {
    final lower = merchant.toLowerCase();
    for (final e in _expenses) {
      if (e.merchant?.toLowerCase() == lower && e.categoryId != null) {
        return e.categoryId;
      }
    }
    return null;
  }

  /// Initialize provider - load categories and expenses
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if user is authenticated before proceeding
      if (!_expenseService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      await Future.wait([
        loadCategories(),
        loadExpenses(),
        loadStats(),
      ]);
      _errorMessage = null;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      debugPrint('ExpenseProvider initialization error: $e');
    } catch (e) {
      _errorMessage = 'Failed to initialize: Unexpected error occurred';
      debugPrint('ExpenseProvider unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories from database
  Future<void> loadCategories() async {
    try {
      _categories = await _expenseService.getCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load categories: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  /// Load expenses with current filters
  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _expenseService.getExpenses(
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        startDate: _startDate,
        endDate: _endDate,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load expenses: ${e.toString()}';
      _expenses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load expense statistics
  Future<void> loadStats() async {
    try {
      _stats = await _expenseService.getExpenseStats(
        startDate: _startDate,
        endDate: _endDate,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load stats: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Add new expense
  Future<bool> addExpense({
    required double amount,
    required DateTime date,
    String? categoryId,
    String? accountId, // New parameter
    String? merchant,
    String? description,
    String? paymentMethod,
    String? notes,
    List<String> tags = const [],
    bool isRecurring = false,
    String? recurringFrequency,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final expense = await _expenseService.createExpense(
        amount: amount,
        date: date,
        categoryId: categoryId,
        accountId: accountId,
        merchant: merchant,
        description: description,
        paymentMethod: paymentMethod,
        notes: notes,
        tags: tags,
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
      );

      // Add to list and re-sort
      _expenses.insert(0, expense);
      _sortExpenses();

      // Reload stats
      await loadStats();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add expense: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing expense
  Future<bool> updateExpense({
    required String id,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? accountId, // New parameter
    String? merchant,
    String? description,
    String? paymentMethod,
    String? notes,
    List<String>? tags,
    bool? isRecurring,
    String? recurringFrequency,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedExpense = await _expenseService.updateExpense(
        id: id,
        amount: amount,
        date: date,
        categoryId: categoryId,
        accountId: accountId,
        merchant: merchant,
        description: description,
        paymentMethod: paymentMethod,
        notes: notes,
        tags: tags,
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
      );

      // Update in list
      final index = _expenses.indexWhere((e) => e.id == id);
      if (index != -1) {
        _expenses[index] = updatedExpense;
        _sortExpenses();
      }

      // Reload stats
      await loadStats();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update expense: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete expense (soft delete)
  Future<bool> deleteExpense(String id) async {
    // Optimistically remove from list immediately for smooth UI
    final expenseToDelete = _expenses.firstWhere((e) => e.id == id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();

    try {
      await _expenseService.deleteExpense(id);

      // Reload stats after successful delete
      await loadStats();

      _errorMessage = null;
      return true;
    } catch (e) {
      // Restore the expense if delete failed
      _expenses.add(expenseToDelete);
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _errorMessage = 'Failed to delete expense: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Get deleted expenses (trash)
  Future<List<Expense>> getDeletedExpenses() async {
    try {
      return await _expenseService.getDeletedExpenses();
    } catch (e) {
      _errorMessage = 'Failed to load deleted expenses: ${e.toString()}';
      return [];
    }
  }

  /// Restore expense from trash
  Future<bool> restoreExpense(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _expenseService.restoreExpense(id);

      // Reload expenses to include restored item
      await loadExpenses();
      await loadStats();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to restore expense: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Permanently delete expense
  Future<bool> permanentlyDeleteExpense(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _expenseService.permanentlyDeleteExpense(id);

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to permanently delete expense: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Auto-cleanup old deleted expenses (30+ days in trash)
  Future<int> autoCleanupOldDeleted() async {
    try {
      return await _expenseService.autoCleanupOldDeleted();
    } catch (e) {
      return 0;
    }
  }

  /// Set tag filter (client-side)
  void setTagFilter(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  /// Set category filter
  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadExpenses();
    loadStats();
  }

  /// Set account filter
  void setAccountFilter(String? accountId) {
    _selectedAccountId = accountId;
    loadExpenses();
    loadStats();
  }

  /// Set date range filter
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    loadExpenses();
    loadStats();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategoryId = null;
    _selectedAccountId = null;
    _selectedTag = null;
    _startDate = null;
    _endDate = null;
    loadExpenses();
    loadStats();
  }

  /// Sort expenses by date (newest first)
  void _sortExpenses() {
    _expenses.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  /// Get category name by ID
  String getCategoryName(String? categoryId) {
    if (categoryId == null) return 'Uncategorized';
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get category by ID
  models.Category? getCategory(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }
}
