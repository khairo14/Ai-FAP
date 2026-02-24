import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/debts/debt_provider.dart';
import 'package:fundvanceai/features/debts/screens/debt_form_screen.dart';
import 'package:fundvanceai/shared/models/debt.dart';
import 'package:fundvanceai/shared/services/debt_service.dart';
import 'package:fundvanceai/features/debts/widgets/debt_ai_card.dart';
import 'package:fundvanceai/features/accounts/account_provider.dart';
import 'package:fundvanceai/features/home/home_provider.dart';

class DebtDetailScreen extends StatefulWidget {
  final Debt debt;
  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen>
    with SingleTickerProviderStateMixin {
  final DebtService _service = DebtService();
  late TabController _tabController;
  List<DebtPayment> _payments = [];
  bool _loadingPayments = true;
  late Debt _debt;

  // Simulator state
  double _extraPayment = 0;
  PayoffSimulation? _snowball;
  PayoffSimulation? _avalanche;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _tabController = TabController(length: 3, vsync: this);
    _loadPayments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ap = context.read<AccountProvider>();
      if (ap.accounts.isEmpty) ap.loadAccounts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _loadingPayments = true);
    try {
      _payments = await _service.getPayments(_debt.id);
    } catch (_) {}
    if (mounted) setState(() => _loadingPayments = false);
  }

  Future<void> _deletePayment(String paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text(
            'Remove this payment record? The debt balance will be updated.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok =
        await context.read<DebtProvider>().deletePayment(paymentId, _debt.id);
    if (!mounted) return;
    if (ok) {
      _syncDebt();
      await _loadPayments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete payment')),
      );
    }
  }

  void _syncDebt() {
    final provider = context.read<DebtProvider>();
    final updated = provider.debts.firstWhere(
      (d) => d.id == _debt.id,
      orElse: () => _debt,
    );
    if (mounted) setState(() => _debt = updated);
  }

  void _runSimulation() {
    final allDebts = context.read<DebtProvider>().activeDebts;
    setState(() {
      _snowball = _service.simulate(
        debts: allDebts,
        extraMonthlyPayment: _extraPayment,
        strategy: 'snowball',
      );
      _avalanche = _service.simulate(
        debts: allDebts,
        extraMonthlyPayment: _extraPayment,
        strategy: 'avalanche',
      );
    });
  }

  Future<void> _showPaymentDialog() async {
    final amountCtrl =
        TextEditingController(text: _debt.minimumPayment.toStringAsFixed(2));
    final notesCtrl = TextEditingController();
    String? selectedAccountId;

    await showDialog(
      context: context,
      builder: (ctx) {
        final accounts = context.read<AccountProvider>().activeAccounts;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Record Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance: ${NumberFormat.currency(symbol: '\$').format(_debt.currentBalance)}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount *',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Pay from account ──────────────────────────────────
                  DropdownButtonFormField<String?>(
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Pay from account',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No account / untracked'),
                      ),
                      ...accounts.map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            '${a.name}  ·  '
                            '\$${a.currentBalance.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedAccountId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;
                  Navigator.pop(ctx);

                  final success =
                      await context.read<DebtProvider>().recordPayment(
                            debtId: _debt.id,
                            amount: amount,
                            accountId: selectedAccountId,
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          );

                  if (success && mounted) {
                    _syncDebt();
                    _loadPayments();
                    // Refresh account balances if an account was used
                    if (selectedAccountId != null) {
                      context.read<AccountProvider>().loadAccounts();
                    }
                    // Refresh dashboard totals
                    context
                        .read<HomeProvider>()
                        .loadDashboardData(showLoading: false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment recorded!')),
                    );
                  }
                },
                child: const Text('Record'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editDebt() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DebtFormScreen(debt: _debt)),
    );
    if (result == true) _syncDebt();
  }

  Future<void> _deleteDebt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Debt'),
        content: const Text('Delete this debt record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<DebtProvider>().deleteDebt(_debt.id);
      if (success && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(_debt.name),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined), onPressed: _editDebt),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteDebt,
              color: colorScheme.error),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Payments'),
            Tab(text: 'Payoff Calc'),
          ],
        ),
      ),
      floatingActionButton: _debt.isPaidOff
          ? null
          : FloatingActionButton.extended(
              onPressed: _showPaymentDialog,
              icon: const Icon(Icons.payment),
              label: const Text('Record Payment'),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Overview ─────────────────────────────────────────────
          _OverviewTab(debt: _debt, currency: currency),

          // ── Tab 2: Payment History ───────────────────────────────────────
          _PaymentHistoryTab(
            payments: _payments,
            loading: _loadingPayments,
            currency: currency,
            onDelete: _deletePayment,
          ),

          // ── Tab 3: Payoff Calculator ─────────────────────────────────────
          _PayoffCalcTab(
            debt: _debt,
            initialExtra: _extraPayment,
            snowball: _snowball,
            avalanche: _avalanche,
            onRun: (extra) {
              setState(() => _extraPayment = extra);
              _runSimulation();
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Debt debt;
  final NumberFormat currency;

  const _OverviewTab({required this.debt, required this.currency});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = debt.progressPercent.clamp(0.0, 1.0);
    final allActiveDebts = context.watch<DebtProvider>().activeDebts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Progress card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        color: Colors.green,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(debt.debtType.icon,
                              size: 28, color: colorScheme.error),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(currency.format(debt.currentBalance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        )),
                Text('remaining of ${currency.format(debt.totalAmount)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                if (debt.isPaidOff) ...[
                  const SizedBox(height: 8),
                  const Chip(
                    label: Text('Paid Off!'),
                    avatar:
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Details
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _Row('Type', debt.debtType.label, Icons.category_outlined),
                _Row('APR', '${debt.interestRate.toStringAsFixed(2)}%',
                    Icons.percent),
                _Row(
                    'Monthly Interest',
                    currency.format(debt.monthlyInterestCharge),
                    Icons.trending_up),
                _Row(
                    'Min. Payment',
                    '${currency.format(debt.minimumPayment)}/mo',
                    Icons.payments_outlined),
                if (debt.paymentDueDay != null)
                  _Row('Due Day', 'Day ${debt.paymentDueDay}',
                      Icons.event_outlined),
                if (debt.description != null)
                  _Row('Description', debt.description!, Icons.notes_outlined),
                if (debt.notes != null)
                  _Row('Notes', debt.notes!, Icons.sticky_note_2_outlined),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // AI Coaching card
        DebtAICard(debt: debt, allActiveDebts: allActiveDebts),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Row(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Flexible(
                  child: Text(value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaymentHistoryTab extends StatelessWidget {
  final List<DebtPayment> payments;
  final bool loading;
  final NumberFormat currency;
  final Future<void> Function(String paymentId) onDelete;

  const _PaymentHistoryTab({
    required this.payments,
    required this.loading,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('No payments yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: payments.length,
      itemBuilder: (context, i) {
        final p = payments[i];
        return Dismissible(
          key: ValueKey(p.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            await onDelete(p.id);
            // Return false — the widget rebuilds via setState in the parent
            return false;
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                child: const Icon(Icons.check, color: Colors.green),
              ),
              title: Text(currency.format(p.amount),
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat.yMMMMd().format(p.paidAt)),
              trailing: p.notes != null
                  ? Tooltip(
                      message: p.notes!,
                      child: const Icon(Icons.notes, size: 16))
                  : null,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PayoffCalcTab extends StatefulWidget {
  final Debt debt;
  final double initialExtra;
  final PayoffSimulation? snowball;
  final PayoffSimulation? avalanche;
  final void Function(double extra) onRun;

  const _PayoffCalcTab({
    required this.debt,
    required this.initialExtra,
    required this.snowball,
    required this.avalanche,
    required this.onRun,
  });

  @override
  State<_PayoffCalcTab> createState() => _PayoffCalcTabState();
}

class _PayoffCalcTabState extends State<_PayoffCalcTab> {
  late final TextEditingController _extraCtrl;

  @override
  void initState() {
    super.initState();
    _extraCtrl =
        TextEditingController(text: widget.initialExtra.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Extra Monthly Payment',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'When you pay more than minimums, the Snowball and Avalanche strategies show different payoff paths across all your debts.',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _extraCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Extra \$/month',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    final extra = double.tryParse(_extraCtrl.text.trim()) ?? 0;
                    widget.onRun(extra);
                  },
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calculate'),
                ),
              ],
            ),
          ),
        ),
        if (widget.snowball != null && widget.avalanche != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StrategyCard(
                  title: '❄️ Snowball',
                  subtitle: 'Smallest balance first',
                  simulation: widget.snowball!,
                  currency: currency,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StrategyCard(
                  title: '🌊 Avalanche',
                  subtitle: 'Highest interest first',
                  simulation: widget.avalanche!,
                  currency: currency,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comparison',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _CompRow(
                    label: 'Months to payoff',
                    snowballValue: '${widget.snowball!.totalMonths} mo',
                    avalancheValue: '${widget.avalanche!.totalMonths} mo',
                    avalancheWins: widget.avalanche!.totalMonths <=
                        widget.snowball!.totalMonths,
                  ),
                  _CompRow(
                    label: 'Total interest paid',
                    snowballValue:
                        currency.format(widget.snowball!.totalInterestPaid),
                    avalancheValue:
                        currency.format(widget.avalanche!.totalInterestPaid),
                    avalancheWins: widget.avalanche!.totalInterestPaid <=
                        widget.snowball!.totalInterestPaid,
                  ),
                  const Divider(),
                  Text(
                    widget.avalanche!.totalInterestPaid <
                            widget.snowball!.totalInterestPaid
                        ? '💡 Avalanche saves ${currency.format(widget.snowball!.totalInterestPaid - widget.avalanche!.totalInterestPaid)} in interest — best for minimizing cost.'
                        : '💡 Snowball keeps motivation high by eliminating small debts first.',
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final PayoffSimulation simulation;
  final NumberFormat currency;
  final Color color;

  const _StrategyCard({
    required this.title,
    required this.subtitle,
    required this.simulation,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Text('${simulation.totalMonths} months',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              currency.format(simulation.totalInterestPaid),
              style: TextStyle(color: color, fontSize: 13),
            ),
            Text('interest paid',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _CompRow extends StatelessWidget {
  final String label;
  final String snowballValue;
  final String avalancheValue;
  final bool avalancheWins;

  const _CompRow({
    required this.label,
    required this.snowballValue,
    required this.avalancheValue,
    required this.avalancheWins,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ValueChip(
                  label: '❄️ $snowballValue',
                  winner: !avalancheWins,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ValueChip(
                  label: '🌊 $avalancheValue',
                  winner: avalancheWins,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String label;
  final bool winner;

  const _ValueChip({required this.label, required this.winner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: winner
            ? Colors.green.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: winner ? Border.all(color: Colors.green, width: 1) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: winner ? FontWeight.bold : FontWeight.normal,
          color: winner ? Colors.green : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
