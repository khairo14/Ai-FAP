import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/receipt_scan_result.dart';
import '../../../shared/models/category.dart';
import '../../../shared/services/auto_categorization_service.dart';

/// Full-screen modal displayed after a receipt is scanned.
/// Shows extracted data (editable), confidence indicator, and raw text.
/// Pops with a [Map] of confirmed values when user taps "Use This Data".
class ReceiptReviewScreen extends StatefulWidget {
  final ReceiptScanResult result;
  /// Expense categories passed from caller to avoid async Provider reads
  final List<Category> categories;

  const ReceiptReviewScreen({
    super.key,
    required this.result,
    required this.categories,
  });

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.result.amount != null
          ? widget.result.amount!.toStringAsFixed(2)
          : '',
    );
    _merchantCtrl =
        TextEditingController(text: widget.result.merchant ?? '');
    _selectedDate = widget.result.date ?? DateTime.now();

    // Resolve suggested category synchronously (categories already provided)
    if (widget.result.suggestedCategoryName != null) {
      _selectedCategoryId = AutoCategorizationService.findCategoryId(
        widget.result.suggestedCategoryName!,
        widget.categories,
      );
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    super.dispose();
  }

  Color _confidenceColor(double c) {
    if (c >= 0.8) return Colors.green;
    if (c >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _confidenceLabel(double c) {
    if (c >= 0.8) return 'High confidence';
    if (c >= 0.5) return 'Medium confidence';
    return 'Low confidence — please review';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _useData() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String, dynamic>{
      'amount': double.tryParse(_amountCtrl.text),
      'date': _selectedDate,
      'merchant': _merchantCtrl.text.trim().isEmpty
          ? null
          : _merchantCtrl.text.trim(),
      'categoryId': _selectedCategoryId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conf = widget.result.confidence;
    final confColor = _confidenceColor(conf);
    final categories = widget.categories
        .where((c) => c.categoryType == 'expense' || c.categoryType == 'both')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Review'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Discard',
        ),
        actions: [
          TextButton.icon(
            onPressed: _useData,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Use Data',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Confidence banner ───────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: confColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: confColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    conf >= 0.8
                        ? Icons.check_circle_outline
                        : conf >= 0.5
                            ? Icons.info_outline
                            : Icons.warning_amber_outlined,
                    color: confColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _confidenceLabel(conf),
                      style: TextStyle(
                          color: confColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: confColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(conf * 100).round()}%',
                      style: TextStyle(
                          color: confColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Extracted fields ────────────────────────────────────────
            Text('Extracted Data',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
                suffixIcon: widget.result.amount == null
                    ? const Icon(Icons.warning_amber, color: Colors.orange)
                    : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter the amount';
                }
                if (double.tryParse(v) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Merchant
            TextFormField(
              controller: _merchantCtrl,
              decoration: InputDecoration(
                labelText: 'Merchant / Store',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.store_outlined),
                suffixIcon: widget.result.merchant == null
                    ? const Icon(Icons.warning_amber, color: Colors.orange)
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: widget.result.date == null
                      ? const Icon(Icons.warning_amber, color: Colors.orange)
                      : null,
                ),
                child: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<String?>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category (suggested)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('None')),
                ...categories.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 20),

            // ── Detected items ──────────────────────────────────────────
            if (widget.result.items.isNotEmpty) ...[
              Text('Detected Items (${widget.result.items.length})',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.colorScheme.outline
                          .withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: widget.result.items
                      .take(10)
                      .map((item) => ListTile(
                            dense: true,
                            title: Text(item.name,
                                style: const TextStyle(fontSize: 13)),
                            trailing: item.price != null
                                ? Text(
                                    item.price!.toStringAsFixed(2),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  )
                                : null,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Raw OCR text (collapsible) ──────────────────────────────
            InkWell(
              onTap: () => setState(() => _showRawText = !_showRawText),
              child: Row(
                children: [
                  Icon(
                    _showRawText
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showRawText ? 'Hide raw text' : 'Show raw OCR text',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (_showRawText) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.colorScheme.outline
                          .withValues(alpha: 0.3)),
                ),
                child: SelectableText(
                  widget.result.rawText,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _useData,
                  icon: const Icon(Icons.check),
                  label: const Text('Use This Data'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
