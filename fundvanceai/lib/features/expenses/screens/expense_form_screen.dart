import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/shared/models/expense.dart';
import 'package:fundvanceai/core/constants/currencies.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense; // For editing existing expense

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
  String? _selectedPaymentMethod;
  bool _isRecurring = false;
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'E-Wallet',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      // Pre-fill form for editing
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _merchantController.text = widget.expense!.merchant ?? '';
      _descriptionController.text = widget.expense!.description ?? '';
      _notesController.text = widget.expense!.notes ?? '';
      _selectedDate = widget.expense!.date;
      _selectedCategoryId = widget.expense!.categoryId;
      _selectedPaymentMethod = widget.expense!.paymentMethod;
      _isRecurring = widget.expense!.isRecurring;
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ExpenseProvider>();
    final amount = double.parse(_amountController.text);

    bool success;
    if (widget.expense != null) {
      // Update existing expense
      success = await provider.updateExpense(
        id: widget.expense!.id,
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        merchant: _merchantController.text.isEmpty
            ? null
            : _merchantController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isRecurring: _isRecurring,
      );
    } else {
      // Create new expense
      success = await provider.addExpense(
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategoryId,
        merchant: _merchantController.text.isEmpty
            ? null
            : _merchantController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isRecurring: _isRecurring,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true); // Return true to indicate success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save expense'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isEditing = widget.expense != null;
    final currencySymbol = Currencies.getSymbol(authProvider.userCurrency);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
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
              onPressed: _saveExpense,
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
                labelText: 'Amount *',
                prefixText: '$currencySymbol ',
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
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
              ),
              items: provider.categories.map((category) {
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
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
            ),
            const SizedBox(height: 16),

            // Merchant field
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant/Store',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Payment method dropdown
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value);
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Recurring checkbox
            CheckboxListTile(
              title: const Text('Recurring Expense'),
              subtitle: const Text('Mark if this expense repeats regularly'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() => _isRecurring = value ?? false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
