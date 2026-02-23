import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/expense.dart';
import '../../../core/constants/currencies.dart';
import '../../categories/category_provider.dart';
import '../../expenses/expense_provider.dart';
import '../../expenses/screens/expense_form_screen.dart';

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

  // Filter / sort state
  DateTimeRange? _dateFilter;
  String? _categoryFilterId;
  String _categoryFilterName = 'All';
  String _sortBy = 'date';
  bool _sortAscending = false;

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
    // All transactions are loaded at once via setAccountFilter —
    // no client-side pagination needed.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.name} Transactions'),
        actions: [
          if (_dateFilter != null || _categoryFilterId != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              onPressed: () => setState(() {
                _dateFilter = null;
                _categoryFilterId = null;
                _categoryFilterName = 'All';
              }),
              tooltip: 'Clear filters',
            ),
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

    // Filter expenses for this account + applied filters
    var accountExpenses = provider.expenses
        .where((expense) => expense.accountId == widget.account.id)
        .where((expense) =>
            _categoryFilterId == null ||
            expense.categoryId == _categoryFilterId)
        .where((expense) =>
            _dateFilter == null ||
            (!expense.date.isBefore(_dateFilter!.start) &&
                !expense.date
                    .isAfter(_dateFilter!.end.add(const Duration(days: 1)))))
        .toList()
      ..sort((a, b) {
        int cmp;
        if (_sortBy == 'amount') {
          cmp = a.amount.compareTo(b.amount);
        } else {
          cmp = a.date.compareTo(b.date);
        }
        return _sortAscending ? cmp : -cmp;
      });

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
              _dateFilter != null || _categoryFilterId != null
                  ? 'No Matching Transactions'
                  : 'No Transactions',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _dateFilter != null || _categoryFilterId != null
                  ? 'Try adjusting your filters'
                  : 'No expenses recorded for this account yet',
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
            itemCount: accountExpenses.length,
            itemBuilder: (context, index) {
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
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
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
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseFormScreen(expense: expense),
            ),
          );
          if ((result ?? false) && context.mounted) {
            _loadTransactions();
          }
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
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              subtitle: _dateFilter != null
                  ? Text(
                      '${_dateFilter!.start.day}/${_dateFilter!.start.month}/${_dateFilter!.start.year} '
                      '→ ${_dateFilter!.end.day}/${_dateFilter!.end.month}/${_dateFilter!.end.year}',
                    )
                  : const Text('All dates'),
              trailing: _dateFilter != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() => _dateFilter = null);
                        Navigator.pop(ctx);
                      },
                    )
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _dateFilter,
                );
                if (range != null) setState(() => _dateFilter = range);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Category'),
              subtitle: Text(_categoryFilterName),
              trailing: _categoryFilterId != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _categoryFilterId = null;
                          _categoryFilterName = 'All';
                        });
                        Navigator.pop(ctx);
                      },
                    )
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _showCategoryPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort By'),
              subtitle: Text(
                '${_sortBy == 'date' ? 'Date' : 'Amount'} · '
                '${_sortAscending ? 'Ascending' : 'Descending'}',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showSortOptions();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    final categories = context.read<CategoryProvider>().categories;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All categories'),
                selected: _categoryFilterId == null,
                onTap: () {
                  setState(() {
                    _categoryFilterId = null;
                    _categoryFilterName = 'All';
                  });
                  Navigator.pop(ctx);
                },
              ),
              ...categories.map(
                (cat) => ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(cat.name),
                  selected: _categoryFilterId == cat.id,
                  onTap: () {
                    setState(() {
                      _categoryFilterId = cat.id;
                      _categoryFilterName = cat.name;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sort Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date'),
              value: 'date',
              // ignore: deprecated_member_use
              groupValue: _sortBy,
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _sortBy = v!),
            ),
            RadioListTile<String>(
              title: const Text('Amount'),
              value: 'amount',
              // ignore: deprecated_member_use
              groupValue: _sortBy,
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _sortBy = v!),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Ascending'),
              value: _sortAscending,
              onChanged: (v) => setState(() => _sortAscending = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
