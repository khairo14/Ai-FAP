import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/shared/models/income.dart';
import 'package:intl/intl.dart';

/// Generates an AI narrative + observations for an arbitrary report period.
///
/// Fully on-device — computes from already-loaded Expense and Income lists,
/// no additional Supabase queries required.
class ReportInsightsService {
  ReportInsight generate({
    required List<Expense> current,
    required List<Expense> prior,
    required String periodLabel,
    List<Income> currentIncome = const [],
    List<Income> priorIncome = const [],
  }) {
    final incomeTotal = currentIncome.fold<double>(0.0, (s, i) => s + i.amount);
    final priorIncomeTotal =
        priorIncome.fold<double>(0.0, (s, i) => s + i.amount);

    if (current.isEmpty && incomeTotal == 0) return ReportInsight.empty();

    // ── Aggregate ────────────────────────────────────────────────────────────

    final currTotal = current.fold<double>(0.0, (s, e) => s + e.amount);
    final prevTotal = prior.fold<double>(0.0, (s, e) => s + e.amount);

    final txCount = current.length;
    final avgTx = txCount > 0 ? currTotal / txCount : 0.0;

    // Category breakdown → sorted descending
    final catTotals = <String, double>{};
    for (final e in current) {
      final cat = e.categoryName?.isNotEmpty == true
          ? e.categoryName!
          : 'Uncategorized';
      catTotals[cat] = (catTotals[cat] ?? 0.0) + e.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Busiest spending day
    final dailyTotals = <String, double>{};
    for (final e in current) {
      final day = DateFormat('yyyy-MM-dd').format(e.date);
      dailyTotals[day] = (dailyTotals[day] ?? 0.0) + e.amount;
    }
    String? busiestDay;
    double busiestAmt = 0;
    for (final entry in dailyTotals.entries) {
      if (entry.value > busiestAmt) {
        busiestAmt = entry.value;
        busiestDay = entry.key;
      }
    }

    // Top merchant by amount
    final merchantTotals = <String, double>{};
    for (final e in current) {
      final m = e.merchant?.trim();
      if (m != null && m.isNotEmpty) {
        merchantTotals[m] = (merchantTotals[m] ?? 0.0) + e.amount;
      }
    }
    String? topMerchant;
    double topMerchantAmt = 0;
    if (merchantTotals.isNotEmpty) {
      final sorted = merchantTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topMerchant = sorted.first.key;
      topMerchantAmt = sorted.first.value;
    }

    // Period-over-period change (expenses)
    double changePct = 0;
    bool changeIsUp = false;
    final hasPrior = prevTotal > 0;
    if (hasPrior) {
      changePct = ((currTotal - prevTotal) / prevTotal * 100).abs();
      changeIsUp = currTotal > prevTotal;
    }

    // Net cashflow
    final hasCashflow = incomeTotal > 0;
    final netCashflow = incomeTotal - currTotal;

    // Category concentration — is top cat > 50% of spend?
    bool isConcentrated = false;
    if (sortedCats.isNotEmpty && currTotal > 0) {
      isConcentrated = sortedCats.first.value / currTotal > 0.50;
    }

    // ── NLG ───────────────────────────────────────────────────────────────

    final fmt = NumberFormat('#,##0.00');
    final observations = <String>[];

    // Summary sentence
    final String summary;
    if (current.isEmpty && incomeTotal > 0) {
      summary =
          'During $periodLabel you received \$${fmt.format(incomeTotal)} in income with no recorded expenses.';
    } else {
      final changeSentence = hasPrior
          ? ' That\'s ${changeIsUp ? 'up' : 'down'} ${changePct.toStringAsFixed(0)}% vs the prior period.'
          : '';
      summary =
          'During $periodLabel you made $txCount transaction${txCount == 1 ? '' : 's'} '
          'totalling \$${fmt.format(currTotal)}, averaging \$${fmt.format(avgTx)} each.$changeSentence';
    }

    // Obs 1 — net cashflow (most important, shown first)
    if (hasCashflow) {
      if (netCashflow >= 0) {
        observations.add(
            '💚 Net cashflow: +\$${fmt.format(netCashflow)} — you spent less than you earned this period.');
      } else {
        observations.add(
            '🔴 Net cashflow: −\$${fmt.format(netCashflow.abs())} — expenses exceeded income by \$${fmt.format(netCashflow.abs())}.');
      }
    }

    // Obs 2 — top category
    if (sortedCats.isNotEmpty) {
      final top = sortedCats.first;
      final pct = currTotal > 0
          ? (top.value / currTotal * 100).toStringAsFixed(0)
          : '0';
      observations.add(
          '🏆 ${top.key} was your biggest category at \$${fmt.format(top.value)} ($pct% of spend).');
    }

    // Obs 3 — busiest day
    if (busiestDay != null) {
      final dayFormatted =
          DateFormat('EEEE, MMM d').format(DateTime.parse(busiestDay));
      observations.add(
          '📅 Your busiest spending day was $dayFormatted (\$${fmt.format(busiestAmt)}).');
    }

    // Obs 4 — top merchant
    if (topMerchant != null) {
      observations.add(
          '🏪 You spent the most at $topMerchant (\$${fmt.format(topMerchantAmt)}).');
    }

    // Obs 5 — prior comparison advice
    if (hasPrior) {
      if (!changeIsUp) {
        final saved = prevTotal - currTotal;
        observations.add(
            '✅ You spent \$${fmt.format(saved)} less than the prior period — great work!');
      } else {
        final extra = currTotal - prevTotal;
        final tip =
            sortedCats.isNotEmpty ? sortedCats.first.key : 'your top category';
        observations.add(
            '⚠️ You spent \$${fmt.format(extra)} more than the prior period. Consider trimming $tip.');
      }
    }

    // Obs 6 — income change vs prior
    if (priorIncomeTotal > 0 && incomeTotal > 0) {
      final incomeChangePct =
          ((incomeTotal - priorIncomeTotal) / priorIncomeTotal * 100).abs();
      final incomeUp = incomeTotal > priorIncomeTotal;
      observations.add(
          '${incomeUp ? '📈' : '📉'} Income was ${incomeUp ? 'up' : 'down'} ${incomeChangePct.toStringAsFixed(0)}% vs the prior period (\$${fmt.format(priorIncomeTotal)} → \$${fmt.format(incomeTotal)}).');
    }

    // Obs 7 — concentration warning
    if (isConcentrated && sortedCats.isNotEmpty) {
      final top = sortedCats.first;
      observations.add(
          '💡 Over half your ${periodLabel.toLowerCase()} spending went to ${top.key}. Diversifying could improve budget balance.');
    }

    return ReportInsight(
      summary: summary,
      changeVsPriorPct: changePct,
      changeIsUp: changeIsUp,
      hasPriorData: hasPrior,
      priorTotal: prevTotal,
      currTotal: currTotal,
      incomeTotal: incomeTotal,
      netCashflow: netCashflow,
      observations: observations,
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class ReportInsight {
  final String summary;
  final double changeVsPriorPct;
  final bool changeIsUp;
  final bool hasPriorData;
  final double priorTotal;
  final double currTotal;
  final double incomeTotal;
  final double netCashflow;
  final List<String> observations;

  const ReportInsight({
    required this.summary,
    required this.changeVsPriorPct,
    required this.changeIsUp,
    required this.hasPriorData,
    required this.priorTotal,
    required this.currTotal,
    this.incomeTotal = 0,
    this.netCashflow = 0,
    required this.observations,
  });

  factory ReportInsight.empty() => const ReportInsight(
        summary: '',
        changeVsPriorPct: 0,
        changeIsUp: false,
        hasPriorData: false,
        priorTotal: 0,
        currTotal: 0,
        incomeTotal: 0,
        netCashflow: 0,
        observations: [],
      );

  bool get isEmpty => summary.isEmpty;
}
