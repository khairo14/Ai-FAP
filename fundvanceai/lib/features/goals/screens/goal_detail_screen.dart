import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/goals/goal_provider.dart';
import 'package:fundvanceai/features/goals/screens/goal_form_screen.dart';
import 'package:fundvanceai/shared/models/goal.dart';
import 'package:fundvanceai/shared/services/goal_service.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final GoalService _service = GoalService();
  List<GoalContribution> _contributions = [];
  bool _loadingContributions = true;

  // Track current goal state (balance may change after contribution)
  late Goal _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() => _loadingContributions = true);
    try {
      _contributions = await _service.getContributions(_goal.id);
    } catch (_) {}
    if (mounted) setState(() => _loadingContributions = false);
  }

  void _syncGoal() {
    final provider = context.read<GoalProvider>();
    final updated = provider.goals.firstWhere(
      (g) => g.id == _goal.id,
      orElse: () => _goal,
    );
    if (mounted) setState(() => _goal = updated);
  }

  Future<void> _showContributionDialog() async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isWithdrawal = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Contribution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Deposit')),
                  ButtonSegment(value: true, label: Text('Withdrawal')),
                ],
                selected: {isWithdrawal},
                onSelectionChanged: (v) =>
                    setDialogState(() => isWithdrawal = v.first),
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
                  labelText: 'Amount *',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) return;
                Navigator.pop(ctx);

                final success =
                    await context.read<GoalProvider>().addContribution(
                          goalId: _goal.id,
                          amount: isWithdrawal ? -amount : amount,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                        );

                if (success && mounted) {
                  _syncGoal();
                  _loadContributions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contribution recorded!')),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGoal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalFormScreen(goal: _goal)),
    );
    if (result == true) {
      _syncGoal();
    }
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text(
            'Are you sure you want to delete this goal? This cannot be undone.'),
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
      final success =
          await context.read<GoalProvider>().deleteGoal(_goal.id);
      if (success && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$');
    final progress = _goal.progressPercent.clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_goal.title),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined), onPressed: _editGoal),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteGoal,
              color: colorScheme.error),
        ],
      ),
      floatingActionButton: _goal.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: _showContributionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Contribution'),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Summary Card ────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Circular ring
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          color: _goal.isCompleted
                              ? Colors.green
                              : colorScheme.primary,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_goal.goalType.icon,
                                size: 28, color: colorScheme.primary),
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
                  const SizedBox(height: 16),
                  Text(
                    currency.format(_goal.currentAmount),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'of ${currency.format(_goal.targetAmount)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  if (_goal.isCompleted) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: const Text('Completed!'),
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      side: const BorderSide(color: Colors.green),
                      avatar: const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Details ─────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Type',
                      value: _goal.goalType.label),
                  if (_goal.description != null)
                    _DetailRow(
                        icon: Icons.notes_outlined,
                        label: 'Description',
                        value: _goal.description!),
                  _DetailRow(
                      icon: Icons.savings_outlined,
                      label: 'Remaining',
                      value: currency.format(_goal.remainingAmount)),
                  if (_goal.targetDate != null) ...[
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Target Date',
                      value: DateFormat.yMMMMd().format(_goal.targetDate!),
                    ),
                    if (_goal.daysRemaining != null)
                      _DetailRow(
                        icon: Icons.hourglass_bottom,
                        label: 'Time Left',
                        value: _goal.daysRemaining! < 0
                            ? 'Overdue'
                            : '${_goal.daysRemaining} days',
                      ),
                    if (_goal.requiredDailySaving != null &&
                        !_goal.isCompleted)
                      _DetailRow(
                        icon: Icons.trending_up,
                        label: 'Daily Target',
                        value:
                            '${currency.format(_goal.requiredDailySaving)}/day',
                      ),
                  ],
                  if (_goal.notes != null)
                    _DetailRow(
                        icon: Icons.sticky_note_2_outlined,
                        label: 'Notes',
                        value: _goal.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Contribution History ─────────────────────────────────────────
          Text('Contribution History',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loadingContributions)
            const Center(child: CircularProgressIndicator())
          else if (_contributions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No contributions yet',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            ...(_contributions.map((c) => _ContributionTile(
                contribution: c, currency: currency))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ContributionTile extends StatelessWidget {
  final GoalContribution contribution;
  final NumberFormat currency;

  const _ContributionTile(
      {required this.contribution, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isDeposit = contribution.amount >= 0;
    final color = isDeposit ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: color),
        ),
        title: Text(
          '${isDeposit ? '+' : ''}${currency.format(contribution.amount)}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat.yMMMMd().format(contribution.contributedAt),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12),
        ),
        trailing: contribution.notes != null
            ? Tooltip(
                message: contribution.notes!,
                child: const Icon(Icons.notes, size: 16))
            : null,
      ),
    );
  }
}
