import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/expense.dart';
import '../../../core/constants/currencies.dart';
import '../../expenses/expense_provider.dart';

class AccountTransactionsScreen extends StatefulWidget {
  final Account account;

  const AccountTransactionsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountTransactionsScreen> createState() =>
      _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadTransactions() {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    expenseProvider.setAccountFilter(widget.account.id);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // TODO: Implement pagination in ExpenseProvider
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.name} Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadTransactions();
        },
        child: _buildBody(theme, expenseProvider),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ExpenseProvider provider) {
    if (provider.isLoading && provider.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading transactions',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filter expenses for this account
    final accountExpenses = provider.expenses
        .where((expense) => expense.accountId == widget.account.id)
        .toList();

    if (accountExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No expenses recorded for this account yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCard(theme, accountExpenses),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: accountExpenses.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == accountExpenses.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final expense = accountExpenses[index];
              return _buildTransactionCard(theme, expense);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme, List<Expense> expenses) {
    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final count = expenses.length;
    final currencySymbol = Currencies.getSymbol(widget.account.currency);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Total Spent',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$currencySymbol${total.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.3),
          ),
          Column(
            children: [
              Text(
                'Transactions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(ThemeData theme, Expense expense) {
    final currencySymbol = Currencies.getSymbol(widget.account.currency);
    final dateStr = _formatDate(expense.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.errorContainer,
          child: Icon(
            Icons.remove,
            color: theme.colorScheme.error,
          ),
        ),
        title: Text(
          expense.description ?? 'No description',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              Text(
                expense.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Text(
          '-$currencySymbol${expense.amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        onTap: () {
          // TODO: Navigate to expense details/edit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense details - Coming soon')),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Today';
    } else if (expenseDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show date range picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Date filter - Coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Category'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show category filter
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category filter - Coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort By'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show sort options
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sort options - Coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
