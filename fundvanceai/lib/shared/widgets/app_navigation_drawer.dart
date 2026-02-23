import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/expenses/screens/expense_list_screen.dart';
import 'package:fundvanceai/features/budgets/screens/budget_list_screen.dart';
import 'package:fundvanceai/features/analytics/screens/analytics_dashboard_screen.dart';
import 'package:fundvanceai/features/analytics/screens/smart_insights_screen.dart';
import 'package:fundvanceai/features/notifications/notification_provider.dart';
import 'package:fundvanceai/features/notifications/screens/notifications_screen.dart';
import 'package:fundvanceai/features/income/screens/income_list_screen.dart';
import 'package:fundvanceai/features/accounts/screens/accounts_screen.dart';
import 'package:fundvanceai/features/transfers/screens/transfers_screen.dart';
import 'package:fundvanceai/features/categories/screens/categories_screen.dart';
import 'package:fundvanceai/features/tax_settings/screens/tax_settings_screen.dart';
import 'package:fundvanceai/features/goals/screens/goal_list_screen.dart';
import 'package:fundvanceai/features/debts/screens/debt_list_screen.dart';
import 'package:fundvanceai/features/subscriptions/screens/subscription_tracker_screen.dart';
import 'package:fundvanceai/features/reports/screens/weekly_report_screen.dart';
import 'package:fundvanceai/features/premium/premium_provider.dart';
import 'package:fundvanceai/features/premium/screens/paywall_screen.dart';
import 'package:fundvanceai/shared/screens/settings_screen.dart';
import 'package:fundvanceai/shared/screens/trash_screen.dart';
import 'package:fundvanceai/features/auth/screens/currency_selection_screen.dart';
import 'package:fundvanceai/features/settings/screens/theme_selection_screen.dart';
import 'package:fundvanceai/features/profile/screens/profile_screen.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  static String _drawerInitials(String? name, String? email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.userProfile;
    final isPremium = context.watch<PremiumProvider>().isPremium;

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
                          return Text(
                            _drawerInitials(userProfile.fullName,
                                authProvider.currentUser?.email),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      _drawerInitials(userProfile?.fullName,
                          authProvider.currentUser?.email),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
            icon: Icons.account_circle_outlined,
            title: 'My Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),

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

          // Categories navigation item
          _buildNavigationItem(
            context,
            icon: Icons.category,
            title: 'Categories',
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
            icon: Icons.lightbulb_outline,
            title: 'Smart Insights',
            subtitle: isPremium ? null : 'Pro Feature',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SmartInsightsScreen(),
                ),
              );
            },
          ),

          Consumer<NotificationProvider>(
            builder: (_, notifProvider, __) => _buildNavigationItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              badge: notifProvider.unreadCount > 0
                  ? '${notifProvider.unreadCount}'
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
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

          // Phase 4: Planning Tools
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'PLANNING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),

          _buildNavigationItem(
            context,
            icon: Icons.flag_outlined,
            title: 'Goals',
            subtitle: isPremium ? null : 'Unlimited with Pro',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GoalListScreen(),
                ),
              );
            },
          ),

          _buildNavigationItem(
            context,
            icon: Icons.credit_card_off_outlined,
            title: 'Debt Manager',
            subtitle: isPremium ? null : 'Pro Feature',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DebtListScreen(),
                ),
              );
            },
          ),

          _buildNavigationItem(
            context,
            icon: Icons.repeat_outlined,
            title: 'Subscriptions',
            subtitle: isPremium ? null : 'Pro Feature',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionTrackerScreen(),
                ),
              );
            },
          ),

          _buildNavigationItem(
            context,
            icon: Icons.bar_chart_outlined,
            title: 'Reports',
            subtitle: isPremium ? null : 'PDF export is Pro',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WeeklyReportScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Settings Section
          _buildNavigationItem(
            context,
            icon: Icons.palette_outlined,
            title: 'Appearance',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSelectionScreen(),
                ),
              );
            },
          ),

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

          // Go Premium
          Consumer<PremiumProvider>(
            builder: (_, premiumProvider, __) {
              final isPro = premiumProvider.isPremium;
              return _buildNavigationItem(
                context,
                icon: isPro
                    ? Icons.workspace_premium_rounded
                    : Icons.workspace_premium_outlined,
                title: isPro ? 'FundVance Pro ✓' : 'Go Premium',
                iconColor: const Color(0xFFFFB347),
                textColor: const Color(0xFFFFB347),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaywallScreen(),
                    ),
                  );
                },
              );
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
    String? badge,
  }) {
    final iconWidget = badge != null
        ? Badge(
            label: Text(badge),
            child: Icon(
              icon,
              color: isDisabled
                  ? Colors.grey[400]
                  : iconColor ??
                      (isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null),
            ),
          )
        : Icon(
            icon,
            color: isDisabled
                ? Colors.grey[400]
                : iconColor ??
                    (isSelected ? Theme.of(context).colorScheme.primary : null),
          );

    return ListTile(
      leading: iconWidget,
      title: Text(
        title,
        style: TextStyle(
          color: isDisabled
              ? Colors.grey[400]
              : textColor ??
                  (isSelected ? Theme.of(context).colorScheme.primary : null),
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
      selectedTileColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
      onTap: isDisabled ? null : onTap,
      enabled: !isDisabled,
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
