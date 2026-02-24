import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../account_provider.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../shared/models/account_type.dart';
import '../../../core/constants/currencies.dart';
import '../../auth/auth_provider.dart';

/// Dialog for adding a new account
class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({super.key});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  final _creditLimitController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCurrency;
  bool _includeInTotal = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize currency with user's profile currency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      setState(() {
        _selectedCurrency = authProvider.userCurrency;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<AccountProvider>();

    // Find the first account type in the selected category
    final accountType = provider.accountTypes
        .firstWhere((type) => type.category == _selectedCategory);

    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final creditLimit = _creditLimitController.text.isEmpty
        ? null
        : double.tryParse(_creditLimitController.text);

    final success = await provider.createAccount(
      name: _nameController.text.trim(),
      accountTypeId: accountType.id,
      currency: _selectedCurrency ?? 'USD',
      initialBalance: balance,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      creditLimit: creditLimit,
      includeInTotal: _includeInTotal,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to create account'),
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
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
    final provider = context.watch<AccountProvider>();
    final accountTypes = provider.accountTypes;

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
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
                      // Account Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Account Category *',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                          helperText: 'Choose the type of account',
                        ),
                        items: _buildCategoryItems(accountTypes),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an account category';
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
                          hintText: 'e.g., My Checking Account, PayPal Wallet',
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                          helperText: 'Give your account a unique name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an account name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Initial Balance with Currency Selector
                      TextFormField(
                        controller: _balanceController,
                        decoration: InputDecoration(
                          labelText: 'Initial Balance',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.account_balance),
                          prefixText:
                              '${Currencies.getSymbol(_selectedCurrency ?? 'USD')} ',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.currency_exchange),
                            onPressed: () => _showCurrencyPicker(context),
                            tooltip: 'Change currency',
                          ),
                          border: const OutlineInputBorder(),
                          helperText:
                              'Current balance in ${_selectedCurrency ?? "USD"}',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final balance = double.tryParse(value);
                            if (balance == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Credit Limit (optional)
                      TextFormField(
                        controller: _creditLimitController,
                        decoration: const InputDecoration(
                          labelText: 'Credit Limit (Optional)',
                          hintText: 'For credit cards or lines of credit',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                      ),
                      const SizedBox(height: 16),

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
                        subtitle: const Text(
                            'Count this account in overall net worth'),
                        value: _includeInTotal,
                        onChanged: (value) {
                          setState(() => _includeInTotal = value);
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
                    onPressed: _isLoading ? null : _saveAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildCategoryItems(
      List<AccountType> accountTypes) {
    // Fixed order: cash first, then alphabetical for the rest
    const categoryOrder = [
      'cash',
      'e_wallet',
      'online_bank',
      'bank',
      'credit',
      'investment',
      'crypto'
    ];
    final available = accountTypes.map((type) => type.category).toSet();
    final categories =
        categoryOrder.where((c) => available.contains(c)).toList();

    return categories.map((category) {
      // Get first account type from this category for icon reference
      final firstType =
          accountTypes.firstWhere((type) => type.category == category);

      return DropdownMenuItem<String>(
        value: category,
        child: Row(
          children: [
            Icon(
              IconHelper.accountTypeIcon(category).$1,
              size: 20,
              color: Color(int.parse(firstType.color.substring(1), radix: 16) +
                  0xFF000000),
            ),
            const SizedBox(width: 12),
            Text(_formatCategory(category)),
          ],
        ),
      );
    }).toList();
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
        return category
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
