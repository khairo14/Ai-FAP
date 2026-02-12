import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/account.dart';
import '../../../core/constants/currencies.dart';
import '../account_provider.dart';
import '../widgets/edit_account_dialog.dart';
import 'account_transactions_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  final Account account;

  const AccountDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late Account _currentAccount;

  @override
  void initState() {
    super.initState();
    _currentAccount = widget.account;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    
    // Update current account if it changed in provider
    final updatedAccount = accountProvider.accounts
        .firstWhere((a) => a.id == _currentAccount.id, orElse: () => _currentAccount);
    if (updatedAccount.id == _currentAccount.id) {
      _currentAccount = updatedAccount;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAccount.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context),
            tooltip: 'Edit Account',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Delete Account',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await accountProvider.loadAccounts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Balance Card
              _buildBalanceCard(theme),
              const SizedBox(height: 16),

              // Account Information Card
              _buildInfoCard(theme),
              const SizedBox(height: 16),

              // Account Settings Card
              _buildSettingsCard(theme),
              const SizedBox(height: 16),

              // Quick Actions
              _buildQuickActions(context, theme),
              const SizedBox(height: 24),

              // Transactions Section
              _buildTransactionsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    final isCredit = _currentAccount.accountTypeCategory == 'Credit';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${Currencies.getSymbol(_currentAccount.currency)} ${_currentAccount.currentBalance.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _currentAccount.currentBalance >= 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            if (isCredit) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Currencies.getSymbol(_currentAccount.currency)} ${_currentAccount.availableBalance.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Credit Limit',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Currencies.getSymbol(_currentAccount.currency)} ${_currentAccount.creditLimit?.toStringAsFixed(2) ?? '0.00'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              'Account Type',
              _currentAccount.accountTypeName ?? 'Unknown',
            ),
            _buildInfoRow(
              theme,
              'Category',
              _currentAccount.accountTypeCategory ?? 'Unknown',
            ),
            if (_currentAccount.institutionName != null &&
                _currentAccount.institutionName!.isNotEmpty)
              _buildInfoRow(
                theme,
                'Institution',
                _currentAccount.institutionName!,
              ),
            _buildInfoRow(
              theme,
              'Currency',
              '${Currencies.getName(_currentAccount.currency)} (${_currentAccount.currency})',
            ),
            if (_currentAccount.description != null &&
                _currentAccount.description!.isNotEmpty)
              _buildInfoRow(
                theme,
                'Description',
                _currentAccount.description!,
                isLast: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Include in Total'),
              subtitle: const Text('Include this account in total balance'),
              value: _currentAccount.includeInTotal,
              onChanged: null, // Read-only for now, edit via dialog
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Account is active and in use'),
              value: _currentAccount.isActive,
              onChanged: null, // Read-only for now, edit via dialog
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to add expense with this account pre-selected
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Expense - Coming soon')),
              );
            },
            icon: const Icon(Icons.remove),
            label: const Text('Add Expense'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to add income with this account pre-selected
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Income - Coming soon')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Income'),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transaction History',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View all transactions for this account',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AccountTransactionsScreen(account: _currentAccount),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditAccountDialog(account: _currentAccount),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text(
          'Are you sure you want to delete "${_currentAccount.name}"? You can restore it from the trash later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              final accountProvider =
                  Provider.of<AccountProvider>(context, listen: false);
              
              final success =
                  await accountProvider.deleteAccount(_currentAccount.id);
              
              if (context.mounted) {
                if (success) {
                  Navigator.pop(context); // Return to accounts list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        accountProvider.errorMessage ??
                            'Failed to delete account',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
