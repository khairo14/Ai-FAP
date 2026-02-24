import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/income/income_provider.dart';
import 'package:fundvanceai/features/debts/debt_provider.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/shared/models/income.dart';
import 'package:fundvanceai/shared/models/debt.dart';
import 'package:fundvanceai/features/expenses/screens/expense_form_screen.dart';
import 'package:fundvanceai/features/income/screens/income_form_screen.dart';
import 'package:fundvanceai/features/debts/screens/debt_form_screen.dart';

/// 3-tab screen: Expenses | Income | Reminders
///
/// Expenses tab  — lists all recurring expenses with pause/resume toggle
/// Income tab    — lists all recurring income rows with pause/resume toggle
/// Reminders tab — debt payment reminders with editable reminder-day setting
class ScheduledScreen extends StatelessWidget {
  const ScheduledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scheduled & Reminders'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.repeat), text: 'Expenses'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Income'),
              Tab(icon: Icon(Icons.notifications_active), text: 'Reminders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RecurringExpensesTab(),
            _RecurringIncomeTab(),
            _RemindersTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Recurring Expenses
// ─────────────────────────────────────────────────────────────────────────────

class _RecurringExpensesTab extends StatelessWidget {
  const _RecurringExpensesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final items = provider.recurringExpenses;
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.repeat_outlined,
            message: 'No recurring expenses set up yet.\n'
                'Add a recurring expense to see it here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final expense = items[index];
            return _RecurringExpenseTile(expense: expense, provider: provider);
          },
        );
      },
    );
  }
}

class _RecurringExpenseTile extends StatelessWidget {
  const _RecurringExpenseTile({
    required this.expense,
    required this.provider,
  });

  final Expense expense;
  final ExpenseProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaused = expense.isPaused;
    final nextDue = expense.lastAutoCreatedAt != null
        ? _addFrequencyInterval(
            expense.lastAutoCreatedAt!, expense.recurringFrequency)
        : expense.date;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPaused
            ? Colors.grey.shade200
            : theme.colorScheme.primaryContainer,
        child: Icon(
          isPaused ? Icons.pause_rounded : Icons.repeat,
          color: isPaused ? Colors.grey : theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        expense.merchant ?? 'Expense',
        style: TextStyle(
          color: isPaused ? theme.disabledColor : null,
          decoration: isPaused ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${_capitalize(expense.recurringFrequency ?? 'Unknown')} '
        '• Next: ${DateFormat('MMM d').format(nextDue)}'
        '${expense.recurringEndDate != null ? ' • Ends ${DateFormat('MMM d').format(expense.recurringEndDate!)}' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            expense.currency != null
                ? '${expense.currency} ${expense.amount.toStringAsFixed(2)}'
                : expense.amount.toStringAsFixed(2),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: !isPaused,
            onChanged: (active) =>
                provider.pauseRecurringExpense(expense.id, paused: !active),
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExpenseFormScreen(expense: expense),
          fullscreenDialog: true,
        ),
      ),
      isThreeLine: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Recurring Income
// ─────────────────────────────────────────────────────────────────────────────

class _RecurringIncomeTab extends StatelessWidget {
  const _RecurringIncomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<IncomeProvider>(
      builder: (context, provider, _) {
        final items = provider.recurringIncome;
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            message: 'No recurring income set up yet.\n'
                'Mark an income as recurring to see it here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final income = items[index];
            return _RecurringIncomeTile(income: income, provider: provider);
          },
        );
      },
    );
  }
}

class _RecurringIncomeTile extends StatelessWidget {
  const _RecurringIncomeTile({
    required this.income,
    required this.provider,
  });

  final Income income;
  final IncomeProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaused = income.isPaused;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isPaused ? Colors.grey.shade200 : Colors.green.shade100,
        child: Icon(
          isPaused ? Icons.pause_rounded : Icons.trending_up,
          color: isPaused ? Colors.grey : Colors.green.shade700,
          size: 20,
        ),
      ),
      title: Text(
        income.description ?? 'Income',
        style: TextStyle(
          color: isPaused ? theme.disabledColor : null,
          decoration: isPaused ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${_capitalize(income.recurrencePattern ?? 'Unknown')}'
        '${income.nextOccurrence != null ? ' • Next: ${DateFormat('MMM d').format(income.nextOccurrence!)}' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${income.currency} ${income.amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: !isPaused,
            onChanged: (active) =>
                provider.pauseRecurringIncome(income.id, paused: !active),
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncomeFormScreen(income: income),
          fullscreenDialog: true,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Reminders (Debts)
// ─────────────────────────────────────────────────────────────────────────────

class _RemindersTab extends StatelessWidget {
  const _RemindersTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, _) {
        final debts =
            provider.activeDebts.where((d) => d.paymentDueDay != null).toList();

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (debts.isEmpty) {
          return const _EmptyState(
            icon: Icons.notifications_none_rounded,
            message: 'No debt payment reminders configured.\n'
                'Set a payment due day on a debt to activate reminders.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: debts.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final debt = debts[index];
            return _DebtReminderTile(debt: debt, provider: provider);
          },
        );
      },
    );
  }
}

class _DebtReminderTile extends StatelessWidget {
  const _DebtReminderTile({required this.debt, required this.provider});

  final Debt debt;
  final DebtProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.errorContainer,
        child: Icon(Icons.credit_card,
            color: theme.colorScheme.onErrorContainer, size: 20),
      ),
      title: Text(debt.name),
      subtitle: Text(
        'Due day ${debt.paymentDueDay} each month'
        ' • Remind ${debt.paymentReminderDays} day${debt.paymentReminderDays == 1 ? '' : 's'} before'
        '${debt.autoLogPayment ? ' • Auto-log ON' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${debt.currency} ${debt.currentBalance.toStringAsFixed(0)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DebtFormScreen(debt: debt),
          fullscreenDialog: true,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.disabledColor),
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

DateTime _addFrequencyInterval(DateTime from, String? frequency) {
  switch ((frequency ?? 'monthly').toLowerCase()) {
    case 'daily':
      return from.add(const Duration(days: 1));
    case 'weekly':
      return from.add(const Duration(days: 7));
    case 'bi-weekly':
    case 'biweekly':
      return from.add(const Duration(days: 14));
    case 'monthly':
      return DateTime(from.year, from.month + 1, from.day);
    case 'yearly':
      return DateTime(from.year + 1, from.month, from.day);
    default:
      return DateTime(from.year, from.month + 1, from.day);
  }
}
