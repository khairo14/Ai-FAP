import 'package:flutter/foundation.dart';
import 'package:fundvanceai/shared/models/goal.dart';
import 'package:fundvanceai/shared/services/goal_service.dart';
import 'package:fundvanceai/shared/services/notification_service.dart';

class GoalProvider extends ChangeNotifier {
  final GoalService _service = GoalService();

  List<Goal> _goals = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  List<Goal> get activeGoals => _goals.where((g) => !g.isCompleted).toList();

  List<Goal> get completedGoals => _goals.where((g) => g.isCompleted).toList();

  double get totalTargetAmount =>
      activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);

  double get totalSaved =>
      activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);

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

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    await loadGoals();
    _isInitialized = true;
  }

  Future<void> loadGoals() async {
    _setLoading(true);
    _clearError();
    try {
      _goals = await _service.getGoals(includeCompleted: true);
      notifyListeners();
    } catch (e) {
      if (!_isNetworkError(e)) {
        _errorMessage = 'Failed to load goals: $e';
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<bool> addGoal({
    required String title,
    String? description,
    required GoalType goalType,
    required double targetAmount,
    String currency = 'USD',
    DateTime? targetDate,
    String? icon,
    String? color,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final goal = await _service.createGoal(
        title: title,
        description: description,
        goalType: goalType,
        targetAmount: targetAmount,
        currency: currency,
        targetDate: targetDate,
        icon: icon,
        color: color,
        notes: notes,
      );
      _goals.insert(0, goal);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create goal: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateGoal({
    required String id,
    String? title,
    String? description,
    GoalType? goalType,
    double? targetAmount,
    String? currency,
    DateTime? targetDate,
    String? icon,
    String? color,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final updated = await _service.updateGoal(
        id: id,
        title: title,
        description: description,
        goalType: goalType,
        targetAmount: targetAmount,
        currency: currency,
        targetDate: targetDate,
        icon: icon,
        color: color,
        notes: notes,
      );
      final index = _goals.indexWhere((g) => g.id == id);
      if (index != -1) _goals[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update goal: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteGoal(String id) async {
    _setLoading(true);
    _clearError();
    try {
      await _service.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete goal: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Contributions ─────────────────────────────────────────────────────────

  Future<bool> addContribution({
    required String goalId,
    required double amount,
    String? notes,
    String? accountId,
    DateTime? contributedAt,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _service.addContribution(
        goalId: goalId,
        amount: amount,
        notes: notes,
        accountId: accountId,
        contributedAt: contributedAt,
      );
      // Refresh so trigger-updated current_amount is reflected
      final refreshed = await _service.refreshGoal(goalId);
      if (refreshed != null) {
        final index = _goals.indexWhere((g) => g.id == goalId);
        if (index != -1) _goals[index] = refreshed;
        // Fire milestone notification
        NotificationService.checkGoalMilestone(
          goalId: refreshed.id,
          goalTitle: refreshed.title,
          currentAmount: refreshed.currentAmount,
          targetAmount: refreshed.targetAmount,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add contribution: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteContribution(String id, String goalId) async {
    _setLoading(true);
    _clearError();
    try {
      await _service.deleteContribution(id);
      // Refresh so trigger-updated current_amount is reflected
      final refreshed = await _service.refreshGoal(goalId);
      if (refreshed != null) {
        final index = _goals.indexWhere((g) => g.id == goalId);
        if (index != -1) _goals[index] = refreshed;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete contribution: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void reset() {
    _goals = [];
    _isLoading = false;
    _isInitialized = false;
    _errorMessage = null;
    notifyListeners();
  }
}
