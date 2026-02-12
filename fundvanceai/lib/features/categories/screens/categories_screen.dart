import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/category.dart';
import '../category_provider.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/delete_category_dialog.dart';

/// Category management screen with full CRUD functionality
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCategoryDialog({Category? category, String? parentId}) async {
    await showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        category: category,
        parentId: parentId,
      ),
    );
  }

  Future<void> _showDeleteDialog(Category category) async {
    await showDialog(
      context: context,
      builder: (context) => DeleteCategoryDialog(category: category),
    );
  }

  IconData _getIconData(String iconName) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Default', icon: Icon(Icons.star)),
            Tab(text: 'Custom', icon: Icon(Icons.edit)),
          ],
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.errorMessage != null) {
            return _buildErrorView(categoryProvider.errorMessage!);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(categoryProvider.topLevelCategories.cast<Category>(), categoryProvider),
              _buildCategoryList(categoryProvider.defaultCategories.cast<Category>(), categoryProvider),
              _buildCategoryList(categoryProvider.customCategories.cast<Category>(), categoryProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, CategoryProvider provider) {
    if (categories.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadCategories(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final subcategories = (provider.subcategories[category.id] ?? []).cast<Category>();
          
          return _buildCategoryCard(category, subcategories, provider);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    Category category,
    List<Category> subcategories,
    CategoryProvider provider,
  ) {
    final theme = Theme.of(context);
    final hasSubcategories = subcategories.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color != null
                    ? _hexToColor(category.color!).withValues(alpha: 0.1)
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                category.icon != null
                    ? _getIconData(category.icon!)
                    : Icons.category,
                color: category.color != null
                    ? _hexToColor(category.color!)
                    : theme.colorScheme.primary,
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                if (category.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'System',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (hasSubcategories) ...[
                  if (category.isDefault) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${subcategories.length} subcategories',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!category.isDefault) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showCategoryDialog(category: category),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _showDeleteDialog(category),
                    tooltip: 'Delete',
                  ),
                ],
                if (category.parentId == null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => _showCategoryDialog(parentId: category.id),
                    tooltip: 'Add Subcategory',
                  ),
              ],
            ),
          ),
          
          // Subcategories
          if (hasSubcategories)
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Column(
                children: subcategories.map((sub) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 32),
                    leading: Icon(
                      sub.icon != null ? _getIconData(sub.icon!) : Icons.subdirectory_arrow_right,
                      size: 20,
                      color: sub.color != null
                          ? _hexToColor(sub.color!)
                          : theme.colorScheme.secondary,
                    ),
                    title: Text(sub.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!sub.isDefault) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showCategoryDialog(category: sub),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _showDeleteDialog(sub),
                            tooltip: 'Delete',
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Categories Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first custom category',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CategoryProvider>().loadCategories();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}