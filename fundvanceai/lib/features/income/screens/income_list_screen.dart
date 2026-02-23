import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/app_error_view.dart';
import '../../auth/auth_provider.dart';
import '../income_provider.dart';
import 'income_form_screen.dart';
import '../../../shared/models/income.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/utils/icon_helper.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  bool _dataChanged = false;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      final provider = Provider.of<IncomeProvider>(context, listen: false);
      if (!provider.isInitialized) {
        provider.initialize();
      }
    }
  }

  Future<void> _refreshIncome() async {
    await context.read<IncomeProvider>().loadIncome();
  }

  Future<void> _addIncome() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IncomeFormScreen(),
      ),
    );
    if (result == true) {
      setState(() => _dataChanged = true);
      _refreshIncome();
    }
  }

  Future<void> _editIncome(Income income) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomeFormScreen(income: income),
      ),
    );
    if (result == true) {
      setState(() => _dataChanged = true);
      _refreshIncome();
    }
  }

  Future<void> _deleteIncome(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content:
            const Text('Are you sure you want to delete this income entry?'),
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
      final success = await context.read<IncomeProvider>().deleteIncome(id);

      if (!mounted) return;

      if (success) {
        setState(() => _dataChanged = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Income moved to trash'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                await context.read<IncomeProvider>().restoreIncome(id);
                setState(() => _dataChanged = true);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete income'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showFilterDialog() async {
    final provider = context.read<IncomeProvider>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Income'),
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
                        IconHelper.getIcon(
                          category.icon,
                          size: 20,
                          color: IconHelper.hexToColor(category.color),
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
    final incomeProvider = context.watch<IncomeProvider>();
    final theme = Theme.of(context);
    final userCurrency = authProvider.userCurrency;
    final currencySymbol = Currencies.getSymbol(userCurrency);

    return PopScope(
      canPop: !_dataChanged,
      onPopInvokedWithResult: (didPop, result) {
        if (_dataChanged && !didPop) {
          Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Income'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshIncome,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshIncome,
          child: incomeProvider.isLoading
              ? const ShimmerListScreen(itemCount: 8)
              : incomeProvider.errorMessage != null
                  ? _buildErrorView(incomeProvider.errorMessage!, theme)
                  : incomeProvider.incomeList.isEmpty
                      ? _buildEmptyView(theme)
                      : Column(
                          children: [
                            _buildStatsCard(
                                incomeProvider, currencySymbol, theme),
                            Expanded(
                              child: _buildIncomeList(
                                  incomeProvider, currencySymbol, theme),
                            ),
                          ],
                        ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addIncome,
          icon: const Icon(Icons.add),
          label: const Text('Add Income'),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }

  Widget _buildStatsCard(
      IncomeProvider provider, String currencySymbol, ThemeData theme) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    final totalGross = stats['totalGrossIncome'] as double? ?? 0;
    final totalNet = stats['totalNetIncome'] as double? ?? 0;
    final totalTax = stats['totalTax'] as double? ?? 0;
    final count = stats['incomeCount'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  label: 'Gross Income',
                  value:
                      '$currencySymbol${NumberFormat('#,##0.00').format(totalGross)}',
                  color: Colors.green,
                  theme: theme,
                ),
                _buildStatItem(
                  label: 'Net Income',
                  value:
                      '$currencySymbol${NumberFormat('#,##0.00').format(totalNet)}',
                  color: Colors.blue,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  label: 'Tax',
                  value:
                      '$currencySymbol${NumberFormat('#,##0.00').format(totalTax)}',
                  color: Colors.orange,
                  theme: theme,
                ),
                _buildStatItem(
                  label: 'Entries',
                  value: count.toString(),
                  color: Colors.purple,
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeList(
      IncomeProvider provider, String currencySymbol, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.incomeList.length,
      itemBuilder: (context, index) {
        final income = provider.incomeList[index];
        return _buildIncomeCard(income, currencySymbol, theme);
      },
    );
  }

  Widget _buildIncomeCard(
      Income income, String currencySymbol, ThemeData theme) {
    final incomeCurrencySymbol = Currencies.getSymbol(income.currency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editIncome(income),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconHelper.getIcon(
                      income.categoryIcon ?? 'money',
                      size: 24,
                      color: IconHelper.hexToColor(
                          income.categoryColor ?? '#4CAF50'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Income details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          income.categoryName ?? 'Unknown Category',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (income.accountName != null)
                          Text(
                            income.accountName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+$incomeCurrencySymbol${NumberFormat('#,##0.00').format(income.amount)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      if (income.taxCalculated != null &&
                          income.taxCalculated! > 0)
                        Text(
                          'Net: $incomeCurrencySymbol${NumberFormat('#,##0.00').format(income.netAmount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
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
                        _editIncome(income);
                      } else if (value == 'delete') {
                        _deleteIncome(income.id);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(income.incomeDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (income.taxCalculated != null &&
                      income.taxCalculated! > 0) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.account_balance,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tax: $incomeCurrencySymbol${NumberFormat('#,##0.00').format(income.taxCalculated)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  if (income.isRecurring) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.repeat, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      income.recurrencePattern ?? 'Recurring',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(32.0),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.money_off,
                size: 80,
                color: Colors.green[200],
              ),
              const SizedBox(height: 16),
              Text(
                'No Income Yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first income entry',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String error, ThemeData theme) {
    return AppErrorView(
      message: error,
      title: 'Error Loading Income',
      onRetry: _refreshIncome,
    );
  }
}
