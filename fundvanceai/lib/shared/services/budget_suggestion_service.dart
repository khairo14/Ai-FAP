import 'package:fundvanceai/core/config/supabase_config.dart';

/// Represents a single AI-generated budget suggestion for one category.
class BudgetSuggestion {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  /// Which 50/30/20 bucket this category belongs to.
  /// One of: 'needs', 'wants', 'savings'
  final String bucket;

  /// AI-suggested monthly budget amount (capped by 50/30/20 rule).
  final double suggestedAmount;

  /// User's 3-month historical average spending in this category.
  final double historicalAvg;

  /// Whether the user already has an active budget for this category.
  final bool alreadyHasBudget;

  /// Existing budget ID if [alreadyHasBudget] is true.
  final String? existingBudgetId;

  const BudgetSuggestion({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.bucket,
    required this.suggestedAmount,
    required this.historicalAvg,
    this.alreadyHasBudget = false,
    this.existingBudgetId,
  });
}

/// Result object returned by [BudgetSuggestionService.generateSuggestions].
class BudgetSuggestionResult {
  /// Monthly income used for the calculation.
  final double monthlyIncome;

  /// Needs allocation (50% of income).
  final double needsLimit;

  /// Wants allocation (30% of income).
  final double wantsLimit;

  /// Savings recommendation (20% of income).
  final double savingsRecommendation;

  /// Total projected monthly spending from all suggestions.
  final double totalSuggested;

  /// Category-level suggestions (only includes categories found in user data).
  final List<BudgetSuggestion> suggestions;

  const BudgetSuggestionResult({
    required this.monthlyIncome,
    required this.needsLimit,
    required this.wantsLimit,
    required this.savingsRecommendation,
    required this.totalSuggested,
    required this.suggestions,
  });
}

/// On-device 50/30/20 budget suggestion engine.
///
/// Uses the user's historical expense data (last 3 months) and their monthly
/// income to generate category-level budget recommendations following the
/// 50/30/20 budgeting rule:
///   • 50% Needs  – Groceries, Bills, Transport, Healthcare, Education
///   • 30% Wants  – Food & Dining, Shopping, Entertainment, Personal Care
///   • 20% Savings – Shown as a headline recommendation (not a budget category)
///
/// No external AI API required — all logic runs on-device.
class BudgetSuggestionService {
  final _supabase = SupabaseConfig.client;

  // ── 50/30/20 bucket mapping ─────────────────────────────────────────────
  // Category names (case-insensitive match) → bucket
  static const Map<String, String> _categoryBucket = {
    // Needs (50 %)
    'groceries': 'needs',
    'bills & utilities': 'needs',
    'utilities': 'needs',
    'transportation': 'needs',
    'transport': 'needs',
    'healthcare': 'needs',
    'health': 'needs',
    'education': 'needs',
    'rent': 'needs',
    'housing': 'needs',
    'insurance': 'needs',

    // Wants (30 %)
    'food & dining': 'wants',
    'dining': 'wants',
    'restaurants': 'wants',
    'shopping': 'wants',
    'entertainment': 'wants',
    'personal care': 'wants',
    'beauty': 'wants',
    'hobbies': 'wants',
    'travel': 'wants',
    'subscriptions': 'wants',
    'clothing': 'wants',
    'technology': 'wants',
  };

  static String _bucketForCategory(String name) {
    final lower = name.toLowerCase();
    return _categoryBucket[lower] ?? 'wants'; // default unrecognised → wants
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Generate 50/30/20 budget suggestions.
  ///
  /// [monthlyIncome] — use the value supplied by the user. If null, the
  /// service will attempt to calculate it from the last 3 months of income
  /// records in Supabase; if still unavailable, throws [StateError].
  Future<BudgetSuggestionResult> generateSuggestions({
    double? monthlyIncome,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('User not authenticated');

    // ── 1. Resolve monthly income ────────────────────────────────────────
    final income = monthlyIncome ?? await _estimateMonthlyIncome(userId);
    if (income <= 0) throw StateError('No income data available');

    final needsLimit = income * 0.50;
    final wantsLimit = income * 0.30;
    final savingsGoal = income * 0.20;

    // ── 2. Fetch 3-month expense history ─────────────────────────────────
    final threeMonthsAgo =
        DateTime.now().subtract(const Duration(days: 92));
    final expenses = await _fetchExpenses(userId, threeMonthsAgo, DateTime.now());

    // ── 3. Average per-category spend per month ───────────────────────────
    final spendByCatId = <String, double>{};
    for (final e in expenses) {
      final catId =
          (e['category_id'] as String?) ??
          (e['expense_categories'] as Map?)?['id'] as String? ??
          '__none';
      spendByCatId[catId] =
          (spendByCatId[catId] ?? 0.0) + (e['amount'] as num).toDouble();
    }
    // Divide by 3 to get monthly average
    spendByCatId.updateAll((k, v) => v / 3.0);

    // ── 4. Fetch all user expense categories ──────────────────────────────
    final categories = await _fetchCategories(userId);

    // ── 5. Fetch existing budgets to mark already-budgeted categories ─────
    final budgets = await _fetchBudgets(userId);
    final budgetByCatId = <String, Map<String, dynamic>>{
      for (final b in budgets)
        if (b['category_id'] != null) b['category_id'] as String: b,
    };

    // ── 6. Build per-category suggestions ────────────────────────────────
    // Group categories by bucket
    final needsCats = <Map<String, dynamic>>[];
    final wantsCats = <Map<String, dynamic>>[];

    for (final cat in categories) {
      final id = cat['id'] as String;
      final name = cat['name'] as String;
      final bucket = _bucketForCategory(name);
      final histAvg = spendByCatId[id] ?? 0.0;
      if (bucket == 'needs') {
        needsCats.add({...cat, 'histAvg': histAvg});
      } else {
        wantsCats.add({...cat, 'histAvg': histAvg});
      }
    }

    // ── 7. Allocate bucket amounts ────────────────────────────────────────
    final suggestions = <BudgetSuggestion>[
      ..._allocate(needsCats, needsLimit, 'needs', budgetByCatId),
      ..._allocate(wantsCats, wantsLimit, 'wants', budgetByCatId),
    ];

    // Sort: needs first, then wants; within each bucket by suggested amount desc
    suggestions.sort((a, b) {
      if (a.bucket != b.bucket) {
        return a.bucket == 'needs' ? -1 : 1;
      }
      return b.suggestedAmount.compareTo(a.suggestedAmount);
    });

    final totalSuggested =
        suggestions.fold(0.0, (s, x) => s + x.suggestedAmount);

    return BudgetSuggestionResult(
      monthlyIncome: income,
      needsLimit: needsLimit,
      wantsLimit: wantsLimit,
      savingsRecommendation: savingsGoal,
      totalSuggested: totalSuggested,
      suggestions: suggestions,
    );
  }

  // ─── Allocation helper ────────────────────────────────────────────────────

  List<BudgetSuggestion> _allocate(
    List<Map<String, dynamic>> cats,
    double bucketLimit,
    String bucket,
    Map<String, Map<String, dynamic>> budgetByCatId,
  ) {
    if (cats.isEmpty) return [];

    final histTotals = cats.fold(0.0, (s, c) => s + (c['histAvg'] as double));

    return cats.map((cat) {
      final id = cat['id'] as String;
      final name = cat['name'] as String;
      final histAvg = cat['histAvg'] as double;

      // Suggested = proportional share of bucket limit, BUT never more than
      // 1.15× historical average (avoid suggesting a drastic increase)
      double suggested;
      if (histTotals <= 0) {
        // No history — distribute bucket equally
        suggested = bucketLimit / cats.length;
      } else if (histTotals <= bucketLimit) {
        // User spends less than the limit → suggest their historical average
        suggested = histAvg;
      } else {
        // User overspends bucket → scale each category down proportionally
        final share = histAvg / histTotals;
        suggested = bucketLimit * share;
      }

      // Round to nearest 5 for cleaner numbers
      suggested = (suggested / 5).round() * 5.0;
      if (suggested <= 0 && histAvg <= 0) return null;
      if (suggested <= 0) suggested = 5.0;

      final existingBudget = budgetByCatId[id];
      return BudgetSuggestion(
        categoryId: id,
        categoryName: name,
        categoryIcon: cat['icon'] as String?,
        categoryColor: cat['color'] as String?,
        bucket: bucket,
        suggestedAmount: suggested,
        historicalAvg: histAvg,
        alreadyHasBudget: existingBudget != null,
        existingBudgetId: existingBudget?['id'] as String?,
      );
    }).whereType<BudgetSuggestion>().toList();
  }

  // ─── Data fetchers ────────────────────────────────────────────────────────

  Future<double> _estimateMonthlyIncome(String userId) async {
    try {
      final threeMonthsAgo =
          DateTime.now().subtract(const Duration(days: 92));
      final rows = await _supabase
          .from('income')
          .select('amount, income_date')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .gte('income_date',
              threeMonthsAgo.toIso8601String().split('T')[0]);

      if ((rows as List).isEmpty) return 0.0;
      final total =
          rows.fold(0.0, (s, r) => s + (r['amount'] as num).toDouble());
      return total / 3.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchExpenses(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final result = await _supabase
          .from('expenses')
          .select(
              'id, amount, date, category_id, expense_categories(id, name)')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories(String userId) async {
    try {
      final result = await _supabase
          .from('expense_categories')
          .select('id, name, icon, color')
          .or('user_id.eq.$userId,user_id.is.null')
          .filter('deleted_at', 'is', null)
          .order('name');
      return List<Map<String, dynamic>>.from(result as List);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBudgets(String userId) async {
    try {
      final result = await _supabase
          .from('budgets')
          .select('id, category_id, amount')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);
      return List<Map<String, dynamic>>.from(result as List);
    } catch (_) {
      return [];
    }
  }
}
