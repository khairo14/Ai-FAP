import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../account_provider.dart';
import '../../../shared/models/account.dart';
import '../../../core/constants/currencies.dart';

/// Full-featured account management screen
/// Manages bank accounts, wallets, credit cards, and other financial accounts
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool _showInactiveAccounts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'toggle_inactive') {
                setState(() {
                  _showInactiveAccounts = !_showInactiveAccounts;
                });
              } else if (value == 'trash') {
                _showDeletedAccounts(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_inactive',
                child: Row(
                  children: [
                    Icon(_showInactiveAccounts 
                        ? Icons.visibility_off 
                        : Icons.visibility),
                    const SizedBox(width: 12),
                    Text(_showInactiveAccounts 
                        ? 'Hide Inactive' 
                        : 'Show Inactive'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 12),
                    Text('Deleted Accounts'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.accounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return _buildErrorView(context, provider);
          }

          if (provider.accounts.isEmpty) {
            return _buildEmptyView(context);
          }

          final displayAccounts = _showInactiveAccounts
              ? provider.accounts.where((a) => !a.isDeleted).toList()
              : provider.activeAccounts;

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: Column(
              children: [
                _buildTotalBalanceCard(context, provider),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayAccounts.length,
                    itemBuilder: (context, index) {
                      return _buildAccountCard(
                        context, 
                        displayAccounts[index], 
                        provider
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, AccountProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            if (provider.totalBalances.isEmpty)
              Text(
                'No accounts yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              ...provider.totalBalances.entries.map((entry) {
                final currencySymbol = Currencies.getSymbol(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$currencySymbol${entry.value.toStringAsFixed(2)} ${entry.key}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account, AccountProvider provider) {
    final theme = Theme.of(context);
    final currencySymbol = Currencies.getSymbol(account.currency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: account.isActive 
              ? theme.colorScheme.primaryContainer
              : Colors.grey.shade300,
          child: Icon(
            _getAccountIcon(account),
            color: account.isActive 
                ? theme.colorScheme.primary
                : Colors.grey.shade600,
          ),
        ),
        title: Text(
          account.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: account.isActive ? null : Colors.grey.shade600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.institutionName != null) ...[
              Text(account.institutionName!),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Text(
                  '$currencySymbol${account.currentBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: account.currentBalance >= 0 
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                if (!account.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                if (account.isCreditAccount)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Credit',
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showEditAccountDialog(context, account);
            } else if (value == 'toggle_active') {
              await provider.toggleAccountStatus(account.id);
            } else if (value == 'toggle_include') {
              await provider.toggleIncludeInTotal(account.id);
            } else if (value == 'delete') {
              _confirmDelete(context, account, provider);
            }
          },
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
            PopupMenuItem(
              value: 'toggle_active',
              child: Row(
                children: [
                  Icon(account.isActive ? Icons.visibility_off : Icons.visibility, size: 20),
                  const SizedBox(width: 12),
                  Text(account.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_include',
              child: Row(
                children: [
                  Icon(
                    account.includeInTotal ? Icons.check_box : Icons.check_box_outline_blank, 
                    size: 20
                  ),
                  const SizedBox(width: 12),
                  Text(account.includeInTotal ? 'Exclude from Total' : 'Include in Total'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showAccountDetails(context, account),
      ),
    );
  }

  IconData _getAccountIcon(Account account) {
    // Default icons - would be enhanced with account type data
    return Icons.account_balance_wallet;
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Accounts Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first account to start tracking your finances',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, AccountProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error Loading Accounts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Unknown error',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    // TODO: Implement add account dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add account dialog coming next')),
    );
  }

  void _showEditAccountDialog(BuildContext context, Account account) {
    // TODO: Implement edit account dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit account dialog coming next')),
    );
  }

  void _showAccountDetails(BuildContext context, Account account) {
    // TODO: Implement account details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Details for ${account.name}')),
    );
  }

  void _showDeletedAccounts(BuildContext context) {
    // TODO: Implement deleted accounts view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted accounts view coming next')),
    );
  }

  void _confirmDelete(BuildContext context, Account account, AccountProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text(
          'Are you sure you want to delete "${account.name}"? You can restore it later from the trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteAccount(account.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                          ? 'Account deleted' 
                          : 'Failed to delete account',
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}