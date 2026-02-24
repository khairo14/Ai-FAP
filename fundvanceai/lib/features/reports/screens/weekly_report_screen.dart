import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/income/income_provider.dart';
import 'package:fundvanceai/features/goals/goal_provider.dart';
import 'package:fundvanceai/features/debts/debt_provider.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/shared/models/income.dart';
import 'package:fundvanceai/shared/services/report_pdf_service.dart';
import 'package:fundvanceai/shared/services/report_csv_service.dart';
import 'package:fundvanceai/features/premium/premium_provider.dart';
import 'package:fundvanceai/features/premium/screens/paywall_screen.dart';
import 'package:fundvanceai/shared/services/report_insights_service.dart';

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
  int _selectedPeriodIndex =
      0; // 0=this week, 1=last week, 2=this month, 3=custom
  DateTimeRange? _customRange;
  bool _isExporting = false;
  bool _isExportingCsv = false;

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

  // ── CSV export ─────────────────────────────────────────────────────────────
  Future<void> _exportCsv() async {
    setState(() => _isExportingCsv = true);
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final incomeProvider = context.read<IncomeProvider>();
      final period = _buildPeriods()[_selectedPeriodIndex];

      final filteredExpenses = expenseProvider.expenses
          .where((e) =>
              !e.date.isBefore(period.start) && !e.date.isAfter(period.end))
          .toList();

      final filteredIncome = incomeProvider.incomeList
          .where((i) =>
              !i.incomeDate.isBefore(period.start) &&
              !i.incomeDate.isAfter(period.end))
          .toList();

      final csv = ReportCsvService.buildCsv(
        expenses: filteredExpenses,
        income: filteredIncome,
        periodLabel: period.label,
      );

      await Clipboard.setData(ClipboardData(text: csv));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV copied to clipboard '
              '(${filteredExpenses.length} expenses, '
              '${filteredIncome.length} income rows). '
              'Paste into any spreadsheet app.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  List<_ReportPeriod> _buildPeriods() {
    final now = DateTime.now();

    // This week: Monday → today
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekStartMidnight =
        DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day);

    // Last week
    final lastWeekStart =
        thisWeekStartMidnight.subtract(const Duration(days: 7));
    final lastWeekEnd =
        thisWeekStartMidnight.subtract(const Duration(seconds: 1));

    // This month
    final thisMonthStart = DateTime(now.year, now.month);

    final periods = [
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

    if (_customRange != null) {
      final fmt = DateFormat('MMM d');
      periods.add(_ReportPeriod(
        label:
            '${fmt.format(_customRange!.start)} – ${fmt.format(_customRange!.end)}',
        start: _customRange!.start,
        end: DateTime(_customRange!.end.year, _customRange!.end.month,
            _customRange!.end.day, 23, 59, 59),
      ));
    }

    return periods;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: initial,
      helpText: 'Select report period',
      saveText: 'Apply',
    );

    if (picked != null && mounted) {
      setState(() {
        _customRange = picked;
        _selectedPeriodIndex = 3; // switch to custom tab
      });
    }
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
          // ── Custom date range picker ─────────────────────────────────
          IconButton(
            icon: Icon(
              Icons.date_range_outlined,
              color: _selectedPeriodIndex == 3 ? colorScheme.primary : null,
            ),
            tooltip: 'Custom date range',
            onPressed: _pickCustomRange,
          ),
          // ── CSV export button ────────────────────────────────────────
          if (_isExportingCsv)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Consumer<PremiumProvider>(
              builder: (context, premium, _) => IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.table_chart_outlined),
                    if (!premium.isPremium)
                      const Positioned(
                        top: -2,
                        right: -2,
                        child: Icon(Icons.lock_rounded,
                            size: 10, color: Color(0xFFFFB347)),
                      ),
                  ],
                ),
                tooltip:
                    premium.isPremium ? 'Export CSV' : 'Pro Feature — Upgrade',
                onPressed: premium.isPremium
                    ? _exportCsv
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen()),
                        ),
              ),
            ),
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
            Consumer<PremiumProvider>(
              builder: (context, premium, _) => IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined),
                    if (!premium.isPremium)
                      const Positioned(
                        top: -2,
                        right: -2,
                        child: Icon(Icons.lock_rounded,
                            size: 10, color: Color(0xFFFFB347)),
                      ),
                  ],
                ),
                tooltip:
                    premium.isPremium ? 'Export PDF' : 'Pro Feature — Upgrade',
                onPressed: premium.isPremium
                    ? _exportPdf
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen()),
                        ),
              ),
            ),
        ],
      ),
      body: Consumer4<ExpenseProvider, IncomeProvider, GoalProvider,
          DebtProvider>(
        builder: (context, expenseProvider, incomeProvider, goalProvider,
            debtProvider, _) {
          // Initialise providers if not already
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (expenseProvider.expenses.isEmpty &&
                !expenseProvider.isLoading) {
              expenseProvider.initialize();
            }
            if (incomeProvider.incomeList.isEmpty &&
                !incomeProvider.isInitialized) {
              incomeProvider.initialize();
            }
            if (!goalProvider.isInitialized) {
              goalProvider.initialize();
            }
            if (!debtProvider.isInitialized) {
              debtProvider.initialize();
            }
          });

          final expenses = expenseProvider.expenses;
          final incomeList = incomeProvider.incomeList;
          final filtered = expenses
              .where((e) =>
                  !e.date.isBefore(period.start) && !e.date.isAfter(period.end))
              .toList();

          // Prior period (same duration, immediately before)
          final duration = period.end.difference(period.start);
          final priorEnd = period.start.subtract(const Duration(seconds: 1));
          final priorStart = priorEnd.subtract(duration);
          final priorExpenses = expenses
              .where((e) =>
                  !e.date.isBefore(priorStart) && !e.date.isAfter(priorEnd))
              .toList();

          // Income for current and prior period
          final filteredIncome = incomeList
              .where((i) =>
                  !i.incomeDate.isBefore(period.start) &&
                  !i.incomeDate.isAfter(period.end))
              .toList();
          final priorIncome = incomeList
              .where((i) =>
                  !i.incomeDate.isBefore(priorStart) &&
                  !i.incomeDate.isAfter(priorEnd))
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
            children: [
              // ── Period Selector ───────────────────────────────────────
              SegmentedButton<int>(
                segments: [
                  const ButtonSegment(value: 0, label: Text('This Week')),
                  const ButtonSegment(value: 1, label: Text('Last Week')),
                  const ButtonSegment(value: 2, label: Text('This Month')),
                  if (_customRange != null)
                    ButtonSegment(
                      value: 3,
                      label: Text(
                        periods[3].label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selected: {_selectedPeriodIndex},
                onSelectionChanged: (v) {
                  final idx = v.first;
                  if (idx == 3 && _customRange == null) {
                    _pickCustomRange();
                  } else {
                    setState(() => _selectedPeriodIndex = idx);
                  }
                },
              ),
              const SizedBox(height: 20),

              // ── Spending & Income Summary ──────────────────────────────
              _SpendingSummaryCard(expenses: filtered, period: period),
              const SizedBox(height: 16),

              _IncomeSummaryCard(
                income: filteredIncome,
                priorIncome: priorIncome,
                period: period,
              ),
              const SizedBox(height: 16),

              // ── AI Analysis ───────────────────────────────────────────
              _ReportAICard(
                current: filtered,
                prior: priorExpenses,
                currentIncome: filteredIncome,
                priorIncome: priorIncome,
                periodLabel: period.label,
              ),
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

              // ── Debt Snapshot ─────────────────────────────────────────
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

  const _SpendingSummaryCard({required this.expenses, required this.period});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$');
    final total = expenses.fold(0.0, (s, e) => s + e.amount);
    final days = period.end.difference(period.start).inDays + 1;
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

    // Aggregate by category — use the join-populated categoryName on the
    // Expense model so we don't depend on ExpenseProvider._categories being
    // loaded (avoids "Unknown" when the report screen opens independently).
    final Map<String, double> categoryTotals = {};
    final Map<String, String> categoryNames = {};
    for (final e in expenses) {
      final key = e.categoryId ?? 'uncategorized';
      final name = e.categoryName?.isNotEmpty == true
          ? e.categoryName!
          : (e.categoryId != null
              ? expenseProvider.getCategoryName(e.categoryId!)
              : 'Uncategorized');
      categoryTotals[key] = (categoryTotals[key] ?? 0) + e.amount;
      categoryNames[key] = name;
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(5).toList();
    final grandTotal = sorted.fold(0.0, (sum, e) => sum + e.value);

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
              final pct = grandTotal > 0 ? entry.value / grandTotal : 0.0;
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        Text(currency.format(entry.value),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct,
                      borderRadius: BorderRadius.circular(4),
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}% of period spend',
                      style: TextStyle(
                          fontSize: 11, color: colorScheme.onSurfaceVariant),
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

class _IncomeSummaryCard extends StatelessWidget {
  final List<Income> income;
  final List<Income> priorIncome;
  final _ReportPeriod period;

  const _IncomeSummaryCard({
    required this.income,
    required this.priorIncome,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final currencyDec = NumberFormat.currency(symbol: '\$');

    final total = income.fold(0.0, (s, i) => s + i.amount);
    final netTotal = income.fold(0.0, (s, i) => s + i.netAmount);
    final priorTotal = priorIncome.fold(0.0, (s, i) => s + i.amount);

    // Source breakdown
    final bySource = <String, double>{};
    for (final i in income) {
      final src =
          i.categoryName?.isNotEmpty == true ? i.categoryName! : 'Other';
      bySource[src] = (bySource[src] ?? 0) + i.amount;
    }
    final sortedSources = bySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Change vs prior
    final hasPrior = priorTotal > 0;
    final changeIsUp = total > priorTotal;
    final changePct =
        hasPrior ? ((total - priorTotal) / priorTotal * 100).abs() : 0.0;

    if (income.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('${period.label} Income',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('No income recorded',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text('${period.label} Income',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (hasPrior)
                  _ChangeBadge(
                      pct: changePct, isUp: changeIsUp, invertColor: true),
              ],
            ),
            const SizedBox(height: 12),

            // Gross / Net row
            Row(
              children: [
                Expanded(
                  child: _SnapshotStat(
                    label: 'Gross income',
                    value: currency.format(total),
                    color: Colors.green.shade600,
                  ),
                ),
                Expanded(
                  child: _SnapshotStat(
                    label: 'Net (after tax)',
                    value: currencyDec.format(netTotal),
                    color: Colors.teal.shade600,
                  ),
                ),
                Expanded(
                  child: _SnapshotStat(
                    label:
                        '${income.length} record${income.length == 1 ? '' : 's'}',
                    value: '',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Source breakdown (top 3)
            if (sortedSources.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              ...sortedSources.take(3).map((entry) {
                final pct = total > 0 ? entry.value / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          Text(currency.format(entry.value),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct,
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.green.shade400,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                );
              }),
            ],
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

  const _DailyBreakdownCard({required this.expenses, required this.period});

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
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: daily.entries.map((entry) {
                  final barHeight =
                      maxAmt > 0 ? (entry.value / maxAmt) * 90 : 0.0;
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
                              fontSize: 9, color: colorScheme.onSurfaceVariant),
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
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.credit_card_off_outlined, color: colorScheme.error),
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

// ─────────────────────────────────────────────────────────────────────────────
// AI Analysis Card  (synchronous — computes from already-loaded provider data)
// ─────────────────────────────────────────────────────────────────────────────

class _ReportAICard extends StatelessWidget {
  final List<Expense> current;
  final List<Expense> prior;
  final List<Income> currentIncome;
  final List<Income> priorIncome;
  final String periodLabel;

  const _ReportAICard({
    required this.current,
    required this.prior,
    required this.currentIncome,
    required this.priorIncome,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Compute synchronously — no DB round-trip
    final insight = ReportInsightsService().generate(
      current: current,
      prior: prior,
      periodLabel: periodLabel,
      currentIncome: currentIncome,
      priorIncome: priorIncome,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('AI Analysis',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (insight.hasPriorData)
                  _ChangeBadge(
                    pct: insight.changeVsPriorPct,
                    isUp: insight.changeIsUp,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Body ───────────────────────────────────────────────────
            if (insight.isEmpty)
              Text(
                'No transactions recorded for this period.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else ...[
              // NLG summary paragraph
              Text(
                insight.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),

              if (insight.observations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                ...insight.observations.map(
                  (obs) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      obs,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Period-over-period badge ──────────────────────────────────────────────────

class _ChangeBadge extends StatelessWidget {
  final double pct;
  final bool isUp;

  /// When true, "up" is green (good) — used for income. Default false (expenses: up = bad).
  final bool invertColor;

  const _ChangeBadge(
      {required this.pct, required this.isUp, this.invertColor = false});

  @override
  Widget build(BuildContext context) {
    final bad = invertColor ? !isUp : isUp;
    final color = bad ? Colors.red.shade600 : Colors.green.shade600;
    final bg = bad ? Colors.red.shade50 : Colors.green.shade50;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '${pct.toStringAsFixed(0)}% vs prior',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
