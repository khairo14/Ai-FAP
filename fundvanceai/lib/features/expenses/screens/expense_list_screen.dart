import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/shared/widgets/shimmer_loading.dart';
import 'package:fundvanceai/shared/widgets/app_error_view.dart';
import 'package:fundvanceai/features/expenses/screens/expense_form_screen.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/core/constants/currencies.dart';
import 'package:fundvanceai/core/utils/icon_helper.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().initialize();
    });
  }

  Future<void> _refreshExpenses() async {
    await context.read<ExpenseProvider>().loadExpenses();
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseFormScreen(),
      ),
    );
    if (result == true) {
      setState(() => _dataChanged = true);
      _refreshExpenses();
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(expense: expense),
      ),
    );
    if (result == true) {
      setState(() => _dataChanged = true);
      _refreshExpenses();
    }
  }

  /// Open the form pre-filled with the expense data but today as the date
  Future<void> _repeatExpense(Expense expense) async {
    // Build a copy of the expense with today's date and no id (treated as new)
    final template = expense.copyWith(date: DateTime.now());
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(expense: template),
      ),
    );
    if (result == true) {
      setState(() => _dataChanged = true);
      _refreshExpenses();
    }
  }

  Future<void> _deleteExpense(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _deleteExpenseConfirmed(id);
    }
  }

  Future<void> _deleteExpenseConfirmed(String id) async {
    final success = await context.read<ExpenseProvider>().deleteExpense(id);

    if (!mounted) return;

    if (success) {
      setState(() => _dataChanged = true);

      // Show undo snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense moved to trash'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // Restore the expense
              await context.read<ExpenseProvider>().restoreExpense(id);
              setState(() => _dataChanged = true);
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete expense'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showFilterDialog() async {
    final provider = context.read<ExpenseProvider>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Expenses'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: provider.selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...provider.categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        if (category.icon != null)
                          Text(
                            category.icon!,
                            style: const TextStyle(fontSize: 20),
                          ),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                provider.setCategoryFilter(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear Filters'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _dataChanged) {
          // Return true to indicate data was changed
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _dataChanged),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.expenses.isEmpty) {
              return const ShimmerListScreen(itemCount: 8);
            }

            if (provider.errorMessage != null && provider.expenses.isEmpty) {
              return AppErrorView(
                message: provider.errorMessage!,
                onRetry: _refreshExpenses,
              );
            }

            if (provider.expenses.isEmpty) {
              return _EmptyExpenseState(
                onAdd: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpenseFormScreen(),
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Stats summary
                if (provider.stats != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Count
                        Text(
                          '${provider.stats!['count']} expenses',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(width: 12),
                        // Currency totals
                        if (provider.stats!['byCurrency'] != null &&
                            (provider.stats!['byCurrency'] as Map).isNotEmpty)
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              alignment: WrapAlignment.end,
                              children: [
                                ...(provider.stats!['byCurrency'] as Map)
                                    .entries
                                    .map((entry) {
                                  final currencyCode = entry.key as String;
                                  final total = entry.value as double;
                                  final symbol =
                                      Currencies.getSymbol(currencyCode);
                                  return Text(
                                    '$symbol ${total.toStringAsFixed(2)} $currencyCode',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                // Expense list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshExpenses,
                    child: ListView.builder(
                      itemCount: provider.expenses.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final expense = provider.expenses[index];
                        return _ExpenseCard(
                          expense: expense,
                          onTap: () => _editExpense(expense),
                          onRepeat: () => _repeatExpense(expense),
                          onDelete: () => _deleteExpense(expense.id),
                          onDeleteConfirmed: () =>
                              _deleteExpenseConfirmed(expense.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addExpense,
          child: const Icon(Icons.add),
        ),
      ), // Scaffold
    ); // PopScope
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onRepeat;
  final VoidCallback onDelete;
  final Future<void> Function() onDeleteConfirmed;

  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.onRepeat,
    required this.onDelete,
    required this.onDeleteConfirmed,
  });

  Color _getCategoryColor() {
    if (expense.categoryColor != null) {
      try {
        return Color(
            int.parse(expense.categoryColor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = Currencies.getSymbol(expense.currency ?? 'USD');
    final categoryColor = _getCategoryColor();

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: Text(
                'Delete "${expense.displayName}"? This action can be undone from trash.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async => await onDeleteConfirmed(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconHelper.getIcon(
                    expense.categoryIcon,
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Expense Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expense Name
                      Text(
                        expense.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Category and Date
                      Row(
                        children: [
                          if (expense.categoryName != null) ...[
                            Icon(Icons.category,
                                size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Text(
                              expense.categoryName!,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.calendar_today,
                              size: 11, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('MMM dd').format(expense.date),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),

                      // Account and Payment Method
                      if (expense.accountName != null ||
                          expense.paymentMethod != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (expense.accountName != null) ...[
                              Icon(Icons.account_balance_wallet,
                                  size: 11, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(
                                expense.accountName!,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500]),
                              ),
                              if (expense.paymentMethod != null)
                                const SizedBox(width: 6),
                            ],
                            if (expense.paymentMethod != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  expense.paymentMethod!,
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.grey[700]),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (expense.isRecurring) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat,
                                      size: 9, color: Colors.blue[600]),
                                  const SizedBox(width: 2),
                                  Text(
                                    expense.recurringFrequency ?? 'recurring',
                                    style: TextStyle(
                                        fontSize: 9, color: Colors.blue[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Amount and Menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currencySymbol ${expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600],
                          ),
                    ),
                    Text(
                      expense.currency ?? 'USD',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),

                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'repeat',
                      child: Row(
                        children: [
                          Icon(Icons.repeat, size: 20, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('Repeat Today'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onTap();
                    } else if (value == 'repeat') {
                      onRepeat();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyExpenseState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyExpenseState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 52,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No expenses yet',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your spending by adding your first expense.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
