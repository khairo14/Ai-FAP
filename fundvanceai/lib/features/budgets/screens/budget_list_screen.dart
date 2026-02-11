import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/budgets/budget_provider.dart';
import 'package:fundvanceai/features/budgets/screens/budget_form_screen.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/shared/models/budget.dart';
import 'package:fundvanceai/core/constants/currencies.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseProvider = context.read<ExpenseProvider>();
      final budgetProvider = context.read<BudgetProvider>();
      
      // Load categories first if not loaded
      if (expenseProvider.categories.isEmpty) {
        expenseProvider.loadCategories();
      }
      
      // Then load budgets
      budgetProvider.initialize();
    });
  }

  Future<void> _refreshBudgets() async {
    await context.read<BudgetProvider>().loadBudgets();
  }

  Future<void> _addBudget() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BudgetFormScreen(),
      ),
    );
    if (result == true) {
      _refreshBudgets();
    }
  }

  Future<void> _editBudget(Budget budget) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetFormScreen(budget: budget),
      ),
    );
    if (result == true) {
      _refreshBudgets();
    }
  }

  Future<void> _deleteBudget(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
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
      await _deleteBudgetConfirmed(id);
    }
  }

  Future<void> _deleteBudgetConfirmed(String id) async {
    final success = await context.read<BudgetProvider>().deleteBudget(id);
    
    if (!mounted) return;
    
    if (success) {
      // Show undo snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Budget moved to trash'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // Restore the budget
              await context.read<BudgetProvider>().restoreBudget(id);
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete budget'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currencySymbol = Currencies.getSymbol(authProvider.userCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.budgets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshBudgets,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No budgets yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to create your first budget',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          label: 'Total Budget',
                          value:
                              '$currencySymbol${provider.totalBudgetAmount.toStringAsFixed(2)}',
                          icon: Icons.account_balance_wallet,
                        ),
                        _SummaryItem(
                          label: 'Total Spent',
                          value:
                              '$currencySymbol${provider.totalSpentAmount.toStringAsFixed(2)}',
                          icon: Icons.receipt,
                        ),
                      ],
                    ),
                    if (provider.overBudgetCount > 0 ||
                        provider.warningCount > 0) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (provider.overBudgetCount > 0)
                            _AlertBadge(
                              count: provider.overBudgetCount,
                              label: 'Over Budget',
                              color: Colors.red,
                            ),
                          if (provider.warningCount > 0)
                            _AlertBadge(
                              count: provider.warningCount,
                              label: 'Warning',
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Budget list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshBudgets,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.budgetStatuses.length,
                    itemBuilder: (context, index) {
                      final status = provider.budgetStatuses[index];
                      final budget = status['budget'] as Budget;
                      return _BudgetCard(
                        budget: budget,
                        status: status,
                        currencySymbol: currencySymbol,
                        onTap: () => _editBudget(budget),
                        onDelete: () => _deleteBudget(budget.id),
                        onDeleteConfirmed: () => _deleteBudgetConfirmed(budget.id),
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
        onPressed: _addBudget,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _AlertBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _AlertBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final Map<String, dynamic> status;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Future<void> Function() onDeleteConfirmed;

  const _BudgetCard({
    required this.budget,
    required this.status,
    required this.currencySymbol,
    required this.onTap,
    required this.onDelete,
    required this.onDeleteConfirmed,
  });

  Color _getStatusColor(String statusType) {
    switch (statusType) {
      case 'over':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final categoryName = budget.categoryId != null
        ? expenseProvider.getCategoryName(budget.categoryId)
        : 'All Categories';
    final category = budget.categoryId != null
        ? expenseProvider.getCategory(budget.categoryId)
        : null;

    final budgetAmount = status['budget_amount'] as double? ?? 0.0;
    final spentAmount = status['spent_amount'] as double? ?? 0.0;
    final percentage = status['percentage'] as double? ?? 0.0;
    final remaining = status['remaining'] as double? ?? 0.0;
    final statusType = status['status'] as String? ?? 'ok';

    final statusColor = _getStatusColor(statusType);
    final progressValue = (percentage / 100).clamp(0.0, 1.0);

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Budget'),
            content: const Text('Are you sure you want to delete this budget?'),
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
      },
      onDismissed: (direction) async => await onDeleteConfirmed(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    if (category?.icon != null)
                      Text(
                        category!.icon!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    if (category?.icon != null) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            budget.periodDisplay,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          onTap();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey[200],
                    color: statusColor,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),

                // Amount details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spent',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '$currencySymbol${spentAmount.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Budget',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '$currencySymbol${budgetAmount.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          remaining >= 0 ? 'Remaining' : 'Over',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '$currencySymbol${remaining.abs().toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: remaining >= 0 ? Colors.green : Colors.red,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
