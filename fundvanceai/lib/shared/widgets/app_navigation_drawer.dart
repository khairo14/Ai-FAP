import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/expenses/screens/expense_list_screen.dart';
import 'package:fundvanceai/features/budgets/screens/budget_list_screen.dart';
import 'package:fundvanceai/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:fundvanceai/features/income/screens/income_list_screen.dart';
import 'package:fundvanceai/features/accounts/screens/accounts_screen.dart';
import 'package:fundvanceai/features/transfers/screens/transfers_screen.dart';
import 'package:fundvanceai/features/categories/screens/categories_screen.dart';
import 'package:fundvanceai/features/tax_settings/screens/tax_settings_screen.dart';
import 'package:fundvanceai/shared/screens/settings_screen.dart';
import 'package:fundvanceai/shared/screens/trash_screen.dart';
import 'package:fundvanceai/features/auth/screens/currency_selection_screen.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.userProfile;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User Profile Header
          UserAccountsDrawerHeader(
            accountName: Text(
              userProfile?.fullName ?? 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              authProvider.currentUser?.email ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: userProfile?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        userProfile!.avatarUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blue,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue,
                    ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Navigation Items
          _buildNavigationItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate to home - already there
            },
            isSelected: true,
          ),

          _buildNavigationItem(
            context,
            icon: Icons.receipt_long,
            title: 'Expenses',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExpenseListScreen(),
                ),
              );
            },
          ),

          // Income navigation item
          _buildNavigationItem(
            context,
            icon: Icons.attach_money,
            title: 'Income',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IncomeListScreen(),
                ),
              );
            },
          ),

          _buildNavigationItem(
            context,
            icon: Icons.pie_chart,
            title: 'Budgets',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetListScreen(),
                ),
              );
            },
          ),

          // Accounts navigation item
          _buildNavigationItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Accounts',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountsScreen(),
                ),
              );
            },
          ),

          // Transfers navigation item
          _buildNavigationItem(
            context,
            icon: Icons.swap_horiz,
            title: 'Transfers',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransfersScreen(),
                ),
              );
            },
          ),

          // Expense Categories navigation item
          _buildNavigationItem(
            context,
            icon: Icons.category,
            title: 'Expense Categories',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
            },
          ),

          _buildNavigationItem(
            context,
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboardScreen(),
                ),
              );
            },
          ),

          _buildNavigationItem(
            context,
            icon: Icons.delete_outline,
            title: 'Trash',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrashScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Settings Section
          _buildNavigationItem(
            context,
            icon: Icons.currency_exchange,
            title: 'Currency Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrencySelectionScreen(),
                ),
              );
            },
          ),

          _buildNavigationItem(
            context,
            icon: Icons.receipt_long,
            title: 'Tax Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaxSettingsScreen(),
                ),
              );
            },
          ),

          _buildNavigationItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Sign Out
          _buildNavigationItem(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showSignOutDialog(context);
            },
          ),

          // App Version
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'FundVance AI v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isDisabled = false,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDisabled
            ? Colors.grey[400]
            : iconColor ??
                (isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : null),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDisabled
              ? Colors.grey[400]
              : textColor ??
                  (isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : null),
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
      onTap: isDisabled ? null : onTap,
      enabled: !isDisabled,
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.construction,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Coming Soon'),
          ],
        ),
        content: Text(
          '$feature is currently under development and will be available in the next update!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}