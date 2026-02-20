import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/category.dart';
import '../category_provider.dart';

/// Dialog for deleting a category with expense reassignment option
class DeleteCategoryDialog extends StatefulWidget {
  final Category category;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
  });

  @override
  State<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<DeleteCategoryDialog> {
  String? _reassignToCategoryId;
  bool _isLoading = false;
  int _expenseCount = 0;
  int _budgetCount = 0;
  bool _loadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadUsageCounts();
  }

  Future<void> _loadUsageCounts() async {
    final categoryProvider = context.read<CategoryProvider>();
    
    final expenseCount = await categoryProvider.getCategoryExpenseCount(widget.category.id);
    final budgetCount = await categoryProvider.getCategoryBudgetCount(widget.category.id);
    
    if (mounted) {
      setState(() {
        _expenseCount = expenseCount;
        _budgetCount = budgetCount;
        _loadingCounts = false;
      });
    }
  }

  Future<void> _deleteCategory() async {
    setState(() => _isLoading = true);

    final categoryProvider = context.read<CategoryProvider>();
    final success = await categoryProvider.deleteCategory(
      categoryId: widget.category.id,
      reassignToCategoryId: _reassignToCategoryId,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (success) {
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(categoryProvider.errorMessage ?? 'Failed to delete category'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  IconData _getIconData(String iconName) {
    // Simple icon mapping
    final iconMap = <String, IconData>{
      'shopping_cart': Icons.shopping_cart,
      'restaurant': Icons.restaurant,
      'local_gas_station': Icons.local_gas_station,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'medical_services': Icons.medical_services,
      'school': Icons.school,
      'sports_esports': Icons.sports_esports,
      'movie': Icons.movie,
      'flight': Icons.flight,
      'phone_android': Icons.phone_android,
      'wifi': Icons.wifi,
      'water_drop': Icons.water_drop,
      'bolt': Icons.bolt,
      'payment': Icons.payment,
      'savings': Icons.savings,
      'card_giftcard': Icons.card_giftcard,
      'pets': Icons.pets,
      'spa': Icons.spa,
      'fitness_center': Icons.fitness_center,
      'fastfood': Icons.fastfood,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'checkroom': Icons.checkroom,
      'style': Icons.style,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  Color _hexToColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUsage = _expenseCount > 0 || _budgetCount > 0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Delete Category'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (widget.category.icon != null)
                    Icon(
                      _getIconData(widget.category.icon!),
                      size: 32,
                      color: widget.category.color != null
                          ? _hexToColor(widget.category.color!)
                          : theme.colorScheme.primary,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.category.isDefault)
                          Text(
                            'System Category',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warning message
            if (widget.category.isDefault)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cannot delete system categories',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            else if (_loadingCounts)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Usage information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasUsage
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasUsage
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.receipt, size: 16),
                        const SizedBox(width: 4),
                        Text('$_expenseCount expenses'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 16),
                        const SizedBox(width: 4),
                        Text('$_budgetCount budgets'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reassignment option
              if (hasUsage) ...[
                Text(
                  'What should happen to existing expenses and budgets?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, _) {
                    // Get available categories (excluding the one being deleted)
                    final availableCategories = categoryProvider.categories
                        .where((cat) => cat.id != widget.category.id)
                        .toList();

                    return Column(
                      children: [
                        RadioListTile<String?>(
                          value: null,
                          groupValue: _reassignToCategoryId,
                          onChanged: (value) {
                            setState(() => _reassignToCategoryId = value);
                          },
                          title: const Text('Remove category'),
                          subtitle: const Text('Set expenses and budgets to "Uncategorized"'),
                          dense: true,
                        ),
                        RadioListTile<String>(
                          value: 'reassign',
                          groupValue: _reassignToCategoryId ?? 'none',
                          onChanged: (_) {
                            // Will be set when dropdown is changed
                          },
                          title: const Text('Reassign to another category'),
                          dense: true,
                        ),
                        if (_reassignToCategoryId != null && _reassignToCategoryId != 'none')
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 8),
                            child: DropdownButtonFormField<String>(
                              initialValue: _reassignToCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Select Category',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: availableCategories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Row(
                                    children: [
                                      if (category.icon != null)
                                        Icon(
                                          _getIconData(category.icon!),
                                          size: 20,
                                          color: category.color != null
                                              ? _hexToColor(category.color!)
                                              : null,
                                        ),
                                      const SizedBox(width: 8),
                                      Text(category.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _reassignToCategoryId = value);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ] else
                Text(
                  'This category is not being used and can be safely deleted.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (!widget.category.isDefault)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: _isLoading || _loadingCounts ? null : _deleteCategory,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Delete'),
          ),
      ],
    );
  }
}
