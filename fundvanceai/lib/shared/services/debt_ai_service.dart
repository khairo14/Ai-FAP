import 'dart:math' as math;
import '../models/debt.dart';
import 'debt_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models returned by DebtAIService
// ─────────────────────────────────────────────────────────────────────────────

/// Which payoff strategy is recommended and why.
class StrategyRecommendation {
  /// 'avalanche' | 'snowball' | 'tie'
  final String recommended;
  final String headline; // 1-line summary
  final String explanation; // 2-3 sentence plain-English reasoning
  final double interestSavedVsAlternative; // 0 if tie
  final int monthsDifferenceVsAlternative; // avalanche months - snowball months

  const StrategyRecommendation({
    required this.recommended,
    required this.headline,
    required this.explanation,
    required this.interestSavedVsAlternative,
    required this.monthsDifferenceVsAlternative,
  });
}

/// Outcome of adding an extra fixed monthly payment.
class WhatIfResult {
  final double extraPerMonth;
  final int monthsSaved; // vs no extra payment (min only)
  final double interestSaved; // vs no extra payment
  final DateTime projectedPayoffDate; // all debts cleared

  const WhatIfResult({
    required this.extraPerMonth,
    required this.monthsSaved,
    required this.interestSaved,
    required this.projectedPayoffDate,
  });
}

/// Per-debt payoff projection.
class DebtPayoffProjection {
  final DateTime estimatedPayoffDate;
  final int monthsRemaining;
  final double totalInterestRemaining;

  const DebtPayoffProjection({
    required this.estimatedPayoffDate,
    required this.monthsRemaining,
    required this.totalInterestRemaining,
  });
}

/// Income-to-debt insight.
class IncomeDebtInsight {
  final double debtToIncomeRatio; // monthly minimums / monthly income
  final String ratingLabel; // 'Healthy' | 'Moderate' | 'High' | 'Critical'
  final String advice;
  final bool hasSurplus; // monthly income - minimums > 0

  const IncomeDebtInsight({
    required this.debtToIncomeRatio,
    required this.ratingLabel,
    required this.advice,
    required this.hasSurplus,
  });
}

/// Which celebration milestone a debt has crossed.
enum DebtMilestone { none, quarter, half, threeQuarters, paidOff }

// ─────────────────────────────────────────────────────────────────────────────

/// On-device AI coaching for debts. No external API required.
class DebtAIService {
  final DebtService _debtService = DebtService();

  // ── Strategy recommendation ───────────────────────────────────────────────

  /// Compare snowball vs avalanche (both at minimum payments only) and
  /// recommend the mathematically better strategy with a plain-English reason.
  StrategyRecommendation recommendStrategy(List<Debt> activeDebts) {
    if (activeDebts.isEmpty) {
      return const StrategyRecommendation(
        recommended: 'snowball',
        headline: 'Add debts to get a strategy recommendation.',
        explanation: '',
        interestSavedVsAlternative: 0,
        monthsDifferenceVsAlternative: 0,
      );
    }

    if (activeDebts.length == 1) {
      final d = activeDebts.first;
      final projection = _projectSingleDebt(d);
      return StrategyRecommendation(
        recommended: 'direct',
        headline: 'Focus all extra payments on ${d.name}.',
        explanation:
            'You only have one active debt. Pay as much as you can each month '
            'to minimise the total interest paid. At your minimum payment, '
            'you\'ll be debt-free in about ${projection.monthsRemaining} months.',
        interestSavedVsAlternative: 0,
        monthsDifferenceVsAlternative: 0,
      );
    }

    final snowball = _debtService.simulate(
      debts: activeDebts,
      extraMonthlyPayment: 0,
      strategy: 'snowball',
    );
    final avalanche = _debtService.simulate(
      debts: activeDebts,
      extraMonthlyPayment: 0,
      strategy: 'avalanche',
    );

    final interestDiff =
        snowball.totalInterestPaid - avalanche.totalInterestPaid;
    final monthsDiff = snowball.totalMonths - avalanche.totalMonths;

    // Prefer avalanche when it saves meaningful interest (> $10)
    if (interestDiff > 10) {
      final highestDebt = _highestInterestDebt(activeDebts);
      final monthsPart = monthsDiff > 0
          ? 'and clear all debts $monthsDiff month${monthsDiff != 1 ? 's' : ''} sooner'
          : 'over the same timeline';
      return StrategyRecommendation(
        recommended: 'avalanche',
        headline:
            'Avalanche saves you \$${_fmt(interestDiff)} in total interest.',
        explanation: 'The Avalanche method targets your highest-interest debt '
            'first (${highestDebt.name} at '
            '${highestDebt.interestRate.toStringAsFixed(1)}% APR). '
            'Compared to Snowball, you\'ll pay \$${_fmt(interestDiff)} less '
            'in interest $monthsPart.',
        interestSavedVsAlternative: interestDiff,
        monthsDifferenceVsAlternative: monthsDiff,
      );
    }

    // Prefer snowball when savings are small — psychological wins matter
    if (interestDiff.abs() <= 10) {
      final smallestDebt = _smallestBalanceDebt(activeDebts);
      return StrategyRecommendation(
        recommended: 'snowball',
        headline:
            'Snowball keeps motivation high — savings difference is minimal.',
        explanation:
            'Both strategies cost about the same in interest at your current '
            'payment levels. The Snowball method targets ${smallestDebt.name} first '
            '(lowest balance) so you get a quick win, which research shows helps '
            'people stay on track. Choose whichever keeps you motivated.',
        interestSavedVsAlternative: interestDiff.abs(),
        monthsDifferenceVsAlternative: monthsDiff.abs(),
      );
    }

    // Snowball actually wins (rare — can happen with very unequal minimums)
    return StrategyRecommendation(
      recommended: 'snowball',
      headline: 'Snowball is more efficient for your debt mix.',
      explanation:
          'Given your specific balance sizes and minimum payment ratios, '
          'the Snowball strategy pays off your debts slightly faster than Avalanche. '
          'It also gives you quick wins by eliminating small balances first.',
      interestSavedVsAlternative: interestDiff.abs(),
      monthsDifferenceVsAlternative: monthsDiff.abs(),
    );
  }

  // ── What-if extra payment ─────────────────────────────────────────────────

  /// Show how much time and money is saved by adding [extra] per month on top
  /// of minimums, applied using the recommended strategy.
  WhatIfResult whatIfExtraPayment(List<Debt> activeDebts, double extra) {
    final baseline = _debtService.simulate(
      debts: activeDebts,
      extraMonthlyPayment: 0,
      strategy: 'avalanche',
    );
    final boosted = _debtService.simulate(
      debts: activeDebts,
      extraMonthlyPayment: extra,
      strategy: 'avalanche',
    );

    final monthsSaved = baseline.totalMonths - boosted.totalMonths;
    final interestSaved =
        baseline.totalInterestPaid - boosted.totalInterestPaid;
    final payoffDate =
        DateTime.now().add(Duration(days: boosted.totalMonths * 30));

    return WhatIfResult(
      extraPerMonth: extra,
      monthsSaved: monthsSaved.clamp(0, 9999),
      interestSaved: interestSaved.clamp(0.0, double.maxFinite),
      projectedPayoffDate: payoffDate,
    );
  }

  /// Convenience: returns 3 what-if tiers at 25%, 50%, 100% of minimum total.
  List<WhatIfResult> suggestedWhatIfs(List<Debt> activeDebts) {
    if (activeDebts.isEmpty) return [];
    final totalMin = activeDebts.fold(0.0, (s, d) => s + d.minimumPayment);
    final tiers = [
      (totalMin * 0.25).roundToDouble(),
      (totalMin * 0.50).roundToDouble(),
      totalMin.roundToDouble(),
    ];
    return tiers
        .where((t) => t >= 1)
        .map((t) => whatIfExtraPayment(activeDebts, t))
        .toList();
  }

  // ── Per-debt payoff projection ────────────────────────────────────────────

  /// Estimate payoff date + remaining interest for a single debt at minimum payment.
  DebtPayoffProjection projectDebt(Debt debt) {
    return _projectSingleDebt(debt);
  }

  DebtPayoffProjection _projectSingleDebt(Debt debt) {
    final months = _monthsToPaySingleDebt(
      balance: debt.currentBalance,
      annualRate: debt.interestRate,
      monthlyPayment: debt.minimumPayment,
    );

    final totalInterest = _totalInterestSingle(
      balance: debt.currentBalance,
      annualRate: debt.interestRate,
      monthlyPayment: debt.minimumPayment,
      months: months,
    );

    final payoffDate = DateTime.now().add(Duration(days: months * 30));
    return DebtPayoffProjection(
      estimatedPayoffDate: payoffDate,
      monthsRemaining: months,
      totalInterestRemaining: totalInterest,
    );
  }

  // ── Income-aware insight ──────────────────────────────────────────────────

  /// Compare total debt minimum payments against estimated monthly income.
  /// [monthlyNetIncome] can be 0 if user hasn't logged income — advice adapts.
  IncomeDebtInsight incomeInsight(
      List<Debt> activeDebts, double monthlyNetIncome) {
    final totalMin = activeDebts.fold(0.0, (s, d) => s + d.minimumPayment);

    if (monthlyNetIncome <= 0) {
      return IncomeDebtInsight(
        debtToIncomeRatio: 0,
        ratingLabel: 'Unknown',
        advice:
            'Log your monthly income to unlock a personalised debt-to-income '
            'ratio and see how much of your paycheck goes to debt payments.',
        hasSurplus: false,
      );
    }

    final ratio = totalMin / monthlyNetIncome;
    final surplus = monthlyNetIncome - totalMin;
    String label;
    String advice;

    if (ratio < 0.15) {
      label = 'Healthy';
      advice = 'Your debt payments are only ${_pct(ratio)} of your income — '
          'well within healthy limits (under 15%). '
          'Consider directing some of your surplus \$${_fmt(surplus)} toward '
          'an emergency fund or investments.';
    } else if (ratio < 0.30) {
      label = 'Moderate';
      advice =
          'Your minimum payments are ${_pct(ratio)} of your income — manageable '
          'but leaving limited room. Adding even \$${(surplus * 0.2).round()}/month '
          'in extra payments would noticeably speed up your payoff.';
    } else if (ratio < 0.43) {
      label = 'High';
      advice = 'At ${_pct(ratio)} of income, your debt load is high. Financial '
          'advisors recommend keeping this below 36%. Focus on eliminating your '
          'highest-rate debt first — every dollar freed up improves your ratio.';
    } else {
      label = 'Critical';
      advice =
          '${_pct(ratio)} of your income goes to minimum payments — this is a '
          'critical debt burden. Prioritise stopping new debt, then apply any '
          'extra income to the highest-interest balance. Consider seeking '
          'a debt consolidation review.';
    }

    return IncomeDebtInsight(
      debtToIncomeRatio: ratio,
      ratingLabel: label,
      advice: advice,
      hasSurplus: surplus > 0,
    );
  }

  // ── Milestone detection ───────────────────────────────────────────────────

  DebtMilestone getMilestone(Debt debt) {
    if (debt.isPaidOff || debt.progressPercent >= 0.999) {
      return DebtMilestone.paidOff;
    }
    if (debt.progressPercent >= 0.75) return DebtMilestone.threeQuarters;
    if (debt.progressPercent >= 0.50) return DebtMilestone.half;
    if (debt.progressPercent >= 0.25) return DebtMilestone.quarter;
    return DebtMilestone.none;
  }

  String milestoneMessage(DebtMilestone milestone, String debtName) {
    switch (milestone) {
      case DebtMilestone.paidOff:
        return '🎉 $debtName is fully paid off! Amazing work!';
      case DebtMilestone.threeQuarters:
        return '🔥 75% of $debtName paid! The finish line is in sight.';
      case DebtMilestone.half:
        return '⚡ You\'re halfway through $debtName — keep the momentum!';
      case DebtMilestone.quarter:
        return '✅ 25% of $debtName paid — a great start! Stay consistent.';
      case DebtMilestone.none:
        return '';
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  int _monthsToPaySingleDebt({
    required double balance,
    required double annualRate,
    required double monthlyPayment,
  }) {
    if (balance <= 0) return 0;
    if (monthlyPayment <= 0) return 999;
    final r = annualRate / 100 / 12;
    if (r == 0) return (balance / monthlyPayment).ceil().clamp(1, 999);
    final rB = r * balance;
    if (monthlyPayment <= rB) return 999; // payment doesn't cover interest
    final n = -(math.log(1 - rB / monthlyPayment)) / math.log(1 + r);
    return n.ceil().clamp(1, 999);
  }

  double _totalInterestSingle({
    required double balance,
    required double annualRate,
    required double monthlyPayment,
    required int months,
  }) {
    if (months >= 999) return double.infinity;
    final total = monthlyPayment * months;
    return (total - balance).clamp(0.0, double.maxFinite);
  }

  Debt _highestInterestDebt(List<Debt> debts) {
    return debts.reduce((a, b) => a.interestRate > b.interestRate ? a : b);
  }

  Debt _smallestBalanceDebt(List<Debt> debts) {
    return debts.reduce((a, b) => a.currentBalance < b.currentBalance ? a : b);
  }

  String _fmt(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return v.toStringAsFixed(0);
  }

  String _pct(double ratio) => '${(ratio * 100).toStringAsFixed(0)}%';
}
