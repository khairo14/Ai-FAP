import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/transfer_category.dart';
import '../category_provider.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/delete_category_dialog.dart';

/// Unified category screen — Expense (CRUD), Income & Transfer (view-only, system)
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _showCategoryDialog({Category? category, String? parentId}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CategoryFormDialog(
        category: category,
        parentId: parentId,
      ),
    );
    if (result == true && mounted) {
      context.read<CategoryProvider>().loadCategories();
    }
  }

  Future<void> _showDeleteDialog(Category category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteCategoryDialog(category: category),
    );
    if (result == true && mounted) {
      context.read<CategoryProvider>().loadCategories();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  IconData _iconData(String? iconName) {
    const map = <String, IconData>{
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
      // Income
      'work': Icons.work,
      'business': Icons.business,
      'trending_up': Icons.trending_up,
      'account_balance': Icons.account_balance,
      'real_estate_agent': Icons.real_estate_agent,
      'handshake': Icons.handshake,
      'laptop': Icons.laptop,
      'interests': Icons.interests,
      'volunteer_activism': Icons.volunteer_activism,
      'local_atm': Icons.local_atm,
      // Transfer
      'swap_horiz': Icons.swap_horiz,
      'family_restroom': Icons.family_restroom,
      'currency_exchange': Icons.currency_exchange,
      'security': Icons.security,
      'receipt': Icons.receipt,
      'refresh': Icons.refresh,
    };
    return map[iconName ?? ''] ?? Icons.label_outline;
  }

  Color _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<CategoryProvider>().loadCategories(),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return _buildError(provider);
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadCategories(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildExpenseSection(provider, theme),
                const SizedBox(height: 12),
                _buildSystemSection(
                  theme: theme,
                  title: 'Income Categories',
                  subtitle: 'Used when recording income',
                  icon: Icons.trending_up,
                  color: Colors.green,
                  categories: provider.incomeSystemCategories,
                ),
                const SizedBox(height: 12),
                _buildSystemSection(
                  theme: theme,
                  title: 'Transfer Categories',
                  subtitle: 'Used to classify transfers',
                  icon: Icons.swap_horiz,
                  color: Colors.blue,
                  categories: provider.transferSystemCategories,
                ),
                const SizedBox(height: 80),
              ],
            ),
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

  // ─── Expense section (full CRUD) ──────────────────────────────────────────

  Widget _buildExpenseSection(CategoryProvider provider, ThemeData theme) {
    final categories = provider.topLevelCategories.cast<Category>();
    final customCount = provider.customCategories.length;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
          child: const Icon(Icons.receipt_long, color: Colors.orange),
        ),
        title: const Text('Expense Categories',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${categories.length} total \u00B7 $customCount custom'),
        children: [
          if (categories.isEmpty)
            _emptyHint('No expense categories yet. Tap + to add one.')
          else
            ...categories.map((cat) {
              final subs = (provider.subcategories[cat.id] ?? []).cast<Category>();
              return _buildExpenseTile(cat, subs, theme);
            }),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(Category cat, List<Category> subs, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _hexColor(cat.color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconData(cat.icon),
                  color: _hexColor(cat.color), size: 20),
            ),
            title: Text(cat.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Wrap(
              spacing: 6,
              children: [
                if (cat.isDefault || cat.isSystem)
                  _chip('System', Colors.blue)
                else
                  _chip('Custom', Colors.green),
                if (subs.isNotEmpty)
                  _chip('${subs.length} subs', Colors.purple),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cat.parentId == null)
                  IconButton(
                    icon: const Icon(Icons.account_tree_outlined, size: 18),
                    tooltip: 'Add sub-category',
                    onPressed: () => _showCategoryDialog(parentId: cat.id),
                  ),
                if (!cat.isDefault && !cat.isSystem) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit',
                    onPressed: () => _showCategoryDialog(category: cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () => _showDeleteDialog(cat),
                  ),
                ],
              ],
            ),
          ),
          if (subs.isNotEmpty)
            Container(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Column(
                children: subs.map((sub) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 56, right: 8),
                    leading: Icon(_iconData(sub.icon),
                        size: 18, color: _hexColor(sub.color)),
                    title: Text(sub.name,
                        style: const TextStyle(fontSize: 13)),
                    trailing: (!sub.isDefault && !sub.isSystem)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                tooltip: 'Edit',
                                onPressed: () =>
                                    _showCategoryDialog(category: sub),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 16, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _showDeleteDialog(sub),
                              ),
                            ],
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── System section (income / transfer — view-only) ───────────────────────

  Widget _buildSystemSection({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<TransferCategory> categories,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${categories.length} system \u00B7 $subtitle'),
        children: [
          if (categories.isEmpty)
            _emptyHint('No $title found.')
          else
            ...categories
                .map((cat) => _buildSystemTile(cat, color, theme)),
        ],
      ),
    );
  }

  Widget _buildSystemTile(
      TransferCategory cat, Color accent, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _hexColor(cat.color).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_iconData(cat.icon),
              color: _hexColor(cat.color), size: 20),
        ),
        title: Text(cat.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: (cat.description != null && cat.description!.isNotEmpty)
            ? Text(cat.description!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
            : null,
        trailing: _chip('System', accent),
      ),
    );
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptyHint(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.grey[500], fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildError(CategoryProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            Text(provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => provider.loadCategories(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
