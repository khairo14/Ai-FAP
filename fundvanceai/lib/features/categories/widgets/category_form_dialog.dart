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
  
  String? _selectedIcon;
  String? _selectedColor;
  String? _selectedParentId;
  bool _isLoading = false;

  // Available icons for categories
  final List<Map<String, dynamic>> _availableIcons = [
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
  ];

  // Available colors for categories
  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? _availableIcons[0]['name'];
    _selectedColor = widget.category?.color ?? _colorToHex(Colors.blue);
    _selectedParentId = widget.parentId ?? widget.category?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Color _hexToColor(String hex) {
    final hexColor = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  IconData _getIconData(String iconName) {
    final iconEntry = _availableIcons.firstWhere(
      (icon) => icon['name'] == iconName,
      orElse: () => _availableIcons[0],
    );
    return iconEntry['icon'] as IconData;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final categoryProvider = context.read<CategoryProvider>();
    bool success;

    if (widget.category != null) {
      // Update existing category
      success = await categoryProvider.updateCategory(
        categoryId: widget.category!.id,
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        parentId: _selectedParentId,
      );
    } else {
      // Create new category
      final newCategory = await categoryProvider.createCategory(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        parentId: _selectedParentId,
      );
      success = newCategory != null;
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.category != null
              ? 'Category updated successfully'
              : 'Category created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(categoryProvider.errorMessage ?? 'Failed to save category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'Create Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedColor != null
                        ? _hexToColor(_selectedColor!).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(_selectedIcon ?? _availableIcons[0]['name']),
                    size: 48,
                    color: _selectedColor != null
                        ? _hexToColor(_selectedColor!)
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Icon selection
              Text(
                'Select Icon',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final iconData = _availableIcons[index];
                    final isSelected = _selectedIcon == iconData['name'];
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = iconData['name'] as String;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData['icon'] as IconData,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Color selection
              Text(
                'Select Color',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColor == _colorToHex(color);
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = _colorToHex(color);
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              // Parent category selection (if not editing and not creating subcategory)
              if (!isEditing && widget.parentId == null) ...[
                const SizedBox(height: 16),
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, _) {
                    final topLevelCategories = categoryProvider.topLevelCategories;
                    
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedParentId,
                      decoration: const InputDecoration(
                        labelText: 'Parent Category (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None (Top Level)'),
                        ),
                        ...topLevelCategories.map((category) {
                          return DropdownMenuItem<String?>(
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
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedParentId = value;
                        });
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submitForm,
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
}
