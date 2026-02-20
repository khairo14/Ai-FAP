import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../auth/auth_provider.dart';
import '../../accounts/account_provider.dart';
import '../income_provider.dart';
import '../../../shared/models/income.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/utils/icon_helper.dart';

class IncomeFormScreen extends StatefulWidget {
  final Income? income;

  const IncomeFormScreen({super.key, this.income});

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _taxPercentageController = TextEditingController();
  final _taxFixedController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedAccountId;
  String _selectedCurrency = 'USD';
  String? _taxType;
  bool _isRecurring = false;
  String? _recurrencePattern;
  bool _isLoading = false;
  bool _hasInitialized = false;

  double _calculatedTax = 0;
  double _netAmount = 0;

  @override
  void initState() {
    super.initState();

    if (widget.income != null) {
      final inc = widget.income!;
      _amountController.text = inc.amount.toStringAsFixed(2);
      _descriptionController.text = inc.description ?? '';
      _selectedDate = inc.incomeDate;
      _selectedCategoryId = inc.categoryId;
      _selectedAccountId = inc.accountId;
      _selectedCurrency = inc.currency;
      _taxType = inc.taxType;

      if (inc.taxPercentage != null) {
        _taxPercentageController.text = inc.taxPercentage!.toStringAsFixed(2);
      }
      if (inc.taxFixedAmount != null) {
        _taxFixedController.text = inc.taxFixedAmount!.toStringAsFixed(2);
      }

      _isRecurring = inc.isRecurring;
      _recurrencePattern = inc.recurrencePattern;
      _calculatedTax = inc.taxCalculated ?? 0;
      _netAmount = inc.netAmount;
    }

    _amountController.addListener(_calculateTax);
    _taxPercentageController.addListener(_calculateTax);
    _taxFixedController.addListener(_calculateTax);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      _hasInitialized = true;

      final incomeProvider = context.read<IncomeProvider>();
      final accountProvider = context.read<AccountProvider>();

      if (incomeProvider.categories.isEmpty) {
        incomeProvider.loadCategories();
      }
      if (accountProvider.accounts.isEmpty) {
        accountProvider.loadAccounts();
      }

      if (widget.income == null) {
        final authProvider = context.read<AuthProvider>();
        _selectedCurrency = authProvider.userCurrency;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _taxPercentageController.dispose();
    _taxFixedController.dispose();
    super.dispose();
  }

  void _onAccountChanged(String? accountId, AccountProvider accountProvider) {
    setState(() {
      _selectedAccountId = accountId;
      if (accountId != null) {
        final account = accountProvider.accounts
            .firstWhere((a) => a.id == accountId);
        _selectedCurrency = account.currency;
      }
    });
  }

  void _calculateTax() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    double tax = 0;

    if (_taxType == 'percentage') {
      final percentage = double.tryParse(_taxPercentageController.text) ?? 0;
      tax = amount * (percentage / 100);
    } else if (_taxType == 'fixed') {
      tax = double.tryParse(_taxFixedController.text) ?? 0;
    } else if (_taxType == 'hybrid') {
      final percentage = double.tryParse(_taxPercentageController.text) ?? 0;
      final fixed = double.tryParse(_taxFixedController.text) ?? 0;
      tax = (amount * (percentage / 100)) + fixed;
    }

    setState(() {
      _calculatedTax = tax;
      _netAmount = amount - tax;
    });
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

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<IncomeProvider>();
    final amount = double.parse(_amountController.text);
    final taxPercentage = (_taxType == 'percentage' || _taxType == 'hybrid')
        ? double.tryParse(_taxPercentageController.text)
        : null;
    final taxFixed = (_taxType == 'fixed' || _taxType == 'hybrid')
        ? double.tryParse(_taxFixedController.text)
        : null;

    bool success;
    if (widget.income != null) {
      success = await provider.updateIncome(
        id: widget.income!.id,
        amount: amount,
        currency: _selectedCurrency,
        categoryId: _selectedCategoryId,
        incomeDate: _selectedDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        taxType: _taxType,
        taxPercentage: taxPercentage,
        taxFixedAmount: taxFixed,
        isRecurring: _isRecurring,
        recurrencePattern: _recurrencePattern,
        accountId: _selectedAccountId,
      );
    } else {
      success = await provider.addIncome(
        amount: amount,
        currency: _selectedCurrency,
        categoryId: _selectedCategoryId ?? '',
        incomeDate: _selectedDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        taxType: _taxType,
        taxPercentage: taxPercentage,
        taxFixedAmount: taxFixed,
        isRecurring: _isRecurring,
        recurrencePattern: _recurrencePattern,
        accountId: _selectedAccountId,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save income'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.income != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Income' : 'Add Income'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Income?'),
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
                  final success = await context
                      .read<IncomeProvider>()
                      .deleteIncome(widget.income!.id);
                  if (success && mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
            ),
        ],
      ),
      body: Consumer2<IncomeProvider, AccountProvider>(
        builder: (context, incomeProvider, accountProvider, _) {
          final currencySymbol = Currencies.getSymbol(_selectedCurrency);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                //  Main details card 
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Amount
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixIcon: Icon(Icons.payments,
                                color: Colors.green[400]),
                            prefixText: '$currencySymbol ',
                            hintText: '0.00',
                          ),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            if (double.parse(value) <= 0) {
                              return 'Must be > 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category
                        if (incomeProvider.isLoading &&
                            incomeProvider.categories.isEmpty)
                          const LinearProgressIndicator()
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category,
                                  color: Colors.amber[700]),
                            ),
                            items: incomeProvider.categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconHelper.getIcon(cat.icon,
                                        size: 20,
                                        color: IconHelper.hexToColor(
                                            cat.color)),
                                    const SizedBox(width: 8),
                                    Text(cat.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategoryId = v),
                            validator: (v) => v == null
                                ? 'Please select a category'
                                : null,
                          ),
                        const SizedBox(height: 16),

                        // Date
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.calendar_today,
                                  color: Colors.blue[400]),
                            ),
                            child: Text(DateFormat('MMM dd, yyyy')
                                .format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Account (required — income always goes into an account)
                        DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          decoration: InputDecoration(
                            labelText: 'Account *',
                            helperText:
                                'Balance will increase by net income amount',
                            prefixIcon: Icon(
                                Icons.account_balance_wallet,
                                color: Colors.teal[400]),
                          ),
                          items: accountProvider.accounts.map((acc) {
                            return DropdownMenuItem<String>(
                              value: acc.id,
                              child: Text(
                                  '${acc.name}  (${Currencies.getSymbol(acc.currency)}${acc.currentBalance.toStringAsFixed(2)})'),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              _onAccountChanged(v, accountProvider),
                          validator: (v) =>
                              v == null ? 'Please select an account' : null,
                        ),
                        const SizedBox(height: 16),

                        // Currency (auto-set by account, still editable)
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: InputDecoration(
                            labelText: 'Currency',
                            helperText: _selectedAccountId != null
                                ? 'Set by selected account'
                                : null,
                            prefixIcon: Icon(Icons.currency_exchange,
                                color: Colors.purple[400]),
                          ),
                          items: Currencies.all.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.code,
                              child: Text(
                                  '${c.symbol}  ${c.code} - ${c.name}'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedCurrency = v);
                            }
                          },
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please select a currency'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //  Tax card 
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Calculation',
                          style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _taxType,
                          decoration: InputDecoration(
                            labelText: 'Tax Type',
                            prefixIcon: Icon(Icons.receipt_long,
                                color: Colors.orange[400]),
                          ),
                          items: const [
                            DropdownMenuItem<String>(
                                value: null, child: Text('No Tax')),
                            DropdownMenuItem<String>(
                                value: 'percentage',
                                child: Text('Percentage (%)')),
                            DropdownMenuItem<String>(
                                value: 'fixed',
                                child: Text('Fixed Amount')),
                            DropdownMenuItem<String>(
                                value: 'hybrid',
                                child: Text('Hybrid (% + Fixed)')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _taxType = value;
                              _calculateTax();
                            });
                          },
                        ),

                        if (_taxType == 'percentage' ||
                            _taxType == 'hybrid') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _taxPercentageController,
                            decoration: const InputDecoration(
                              labelText: 'Tax Percentage',
                              suffixText: '%',
                              prefixIcon: Icon(Icons.percent),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ],

                        if (_taxType == 'fixed' ||
                            _taxType == 'hybrid') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _taxFixedController,
                            decoration: InputDecoration(
                              labelText: 'Fixed Tax Amount',
                              prefixText: '$currencySymbol ',
                              prefixIcon: const Icon(Icons.money_off),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ],

                        if (_taxType != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tax:',
                                        style:
                                            theme.textTheme.bodyMedium),
                                    Text(
                                      '$currencySymbol${NumberFormat('#,##0.00').format(_calculatedTax)}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Net Income:',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.bold)),
                                    Text(
                                      '$currencySymbol${NumberFormat('#,##0.00').format(_netAmount)}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //  Notes card 
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description,
                                color: Colors.purple),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes (Optional)',
                            prefixIcon: Icon(Icons.sticky_note_2,
                                color: Colors.amber),
                          ),
                          maxLines: 2,
                        ),
                        CheckboxListTile(
                          title: const Text('Recurring Income'),
                          subtitle:
                              const Text('This income repeats regularly'),
                          value: _isRecurring,
                          onChanged: (v) =>
                              setState(() => _isRecurring = v ?? false),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_isRecurring) ...[
                          DropdownButtonFormField<String>(
                            value: _recurrencePattern,
                            decoration: const InputDecoration(
                              labelText: 'Recurrence Pattern',
                            ),
                            items: const [
                              DropdownMenuItem<String>(
                                  value: 'weekly',
                                  child: Text('Weekly')),
                              DropdownMenuItem<String>(
                                  value: 'monthly',
                                  child: Text('Monthly')),
                              DropdownMenuItem<String>(
                                  value: 'yearly',
                                  child: Text('Yearly')),
                            ],
                            onChanged: (v) =>
                                setState(() => _recurrencePattern = v),
                            validator: (v) {
                              if (_isRecurring && v == null) {
                                return 'Please select a recurrence pattern';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                //  Save button 
                FilledButton(
                  onPressed: _isLoading ? null : _saveIncome,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Text(isEditing ? 'Update Income' : 'Add Income'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}