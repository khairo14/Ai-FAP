import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/budgets/budget_provider.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/shared/models/budget.dart';
import 'package:fundvanceai/shared/models/category.dart';
import 'package:fundvanceai/core/constants/currencies.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Expense> _deletedExpenses = [];
  List<Budget> _deletedBudgets = [];
  late Map<String, Category> _categoryMap;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeletedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeletedItems() async {
    setState(() => _isLoading = true);

    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    // Build category map for lookups
    _categoryMap = {
      for (var cat in expenseProvider.categories) cat.id: cat
    };

    // Load deleted items
    _deletedExpenses = await expenseProvider.getDeletedExpenses();
    _deletedBudgets = await budgetProvider.getDeletedBudgets();

    // Auto-cleanup items older than 30 days
    await expenseProvider.autoCleanupOldDeleted();
    await budgetProvider.autoCleanupOldDeleted();

    setState(() => _isLoading = false);
  }

  Future<void> _restoreExpense(Expense expense) async {
    final success = await context.read<ExpenseProvider>().restoreExpense(expense.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense restored successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDeletedItems();
    }
  }

  Future<void> _restoreBudget(Budget budget) async {
    final success = await context.read<BudgetProvider>().restoreBudget(budget.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget restored successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDeletedItems();
    }
  }

  Future<void> _permanentlyDeleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: const Text(
          'This will permanently delete this expense. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<ExpenseProvider>().permanentlyDeleteExpense(expense.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense permanently deleted'),
          ),
        );
        _loadDeletedItems();
      }
    }
  }

  Future<void> _permanentlyDeleteBudget(Budget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: const Text(
          'This will permanently delete this budget. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<BudgetProvider>().permanentlyDeleteBudget(budget.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget permanently deleted'),
          ),
        );
        _loadDeletedItems();
      }
    }
  }

  int _daysUntilPermanentDelete(DateTime? deletedAt) {
    if (deletedAt == null) return 30;
    final daysInTrash = DateTime.now().difference(deletedAt).inDays;
    return 30 - daysInTrash;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currencySymbol = Currencies.getSymbol(authProvider.userCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Expenses (${_deletedExpenses.length})',
              icon: const Icon(Icons.receipt_long),
            ),
            Tab(
              text: 'Budgets (${_deletedBudgets.length})',
              icon: const Icon(Icons.pie_chart),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesList(currencySymbol),
                _buildBudgetsList(currencySymbol),
              ],
            ),
    );
  }

  Widget _buildExpensesList(String currencySymbol) {
    if (_deletedExpenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No deleted expenses',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Items are kept for 30 days before permanent deletion',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedExpenses.length,
      itemBuilder: (context, index) {
        final expense = _deletedExpenses[index];
        final category = _categoryMap[expense.categoryId];
        final daysLeft = _daysUntilPermanentDelete(expense.deletedAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.2),
              child: category?.icon != null
                  ? Text(category!.icon!, style: const TextStyle(fontSize: 20))
                  : const Icon(Icons.receipt, color: Colors.red),
            ),
            title: Text(
              expense.merchant ?? expense.description ?? 'Expense',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? 'Uncategorized',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(expense.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  daysLeft > 0
                      ? 'Deletes in $daysLeft days'
                      : 'Deleting soon...',
                  style: TextStyle(
                    fontSize: 11,
                    color: daysLeft < 7 ? Colors.orange : Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currencySymbol${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Row(
                        children: [
                          Icon(Icons.restore, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Restore'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Forever'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'restore') {
                      _restoreExpense(expense);
                    } else if (value == 'delete') {
                      _permanentlyDeleteExpense(expense);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetsList(String currencySymbol) {
    if (_deletedBudgets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No deleted budgets',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Items are kept for 30 days before permanent deletion',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedBudgets.length,
      itemBuilder: (context, index) {
        final budget = _deletedBudgets[index];
        final category = _categoryMap[budget.categoryId];
        final daysLeft = _daysUntilPermanentDelete(budget.deletedAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: category?.icon != null
                  ? Text(category!.icon!, style: const TextStyle(fontSize: 20))
                  : const Icon(Icons.pie_chart, color: Colors.orange),
            ),
            title: Text(
              category?.name ?? 'Overall Budget',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.periodDisplay,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  daysLeft > 0
                      ? 'Deletes in $daysLeft days'
                      : 'Deleting soon...',
                  style: TextStyle(
                    fontSize: 11,
                    color: daysLeft < 7 ? Colors.orange : Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currencySymbol${budget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Row(
                        children: [
                          Icon(Icons.restore, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Restore'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Forever'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'restore') {
                      _restoreBudget(budget);
                    } else if (value == 'delete') {
                      _permanentlyDeleteBudget(budget);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
