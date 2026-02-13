import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../account_provider.dart';
import '../../../shared/models/account.dart';
import '../../../core/constants/currencies.dart';

/// Dialog for editing an existing account
class EditAccountDialog extends StatefulWidget {
  final Account account;

  const EditAccountDialog({
    super.key,
    required this.account,
  });

  @override
  State<EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<EditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _institutionController;
  late final TextEditingController _initialBalanceController;
  late final TextEditingController _creditLimitController;
  
  late String _selectedCurrency;
  late bool _includeInTotal;
  late bool _isActive;
  late bool _isInitialBalanceSet; // Track if initial balance has been set
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing account data
    _nameController = TextEditingController(text: widget.account.name);
    _descriptionController = TextEditingController(text: widget.account.description ?? '');
    _institutionController = TextEditingController(text: widget.account.institutionName ?? '');
    _initialBalanceController = TextEditingController(
      text: widget.account.initialBalance.toStringAsFixed(2),
    );
    _creditLimitController = TextEditingController(
      text: widget.account.creditLimit?.toStringAsFixed(2) ?? '',
    );
    _selectedCurrency = widget.account.currency;
    _includeInTotal = widget.account.includeInTotal;
    _isActive = widget.account.isActive;
    
    // Initial balance is considered "set" if it's not 0 or if there are transactions
    _isInitialBalanceSet = widget.account.initialBalance != 0 || 
                          widget.account.currentBalance != widget.account.initialBalance;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _institutionController.dispose();
    _initialBalanceController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<AccountProvider>();
    
    final initialBalance = double.tryParse(_initialBalanceController.text);
    final creditLimit = _creditLimitController.text.isEmpty 
        ? null 
        : double.tryParse(_creditLimitController.text);

    final success = await provider.updateAccount(
      accountId: widget.account.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      institutionName: _institutionController.text.trim().isEmpty
          ? null
          : _institutionController.text.trim(),
      currency: _selectedCurrency != widget.account.currency ? _selectedCurrency : null,
      initialBalance: !_isInitialBalanceSet && initialBalance != widget.account.initialBalance ? initialBalance : null,
      creditLimit: creditLimit,
      includeInTotal: _includeInTotal,
      isActive: _isActive,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCurrencyPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: Currencies.all.length,
            itemBuilder: (context, index) {
              final currency = Currencies.all[index];
              final isSelected = currency.code == _selectedCurrency;
              
              return ListTile(
                leading: Text(
                  currency.symbol,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(currency.name),
                trailing: Text(
                  currency.code,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                selected: isSelected,
                onTap: () {
                  setState(() => _selectedCurrency = currency.code);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = Currencies.getSymbol(_selectedCurrency);

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.account.accountTypeName ?? 'Account',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Balance Info (Read-only)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Balance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Text(
                                      '$currencySymbol ${widget.account.currentBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _selectedCurrency,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Initial Balance with Currency Selector
                      TextFormField(
                        controller: _initialBalanceController,
                        decoration: InputDecoration(
                          labelText: 'Initial Balance',
                          hintText: 'Starting balance for this account',
                          prefixIcon: const Icon(Icons.account_balance),
                          prefixText: '$currencySymbol ',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.currency_exchange),
                            onPressed: () => _showCurrencyPicker(context),
                            tooltip: 'Change currency',
                          ),
                          border: const OutlineInputBorder(),
                          helperText: _isInitialBalanceSet 
                              ? 'Initial balance is locked (already set)'
                              : 'Set your starting balance (can only be set once)',
                          helperMaxLines: 2,
                          filled: _isInitialBalanceSet,
                          fillColor: _isInitialBalanceSet ? Colors.grey.shade200 : null,
                        ),
                        enabled: !_isInitialBalanceSet,
                        style: TextStyle(color: _isInitialBalanceSet ? Colors.grey.shade700 : null),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an initial balance';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Account Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Account Name *',
                          hintText: 'e.g., My Checking Account',
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an account name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Institution Name
                      TextFormField(
                        controller: _institutionController,
                        decoration: const InputDecoration(
                          labelText: 'Institution Name (Optional)',
                          hintText: 'e.g., Chase Bank',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Credit Limit (optional)
                      if (widget.account.isCreditAccount) ...[
                        TextFormField(
                          controller: _creditLimitController,
                          decoration: const InputDecoration(
                            labelText: 'Credit Limit (Optional)',
                            hintText: 'For credit cards or lines of credit',
                            prefixIcon: Icon(Icons.credit_card),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Additional notes about this account',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Include in Total Switch
                      SwitchListTile(
                        title: const Text('Include in Total Balance'),
                        subtitle: const Text('Count this account in overall net worth'),
                        value: _includeInTotal,
                        onChanged: (value) {
                          setState(() => _includeInTotal = value);
                        },
                      ),

                      // Active Status Switch
                      SwitchListTile(
                        title: const Text('Account Active'),
                        subtitle: const Text('Enable to use this account for transactions'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
