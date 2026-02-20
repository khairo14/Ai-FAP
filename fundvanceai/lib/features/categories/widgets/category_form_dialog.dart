import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/category.dart';
import '../category_provider.dart';

/// Dialog for creating or editing a category
class CategoryFormDialog extends StatefulWidget {
  final Category? category; // null for create, non-null for edit
  final String? parentId; // For creating subcategories

  const CategoryFormDialog({
    super.key,
    this.category,
    this.parentId,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  String _selectedIcon = 'shopping_cart';
  String _selectedColor = '#2196F3';
  String? _selectedParentId;
  String _selectedType = 'expense';
  bool _isLoading = false;
  String? _submitError;

  // Available icons
  static const _icons = <Map<String, dynamic>>[
    {'icon': Icons.shopping_cart, 'name': 'shopping_cart'},
    {'icon': Icons.restaurant, 'name': 'restaurant'},
    {'icon': Icons.local_gas_station, 'name': 'local_gas_station'},
    {'icon': Icons.home, 'name': 'home'},
    {'icon': Icons.directions_car, 'name': 'directions_car'},
    {'icon': Icons.medical_services, 'name': 'medical_services'},
    {'icon': Icons.school, 'name': 'school'},
    {'icon': Icons.sports_esports, 'name': 'sports_esports'},
    {'icon': Icons.movie, 'name': 'movie'},
    {'icon': Icons.flight, 'name': 'flight'},
    {'icon': Icons.phone_android, 'name': 'phone_android'},
    {'icon': Icons.wifi, 'name': 'wifi'},
    {'icon': Icons.water_drop, 'name': 'water_drop'},
    {'icon': Icons.bolt, 'name': 'bolt'},
    {'icon': Icons.payment, 'name': 'payment'},
    {'icon': Icons.savings, 'name': 'savings'},
    {'icon': Icons.card_giftcard, 'name': 'card_giftcard'},
    {'icon': Icons.pets, 'name': 'pets'},
    {'icon': Icons.spa, 'name': 'spa'},
    {'icon': Icons.fitness_center, 'name': 'fitness_center'},
    {'icon': Icons.fastfood, 'name': 'fastfood'},
    {'icon': Icons.local_cafe, 'name': 'local_cafe'},
    {'icon': Icons.local_bar, 'name': 'local_bar'},
    {'icon': Icons.checkroom, 'name': 'checkroom'},
    {'icon': Icons.style, 'name': 'style'},
    {'icon': Icons.work, 'name': 'work'},
    {'icon': Icons.account_balance, 'name': 'account_balance'},
    {'icon': Icons.trending_up, 'name': 'trending_up'},
    {'icon': Icons.swap_horiz, 'name': 'swap_horiz'},
    {'icon': Icons.category, 'name': 'category'},
  ];

  // Available colors (as hex strings â€” no Color.r/g/b needed)
  static const _colorHexes = <String>[
    '#F44336', '#E91E63', '#9C27B0', '#673AB7',
    '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4',
    '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
    '#FFC107', '#FF9800', '#FF5722', '#795548',
    '#9E9E9E', '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'shopping_cart';
    _selectedColor = widget.category?.color ?? '#2196F3';
    _selectedParentId = widget.parentId ?? widget.category?.parentId;
    _selectedType = widget.category?.categoryType ?? 'expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Safe hexâ†’Color, works on all Flutter versions
  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  IconData _iconDataFor(String name) {
    final entry = _icons.firstWhere(
      (e) => e['name'] == name,
      orElse: () => _icons.first,
    );
    return entry['icon'] as IconData;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _submitError = null;
    });

    final provider = context.read<CategoryProvider>();
    bool success;

    if (widget.category != null) {
      success = await provider.updateCategory(
        categoryId: widget.category!.id,
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        parentId: _selectedParentId,
        categoryType: _selectedType,
        clearParent:
            _selectedParentId == null && widget.category!.parentId != null,
      );
    } else {
      final created = await provider.createCategory(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        parentId: _selectedParentId,
        categoryType: _selectedType,
      );
      success = created != null;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(SnackBar(
        content: Text(widget.category != null
            ? 'Category updated'
            : 'Category created'),
        backgroundColor: Colors.green,
      ));
    } else {
      setState(() {
        _submitError = provider.errorMessage ??
            'Failed to save category. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.category != null;
    final previewColor = _hexToColor(_selectedColor);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'New Category'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ Preview â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: previewColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconDataFor(_selectedIcon),
                      size: 48,
                      color: previewColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // â”€â”€ Name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Please enter a name'
                          : null,
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // â”€â”€ Type (top-level only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (widget.parentId == null) ...[
                  Text('Category Type',
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _typeChip('expense', 'Expense',
                          Icons.receipt_long, Colors.orange),
                      const SizedBox(width: 8),
                      _typeChip('income', 'Income',
                          Icons.trending_up, Colors.green),
                      const SizedBox(width: 8),
                      _typeChip('both', 'Both',
                          Icons.swap_vert, Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // â”€â”€ Icon picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Text('Select Icon',
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.outline
                            .withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _icons.map((entry) {
                      final name = entry['name'] as String;
                      final icon = entry['icon'] as IconData;
                      final selected = _selectedIcon == name;
                      return InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () =>
                            setState(() => _selectedIcon = name),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected
                                ? previewColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: selected
                                  ? previewColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(icon,
                              size: 20,
                              color: selected
                                  ? previewColor
                                  : theme.colorScheme.onSurfaceVariant),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // â”€â”€ Color picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Text('Select Color',
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorHexes.map((hex) {
                    final c = _hexToColor(hex);
                    final selected = _selectedColor == hex;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedColor = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                // â”€â”€ Parent picker (create only, top-level only) â”€â”€â”€â”€â”€â”€
                if (!isEditing && widget.parentId == null) ...[
                  const SizedBox(height: 16),
                  Consumer<CategoryProvider>(
                    builder: (_, prov, __) {
                      final tops = prov.topLevelCategories
                          .cast<Category>();
                      return DropdownButtonFormField<String?>(
                        initialValue: _selectedParentId,
                        decoration: const InputDecoration(
                          labelText: 'Parent Category (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder_open),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None (top level)'),
                          ),
                          ...tops.map((cat) => DropdownMenuItem<String?>(
                                value: cat.id,
                                child: Text(cat.name),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedParentId = v),
                      );
                    },
                  ),
                ],

                // â”€â”€ Inline error â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer,
                            size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _submitError!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget _typeChip(
      String value, String label, IconData icon, Color color) {
    final selected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18, color: selected ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected ? color : Colors.grey,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
