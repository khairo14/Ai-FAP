import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/budgets/budget_provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/shared/models/budget.dart';
import 'package:fundvanceai/core/constants/currencies.dart';
import 'package:fundvanceai/core/utils/icon_helper.dart';

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
  bool _carryForward = false;
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
      _carryForward = widget.budget!.carryForward;

      // Check if dates are custom or auto-calculated defaults
      if (widget.budget!.startDate != null && widget.budget!.endDate != null) {
        final now = DateTime.now();
        final defaultStart = _getDefaultStartDate(widget.budget!.period, now);
        final defaultEnd = _getDefaultEndDate(widget.budget!.period, now);

        // Only treat as custom if dates don't match defaults
        final isCustom =
            widget.budget!.startDate!.compareTo(defaultStart) != 0 ||
                widget.budget!.endDate!.compareTo(defaultEnd) != 0;

        if (isCustom) {
          _startDate = widget.budget!.startDate;
          _endDate = widget.budget!.endDate;
          _useCustomDates = true;
        }
      }
    }
  }

  /// Get default start date based on period
  DateTime _getDefaultStartDate(String period, DateTime now) {
    switch (period.toLowerCase()) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'yearly':
        return DateTime(now.year, 1, 1);
      case 'monthly':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  /// Get default end date based on period
  DateTime _getDefaultEndDate(String period, DateTime now) {
    switch (period.toLowerCase()) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return startOfWeek.add(const Duration(days: 6));
      case 'yearly':
        return DateTime(now.year, 12, 31);
      case 'monthly':
      default:
        return DateTime(now.year, now.month + 1, 0);
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
        carryForward: _carryForward,
      );
    } else {
      // Create new budget
      success = await budgetProvider.addBudget(
        amount: amount,
        period: _selectedPeriod,
        categoryId: _selectedCategoryId,
        startDate: _useCustomDates ? _startDate : null,
        endDate: _useCustomDates ? _endDate : null,
        carryForward: _carryForward,
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
    final seenIds = <String>{};
    final availableCategories = expenseProvider.categories.where((category) {
      // Skip empty IDs
      if (category.id.isEmpty) {
        return false;
      }

      // Check for duplicates
      if (seenIds.contains(category.id)) {
        return false;
      }
      seenIds.add(category.id);

      // When editing, include the current category
      if (isEditing && category.id == widget.budget?.categoryId) {
        return true;
      }
      // Otherwise, only include categories without budgets
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
                prefixIcon: Icon(Icons.account_balance_wallet,
                    size: 20, color: Colors.purple[400]),
                prefixText: '$currencySymbol ',
                border: const OutlineInputBorder(),
                helperText: 'Maximum amount to spend',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const SizedBox(height: 12),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId != null &&
                      availableCategories
                          .any((c) => c.id == _selectedCategoryId)
                  ? _selectedCategoryId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category, size: 20, color: Colors.amber),
                border: OutlineInputBorder(),
                helperText: 'Leave empty for overall budget',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...availableCategories.map((category) {
                  return DropdownMenuItem<String>(
                    key: ValueKey(category.id),
                    value: category.id,
                    child: Row(
                      children: [
                        if (category.icon != null)
                          Icon(
                            IconHelper.getIconData(category.icon),
                            size: 20,
                            color: category.color != null
                                ? IconHelper.hexToColor(category.color!)
                                : null,
                          ),
                        const SizedBox(width: 12),
                        Text(category.name,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) {
                      // Disable during save
                      setState(() => _selectedCategoryId = value);
                    },
            ),
            const SizedBox(height: 12),

            // Period selector
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Period *',
                prefixIcon:
                    Icon(Icons.calendar_month, size: 20, color: Colors.blue),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                _getPeriodDescription(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            // Custom date range option
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                title: const Text('Custom Date Range',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Set specific start and end dates',
                    style: TextStyle(fontSize: 12)),
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
            ),
            const SizedBox(height: 12),

            // Start date picker (if custom dates enabled)
            if (_useCustomDates) ...[
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    prefixIcon: Icon(Icons.calendar_today,
                        size: 20, color: Colors.green),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                        : 'Select start date',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // End date picker
              InkWell(
                onTap: _selectEndDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    prefixIcon: Icon(Icons.calendar_today,
                        size: 20, color: Colors.orange),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('MMM dd, yyyy').format(_endDate!)
                        : 'Select end date',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Carry-forward option (not available for custom date ranges)
            if (!_useCustomDates) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  title: const Text('Carry Forward Unspent',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text(
                      'Roll unused budget from previous period into this one',
                      style: TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.savings_outlined),
                  value: _carryForward,
                  onChanged: (value) => setState(() => _carryForward = value),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Info card
            Card(
              elevation: 0,
              color: Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.teal.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Budgets',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Budgets help you control spending in specific categories or overall\n'
                      '• You\'ll get alerts when approaching or exceeding limits\n'
                      '• Track progress and compare to previous periods\n'
                      '• Each category can have one active budget',
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.teal.shade900),
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
