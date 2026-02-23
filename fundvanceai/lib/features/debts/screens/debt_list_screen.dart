import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/debts/debt_provider.dart';
import 'package:fundvanceai/features/debts/screens/debt_form_screen.dart';
import 'package:fundvanceai/features/debts/screens/debt_detail_screen.dart';
import 'package:fundvanceai/shared/models/debt.dart';
import 'package:fundvanceai/shared/widgets/premium_gate.dart';
import 'package:fundvanceai/features/premium/premium_provider.dart';
import 'package:fundvanceai/features/premium/screens/paywall_screen.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<DebtProvider>().loadDebts();
  }

  void _openDetail(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: debt)),
    );
  }

  Future<void> _addDebt() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DebtFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Manager'),
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Paid Off'),
          ],
        ),
      ),
      floatingActionButton: Consumer<PremiumProvider>(
        builder: (context, premium, _) => FloatingActionButton.extended(
          onPressed: premium.isPremium
              ? _addDebt
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  ),
          icon: Icon(premium.isPremium ? Icons.add : Icons.lock_rounded),
          label: Text(premium.isPremium ? 'Add Debt' : 'Upgrade to Add'),
        ),
      ),
      body: PremiumGate(
        featureIcon: Icons.credit_card_off_outlined,
        featureName: 'Debt Payoff Planner',
        featureDescription:
            'Use snowball and avalanche strategies to eliminate debt faster with AI-powered payoff simulations.',
        child: Consumer<DebtProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary bar
              if (provider.activeDebts.isNotEmpty)
                _SummaryBanner(provider: provider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DebtTab(
                      debts: provider.activeDebts,
                      onRefresh: _refresh,
                      onTap: _openDetail,
                      empty: _EmptyState(
                        icon: Icons.credit_score_outlined,
                        title: 'No active debts',
                        subtitle: 'Tap + to track a debt or loan',
                      ),
                    ),
                    _DebtTab(
                      debts: provider.paidOffDebts,
                      onRefresh: _refresh,
                      onTap: _openDetail,
                      empty: _EmptyState(
                        icon: Icons.celebration_outlined,
                        title: 'No paid-off debts yet',
                        subtitle: 'Keep making payments – you\'ll get there!',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final DebtProvider provider;
  const _SummaryBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      color: colorScheme.errorContainer.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BannerStat(
            label: 'Total Debt',
            value: currency.format(provider.totalBalance),
            color: colorScheme.error,
          ),
          _BannerStat(
            label: 'Min/Month',
            value: currency.format(provider.totalMinimumPayments),
            color: Colors.orange,
          ),
          _BannerStat(
            label: 'Interest/Mo',
            value: currency.format(provider.totalMonthlyInterest),
            color: Colors.deepOrange,
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BannerStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DebtTab extends StatelessWidget {
  final List<Debt> debts;
  final Future<void> Function() onRefresh;
  final void Function(Debt) onTap;
  final Widget empty;

  const _DebtTab(
      {required this.debts,
      required this.onRefresh,
      required this.onTap,
      required this.empty});

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) return empty;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: debts.length,
        itemBuilder: (context, i) =>
            _DebtCard(debt: debts[i], onTap: () => onTap(debts[i])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTap;

  const _DebtCard({required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final progress = debt.progressPercent.clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        colorScheme.errorContainer.withValues(alpha: 0.3),
                    child: Icon(debt.debtType.icon, color: colorScheme.error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(debt.name,
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(debt.debtType.label,
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (debt.isPaidOff)
                    const Icon(Icons.check_circle,
                        size: 20, color: Colors.green),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                color: Colors.green,
                backgroundColor: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ${currency.format(debt.currentBalance)}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '${debt.interestRate.toStringAsFixed(1)}% APR',
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.error),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% paid off',
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    'Min: ${currency.format(debt.minimumPayment)}/mo',
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
