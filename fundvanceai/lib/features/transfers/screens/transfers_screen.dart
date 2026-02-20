import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../transfer_provider.dart';
import '../widgets/create_transfer_dialog.dart';
import '../../../shared/models/transfer.dart';
import '../../../core/constants/currencies.dart';
import '../../accounts/account_provider.dart';

/// Transfer management screen for inter-account transfers
class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransferProvider>(context, listen: false).loadTransfers();
      Provider.of<AccountProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transferProvider = Provider.of<TransferProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTransferDialog(context),
            tooltip: 'New Transfer',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => transferProvider.loadTransfers(),
        child: _buildBody(theme, transferProvider),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTransferDialog(context),
        icon: const Icon(Icons.swap_horiz),
        label: const Text('New Transfer'),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, TransferProvider provider) {
    if (provider.isLoading && provider.transfers.isEmpty) {
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
              'Error loading transfers',
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
              onPressed: () => provider.loadTransfers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transfers Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Transfer money between your accounts',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateTransferDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Transfer'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.transfers.length,
      itemBuilder: (context, index) {
        final transfer = provider.transfers[index];
        return _buildTransferCard(theme, transfer);
      },
    );
  }

  Widget _buildTransferCard(ThemeData theme, Transfer transfer) {
    final fromSymbol = Currencies.getSymbol(transfer.fromCurrency);
    final toSymbol = Currencies.getSymbol(transfer.toCurrency);
    final dateStr = _formatDate(transfer.transferDate);
    final isDifferentCurrency = transfer.fromCurrency != transfer.toCurrency;
    final fromLabel = transfer.fromAccountName ?? transfer.fromAccountId.substring(0, 8);
    final toLabel = transfer.toAccountName ?? transfer.toAccountId.substring(0, 8);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.swap_horiz,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Flexible(child: Text(fromLabel, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 14),
            ),
            Flexible(child: Text(toLabel, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$fromSymbol${transfer.fromAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16),
                Expanded(
                  child: Text(
                    '$toSymbol${transfer.toAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (isDifferentCurrency && transfer.exchangeRate != null)
              Text(
                'Rate: ${transfer.exchangeRate!.toStringAsFixed(4)}',
                style: theme.textTheme.bodySmall,
              ),
            if (transfer.transferFee > 0)
              Text(
                'Fee: $fromSymbol${transfer.transferFee.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            if (transfer.description != null && transfer.description!.isNotEmpty)
              Text(
                transfer.description!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (transfer.categoryName != null)
              Row(
                children: [
                  Icon(Icons.label_outline, size: 13,
                      color: theme.colorScheme.primary.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    transfer.categoryName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(context, transfer);
            }
          },
          itemBuilder: (context) => [
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transferDate = DateTime(date.year, date.month, date.day);

    if (transferDate == today) {
      return 'Today';
    } else if (transferDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showCreateTransferDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateTransferDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Transfer transfer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transfer?'),
        content: Text(
          'Are you sure you want to delete this transfer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final transferProvider =
                  Provider.of<TransferProvider>(context, listen: false);

              final success = await transferProvider.deleteTransfer(transfer.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Transfer deleted successfully'
                          : 'Failed to delete transfer',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
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