import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/core/utils/icon_helper.dart';
import 'package:fundvanceai/features/budgets/budget_provider.dart';
import 'package:fundvanceai/features/income/income_provider.dart';
import 'package:fundvanceai/shared/services/budget_suggestion_service.dart';

class BudgetSuggestionScreen extends StatefulWidget {
  const BudgetSuggestionScreen({super.key});

  @override
  State<BudgetSuggestionScreen> createState() => _BudgetSuggestionScreenState();
}

class _BudgetSuggestionScreenState extends State<BudgetSuggestionScreen> {
  final _incomeController = TextEditingController();
  final _service = BudgetSuggestionService();

  BudgetSuggestionResult? _result;
  bool _isCalculating = false;
  bool _isApplying = false;
  String? _error;

  // Which suggestions the user has toggled on/off for bulk apply
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillIncome());
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _prefillIncome() {
    final incomeProvider = context.read<IncomeProvider>();
    final stats = incomeProvider.stats;
    if (stats != null) {
      double monthly = 0.0;
      final rawMonthly = stats['monthly_total'];
      final rawTotal = stats['total'];
      if (rawMonthly != null) {
        monthly = (rawMonthly as num).toDouble();
      } else if (rawTotal != null) {
        monthly = (rawTotal as num).toDouble() / 3.0;
      }
      if (monthly > 0) {
        _incomeController.text = monthly.toStringAsFixed(0);
      }
    }
  }

  Future<void> _calculate() async {
    final incomeText = _incomeController.text.trim();
    double? income;
    if (incomeText.isNotEmpty) {
      income = double.tryParse(incomeText);
      if (income == null || income <= 0) {
        setState(() => _error = 'Please enter a valid income amount');
        return;
      }
    }

    setState(() {
      _isCalculating = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.generateSuggestions(monthlyIncome: income);
      setState(() {
        _result = result;
        // Pre-select all suggestions that don't have an existing budget
        _selected.clear();
        for (final s in result.suggestions) {
          if (!s.alreadyHasBudget) _selected.add(s.categoryId);
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  Future<void> _applySelected() async {
    if (_result == null || _selected.isEmpty) return;
    setState(() => _isApplying = true);

    final budgetProvider = context.read<BudgetProvider>();
    int applied = 0;
    int failed = 0;

    for (final suggestion in _result!.suggestions) {
      if (!_selected.contains(suggestion.categoryId)) continue;

      bool success;
      if (suggestion.alreadyHasBudget && suggestion.existingBudgetId != null) {
        success = await budgetProvider.updateBudget(
          id: suggestion.existingBudgetId!,
          amount: suggestion.suggestedAmount,
          period: 'monthly',
          categoryId: suggestion.categoryId,
        );
      } else {
        success = await budgetProvider.addBudget(
          amount: suggestion.suggestedAmount,
          period: 'monthly',
          categoryId: suggestion.categoryId,
        );
      }

      if (success) {
        applied++;
      } else {
        failed++;
      }
    }

    setState(() => _isApplying = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(failed == 0
            ? '$applied budget${applied == 1 ? '' : 's'} applied successfully!'
            : '$applied applied, $failed failed.'),
        backgroundColor: failed == 0 ? Colors.green : Colors.orange,
      ));
      if (failed == 0) Navigator.pop(context, true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AI Budget Suggestions'),
            Text('50/30/20 Rule',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Explainer ─────────────────────────────────────────────────
          Card(
            color: theme.colorScheme.primaryContainer.withAlpha(100),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('How it works',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your monthly income and FundVance AI will suggest '
                    'budgets for each spending category based on the 50/30/20 '
                    'rule and your personal spending history.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _RuleChip(
                      color: Colors.green,
                      label: '50% Needs',
                      sub: 'Groceries, Bills, Transport'),
                  const SizedBox(height: 6),
                  _RuleChip(
                      color: Colors.blue,
                      label: '30% Wants',
                      sub: 'Dining, Shopping, Entertainment'),
                  const SizedBox(height: 6),
                  _RuleChip(
                      color: Colors.purple,
                      label: '20% Savings',
                      sub: 'Emergency fund, investments, debt'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Income input ──────────────────────────────────────────────
          TextFormField(
            controller: _incomeController,
            decoration: InputDecoration(
              labelText: 'Monthly Income',
              hintText: 'Leave blank to auto-detect from your income records',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              prefixText: '\$ ',
              border: const OutlineInputBorder(),
              helperText: 'Used only for this calculation — not stored',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
            ],
          ),
          const SizedBox(height: 12),

          // ── Error ─────────────────────────────────────────────────────
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ),

          // ── Calculate button ──────────────────────────────────────────
          FilledButton.icon(
            onPressed: _isCalculating ? null : _calculate,
            icon: _isCalculating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label:
                Text(_isCalculating ? 'Calculating…' : 'Generate Suggestions'),
          ),

          // ── Results ───────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildSummaryRow(_result!),
            const SizedBox(height: 16),
            _buildBucket('Needs (50%)', 'needs', Colors.green),
            const SizedBox(height: 12),
            _buildBucket('Wants (30%)', 'wants', Colors.blue),
            const SizedBox(height: 12),
            _buildSavingsTile(_result!),
            const SizedBox(height: 24),
            _buildApplyButton(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BudgetSuggestionResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryStat(
                label: 'Income',
                value: '\$${result.monthlyIncome.toStringAsFixed(0)}',
                color: Colors.teal),
            _SummaryStat(
                label: 'Needs cap',
                value: '\$${result.needsLimit.toStringAsFixed(0)}',
                color: Colors.green),
            _SummaryStat(
                label: 'Wants cap',
                value: '\$${result.wantsLimit.toStringAsFixed(0)}',
                color: Colors.blue),
            _SummaryStat(
                label: 'Savings goal',
                value: '\$${result.savingsRecommendation.toStringAsFixed(0)}',
                color: Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildBucket(String title, String bucket, Color color) {
    final items =
        _result!.suggestions.where((s) => s.bucket == bucket).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((s) => _buildSuggestionTile(s, color)),
      ],
    );
  }

  Widget _buildSuggestionTile(BudgetSuggestion s, Color bucketColor) {
    final isSelected = _selected.contains(s.categoryId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selected.remove(s.categoryId);
            } else {
              _selected.add(s.categoryId);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Selection checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) {
                  setState(() {
                    if (isSelected) {
                      _selected.remove(s.categoryId);
                    } else {
                      _selected.add(s.categoryId);
                    }
                  });
                },
                activeColor: bucketColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),

              // Icon
              if (s.categoryIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    IconHelper.getIconData(s.categoryIcon),
                    size: 22,
                    color: s.categoryColor != null
                        ? IconHelper.hexToColor(s.categoryColor!)
                        : bucketColor,
                  ),
                ),

              // Category name + history
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(s.categoryName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 6),
                        if (s.alreadyHasBudget)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Update',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.orange[800])),
                          ),
                      ],
                    ),
                    if (s.historicalAvg > 0)
                      Text(
                        '3-mo avg: \$${s.historicalAvg.toStringAsFixed(0)}/mo',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),

              // Suggested amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${s.suggestedAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: bucketColor),
                  ),
                  const Text('/mo',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsTile(BudgetSuggestionResult result) {
    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Colors.purple[100], shape: BoxShape.circle),
              child: Icon(Icons.savings_outlined,
                  color: Colors.purple[700], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Savings Goal (20%)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800])),
                  const SizedBox(height: 2),
                  Text(
                    'Set aside \$${result.savingsRecommendation.toStringAsFixed(0)}/month '
                    'for emergency funds, investments, or debt payoff.',
                    style: TextStyle(fontSize: 12, color: Colors.purple[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    final count = _selected.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: (_isApplying || count == 0) ? null : _applySelected,
          icon: _isApplying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
          label: Text(
            _isApplying
                ? 'Applying…'
                : 'Apply $count Selected Budget${count == 1 ? '' : 's'}',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              if (_selected.length == _result!.suggestions.length) {
                _selected.clear();
              } else {
                _selected.addAll(_result!.suggestions.map((s) => s.categoryId));
              }
            });
          },
          child: Text(
            _selected.length == _result!.suggestions.length
                ? 'Deselect All'
                : 'Select All',
          ),
        ),
      ],
    );
  }
}

// ── Small helper widgets ───────────────────────────────────────────────────────

class _RuleChip extends StatelessWidget {
  final Color color;
  final String label;
  final String sub;
  const _RuleChip(
      {required this.color, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label — ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(sub, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}
