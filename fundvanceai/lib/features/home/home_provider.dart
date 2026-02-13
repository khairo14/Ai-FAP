import 'package:flutter/foundation.dart';
import '../../shared/services/dashboard_service.dart';
import '../../shared/models/account.dart';

/// Provider for home screen state management
class HomeProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  bool _isLoading = false;
  String? _errorMessage;

  // Financial summary
  Map<String, dynamic> _financialSummary = {};
  
  // Accounts summary
  Map<String, dynamic> _accountsSummary = {};
  
  // Recent transactions
  List<Map<String, dynamic>> _recentTransactions = [];
  
  // Income vs Expenses data
  List<Map<String, dynamic>> _incomeVsExpensesData = [];
  
  // Financial health
  Map<String, dynamic> _financialHealth = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get financialSummary => _financialSummary;
  Map<String, dynamic> get accountsSummary => _accountsSummary;
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;
  List<Map<String, dynamic>> get incomeVsExpensesData => _incomeVsExpensesData;
  Map<String, dynamic> get financialHealth => _financialHealth;

  // Computed getters for multi-currency data
  Map<String, double> get expensesByCurrency {
    final data = _financialSummary['expensesByCurrency'] as Map<String, dynamic>?;
    if (data == null) return {};
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
  
  Map<String, double> get incomeByCurrency {
    final data = _financialSummary['incomeByCurrency'] as Map<String, dynamic>?;
    if (data == null) return {};
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
  
  Map<String, double> get netIncomeByCurrency {
    final data = _financialSummary['netIncomeByCurrency'] as Map<String, dynamic>?;
    if (data == null) return {};
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
  
  int get expenseCount => (_financialSummary['expenseCount'] as int?) ?? 0;
  int get incomeCount => (_financialSummary['incomeCount'] as int?) ?? 0;

  Map<String, double> get balancesByCurrency {
    final data = _accountsSummary['balancesByCurrency'] as Map<String, dynamic>?;
    if (data == null) return {};
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
  
  Map<String, double> get creditAvailableByCurrency {
    final data = _accountsSummary['creditAvailableByCurrency'] as Map<String, dynamic>?;
    if (data == null) return {};
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
  
  int get accountCount => (_accountsSummary['accountCount'] as int?) ?? 0;
  List<Account> get accounts => (_accountsSummary['accounts'] as List<Account>?) ?? [];

  double get healthScore => (_financialHealth['score'] as double?) ?? 0.0;
  String get healthStatus => (_financialHealth['status'] as String?) ?? 'Unknown';
  List<String> get healthInsights => (_financialHealth['insights'] as List<String>?) ?? [];

  /// Load all dashboard data
  Future<void> loadDashboardData({
    DateTime? startDate,
    DateTime? endDate,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _dashboardService.getFinancialSummary(
          startDate: startDate,
          endDate: endDate,
        ),
        _dashboardService.getAccountsSummary(),
        _dashboardService.getRecentTransactions(limit: 10),
        _dashboardService.getIncomeVsExpensesData(months: 6),
        _dashboardService.getFinancialHealthScore(),
      ]);

      _financialSummary = results[0] as Map<String, dynamic>;
      _accountsSummary = results[1] as Map<String, dynamic>;
      _recentTransactions = results[2] as List<Map<String, dynamic>>;
      _incomeVsExpensesData = results[3] as List<Map<String, dynamic>>;
      _financialHealth = results[4] as Map<String, dynamic>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load financial summary only
  Future<void> loadFinancialSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _financialSummary = await _dashboardService.getFinancialSummary(
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load accounts summary only
  Future<void> loadAccountsSummary() async {
    try {
      _accountsSummary = await _dashboardService.getAccountsSummary();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load recent transactions only
  Future<void> loadRecentTransactions({int limit = 10}) async {
    try {
      _recentTransactions = await _dashboardService.getRecentTransactions(limit: limit);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load income vs expenses data
  Future<void> loadIncomeVsExpensesData({int months = 6}) async {
    try {
      _incomeVsExpensesData = await _dashboardService.getIncomeVsExpensesData(months: months);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load financial health score
  Future<void> loadFinancialHealth() async {
    try {
      _financialHealth = await _dashboardService.getFinancialHealthScore();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Refresh all data (for pull-to-refresh)
  Future<void> refresh() async {
    await loadDashboardData(showLoading: false);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (for logout)
  void clear() {
    _financialSummary = {};
    _accountsSummary = {};
    _recentTransactions = [];
    _incomeVsExpensesData = [];
    _financialHealth = {};
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
