import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/transfer_category.dart';
import '../../../shared/services/transfer_category_service.dart';
import '../../../core/constants/currencies.dart';
import '../../accounts/account_provider.dart';
import '../transfer_provider.dart';

class CreateTransferDialog extends StatefulWidget {
  final Account? preselectedFromAccount;
  final Account? preselectedToAccount;

  const CreateTransferDialog({
    super.key,
    this.preselectedFromAccount,
    this.preselectedToAccount,
  });

  @override
  State<CreateTransferDialog> createState() => _CreateTransferDialogState();
}

class _CreateTransferDialogState extends State<CreateTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();

  Account? _fromAccount;
  Account? _toAccount;
  TransferCategory? _selectedCategory;
  List<TransferCategory> _categories = [];
  final DateTime _transferDate = DateTime.now();
  double? _exchangeRate;
  bool _isLoadingRate = false;
  bool _useCustomRate = false;
  final _customRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromAccount = widget.preselectedFromAccount;
    _toAccount = widget.preselectedToAccount;
    _loadCategories();

    if (_fromAccount != null && _toAccount != null) {
      _loadExchangeRate();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _customRateController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await TransferCategoryService().getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _loadExchangeRate() async {
    if (_fromAccount == null || _toAccount == null) return;
    if (_fromAccount!.currency == _toAccount!.currency) {
      setState(() {
        _exchangeRate = 1.0;
      });
      return;
    }

    setState(() {
      _isLoadingRate = true;
    });

    final transferProvider =
        Provider.of<TransferProvider>(context, listen: false);
    final rate = await transferProvider.getExchangeRate(
      _fromAccount!.currency,
      _toAccount!.currency,
    );

    setState(() {
      _exchangeRate = rate;
      _isLoadingRate = false;
    });
  }

  double get _convertedAmount {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = _useCustomRate
        ? (double.tryParse(_customRateController.text) ?? _exchangeRate ?? 1.0)
        : (_exchangeRate ?? 1.0);
    return amount * rate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    final activeAccounts = accountProvider.accounts
        .where((a) => a.isActive && a.deletedAt == null)
        .toList();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Transfer Money',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // From Account
                  Text(
                    'From Account',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Account>(
                    initialValue: _fromAccount,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    hint: const Text('Select source account'),
                    validator: (value) {
                      if (value == null) return 'Please select source account';
                      return null;
                    },
                    items: activeAccounts.map((account) {
                      return DropdownMenuItem(
                        value: account,
                        child: Text(
                          '${account.name} (${Currencies.getSymbol(account.currency)}${account.currentBalance.toStringAsFixed(2)})',
                        ),
                      );
                    }).toList(),
                    onChanged: (account) {
                      setState(() {
                        _fromAccount = account;
                      });
                      _loadExchangeRate();
                    },
                  ),
                  const SizedBox(height: 16),

                  // To Account
                  Text(
                    'To Account',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Account>(
                    initialValue: _toAccount,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    hint: const Text('Select destination account'),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select destination account';
                      }
                      if (value.id == _fromAccount?.id) {
                        return 'Cannot transfer to the same account';
                      }
                      return null;
                    },
                    items: activeAccounts.map((account) {
                      return DropdownMenuItem(
                        value: account,
                        child: Text(
                          '${account.name} (${Currencies.getSymbol(account.currency)}${account.currentBalance.toStringAsFixed(2)})',
                        ),
                      );
                    }).toList(),
                    onChanged: (account) {
                      setState(() {
                        _toAccount = account;
                      });
                      _loadExchangeRate();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  Text(
                    'Amount',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixText: _fromAccount != null
                          ? '${Currencies.getSymbol(_fromAccount!.currency)} '
                          : null,
                      hintText: '0.00',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter valid amount';
                      }
                      if (_fromAccount != null &&
                          amount > _fromAccount!.currentBalance) {
                        return 'Insufficient balance';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Exchange Rate (if different currencies)
                  if (_fromAccount != null &&
                      _toAccount != null &&
                      _fromAccount!.currency != _toAccount!.currency) ...[
                    Card(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.currency_exchange,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Currency Conversion',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingRate)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              Row(
                                children: [
                                  Text('Exchange Rate: '),
                                  Text(
                                    '1 ${_fromAccount!.currency} = ${_exchangeRate?.toStringAsFixed(4) ?? '-'} ${_toAccount!.currency}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                value: _useCustomRate,
                                onChanged: (value) {
                                  setState(() {
                                    _useCustomRate = value ?? false;
                                  });
                                },
                                title: const Text('Use custom rate'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              if (_useCustomRate) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _customRateController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: 'Custom rate',
                                    hintText: _exchangeRate?.toStringAsFixed(4),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Recipient will receive:'),
                                  Text(
                                    '${Currencies.getSymbol(_toAccount!.currency)}${_convertedAmount.toStringAsFixed(2)}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Transfer Category (Optional)
                  Text(
                    'Category (Optional)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TransferCategory?>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    hint: const Text('Select category'),
                    items: [
                      const DropdownMenuItem<TransferCategory?>(
                        value: null,
                        child: Text('No Category'),
                      ),
                      ..._categories.map(
                        (cat) => DropdownMenuItem<TransferCategory?>(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(cat.name),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (cat) => setState(() => _selectedCategory = cat),
                  ),
                  const SizedBox(height: 16),

                  // Transfer Fee
                  Text(
                    'Transfer Fee (Optional)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _feeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixText: _fromAccount != null
                          ? '${Currencies.getSymbol(_fromAccount!.currency)} '
                          : null,
                      hintText: '0.00',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description (Optional)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Transfer notes',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _submitTransfer,
                        icon: const Icon(Icons.send),
                        label: const Text('Transfer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final fee = double.tryParse(_feeController.text) ?? 0.0;
    final convertedAmount = _fromAccount!.currency != _toAccount!.currency
        ? _convertedAmount
        : amount;
    final rate = _useCustomRate
        ? double.tryParse(_customRateController.text)
        : _exchangeRate;

    final transferProvider =
        Provider.of<TransferProvider>(context, listen: false);
    final accountProvider =
        Provider.of<AccountProvider>(context, listen: false);

    final success = await transferProvider.createTransfer(
      fromAccountId: _fromAccount!.id,
      toAccountId: _toAccount!.id,
      fromAmount: amount,
      fromCurrency: _fromAccount!.currency,
      toAmount: convertedAmount,
      toCurrency: _toAccount!.currency,
      categoryId: _selectedCategory?.id,
      exchangeRate: rate,
      transferFee: fee,
      feeCurrency: _fromAccount!.currency,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      referenceNumber: _referenceController.text.isNotEmpty
          ? _referenceController.text
          : null,
      transferDate: _transferDate,
    );

    if (success && mounted) {
      // Reload accounts to update balances
      await accountProvider.loadAccounts();
      if (!mounted) return;

      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              transferProvider.errorMessage ?? 'Failed to create transfer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
