import 'package:flutter/foundation.dart';
import '../../shared/models/income.dart';
import '../../shared/services/income_service.dart';

/// Provider for income management state
class IncomeProvider extends ChangeNotifier {
  final IncomeService _incomeService = IncomeService();

  List<Income> _incomeList = [];
  List<IncomeCategory> _categories = [];
  bool _isLoading = true; // Start with loading true
  bool _isInitialized = false;
  String? _errorMessage;
  Map<String, dynamic>? _stats;

  // Filters
  String? _selectedCategoryId;
  String? _selectedTag;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<Income> get incomeList {
    if (_selectedTag == null) return _incomeList;
    return _incomeList.where((i) => i.tags.contains(_selectedTag)).toList();
  }

  List<IncomeCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get stats => _stats;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedTag => _selectedTag;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  /// All distinct tags used across loaded income, sorted alphabetically
  List<String> get allTags {
    final seen = <String>{};
    for (final i in _incomeList) {
      seen.addAll(i.tags);
    }
    return seen.toList()..sort();
  }

  /// Initialize provider - load categories and income
  Future<void> initialize() async {
    if (_isInitialized) {
      return; // Don't initialize twice
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_incomeService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      await Future.wait([
        loadCategories(),
        loadIncome(),
        loadStats(),
      ]);
      _errorMessage = null;
      _isInitialized = true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } catch (e) {
      _errorMessage = 'Failed to initialize: Unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load income categories
  Future<void> loadCategories() async {
    try {
      _categories = await _incomeService.getIncomeCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load categories: ${e.toString()}';
      _categories = []; // Ensure empty list on error
      notifyListeners();
    }
  }

  /// Load income with current filters
  Future<void> loadIncome() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _incomeList = await _incomeService.getIncome(
        categoryId: _selectedCategoryId,
        startDate: _startDate,
        endDate: _endDate,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load income: ${e.toString()}';
      _incomeList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load income statistics
  Future<void> loadStats() async {
    try {
      _stats = await _incomeService.getIncomeStats(
        startDate: _startDate,
        endDate: _endDate,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load stats: ${e.toString()}';
      _stats = null; // Explicitly set to null on error
      notifyListeners();
    }
  }

  /// Add new income
  Future<bool> addIncome({
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
    try {
      await _incomeService.createIncome(
        amount: amount,
        currency: currency,
        categoryId: categoryId,
        incomeDate: incomeDate,
        description: description,
        taxType: taxType,
        taxPercentage: taxPercentage,
        taxFixedAmount: taxFixedAmount,
        isRecurring: isRecurring,
        recurrencePattern: recurrencePattern,
        accountId: accountId,
        tags: tags,
      );

      // Reload data
      await Future.wait([
        loadIncome(),
        loadStats(),
      ]);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add income: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update existing income
  Future<bool> updateIncome({
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
      await _incomeService.updateIncome(
        id: id,
        amount: amount,
        currency: currency,
        categoryId: categoryId,
        incomeDate: incomeDate,
        description: description,
        taxType: taxType,
        taxPercentage: taxPercentage,
        taxFixedAmount: taxFixedAmount,
        isRecurring: isRecurring,
        recurrencePattern: recurrencePattern,
        accountId: accountId,
        tags: tags,
      );

      // Reload data
      await Future.wait([
        loadIncome(),
        loadStats(),
      ]);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update income: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete income (soft delete)
  Future<bool> deleteIncome(String id) async {
    try {
      await _incomeService.deleteIncome(id);
      await Future.wait([
        loadIncome(),
        loadStats(),
      ]);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete income: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Restore soft-deleted income
  Future<bool> restoreIncome(String id) async {
    try {
      await _incomeService.restoreIncome(id);
      await loadIncome();
      await loadStats();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to restore income: ${e.toString()}';
      notifyListeners();
      return false;
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
    loadIncome();
    loadStats();
  }

  /// Set date range filter
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadIncome();
    loadStats();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategoryId = null;
    _selectedTag = null;
    _startDate = null;
    _endDate = null;
    loadIncome();
    loadStats();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}
