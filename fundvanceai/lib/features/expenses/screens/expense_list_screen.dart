import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/expenses/screens/expense_form_screen.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/core/constants/currencies.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
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
      await context.read<ExpenseProvider>().deleteExpense(id);
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
              value: provider.selectedCategoryId,
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
    final authProvider = context.watch<AuthProvider>();
    final currencySymbol = Currencies.getSymbol(authProvider.userCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.expenses.isEmpty) {
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
                    onPressed: _refreshExpenses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No expenses yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add your first expense',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Stats summary
              if (provider.stats != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Total',
                        value:
                            '$currencySymbol${provider.stats!['total'].toStringAsFixed(2)}',
                      ),
                      _StatItem(
                        label: 'Count',
                        value: '${provider.stats!['count']}',
                      ),
                      _StatItem(
                        label: 'Average',
                        value:
                            '$currencySymbol${provider.stats!['average'].toStringAsFixed(2)}',
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
                    itemBuilder: (context, index) {
                      final expense = provider.expenses[index];
                      return _ExpenseCard(
                        expense: expense,
                        categoryName: provider.getCategoryName(expense.categoryId),
                        currencySymbol: currencySymbol,
                        onTap: () => _editExpense(expense),
                        onDelete: () => _deleteExpense(expense.id),
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
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String categoryName;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.categoryName,
    required this.currencySymbol,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
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
      },
      onDismissed: (direction) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            child: Text(
              '$currencySymbol${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          title: Text(
            expense.merchant ?? expense.description ?? 'Expense',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(categoryName),
              Text(
                DateFormat('MMM dd, yyyy').format(expense.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (expense.paymentMethod != null)
                Text(
                  expense.paymentMethod!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
