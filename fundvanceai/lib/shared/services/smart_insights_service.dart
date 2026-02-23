import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/shared/models/spending_insight.dart';

/// Generates AI-style spending insights by analysing expense and budget data.
///
/// All logic runs entirely on-device — no external AI API required.
/// The "intelligence" comes from programmatic heuristics over the user's data.
class SmartInsightsService {
  final _supabase = SupabaseConfig.client;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Generate all insights for the given month.
  ///
  /// [startDate] / [endDate] should span one calendar month.
  Future<List<SpendingInsight>> generateInsights({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final now = DateTime.now();

    // Fetch data in parallel for speed
    final currentFuture = _fetchExpenses(userId, startDate, endDate);
    final budgetsFuture = _fetchBudgets(userId);
    final previousFuture = _fetchExpenses(
      userId,
      startDate.subtract(const Duration(days: 32)),
      startDate.subtract(const Duration(days: 1)),
    );

    final currentExpenses = await currentFuture;
    final budgets = await budgetsFuture;
    final previousExpenses = await previousFuture;

    final insights = <SpendingInsight>[];

    insights.addAll(
        _budgetAlerts(budgets, currentExpenses, startDate, endDate, now));
    insights.addAll(_anomalyInsights(currentExpenses, previousExpenses, now));
    insights.addAll(_trendInsights(currentExpenses, previousExpenses, now));
    insights.addAll(_recurringInsights(currentExpenses, now));
    insights.addAll(
        _milestoneInsights(currentExpenses, budgets, startDate, endDate, now));
    insights.addAll(_savingsOpportunities(budgets, currentExpenses, now));
    insights.addAll(_spendingPatternInsights(currentExpenses, now));

    // Sort: critical → warning → info → positive, then by generated time
    insights.sort((a, b) {
      final sev =
          _severityOrder(a.severity).compareTo(_severityOrder(b.severity));
      if (sev != 0) return sev;
      return b.generatedAt.compareTo(a.generatedAt);
    });

    return insights;
  }

  /// Detect recurring expenses from the last 3 months of data.
  Future<List<RecurringExpense>> detectRecurring() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 92));
    final expenses =
        await _fetchExpenses(userId, threeMonthsAgo, DateTime.now());

    return _findRecurring(expenses);
  }

  // ─── Budget Alerts ────────────────────────────────────────────────────────

  List<SpendingInsight> _budgetAlerts(
    List<Map<String, dynamic>> budgets,
    List<Map<String, dynamic>> expenses,
    DateTime startDate,
    DateTime endDate,
    DateTime now,
  ) {
    final insights = <SpendingInsight>[];
    final spendByCategory = _groupByCategory(expenses);
    final daysInPeriod = endDate.difference(startDate).inDays + 1;
    final daysPassed = now.difference(startDate).inDays + 1;
    final periodProgress = (daysPassed / daysInPeriod).clamp(0.0, 1.0);

    for (final budget in budgets) {
      final categoryId = budget['expense_categories']?['id'] as String?;
      final categoryName =
          (budget['expense_categories']?['name'] as String?) ?? 'Uncategorized';
      final budgetAmount = (budget['amount'] as num).toDouble();
      final actual =
          categoryId != null ? (spendByCategory[categoryId] ?? 0.0) : 0.0;
      final pct = budgetAmount > 0 ? actual / budgetAmount : 0.0;

      if (pct >= 1.0) {
        insights.add(SpendingInsight(
          type: InsightType.budgetAlert,
          severity: InsightSeverity.critical,
          title: '$categoryName — Budget Exceeded',
          message:
              'You\'ve spent \$${actual.toStringAsFixed(0)} of your \$${budgetAmount.toStringAsFixed(0)} budget '
              '(${(pct * 100).toStringAsFixed(0)}%). '
              'Consider reviewing your spending in this category.',
          category: categoryName,
          amount: actual - budgetAmount,
          actionLabel: 'View Expenses',
          generatedAt: now,
          metadata: {'categoryId': categoryId, 'categoryName': categoryName},
        ));
      } else if (pct >= 0.85) {
        insights.add(SpendingInsight(
          type: InsightType.budgetAlert,
          severity: InsightSeverity.warning,
          title: '$categoryName — Nearly at Budget',
          message: 'You\'ve used ${(pct * 100).toStringAsFixed(0)}% of your '
              '\$${budgetAmount.toStringAsFixed(0)} $categoryName budget with '
              '${(daysInPeriod - daysPassed).clamp(0, daysInPeriod)} days remaining.',
          category: categoryName,
          amount: budgetAmount - actual,
          generatedAt: now,
          metadata: {'categoryId': categoryId, 'categoryName': categoryName},
        ));
      } else if (pct < periodProgress * 0.6 &&
          periodProgress > 0.5 &&
          pct > 0) {
        // Spending is noticeably below pace — positive insight
        insights.add(SpendingInsight(
          type: InsightType.budgetAlert,
          severity: InsightSeverity.positive,
          title: '$categoryName — On Track',
          message: 'You\'re well within budget for $categoryName: '
              '\$${actual.toStringAsFixed(0)} spent of '
              '\$${budgetAmount.toStringAsFixed(0)}. Keep it up!',
          category: categoryName,
          amount: budgetAmount - actual,
          generatedAt: now,
        ));
      }
    }

    return insights;
  }

  // ─── Anomaly Detection ────────────────────────────────────────────────────

  List<SpendingInsight> _anomalyInsights(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> previous,
    DateTime now,
  ) {
    final insights = <SpendingInsight>[];

    final currByCat = _groupByCategory(current);
    final prevByCat = _groupByCategory(previous);

    for (final entry in currByCat.entries) {
      final catId = entry.key;
      final catName = _categoryName(current, catId);
      final currAmount = entry.value;
      final prevAmount = prevByCat[catId] ?? 0.0;

      if (prevAmount < 10) continue; // not enough history

      final changeRatio = (currAmount - prevAmount) / prevAmount;

      if (changeRatio >= 0.5 && currAmount >= 20) {
        // Spending jumped ≥50 % vs last month
        insights.add(SpendingInsight(
          type: InsightType.anomaly,
          severity: changeRatio >= 1.0
              ? InsightSeverity.warning
              : InsightSeverity.info,
          title: 'Unusual Spike — $catName',
          message:
              'Your $catName spending is ${(changeRatio * 100).toStringAsFixed(0)}% '
              'higher than last month (\$${currAmount.toStringAsFixed(0)} vs '
              '\$${prevAmount.toStringAsFixed(0)}).',
          category: catName,
          amount: currAmount - prevAmount,
          generatedAt: now,
          metadata: {'categoryId': catId},
        ));
      }
    }

    // Look for single large transactions (>3× average transaction size)
    if (current.isNotEmpty) {
      final totalSingled = current
          .map((e) => (e['amount'] as num).toDouble())
          .fold(0.0, (a, b) => a + b);
      final avg = totalSingled / current.length;

      for (final e in current) {
        final amt = (e['amount'] as num).toDouble();
        if (amt >= avg * 3 && amt >= 50) {
          final cat = (e['expense_categories'] as Map?)?['name'] as String? ??
              'Uncategorized';
          final merchant = (e['merchant'] as String?) ??
              (e['description'] as String?) ??
              'Unknown';
          insights.add(SpendingInsight(
            type: InsightType.anomaly,
            severity: InsightSeverity.info,
            title: 'Large Transaction Detected',
            message:
                'You made a \$${amt.toStringAsFixed(2)} purchase at $merchant '
                '— ${(amt / avg).toStringAsFixed(1)}× your average transaction size.',
            category: cat,
            amount: amt,
            generatedAt: now,
            metadata: {'expenseId': e['id']},
          ));
          break; // report at most one large-tx insight
        }
      }
    }

    return insights;
  }

  // ─── Trend Insights ───────────────────────────────────────────────────────

  List<SpendingInsight> _trendInsights(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> previous,
    DateTime now,
  ) {
    final insights = <SpendingInsight>[];

    final currTotal = _total(current);
    final prevTotal = _total(previous);

    if (prevTotal < 1) return insights;

    final changePct = ((currTotal - prevTotal) / prevTotal) * 100;

    if (changePct <= -15) {
      insights.add(SpendingInsight(
        type: InsightType.trend,
        severity: InsightSeverity.positive,
        title: 'Spending Down ${changePct.abs().toStringAsFixed(0)}%',
        message: 'Great job! You\'ve reduced total spending by '
            '\$${(prevTotal - currTotal).toStringAsFixed(0)} compared to last month.',
        amount: prevTotal - currTotal,
        generatedAt: now,
      ));
    } else if (changePct >= 20) {
      insights.add(SpendingInsight(
        type: InsightType.trend,
        severity: InsightSeverity.warning,
        title: 'Overall Spending Up ${changePct.toStringAsFixed(0)}%',
        message:
            'Your total spending is \$${(currTotal - prevTotal).toStringAsFixed(0)} '
            'higher than last month. Review which categories drove the increase.',
        amount: currTotal - prevTotal,
        generatedAt: now,
      ));
    }

    return insights;
  }

  // ─── Recurring Expense Insights ───────────────────────────────────────────

  List<SpendingInsight> _recurringInsights(
    List<Map<String, dynamic>> expenses,
    DateTime now,
  ) {
    final insights = <SpendingInsight>[];
    final recurring = _findRecurring(expenses);

    if (recurring.isEmpty) return insights;

    final totalRecurring =
        recurring.fold(0.0, (sum, r) => sum + r.estimatedMonthlyAmount);

    insights.add(SpendingInsight(
      type: InsightType.recurring,
      severity: InsightSeverity.info,
      title:
          '${recurring.length} Recurring Expense${recurring.length > 1 ? 's' : ''} Detected',
      message:
          'You have \$${totalRecurring.toStringAsFixed(0)}/month in recurring expenses'
          ' (${recurring.map((r) => r.merchant).join(', ')}).',
      amount: totalRecurring,
      generatedAt: now,
      actionLabel: 'View All',
      metadata: {'recurringCount': recurring.length},
    ));

    return insights;
  }

  // ─── Milestone Insights ───────────────────────────────────────────────────

  List<SpendingInsight> _milestoneInsights(
    List<Map<String, dynamic>> expenses,
    List<Map<String, dynamic>> budgets,
    DateTime startDate,
    DateTime endDate,
    DateTime now,
  ) {
    final insights = <SpendingInsight>[];

    // "Zero overspend" milestone: all budgets within limit
    if (budgets.isNotEmpty) {
      final spendByCat = _groupByCategory(expenses);
      final allWithin = budgets.every((budget) {
        final catId = budget['expense_categories']?['id'] as String?;
        final budgetAmt = (budget['amount'] as num).toDouble();
        final actual = catId != null ? (spendByCat[catId] ?? 0.0) : 0.0;
        return actual <= budgetAmt;
      });

      if (allWithin) {
        insights.add(SpendingInsight(
          type: InsightType.milestone,
          severity: InsightSeverity.positive,
          title: 'All Budgets On Track 🎉',
          message: 'You\'re within budget across all categories this month. '
              'Keep up the great financial discipline!',
          generatedAt: now,
        ));
      }
    }

    return insights;
  }

  // ─── Savings Opportunities ────────────────────────────────────────────────

  /// Identifies categories where the user is overspending relative to their
  /// budget and quantifies how much they could save per month by cutting back
  /// to the budgeted amount.
  List<SpendingInsight> _savingsOpportunities(
    List<Map<String, dynamic>> budgets,
    List<Map<String, dynamic>> expenses,
    DateTime now,
  ) {
    if (budgets.isEmpty) return [];

    final insights = <SpendingInsight>[];
    final spendByCat = _groupByCategory(expenses);

    // Collect over-budget categories sorted by overspend amount
    final opportunities = <Map<String, dynamic>>[];
    for (final budget in budgets) {
      final catId = budget['expense_categories']?['id'] as String?;
      if (catId == null) continue;
      final catName =
          (budget['expense_categories']?['name'] as String?) ?? 'Uncategorized';
      final budgetAmt = (budget['amount'] as num).toDouble();
      final actual = spendByCat[catId] ?? 0.0;
      final overspend = actual - budgetAmt;
      if (overspend > 5) {
        opportunities.add({
          'catName': catName,
          'catId': catId,
          'overspend': overspend,
          'budgetAmt': budgetAmt,
          'actual': actual,
        });
      }
    }

    if (opportunities.isEmpty) return [];

    // Sort by overspend descending; report up to 3
    opportunities.sort((a, b) =>
        (b['overspend'] as double).compareTo(a['overspend'] as double));
    final top = opportunities.take(3).toList();

    final totalSavings =
        top.fold(0.0, (s, o) => s + (o['overspend'] as double));

    for (final op in top) {
      final catName = op['catName'] as String;
      final overspend = op['overspend'] as double;
      final budget = op['budgetAmt'] as double;
      insights.add(SpendingInsight(
        type: InsightType.savingsOpportunity,
        severity: InsightSeverity.info,
        title: 'Save \$${overspend.toStringAsFixed(0)}/mo on $catName',
        message:
            'You\'re spending \$${(op['actual'] as double).toStringAsFixed(0)} '
            'on $catName versus your \$${budget.toStringAsFixed(0)} budget. '
            'Reducing to your budget target could free up '
            '\$${overspend.toStringAsFixed(0)} per month.',
        category: catName,
        amount: overspend,
        actionLabel: 'View Budget',
        generatedAt: now,
        metadata: {'categoryId': op['catId'], 'totalSavings': totalSavings},
      ));
    }

    return insights;
  }

  // ─── Spending Pattern Insights ────────────────────────────────────────────

  /// Highlights how spending is distributed across categories, calling out
  /// concentration risk (top 3 categories dominating) and the single biggest
  /// spend category so the user knows where to focus.
  List<SpendingInsight> _spendingPatternInsights(
    List<Map<String, dynamic>> expenses,
    DateTime now,
  ) {
    if (expenses.isEmpty) return [];

    final insights = <SpendingInsight>[];
    final total = _total(expenses);
    if (total < 1) return [];

    final spendByCat = _groupByCategory(expenses);

    // Build sorted list of (catName, amount)
    final entries = <MapEntry<String, double>>[];
    for (final catId in spendByCat.keys) {
      final name = _categoryName(expenses, catId);
      entries.add(MapEntry(name, spendByCat[catId]!));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) return [];

    // Top category insight
    final topCat = entries.first;
    final topPct = (topCat.value / total * 100).round();
    if (topPct >= 35) {
      insights.add(SpendingInsight(
        type: InsightType.spendingPattern,
        severity: InsightSeverity.info,
        title: '${topCat.key} is $topPct% of Spending',
        message: '\$${topCat.value.toStringAsFixed(0)} — or $topPct% of your '
            'total spending this month — went to ${topCat.key}. '
            'Consider whether this aligns with your financial goals.',
        category: topCat.key,
        amount: topCat.value,
        generatedAt: now,
      ));
    }

    // Concentration risk: top 3 categories vs total
    if (entries.length >= 3) {
      final top3Total = entries.take(3).fold(0.0, (s, e) => s + e.value);
      final top3Pct = (top3Total / total * 100).round();
      if (top3Pct >= 75) {
        final names = entries.take(3).map((e) => e.key).join(', ');
        insights.add(SpendingInsight(
          type: InsightType.spendingPattern,
          severity: InsightSeverity.info,
          title: 'Top 3 Categories = $top3Pct% of Spend',
          message: '$names account for $top3Pct% '
              '(\$${top3Total.toStringAsFixed(0)}) of your total spending. '
              'Diversifying your budget could help reduce financial risk.',
          amount: top3Total,
          generatedAt: now,
        ));
      }
    }

    return insights;
  }

  // ─── Recurring Detection Algorithm ───────────────────────────────────────

  List<RecurringExpense> _findRecurring(List<Map<String, dynamic>> expenses) {
    // Group by normalised merchant name
    final byMerchant = <String, List<Map<String, dynamic>>>{};

    for (final e in expenses) {
      final merchant = _normaliseMerchant(
        (e['merchant'] as String?) ?? (e['description'] as String?) ?? '',
      );
      if (merchant.isEmpty) continue;
      byMerchant.putIfAbsent(merchant, () => []).add(e);
    }

    const minOccurrences = 2;
    final recurring = <RecurringExpense>[];

    for (final entry in byMerchant.entries) {
      final txList = entry.value;
      if (txList.length < minOccurrences) continue;

      // Check that amounts are similar (within 20% of the median)
      final amounts =
          txList.map((e) => (e['amount'] as num).toDouble()).toList()..sort();
      final median = amounts[amounts.length ~/ 2];
      final allSimilar =
          amounts.every((a) => (a - median).abs() / median <= 0.20);

      if (!allSimilar) continue;

      // Check roughly monthly spacing of dates
      final dates = txList
          .map((e) => DateTime.parse(e['date'] as String))
          .toList()
        ..sort();

      if (dates.length >= 2) {
        final gaps = <int>[];
        for (var i = 1; i < dates.length; i++) {
          gaps.add(dates[i].difference(dates[i - 1]).inDays);
        }
        final avgGap = gaps.fold(0, (a, b) => a + b) / gaps.length;

        // Accept weekly (7±3), bi-weekly (14±5), or monthly (30±8)
        final isWeekly = avgGap >= 4 && avgGap <= 10;
        final isBiWeekly = avgGap >= 9 && avgGap <= 19;
        final isMonthly = avgGap >= 22 && avgGap <= 38;

        if (!isWeekly && !isBiWeekly && !isMonthly) continue;

        String period;
        double monthlyAmount;
        if (isWeekly) {
          period = 'Weekly';
          monthlyAmount = median * 4.33;
        } else if (isBiWeekly) {
          period = 'Bi-weekly';
          monthlyAmount = median * 2.17;
        } else {
          period = 'Monthly';
          monthlyAmount = median;
        }

        recurring.add(RecurringExpense(
          merchant: entry.key,
          period: period,
          estimatedAmount: median,
          estimatedMonthlyAmount: monthlyAmount,
          lastSeen: dates.last,
          occurrences: txList.length,
          categoryName:
              (txList.first['expense_categories'] as Map?)?['name'] as String?,
        ));
      }
    }

    // Sort by monthly amount descending
    recurring.sort(
        (a, b) => b.estimatedMonthlyAmount.compareTo(a.estimatedMonthlyAmount));
    return recurring;
  }

  // ─── Data Helpers ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchExpenses(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _supabase
          .from('expenses')
          .select(
              'id, amount, date, merchant, description, category_id, expense_categories(id, name)')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBudgets(String userId) async {
    try {
      return await _supabase
          .from('budgets')
          .select('id, amount, period, expense_categories(id, name)')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);
    } catch (_) {
      return [];
    }
  }

  /// Group expenses by category_id → total amount
  Map<String, double> _groupByCategory(List<Map<String, dynamic>> expenses) {
    final result = <String, double>{};
    for (final e in expenses) {
      final id = (e['category_id'] as String?) ??
          (e['expense_categories'] as Map?)?['id'] as String? ??
          '__none';
      result[id] = (result[id] ?? 0.0) + (e['amount'] as num).toDouble();
    }
    return result;
  }

  String _categoryName(List<Map<String, dynamic>> expenses, String catId) {
    for (final e in expenses) {
      if ((e['category_id'] ?? (e['expense_categories'] as Map?)?['id']) ==
          catId) {
        return (e['expense_categories'] as Map?)?['name'] as String? ??
            'Uncategorized';
      }
    }
    return 'Uncategorized';
  }

  double _total(List<Map<String, dynamic>> expenses) =>
      expenses.fold(0.0, (s, e) => s + (e['amount'] as num).toDouble());

  String _normaliseMerchant(String raw) {
    if (raw.isEmpty) return '';
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  int _severityOrder(InsightSeverity s) {
    switch (s) {
      case InsightSeverity.critical:
        return 0;
      case InsightSeverity.warning:
        return 1;
      case InsightSeverity.info:
        return 2;
      case InsightSeverity.positive:
        return 3;
    }
  }
}

/// A detected recurring expense pattern
class RecurringExpense {
  final String merchant;
  final String period;
  final double estimatedAmount;
  final double estimatedMonthlyAmount;
  final DateTime lastSeen;
  final int occurrences;
  final String? categoryName;

  const RecurringExpense({
    required this.merchant,
    required this.period,
    required this.estimatedAmount,
    required this.estimatedMonthlyAmount,
    required this.lastSeen,
    required this.occurrences,
    this.categoryName,
  });
}
