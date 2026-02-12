import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../account_provider.dart';
import '../../../shared/models/account.dart';
import '../../../core/constants/currencies.dart';

/// Screen for viewing and restoring deleted accounts
class DeletedAccountsScreen extends StatefulWidget {
  const DeletedAccountsScreen({super.key});

  @override
  State<DeletedAccountsScreen> createState() => _DeletedAccountsScreenState();
}

class _DeletedAccountsScreenState extends State<DeletedAccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadDeletedAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Accounts'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.deletedAccounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return _buildErrorView(context, provider);
          }

          if (provider.deletedAccounts.isEmpty) {
            return _buildEmptyView(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDeletedAccounts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.deletedAccounts.length,
              itemBuilder: (context, index) {
                return _buildAccountCard(
                  context,
                  provider.deletedAccounts[index],
                  provider,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Account account,
    AccountProvider provider,
  ) {
    final theme = Theme.of(context);
    final currencySymbol = Currencies.getSymbol(account.currency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.grey.shade600,
          ),
        ),
        title: Text(
          account.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.accountTypeCategory != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatCategory(account.accountTypeCategory!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Balance: $currencySymbol ${account.currentBalance.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (account.deletedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Deleted: ${_formatDate(account.deletedAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.green),
              tooltip: 'Restore',
              onPressed: () => _confirmRestore(context, account, provider),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Permanently Delete',
              onPressed: () => _confirmPermanentDelete(context, account),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Deleted Accounts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'All your accounts are active.',
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
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Deleted Accounts',
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
              onPressed: () => provider.loadDeletedAccounts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(
    BuildContext context,
    Account account,
    AccountProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Account?'),
        content: Text(
          'Are you sure you want to restore "${account.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.restoreAccount(account.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Account restored successfully'
                          : 'Failed to restore account',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Restore',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: Text(
          'Are you sure you want to permanently delete "${account.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permanent delete feature coming soon'),
                ),
              );
            },
            child: const Text(
              'Permanently Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(String category) {
    switch (category.toLowerCase()) {
      case 'e_wallet':
        return 'E-Wallet';
      case 'online_bank':
        return 'Online Bank';
      case 'bank':
        return 'Bank';
      case 'credit':
        return 'Credit';
      case 'cash':
        return 'Cash';
      case 'crypto':
        return 'Crypto';
      case 'investment':
        return 'Investment';
      default:
        return category.split('_').map((word) =>
            word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
