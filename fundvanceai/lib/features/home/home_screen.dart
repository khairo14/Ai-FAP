import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth/auth_provider.dart';
import 'home_provider.dart';
import 'widgets/income_expenses_chart.dart';
import 'widgets/financial_health_card.dart';
import 'widgets/spending_digest_card.dart';
import '../expenses/screens/expense_list_screen.dart';
import '../notifications/notification_provider.dart';
import '../notifications/screens/notifications_screen.dart';
import '../income/screens/income_list_screen.dart';
import '../accounts/screens/accounts_screen.dart';
import '../accounts/screens/account_details_screen.dart';
import '../transfers/screens/transfers_screen.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/currencies.dart';
import '../../core/utils/icon_helper.dart';
import '../../shared/widgets/app_navigation_drawer.dart';
import '../auth/screens/currency_selection_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load dashboard data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadDashboardData();
      context.read<NotificationProvider>().refreshAlerts();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh dashboard when app returns to foreground
      context.read<HomeProvider>().loadDashboardData(showLoading: false);
    }
  }

  Future<void> _refreshData() async {
    await context.read<HomeProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          // Notification bell with unread badge
          Consumer<NotificationProvider>(
            builder: (_, notifProvider, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ),
                if (notifProvider.hasUnread)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'currency') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurrencySelectionScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'currency',
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 20),
                    const SizedBox(width: 8),
                    Text('Currency: ${authProvider.userCurrency}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          if (homeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (homeProvider.errorMessage != null) {
            return _buildErrorView(homeProvider.errorMessage!, theme);
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(authProvider, theme),
                  const SizedBox(height: 24),

                  // Financial Health Score
                  if (homeProvider.healthScore > 0)
                    FinancialHealthCard(
                      score: homeProvider.healthScore,
                      status: homeProvider.healthStatus,
                      insights: homeProvider.healthInsights,
                    ),
                  const SizedBox(height: 16),

                  // AI Spending Digest
                  const SpendingDigestCard(),
                  const SizedBox(height: 24),

                  // Quick Action Buttons
                  _buildQuickActions(theme),
                  const SizedBox(height: 24),

                  // Financial Overview Cards
                  _buildFinancialOverview(homeProvider, theme),
                  const SizedBox(height: 24),

                  // Income vs Expenses Chart
                  if (homeProvider.incomeVsExpensesData.isNotEmpty)
                    IncomeExpensesChart(
                      data: homeProvider.incomeVsExpensesData,
                      currencySymbol: _getCurrencySymbol(authProvider.userCurrency),
                    ),
                  const SizedBox(height: 24),

                  // Account Balances Summary
                  _buildAccountsSummary(homeProvider, theme),
                  const SizedBox(height: 24),

                  // Recent Transactions
                  _buildRecentTransactions(homeProvider, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.waving_hand,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getTimeOfDayGreeting()}!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (authProvider.currentUser?.email != null)
                      Text(
                        authProvider.currentUser!.email!.split('@')[0],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Track your financial journey with AI-powered insights',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.add_shopping_cart,
                label: 'Add Expense',
                color: Colors.red,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseListScreen(),
                    ),
                  );
                  
                  // Refresh dashboard if expense was added/modified
                  if (result == true && mounted) {
                    await context.read<HomeProvider>().loadDashboardData();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.add_circle,
                label: 'Add Income',
                color: Colors.green,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IncomeListScreen(),
                    ),
                  );
                  
                  // Refresh dashboard if income was added/modified
                  if (result == true && mounted) {
                    await context.read<HomeProvider>().loadDashboardData();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.swap_horiz,
                label: 'Transfer',
                color: Colors.blue,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransfersScreen(),
                    ),
                  );
                  
                  // Refresh dashboard if transfer was made
                  if (result == true && mounted) {
                    await context.read<HomeProvider>().loadDashboardData();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(
      HomeProvider homeProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Month',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (homeProvider.expenseCount > 0 ||
                homeProvider.incomeCount > 0)
              Text(
                '${homeProvider.expenseCount + homeProvider.incomeCount} transactions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMultiCurrencyOverviewCard(
                title: 'Income',
                amountsByCurrency: homeProvider.incomeByCurrency,
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMultiCurrencyOverviewCard(
                title: 'Expenses',
                amountsByCurrency: homeProvider.expensesByCurrency,
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMultiCurrencyOverviewCard(
          title: 'Net Income',
          amountsByCurrency: homeProvider.netIncomeByCurrency,
          icon: Icons.account_balance,
          color: Colors.blue,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMultiCurrencyOverviewCard({
    required String title,
    required Map<String, double> amountsByCurrency,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    
    // Build currency display strings
    final currencyDisplays = <String>[];
    if (amountsByCurrency.isEmpty) {
      currencyDisplays.add('${_getCurrencySymbol('USD')} 0.00');
    } else {
      for (final entry in amountsByCurrency.entries) {
        final currencySymbol = _getCurrencySymbol(entry.key);
        final amount = NumberFormat('#,##0.00').format(entry.value.abs());
        currencyDisplays.add('$currencySymbol $amount${entry.value < 0 ? " (-)" : ""}');
      }
    }
    
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...currencyDisplays.map((display) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              display,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: currencyDisplays.length > 1 ? 18 : null,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAccountsSummary(
      HomeProvider homeProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Account Balances',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountsScreen(),
                  ),
                );
                // Refresh dashboard after returning from accounts screen
                if (mounted) {
                  context.read<HomeProvider>().loadDashboardData(showLoading: false);
                }
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (homeProvider.accountCount == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: theme.colorScheme.onSecondaryContainer
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'No accounts added yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your bank accounts, wallets, and cards to track balances',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer
                        .withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              // Total Balance Card - Redesigned
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Balance',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${homeProvider.accountCount} ${homeProvider.accountCount == 1 ? 'account' : 'accounts'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Display each currency balance
                    if (homeProvider.balancesByCurrency.isEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _getCurrencySymbol('USD'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            '0.00',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'USD',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: homeProvider.balancesByCurrency.entries.map((entry) {
                          final currencySymbol = _getCurrencySymbol(entry.key);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currencySymbol,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                NumberFormat('#,##0.00').format(entry.value),
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: homeProvider.balancesByCurrency.length > 1 ? 26 : 28,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.key,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Account Cards - Redesigned
              ...homeProvider.accounts.take(3).map((account) {
                final accountCurrencySymbol = _getCurrencySymbol(account.currency);
                final isPositive = account.currentBalance >= 0;
                
                // Get icon based on account type
                IconData accountIcon = Icons.account_balance_wallet;
                Color iconColor = Colors.blue;
                
                final typeName = account.accountTypeName?.toLowerCase() ?? '';
                if (typeName.contains('credit')) {
                  accountIcon = Icons.credit_card;
                  iconColor = Colors.orange;
                } else if (typeName.contains('cash')) {
                  accountIcon = Icons.money;
                  iconColor = Colors.green;
                } else if (typeName.contains('wallet') || typeName.contains('paypal')) {
                  accountIcon = Icons.account_balance_wallet;
                  iconColor = Colors.purple;
                } else if (typeName.contains('bank') || typeName.contains('checking') || typeName.contains('savings')) {
                  accountIcon = Icons.account_balance;
                  iconColor = Colors.blue;
                }
                
                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountDetailsScreen(account: account),
                      ),
                    );
                    // Refresh dashboard after returning from account details
                    if (context.mounted) {
                      context.read<HomeProvider>().loadDashboardData(showLoading: false);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              accountIcon,
                              color: iconColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  account.accountTypeName ?? 'Account',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$accountCurrencySymbol ${NumberFormat('#,##0.00').format(account.currentBalance.abs())}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                account.currency,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildRecentTransactions(
      HomeProvider homeProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseListScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (homeProvider.recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent expenses, income, and transfers will appear here',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Card(
            child: Column(
              children: homeProvider.recentTransactions.take(5).map((transaction) {
                final type = transaction['type'] as String;
                final amount = transaction['amount'] as double;
                final currency = transaction['currency'] as String? ?? 'USD';
                final transactionCurrencySymbol = _getCurrencySymbol(currency);
                final description = transaction['description'] as String;
                final category = transaction['category'] as String?;
                final accountName = transaction['accountName'] as String?;
                final categoryIcon = transaction['icon'] as String?;
                final categoryColor = transaction['color'] as String?;
                final date = transaction['date'] as DateTime;

                Color typeColor;
                IconData typeIcon;
                
                if (type == 'income') {
                  typeColor = Colors.green;
                  typeIcon = Icons.arrow_downward;
                } else if (type == 'expense') {
                  typeColor = Colors.red;
                  typeIcon = Icons.arrow_upward;
                } else {
                  typeColor = Colors.blue;
                  typeIcon = Icons.swap_horiz;
                }
                
                // Use category icon and color if available
                if (categoryIcon != null && categoryIcon.isNotEmpty && type != 'transfer') {
                  try {
                    typeIcon = IconHelper.getIconData(categoryIcon);
                    if (categoryColor != null && categoryColor.isNotEmpty) {
                      typeColor = IconHelper.hexToColor(categoryColor);
                    }
                  } catch (e) {
                    // Keep default icon if parsing fails
                  }
                }

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  title: Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    type == 'income'
                        ? (accountName ?? category ?? DateFormat('MMM d, y').format(date))
                        : (category ?? DateFormat('MMM d, y').format(date)),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Text(
                    '${type == 'income' ? '+' : '-'}$transactionCurrencySymbol ${NumberFormat('#,##0.00').format(amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: type == 'income' ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView(String error, ThemeData theme) {
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
              'Error Loading Dashboard',
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
                context.read<HomeProvider>().loadDashboardData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _getCurrencySymbol(String currencyCode) {
    final currency = Currencies.all.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => const CurrencyData(code: 'USD', name: 'US Dollar', symbol: '\$'),
    );
    return currency.symbol;
  }
}
