import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/shared/models/goal.dart';
import 'package:fundvanceai/shared/services/connectivity_service.dart';
import 'package:fundvanceai/shared/services/local_database.dart';

class GoalService {
  final _supabase = SupabaseConfig.client;

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;
  bool get _isOnline => ConnectivityService.instance.isOnline;

  static bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('errno = 7') ||
        msg.contains('authretryable') ||
        msg.contains('clientexception');
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<Goal>> getGoals({bool includeCompleted = true}) async {
    final userId = _userId;

    if (_isOnline) {
      try {
        final List<Map<String, dynamic>> result;
        if (includeCompleted) {
          result = await _supabase
              .from('goals')
              .select()
              .eq('user_id', userId)
              .filter('deleted_at', 'is', null)
              .order('created_at', ascending: false);
        } else {
          result = await _supabase
              .from('goals')
              .select()
              .eq('user_id', userId)
              .filter('deleted_at', 'is', null)
              .eq('is_completed', false)
              .order('created_at', ascending: false);
        }
        // Cache for offline use
        await LocalDatabase.instance.upsertRows(
          table: 'goals',
          userId: userId,
          rows: result.map((r) => Map<String, dynamic>.from(r)).toList(),
          idGetter: (r) => r['id'] as String,
        );
        return result.map(Goal.fromJson).toList();
      } catch (e) {
        if (!_isNetworkError(e)) rethrow;
        // Fall through to cache
      }
    }

    // Offline or network error — serve from SQLite
    final cached = await LocalDatabase.instance.getRows(
      table: 'goals',
      userId: userId,
    );
    var goals = cached
        .where((r) => r['deleted_at'] == null)
        .map(Goal.fromJson)
        .toList();
    if (!includeCompleted) {
      goals = goals.where((g) => !g.isCompleted).toList();
    }
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  Future<Goal> createGoal({
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
    final data = {
      'user_id': _userId,
      'title': title,
      'description': description,
      'goal_type': goalType.dbValue,
      'target_amount': targetAmount,
      'current_amount': 0,
      'currency': currency,
      'target_date': targetDate?.toIso8601String().split('T')[0],
      'icon': icon,
      'color': color,
      'notes': notes,
    };
    final result = await _supabase.from('goals').insert(data).select().single();
    // Cache immediately for offline reads
    await LocalDatabase.instance.upsertRow(
      table: 'goals',
      id: result['id'] as String,
      userId: _userId,
      payload: Map<String, dynamic>.from(result),
    );
    return Goal.fromJson(result);
  }

  Future<Goal> updateGoal({
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
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (goalType != null) data['goal_type'] = goalType.dbValue;
    if (targetAmount != null) data['target_amount'] = targetAmount;
    if (currency != null) data['currency'] = currency;
    if (targetDate != null) {
      data['target_date'] = targetDate.toIso8601String().split('T')[0];
    }
    if (icon != null) data['icon'] = icon;
    if (color != null) data['color'] = color;
    if (notes != null) data['notes'] = notes;

    final result = await _supabase
        .from('goals')
        .update(data)
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    // Keep cache in sync
    await LocalDatabase.instance.upsertRow(
      table: 'goals',
      id: id,
      userId: _userId,
      payload: Map<String, dynamic>.from(result),
    );
    return Goal.fromJson(result);
  }

  Future<void> deleteGoal(String id) async {
    await _supabase
        .from('goals')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId);
    // Remove from cache
    await LocalDatabase.instance
        .deleteRow(table: 'goals', id: id, userId: _userId);
  }

  // ── Contributions ─────────────────────────────────────────────────────────

  Future<GoalContribution> addContribution({
    required String goalId,
    required double amount,
    String? notes,
    String? accountId,
    DateTime? contributedAt,
  }) async {
    final data = <String, dynamic>{
      'goal_id': goalId,
      'user_id': _userId,
      'amount': amount,
      'notes': notes,
      'contributed_at': (contributedAt ?? DateTime.now()).toIso8601String(),
      if (accountId != null) 'account_id': accountId,
    };
    final result = await _supabase
        .from('goal_contributions')
        .insert(data)
        .select()
        .single();
    // Update account balance: deposit subtracts from account, withdrawal adds back
    if (accountId != null) {
      await _supabase.rpc('update_account_balance', params: {
        'account_id': accountId,
        'amount_change': amount.abs(),
        'operation': amount >= 0 ? 'subtract' : 'add',
      });
    }
    return GoalContribution.fromJson(result);
  }

  Future<List<GoalContribution>> getContributions(String goalId) async {
    final result = await _supabase
        .from('goal_contributions')
        .select()
        .eq('goal_id', goalId)
        .eq('user_id', _userId)
        .order('contributed_at', ascending: false)
        .limit(50);
    return result.map(GoalContribution.fromJson).toList();
  }

  Future<void> deleteContribution(String id) async {
    await _supabase
        .from('goal_contributions')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  /// Fetch the latest goal state (after a contribution triggers the DB).
  Future<Goal?> refreshGoal(String id) async {
    final result = await _supabase
        .from('goals')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (result == null) return null;
    // Update cache with latest server state
    await LocalDatabase.instance.upsertRow(
      table: 'goals',
      id: id,
      userId: _userId,
      payload: Map<String, dynamic>.from(result),
    );
    return Goal.fromJson(result);
  }
}
