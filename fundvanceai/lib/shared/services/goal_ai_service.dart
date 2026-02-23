import '../models/goal.dart';
import '../models/income.dart';
import '../models/expense.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class GoalAIInsight {
  /// Average net income per month over last 3 months.
  final double avgMonthlyIncome;

  /// Average expenses per month over last 3 months.
  final double avgMonthlyExpenses;

  /// Estimated monthly surplus (income - expenses).
  final double estimatedSurplus;

  /// Required monthly contribution to reach target by targetDate.
  /// Null if no targetDate is set.
  final double? requiredMonthlyContribution;

  /// Months remaining until target date (null if no target date).
  final int? monthsToTarget;

  /// True when the user hasn't contributed in 30+ days and goal is incomplete.
  final bool isAtRisk;

  /// Days since the last contribution (999 if never contributed).
  final int daysSinceLastContribution;

  /// Amount the user is behind the required pace.
  final double behindPaceAmount;

  /// Milestone label when hitting 25/50/75/100%.
  final String? milestoneLabel;

  /// True when estimated surplus >= required monthly contribution.
  final bool surplusCoversContribution;

  /// Suggested catch-up amount this month to get back on pace.
  final double catchUpThisMonth;

  const GoalAIInsight({
    required this.avgMonthlyIncome,
    required this.avgMonthlyExpenses,
    required this.estimatedSurplus,
    this.requiredMonthlyContribution,
    this.monthsToTarget,
    required this.isAtRisk,
    required this.daysSinceLastContribution,
    required this.behindPaceAmount,
    this.milestoneLabel,
    required this.surplusCoversContribution,
    required this.catchUpThisMonth,
  });

  /// Short headline describing the pacing status.
  String get pacingHeadline {
    if (requiredMonthlyContribution == null) {
      return estimatedSurplus > 0
          ? 'You have ~\$${estimatedSurplus.toStringAsFixed(0)}/mo surplus to save'
          : 'Set a target date to get a pacing plan';
    }
    if (surplusCoversContribution) {
      return 'You can comfortably contribute \$${requiredMonthlyContribution!.toStringAsFixed(0)}/mo';
    }
    return 'Contribution needed: \$${requiredMonthlyContribution!.toStringAsFixed(0)}/mo';
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class GoalAIService {
  /// Analyse a goal and return structured AI insights.
  GoalAIInsight analyze({
    required Goal goal,
    required List<Income> recentIncome,
    required List<Expense> recentExpenses,
    required List<GoalContribution> contributions,
  }) {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    // ── Monthly averages ────────────────────────────────────────────────────
    final monthlyIncome = _avgMonthly(
      recentIncome
          .where((i) => i.incomeDate.isAfter(threeMonthsAgo))
          .map((i) => i.netAmount)
          .toList(),
    );

    final monthlyExpenses = _avgMonthly(
      recentExpenses
          .where((e) => e.date.isAfter(threeMonthsAgo))
          .map((e) => e.amount)
          .toList(),
    );

    final surplus = monthlyIncome - monthlyExpenses;

    // ── Pacing ──────────────────────────────────────────────────────────────
    double? requiredMonthly;
    int? monthsToTarget;

    if (goal.targetDate != null && !goal.isCompleted) {
      final diff = goal.targetDate!.difference(now);
      final months = (diff.inDays / 30.0).ceil();
      monthsToTarget = months <= 0 ? 0 : months;

      if (months > 0 && goal.remainingAmount > 0) {
        requiredMonthly = goal.remainingAmount / months;
      }
    }

    // ── Risk check ──────────────────────────────────────────────────────────
    int daysSinceLast = 999;
    if (contributions.isNotEmpty) {
      final latest = contributions
          .map((c) => c.contributedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      daysSinceLast = now.difference(latest).inDays;
    }
    final isAtRisk = !goal.isCompleted && daysSinceLast > 30;

    // ── Behind-pace calculation ─────────────────────────────────────────────
    double behindPace = 0;
    double catchUp = 0;
    if (requiredMonthly != null) {
      // How much should have been saved from creation to today?
      final elapsed = now.difference(goal.createdAt).inDays / 30.0;
      final expectedSoFar = requiredMonthly * elapsed;
      final deficit = expectedSoFar - goal.currentAmount;
      if (deficit > 0) {
        behindPace = deficit;
        catchUp = (requiredMonthly + deficit / (monthsToTarget ?? 1))
            .clamp(0, double.infinity);
      }
    }

    // ── Milestone label ─────────────────────────────────────────────────────
    final pct = goal.progressPercent * 100;
    String? milestone;
    if (goal.isCompleted || pct >= 100) {
      milestone = '🎉 Goal complete! Fantastic discipline.';
    } else if (pct >= 75) {
      milestone = '🏆 75% there — the finish line is close!';
    } else if (pct >= 50) {
      milestone = '💪 Halfway there — keep the momentum going!';
    } else if (pct >= 25) {
      milestone = '🌱 25% reached — a great start!';
    }

    // ── Surplus covers required? ────────────────────────────────────────────
    final covers =
        requiredMonthly != null ? surplus >= requiredMonthly : surplus > 0;

    return GoalAIInsight(
      avgMonthlyIncome: monthlyIncome,
      avgMonthlyExpenses: monthlyExpenses,
      estimatedSurplus: surplus,
      requiredMonthlyContribution: requiredMonthly,
      monthsToTarget: monthsToTarget,
      isAtRisk: isAtRisk,
      daysSinceLastContribution: daysSinceLast,
      behindPaceAmount: behindPace,
      milestoneLabel: milestone,
      surplusCoversContribution: covers,
      catchUpThisMonth: catchUp,
    );
  }

  /// Suggest a target amount for a new goal based on type and monthly expenses.
  double suggestTarget(GoalType type, double avgMonthlyExpenses) {
    switch (type) {
      case GoalType.emergencyFund:
        // 3–6 months of expenses; recommend 6 for safety
        return (avgMonthlyExpenses * 6).ceilToDouble();
      case GoalType.savings:
        return (avgMonthlyExpenses * 3).ceilToDouble();
      case GoalType.investment:
        return (avgMonthlyExpenses * 12).ceilToDouble();
      case GoalType.purchase:
        return (avgMonthlyExpenses * 2).ceilToDouble();
      case GoalType.debtPayoff:
        return 0; // user should enter actual debt balance
    }
  }

  /// Explanation for why we suggest that target.
  String suggestTargetReason(GoalType type, double avgMonthlyExpenses) {
    switch (type) {
      case GoalType.emergencyFund:
        return 'Based on your avg monthly expenses of \$${avgMonthlyExpenses.toStringAsFixed(0)}, '
            '6 months of coverage is the recommended emergency cushion.';
      case GoalType.savings:
        return 'A 3-month savings buffer based on your monthly spending.';
      case GoalType.investment:
        return 'A 12-month equivalent gives a meaningful investment base.';
      case GoalType.purchase:
        return 'Roughly 2 months of expenses as a starting purchase budget.';
      case GoalType.debtPayoff:
        return 'Enter the actual outstanding balance of the debt you want to pay off.';
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Average monthly amount from a flat list of amounts over ~3 months.
  double _avgMonthly(List<double> amounts) {
    if (amounts.isEmpty) return 0;
    final total = amounts.fold(0.0, (s, a) => s + a);
    return total / 3.0; // always divide by 3 months window
  }
}
