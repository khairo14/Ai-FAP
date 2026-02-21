import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/shared/models/goal.dart';

class GoalService {
  final _supabase = SupabaseConfig.client;

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<Goal>> getGoals({bool includeCompleted = true}) async {
    var query = _supabase
        .from('goals')
        .select()
        .eq('user_id', _userId)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    if (!includeCompleted) {
      query = query.eq('is_completed', false);
    }

    final result = await query;
    return (result as List)
        .map((j) => Goal.fromJson(j as Map<String, dynamic>))
        .toList();
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
    return Goal.fromJson(result as Map<String, dynamic>);
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
    if (targetDate != null) data['target_date'] = targetDate.toIso8601String().split('T')[0];
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
    return Goal.fromJson(result as Map<String, dynamic>);
  }

  Future<void> deleteGoal(String id) async {
    await _supabase
        .from('goals')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ── Contributions ─────────────────────────────────────────────────────────

  Future<GoalContribution> addContribution({
    required String goalId,
    required double amount,
    String? notes,
    DateTime? contributedAt,
  }) async {
    final data = {
      'goal_id': goalId,
      'user_id': _userId,
      'amount': amount,
      'notes': notes,
      'contributed_at': (contributedAt ?? DateTime.now()).toIso8601String(),
    };
    final result = await _supabase
        .from('goal_contributions')
        .insert(data)
        .select()
        .single();
    return GoalContribution.fromJson(result as Map<String, dynamic>);
  }

  Future<List<GoalContribution>> getContributions(String goalId) async {
    final result = await _supabase
        .from('goal_contributions')
        .select()
        .eq('goal_id', goalId)
        .eq('user_id', _userId)
        .order('contributed_at', ascending: false)
        .limit(50);
    return (result as List)
        .map((j) => GoalContribution.fromJson(j as Map<String, dynamic>))
        .toList();
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
    return Goal.fromJson(result as Map<String, dynamic>);
  }
}
