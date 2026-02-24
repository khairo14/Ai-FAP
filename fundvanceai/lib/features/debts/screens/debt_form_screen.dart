import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/debts/debt_provider.dart';
import 'package:fundvanceai/shared/models/debt.dart';

class DebtFormScreen extends StatefulWidget {
  final Debt? debt;
  const DebtFormScreen({super.key, this.debt});

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _currentBalanceController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _minimumPaymentController = TextEditingController();
  final _notesController = TextEditingController();

  DebtType _selectedType = DebtType.creditCard;
  int? _paymentDueDay;
  int _paymentReminderDays = 3;
  bool _autoLogPayment = false;
  bool _isLoading = false;

  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final d = widget.debt!;
      _nameController.text = d.name;
      _descriptionController.text = d.description ?? '';
      _totalAmountController.text = d.totalAmount.toStringAsFixed(2);
      _currentBalanceController.text = d.currentBalance.toStringAsFixed(2);
      _interestRateController.text = d.interestRate.toStringAsFixed(2);
      _minimumPaymentController.text = d.minimumPayment.toStringAsFixed(2);
      _notesController.text = d.notes ?? '';
      _selectedType = d.debtType;
      _paymentDueDay = d.paymentDueDay;
      _paymentReminderDays = d.paymentReminderDays;
      _autoLogPayment = d.autoLogPayment;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _currentBalanceController.dispose();
    _interestRateController.dispose();
    _minimumPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<DebtProvider>();

    double parseField(TextEditingController c) =>
        double.parse(c.text.replaceAll(',', ''));

    bool success;
    if (_isEditing) {
      success = await provider.updateDebt(
        id: widget.debt!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        debtType: _selectedType,
        totalAmount: parseField(_totalAmountController),
        currentBalance: parseField(_currentBalanceController),
        interestRate: parseField(_interestRateController),
        minimumPayment: parseField(_minimumPaymentController),
        paymentDueDay: _paymentDueDay,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        paymentReminderDays: _paymentReminderDays,
        autoLogPayment: _autoLogPayment,
      );
    } else {
      success = await provider.addDebt(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        debtType: _selectedType,
        totalAmount: parseField(_totalAmountController),
        currentBalance: parseField(_currentBalanceController),
        interestRate: parseField(_interestRateController),
        minimumPayment: parseField(_minimumPaymentController),
        paymentDueDay: _paymentDueDay,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        paymentReminderDays: _paymentReminderDays,
        autoLogPayment: _autoLogPayment,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.errorMessage ?? 'An error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRate = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: isRate ? null : '\$ ',
        suffixText: isRate ? '%' : null,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return '$label is required';
        final n = double.tryParse(v.replaceAll(',', ''));
        if (n == null || n < 0) return 'Enter a valid number';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Debt' : 'Add Debt'),
        backgroundColor: colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Debt Type ────────────────────────────────────────────────
            Text('Debt Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DebtType.values.map((type) {
                final selected = type == _selectedType;
                return FilterChip(
                  selected: selected,
                  avatar: Icon(type.icon,
                      size: 16,
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant),
                  label: Text(type.label),
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Name ─────────────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Debt Name *',
                hintText: 'e.g. Chase Visa',
                prefixIcon: Icon(Icons.credit_card_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────────
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Total/ Current ────────────────────────────────────────────
            _buildAmountField(
              controller: _totalAmountController,
              label: 'Original Total Amount *',
              hint: '10000.00',
            ),
            const SizedBox(height: 16),
            _buildAmountField(
              controller: _currentBalanceController,
              label: 'Current Balance *',
              hint: '8500.00',
            ),
            const SizedBox(height: 16),

            // ── Rate + Min Payment ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildAmountField(
                    controller: _interestRateController,
                    label: 'Interest Rate * (%)',
                    hint: '19.99',
                    isRate: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAmountField(
                    controller: _minimumPaymentController,
                    label: 'Min. Payment *',
                    hint: '25.00',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Due Day ────────────────────────────────────────────────────
            DropdownButtonFormField<int?>(
              initialValue: _paymentDueDay,
              decoration: const InputDecoration(
                labelText: 'Payment Due Day (optional)',
                prefixIcon: Icon(Icons.event_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...List.generate(
                    28,
                    (i) => DropdownMenuItem(
                        value: i + 1, child: Text('Day ${i + 1}'))),
              ],
              onChanged: (v) => setState(() => _paymentDueDay = v),
            ),
            const SizedBox(height: 16),

            // ── Notes ──────────────────────────────────────────────────────
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Reminder Preferences ───────────────────────────────────────
            DropdownButtonFormField<int>(
              initialValue: _paymentReminderDays,
              decoration: const InputDecoration(
                labelText: 'Remind me before due date',
                prefixIcon: Icon(Icons.notifications_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 day before')),
                DropdownMenuItem(value: 2, child: Text('2 days before')),
                DropdownMenuItem(value: 3, child: Text('3 days before')),
                DropdownMenuItem(value: 5, child: Text('5 days before')),
                DropdownMenuItem(value: 7, child: Text('7 days before')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _paymentReminderDays = v);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto-log payment'),
              subtitle: const Text(
                  'Automatically record a payment when due date arrives'),
              value: _autoLogPayment,
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.auto_mode_outlined),
              onChanged: (v) => setState(() => _autoLogPayment = v),
            ),
            const SizedBox(height: 16),

            // ── Submit ─────────────────────────────────────────────────────
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save Changes' : 'Add Debt'),
            ),
          ],
        ),
      ),
    );
  }
}
