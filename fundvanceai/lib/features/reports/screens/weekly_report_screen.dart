import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/goals/goal_provider.dart';
import 'package:fundvanceai/features/debts/debt_provider.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/shared/services/report_pdf_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a weekly or monthly report
// ─────────────────────────────────────────────────────────────────────────────

class _ReportPeriod {
  final String label;
  final DateTime start;
  final DateTime end;

  const _ReportPeriod(
      {required this.label, required this.start, required this.end});
}

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  int _selectedPeriodIndex = 0; // 0 = this week, 1 = last week, 2 = this month
  bool _isExporting = false;

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final goalProvider = context.read<GoalProvider>();
      final debtProvider = context.read<DebtProvider>();
      final period = _buildPeriods()[_selectedPeriodIndex];

      final filtered = expenseProvider.expenses
          .where((e) =>
              !e.date.isBefore(period.start) && !e.date.isAfter(period.end))
          .toList();

      // Category totals: name → total amount
      final Map<String, double> categoryTotals = {};
      for (final e in filtered) {
        final name = e.categoryId != null
            ? expenseProvider.getCategoryName(e.categoryId!)
            : 'Uncategorized';
        categoryTotals[name] = (categoryTotals[name] ?? 0) + e.amount;
      }

      // Daily totals: 'Mon, MMM d' → total amount
      final Map<String, double> dailyTotals = {};
      for (final e in filtered) {
        final key = DateFormat('EEE, MMM d').format(e.date);
        dailyTotals[key] = (dailyTotals[key] ?? 0) + e.amount;
      }

      final data = ReportData(
        periodLabel: period.label,
        periodStart: period.start,
        periodEnd: period.end,
        totalSpending: filtered.fold(0.0, (s, e) => s + e.amount),
        transactionCount: filtered.length,
        categoryTotals: categoryTotals,
        dailyTotals: dailyTotals,
        activeGoals: goalProvider.activeGoals.length,
        totalSaved: goalProvider.totalSaved,
        totalGoalTarget: goalProvider.totalTargetAmount,
        completedGoals: goalProvider.completedGoals.length,
        activeDebts: debtProvider.activeDebts.length,
        totalDebtBalance: debtProvider.totalBalance,
        totalMinimumPayments: debtProvider.totalMinimumPayments,
        totalMonthlyInterest: debtProvider.totalMonthlyInterest,
      );

      await ReportPdfService.shareReport(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  List<_ReportPeriod> _buildPeriods() {
    final now = DateTime.now();

    // This week: Monday → today
    final thisWeekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final thisWeekStartMidnight =
        DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day);

    // Last week
    final lastWeekStart =
        thisWeekStartMidnight.subtract(const Duration(days: 7));
    final lastWeekEnd =
        thisWeekStartMidnight.subtract(const Duration(seconds: 1));

    // This month
    final thisMonthStart = DateTime(now.year, now.month);

    return [
      _ReportPeriod(
        label: 'This Week',
        start: thisWeekStartMidnight,
        end: now,
      ),
      _ReportPeriod(
        label: 'Last Week',
        start: lastWeekStart,
        end: lastWeekEnd,
      ),
      _ReportPeriod(
        label: 'This Month',
        start: thisMonthStart,
        end: now,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final periods = _buildPeriods();
    final period = periods[_selectedPeriodIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: colorScheme.surface,
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: Consumer3<ExpenseProvider, GoalProvider, DebtProvider>(
        builder: (context, expenseProvider, goalProvider, debtProvider, _) {
          // Initialise providers if not already
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (expenseProvider.expenses.isEmpty && !expenseProvider.isLoading) expenseProvider.initialize();
            if (!goalProvider.isInitialized) goalProvider.initialize();
            if (!debtProvider.isInitialized) debtProvider.initialize();
          });

          final expenses = expenseProvider.expenses;
          final filtered = expenses
              .where((e) =>
                  !e.date.isBefore(period.start) &&
                  !e.date.isAfter(period.end))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
            children: [
              // ── Period Selector ───────────────────────────────────────
              SegmentedButton<int>(
                segments: List.generate(
                  periods.length,
                  (i) => ButtonSegment(
                      value: i, label: Text(periods[i].label)),
                ),
                selected: {_selectedPeriodIndex},
                onSelectionChanged: (v) =>
                    setState(() => _selectedPeriodIndex = v.first),
              ),
              const SizedBox(height: 20),

              // ── Spending Summary ──────────────────────────────────────
              _SpendingSummaryCard(expenses: filtered, period: period),
              const SizedBox(height: 16),

              // ── Top Categories ────────────────────────────────────────
              _TopCategoriesCard(
                  expenses: filtered, expenseProvider: expenseProvider),
              const SizedBox(height: 16),

              // ── Daily Spending Breakdown ──────────────────────────────
              _DailyBreakdownCard(expenses: filtered, period: period),
              const SizedBox(height: 16),

              // ── Goals Snapshot ────────────────────────────────────────
              _GoalsSnapshotCard(
                  active: goalProvider.activeGoals.length,
                  totalSaved: goalProvider.totalSaved,
                  totalTarget: goalProvider.totalTargetAmount,
                  completed: goalProvider.completedGoals.length),
              const SizedBox(height: 16),

              // ── Debt Snapshot ────────────────────────────────────────
              if (debtProvider.activeDebts.isNotEmpty)
                _DebtSnapshotCard(
                  totalBalance: debtProvider.totalBalance,
                  totalMinimum: debtProvider.totalMinimumPayments,
                  totalInterest: debtProvider.totalMonthlyInterest,
                  count: debtProvider.activeDebts.length,
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SpendingSummaryCard extends StatelessWidget {
  final List<Expense> expenses;
  final _ReportPeriod period;

  const _SpendingSummaryCard(
      {required this.expenses, required this.period});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$');
    final total = expenses.fold(0.0, (s, e) => s + e.amount);
    final days =
        period.end.difference(period.start).inDays + 1;
    final daily = days > 0 ? total / days : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${period.label} Spending',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              currency.format(total),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SummaryChip(
                  label: '${expenses.length} transactions',
                  icon: Icons.receipt_outlined,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: '${currency.format(daily)}/day avg',
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SummaryChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TopCategoriesCard extends StatelessWidget {
  final List<Expense> expenses;
  final ExpenseProvider expenseProvider;

  const _TopCategoriesCard(
      {required this.expenses, required this.expenseProvider});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Aggregate by category
    final Map<String, double> categoryTotals = {};
    final Map<String, String> categoryNames = {};
    for (final e in expenses) {
      if (e.categoryId != null) {
        categoryTotals[e.categoryId!] =
            (categoryTotals[e.categoryId!] ?? 0) + e.amount;
        categoryNames[e.categoryId!] =
            expenseProvider.getCategoryName(e.categoryId!);
      } else {
        categoryTotals['uncategorized'] =
            (categoryTotals['uncategorized'] ?? 0) + e.amount;
        categoryNames['uncategorized'] = 'Uncategorized';
      }
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(5).toList();
    final grandTotal =
        sorted.fold(0.0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Categories',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...top.map((entry) {
              final pct =
                  grandTotal > 0 ? entry.value / grandTotal : 0.0;
              final name = categoryNames[entry.key] ?? 'Other';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        Text(currency.format(entry.value),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct,
                      borderRadius: BorderRadius.circular(4),
                      color: colorScheme.primary,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest,
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}% of period spend',
                      style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DailyBreakdownCard extends StatelessWidget {
  final List<Expense> expenses;
  final _ReportPeriod period;

  const _DailyBreakdownCard(
      {required this.expenses, required this.period});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Aggregate by day
    final Map<String, double> daily = {};
    for (final e in expenses) {
      final key = DateFormat('EEE\nMMM d').format(e.date);
      daily[key] = (daily[key] ?? 0) + e.amount;
    }
    if (daily.isEmpty) return const SizedBox.shrink();

    final maxAmt = daily.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Spending',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: daily.entries.map((entry) {
                  final barHeight = maxAmt > 0
                      ? (entry.value / maxAmt) * 100
                      : 0.0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(currency.format(entry.value),
                          style: TextStyle(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Container(
                        width: 28,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.key,
                          style: TextStyle(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GoalsSnapshotCard extends StatelessWidget {
  final int active;
  final double totalSaved;
  final double totalTarget;
  final int completed;

  const _GoalsSnapshotCard({
    required this.active,
    required this.totalSaved,
    required this.totalTarget,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final pct = totalTarget > 0 ? totalSaved / totalTarget : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Goals Snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SnapshotStat(
                  label: 'Active',
                  value: '$active',
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                _SnapshotStat(
                  label: 'Completed',
                  value: '$completed',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _SnapshotStat(
                  label: 'Total Saved',
                  value: currency.format(totalSaved),
                  color: colorScheme.secondary,
                ),
              ],
            ),
            if (totalTarget > 0) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                borderRadius: BorderRadius.circular(4),
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 4),
              Text(
                '${(pct * 100).toStringAsFixed(0)}% of ${currency.format(totalTarget)} target',
                style: TextStyle(
                    fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SnapshotStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SnapshotStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DebtSnapshotCard extends StatelessWidget {
  final double totalBalance;
  final double totalMinimum;
  final double totalInterest;
  final int count;

  const _DebtSnapshotCard({
    required this.totalBalance,
    required this.totalMinimum,
    required this.totalInterest,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card_off_outlined,
                    color: colorScheme.error),
                const SizedBox(width: 8),
                Text('Debt Snapshot',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SnapshotStat(
                  label: '$count debts',
                  value: currency.format(totalBalance),
                  color: colorScheme.error,
                ),
                const SizedBox(width: 16),
                _SnapshotStat(
                  label: 'min/month',
                  value: currency.format(totalMinimum),
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _SnapshotStat(
                  label: 'interest/mo',
                  value: currency.format(totalInterest),
                  color: Colors.deepOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
