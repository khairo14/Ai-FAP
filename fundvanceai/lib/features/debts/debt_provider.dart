import 'package:flutter/foundation.dart';
import 'package:fundvanceai/shared/models/debt.dart';
import 'package:fundvanceai/shared/services/debt_service.dart';

class DebtProvider extends ChangeNotifier {
  final DebtService _service = DebtService();

  List<Debt> _debts = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Debt> get debts => _debts;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  List<Debt> get activeDebts => _debts.where((d) => !d.isPaidOff).toList();

  List<Debt> get paidOffDebts => _debts.where((d) => d.isPaidOff).toList();

  double get totalBalance =>
      activeDebts.fold(0.0, (sum, d) => sum + d.currentBalance);

  double get totalMinimumPayments =>
      activeDebts.fold(0.0, (sum, d) => sum + d.minimumPayment);

  double get totalMonthlyInterest =>
      activeDebts.fold(0.0, (sum, d) => sum + d.monthlyInterestCharge);

  List<Debt> get snowballOrder => _service
          .simulate(
            debts: activeDebts,
            extraMonthlyPayment: 0,
            strategy: 'snowball',
          )
          .order
          .map((o) {
        return activeDebts.firstWhere((d) => d.name == o.debtName,
            orElse: () => activeDebts.first);
      }).toList();

  List<Debt> get avalancheOrder {
    final sorted = [...activeDebts];
    sorted.sort((a, b) => b.interestRate.compareTo(a.interestRate));
    return sorted;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    await loadDebts();
    _isInitialized = true;
  }

  Future<void> loadDebts() async {
    _setLoading(true);
    _clearError();
    try {
      _debts = await _service.getDebts(includeCompleted: true);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load debts: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<bool> addDebt({
    required String name,
    String? description,
    required DebtType debtType,
    required double totalAmount,
    required double currentBalance,
    required double interestRate,
    required double minimumPayment,
    int? paymentDueDay,
    String currency = 'USD',
    String? icon,
    String? color,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final debt = await _service.createDebt(
        name: name,
        description: description,
        debtType: debtType,
        totalAmount: totalAmount,
        currentBalance: currentBalance,
        interestRate: interestRate,
        minimumPayment: minimumPayment,
        paymentDueDay: paymentDueDay,
        currency: currency,
        icon: icon,
        color: color,
        notes: notes,
      );
      _debts.insert(0, debt);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create debt: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDebt({
    required String id,
    String? name,
    String? description,
    DebtType? debtType,
    double? totalAmount,
    double? currentBalance,
    double? interestRate,
    double? minimumPayment,
    int? paymentDueDay,
    String? currency,
    String? icon,
    String? color,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final updated = await _service.updateDebt(
        id: id,
        name: name,
        description: description,
        debtType: debtType,
        totalAmount: totalAmount,
        currentBalance: currentBalance,
        interestRate: interestRate,
        minimumPayment: minimumPayment,
        paymentDueDay: paymentDueDay,
        currency: currency,
        icon: icon,
        color: color,
        notes: notes,
      );
      final index = _debts.indexWhere((d) => d.id == id);
      if (index != -1) _debts[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update debt: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteDebt(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _service.deleteDebt(id);
      _debts.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete debt: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<bool> recordPayment({
    required String debtId,
    required double amount,
    String? notes,
    DateTime? paidAt,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _service.recordPayment(
        debtId: debtId,
        amount: amount,
        notes: notes,
        paidAt: paidAt,
      );
      // Refresh so trigger-updated balance is reflected
      final refreshed = await _service.refreshDebt(debtId);
      if (refreshed != null) {
        final index = _debts.indexWhere((d) => d.id == debtId);
        if (index != -1) _debts[index] = refreshed;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to record payment: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Simulation ────────────────────────────────────────────────────────────

  PayoffSimulation simulate({
    required double extraMonthlyPayment,
    required String strategy,
  }) =>
      _service.simulate(
        debts: activeDebts,
        extraMonthlyPayment: extraMonthlyPayment,
        strategy: strategy,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void reset() {
    _debts = [];
    _isLoading = false;
    _isInitialized = false;
    _errorMessage = null;
    notifyListeners();
  }
}
