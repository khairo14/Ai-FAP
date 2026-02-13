import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/accounts/account_provider.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/core/constants/currencies.dart';
import 'package:fundvanceai/core/utils/icon_helper.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedCurrency; // Currency of the selected account
  String? _selectedPaymentMethod;
  bool _isRecurring = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseProvider = context.read<ExpenseProvider>();
      final accountProvider = context.read<AccountProvider>();
      final authProvider = context.read<AuthProvider>();
      
      if (expenseProvider.categories.isEmpty) {
        expenseProvider.loadCategories();
      }
      if (accountProvider.accounts.isEmpty) {
        accountProvider.loadAccounts();
      }
      
      // Set initial currency
      if (widget.expense != null && _selectedAccountId != null) {
        // If editing, get currency from the account
        final account = accountProvider.accounts.firstWhere(
          (a) => a.id == _selectedAccountId,
          orElse: () => accountProvider.accounts.first,
        );
        setState(() => _selectedCurrency = account.currency);
      } else {
        // For new expenses, use user's default currency initially
        setState(() => _selectedCurrency = authProvider.userCurrency);
      }
    });
    
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _merchantController.text = widget.expense!.merchant ?? '';
      _descriptionController.text = widget.expense!.description ?? '';
      _notesController.text = widget.expense!.notes ?? '';
      _selectedDate = widget.expense!.date;
      _selectedCategoryId = widget.expense!.categoryId;
      _selectedAccountId = widget.expense!.accountId;
      _selectedPaymentMethod = widget.expense!.paymentMethod;
      _isRecurring = widget.expense!.isRecurring;
    } else {
      // For new expenses, wait for account selection to set payment method
      _selectedPaymentMethod = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ExpenseProvider>();
    final amount = double.parse(_amountController.text);

    bool success;
    if (widget.expense != null) {
      success = await provider.updateExpense(
        id: widget.expense!.id,
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        paymentMethod: _selectedPaymentMethod,
        merchant: _merchantController.text.isEmpty ? null : _merchantController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isRecurring: _isRecurring,
      );
    } else {
      success = await provider.addExpense(
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        paymentMethod: _selectedPaymentMethod,
        merchant: _merchantController.text.isEmpty ? null : _merchantController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isRecurring: _isRecurring,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.money;
      case 'Credit Card':
        return Icons.credit_card;
      case 'Debit Card':
        return Icons.payment;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'E-Wallet':
        return Icons.account_balance_wallet;
      case 'Online Banking':
        return Icons.computer;
      default:
        return Icons.payments;
    }
  }

  String _getPaymentMethodFromAccountType(String? accountTypeCategory) {
    if (accountTypeCategory == null) return 'Cash';
    
    // Use the account type category field for more reliable mapping
    switch (accountTypeCategory.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'credit':
        return 'Credit Card';
      case 'bank':
        return 'Debit Card'; // Traditional bank accounts with debit cards
      case 'online_bank':
      case 'crypto':
      case 'investment':
        return 'Online Banking'; // Online-only transactions
      case 'e_wallet':
        return 'E-Wallet';
      default:
        return 'Cash';
    }
  }

  void _onAccountChanged(String? accountId, List<dynamic> accounts) {
    setState(() {
      _selectedAccountId = accountId;
      
      // Auto-select payment method and currency based on selected account
      if (accountId != null) {
        final account = accounts.firstWhere((a) => a.id == accountId);
        _selectedPaymentMethod = _getPaymentMethodFromAccountType(account.accountTypeCategory);
        _selectedCurrency = account.currency; // Update currency to match account
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.expense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Expense?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  final success = await context.read<ExpenseProvider>().deleteExpense(widget.expense!.id);
                  if (success && mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
            ),
        ],
      ),
      body: Consumer2<ExpenseProvider, AccountProvider>(
        builder: (context, expenseProvider, accountProvider, child) {
          if (expenseProvider.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final authProvider = context.read<AuthProvider>();
          // Use selected account's currency, fallback to user's default currency
          final currencySymbol = Currencies.getSymbol(
            _selectedCurrency ?? authProvider.userCurrency
          );

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Expense Name (Merchant)
                        TextFormField(
                          controller: _merchantController,
                          decoration: InputDecoration(
                            labelText: 'Expense Name',
                            hintText: 'e.g., McDonald\'s, Uber, Electricity Bill',
                            prefixIcon: Icon(Icons.store, color: Colors.teal[400]),
                            helperText: 'What was this expense for?',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),

                        // Amount
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixIcon: Icon(Icons.payments, color: Colors.purple[400]),
                            prefixText: '$currencySymbol ',
                            hintText: '0.00',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            if (double.parse(value) <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category
                        DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category, color: Colors.amber[700]),
                          ),
                          items: expenseProvider.categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Row(
                                children: [
                                  if (cat.icon != null)
                                    Icon(
                                      IconHelper.getIconData(cat.icon),
                                      size: 20,
                                      color: cat.color != null
                                          ? IconHelper.hexToColor(cat.color!)
                                          : null,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(cat.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCategoryId = v),
                          validator: (v) => v == null ? 'Please select a category' : null,
                        ),
                        const SizedBox(height: 16),

                        // Date
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue[400]),
                            ),
                            child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Account (Required)
                        DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          decoration: InputDecoration(
                            labelText: 'Account',
                            prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.green[400]),
                          ),
                          items: accountProvider.accounts.map((acc) {
                            return DropdownMenuItem(
                              value: acc.id,
                              child: Text('${acc.name} (${Currencies.getSymbol(acc.currency)}${acc.currentBalance.toStringAsFixed(2)})'),
                            );
                          }).toList(),
                          onChanged: (v) => _onAccountChanged(v, accountProvider.accounts),
                          validator: (v) => v == null ? 'Please select an account' : null,
                        ),
                        const SizedBox(height: 16),

                        // Payment Method (Auto-selected but editable)
                        DropdownButtonFormField<String>(
                          value: _selectedPaymentMethod,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            prefixIcon: Icon(
                              _selectedPaymentMethod != null
                                  ? _getPaymentMethodIcon(_selectedPaymentMethod!)
                                  : Icons.payment,
                              color: Colors.orange,
                            ),
                            helperText: 'Auto-selected, can be changed',
                            helperMaxLines: 1,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
                            DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
                            DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                            DropdownMenuItem(value: 'E-Wallet', child: Text('E-Wallet')),
                            DropdownMenuItem(value: 'Online Banking', child: Text('Online Banking')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (v) => setState(() => _selectedPaymentMethod = v),
                          validator: (v) => v == null ? 'Please select payment method' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Additional Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description, color: Colors.purple),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes (Optional)',
                            prefixIcon: Icon(Icons.sticky_note_2, color: Colors.amber),
                          ),
                          maxLines: 3,
                        ),
                        CheckboxListTile(
                          title: const Text('Recurring Expense'),
                          value: _isRecurring,
                          onChanged: (v) => setState(() => _isRecurring = v ?? false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                FilledButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEditing ? 'Update Expense' : 'Add Expense'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
