import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/budgets/budget_provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/shared/models/budget.dart';
import 'package:fundvanceai/core/constants/currencies.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget; // For editing existing budget

  const BudgetFormScreen({super.key, this.budget});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedPeriod = 'monthly';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _useCustomDates = false;
  bool _isLoading = false;

  final List<String> _periods = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  @override
  void initState() {
    super.initState();
    // Load categories if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseProvider = context.read<ExpenseProvider>();
      if (expenseProvider.categories.isEmpty) {
        expenseProvider.loadCategories();
      }
    });
    
    if (widget.budget != null) {
      // Pre-fill form for editing
      _amountController.text = widget.budget!.amount.toStringAsFixed(2);
      _selectedCategoryId = widget.budget!.categoryId;
      _selectedPeriod = widget.budget!.period;
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      _useCustomDates = _startDate != null || _endDate != null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final budgetProvider = context.read<BudgetProvider>();
    final amount = double.parse(_amountController.text);

    bool success;
    if (widget.budget != null) {
      // Update existing budget
      success = await budgetProvider.updateBudget(
        id: widget.budget!.id,
        amount: amount,
        period: _selectedPeriod,
        categoryId: _selectedCategoryId,
        startDate: _useCustomDates ? _startDate : null,
        endDate: _useCustomDates ? _endDate : null,
      );
    } else {
      // Create new budget
      success = await budgetProvider.addBudget(
        amount: amount,
        period: _selectedPeriod,
        categoryId: _selectedCategoryId,
        startDate: _useCustomDates ? _startDate : null,
        endDate: _useCustomDates ? _endDate : null,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true); // Return true to indicate success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(budgetProvider.errorMessage ?? 'Failed to save budget'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getPeriodDescription() {
    switch (_selectedPeriod) {
      case 'daily':
        return 'Budget resets every day';
      case 'weekly':
        return 'Budget resets every week';
      case 'yearly':
        return 'Budget resets every year';
      case 'monthly':
      default:
        return 'Budget resets every month';
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isEditing = widget.budget != null;
    final currencySymbol = Currencies.getSymbol(authProvider.userCurrency);

    // Filter out categories that already have budgets (unless editing)
    final availableCategories = expenseProvider.categories.where((category) {
      if (isEditing && category.id == widget.budget?.categoryId) {
        return true; // Include current category when editing
      }
      return !budgetProvider.categoryHasBudget(category.id);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Budget' : 'Add Budget'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveBudget,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Budget Amount *',
                prefixText: '$currencySymbol ',
                border: const OutlineInputBorder(),
                helperText: 'Maximum amount to spend',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter budget amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                helperText: 'Leave empty for overall budget',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...availableCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Row(
                      children: [
                        if (category.icon != null)
                          Text(
                            category.icon!,
                            style: const TextStyle(fontSize: 20),
                          ),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
            ),
            const SizedBox(height: 16),

            // Period selector
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Period *',
                border: OutlineInputBorder(),
              ),
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period[0].toUpperCase() + period.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value ?? 'monthly';
                });
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                _getPeriodDescription(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            // Custom date range option
            SwitchListTile(
              title: const Text('Custom Date Range'),
              subtitle: const Text('Set specific start and end dates'),
              value: _useCustomDates,
              onChanged: (value) {
                setState(() {
                  _useCustomDates = value;
                  if (!value) {
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
            ),
            const SizedBox(height: 8),

            // Start date picker (if custom dates enabled)
            if (_useCustomDates) ...[
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                        : 'Select start date',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // End date picker
              InkWell(
                onTap: _selectEndDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('MMM dd, yyyy').format(_endDate!)
                        : 'Select end date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Info card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Budgets',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Budgets help you control spending in specific categories or overall\n'
                      '• You\'ll get alerts when approaching or exceeding limits\n'
                      '• Track progress and compare to previous periods\n'
                      '• Each category can have one active budget',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
