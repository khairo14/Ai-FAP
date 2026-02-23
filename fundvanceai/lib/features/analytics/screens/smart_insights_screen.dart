import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/shared/models/spending_insight.dart';
import 'package:fundvanceai/shared/services/smart_insights_service.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/core/constants/currencies.dart';
import 'package:fundvanceai/shared/widgets/premium_gate.dart';
import 'package:provider/provider.dart';

/// Full-screen Smart Insights experience with two tabs:
/// ① AI-generated insight cards  ② Detected recurring expenses
class SmartInsightsScreen extends StatefulWidget {
  const SmartInsightsScreen({super.key});

  @override
  State<SmartInsightsScreen> createState() => _SmartInsightsScreenState();
}

class _SmartInsightsScreenState extends State<SmartInsightsScreen>
    with SingleTickerProviderStateMixin {
  final _service = SmartInsightsService();
  late final TabController _tabs;

  bool _loading = true;
  String? _error;

  List<SpendingInsight> _insights = [];
  List<RecurringExpense> _recurring = [];

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _initDates();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _initDates() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.generateInsights(startDate: _startDate, endDate: _endDate),
        _service.detectRecurring(),
      ]);
      if (!mounted) return;
      setState(() {
        _insights = results[0] as List<SpendingInsight>;
        _recurring = results[1] as List<RecurringExpense>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _currencySymbol(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              icon: const Icon(Icons.lightbulb_outline),
              text: 'Insights (${_insights.length})',
            ),
            Tab(
              icon: const Icon(Icons.repeat),
              text: 'Recurring (${_recurring.length})',
            ),
          ],
        ),
      ),
      body: PremiumGate(
        featureIcon: Icons.smart_toy_outlined,
        featureName: 'AI Smart Insights',
        featureDescription:
            'Get personalised spending analysis, anomaly detection, and budget alerts powered by on-device AI.',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(
                    message: _error!,
                    onRetry: _load,
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _InsightsTab(insights: _insights, symbol: symbol),
                      _RecurringTab(recurring: _recurring, symbol: symbol),
                    ],
                  ),
      ),
    );
  }

  String _currencySymbol(BuildContext context) {
    final code =
        context.watch<AuthProvider>().userProfile?.currency ?? 'USD';
    return Currencies.all
        .firstWhere((c) => c.code == code,
            orElse: () =>
                const CurrencyData(code: 'USD', name: 'US Dollar', symbol: '\$'))
        .symbol;
  }
}

// ─── Insights Tab ─────────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final List<SpendingInsight> insights;
  final String symbol;

  const _InsightsTab({required this.insights, required this.symbol});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const _EmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No insights yet',
        subtitle: 'Add more expenses and budgets to unlock personalised insights.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final state =
            context.findAncestorStateOfType<_SmartInsightsScreenState>();
        await state?._load();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _InsightCard(insight: insights[i], symbol: symbol),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final SpendingInsight insight;
  final String symbol;

  const _InsightCard({required this.insight, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: insight.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: insight.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(insight.icon, size: 20, color: insight.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: insight.color,
                        ),
                      ),
                      Text(
                        insight.severityLabel.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: insight.color.withValues(alpha: 0.75),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                if (insight.amount != null)
                  _AmountChip(
                      amount: insight.amount!, symbol: symbol, color: insight.color),
              ],
            ),
            const SizedBox(height: 12),
            // ── Message
            Text(
              insight.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            // ── Optional category tag
            if (insight.category != null) ...[
              const SizedBox(height: 10),
              _CategoryChip(name: insight.category!, color: insight.color),
            ],
            // ── Optional action
            if (insight.actionLabel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: insight.color,
                    side: BorderSide(color: insight.color.withValues(alpha: 0.6)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {},
                  child: Text(insight.actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Recurring Tab ────────────────────────────────────────────────────────────

class _RecurringTab extends StatelessWidget {
  final List<RecurringExpense> recurring;
  final String symbol;

  const _RecurringTab({required this.recurring, required this.symbol});

  @override
  Widget build(BuildContext context) {
    if (recurring.isEmpty) {
      return const _EmptyState(
        icon: Icons.repeat,
        title: 'No recurring expenses detected',
        subtitle:
            'As you add more transactions we\'ll automatically identify subscriptions and regular bills.',
      );
    }

    final totalMonthly =
        recurring.fold(0.0, (s, r) => s + r.estimatedMonthlyAmount);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.repeat, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Recurring / Month',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.5),
                    ),
                    Text(
                      '$symbol${totalMonthly.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${recurring.length} subscription${recurring.length > 1 ? 's' : ''} tracked',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Individual recurring items
        ...recurring.map((r) => _RecurringCard(r: r, symbol: symbol)),
      ],
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringExpense r;
  final String symbol;

  const _RecurringCard({required this.r, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastSeenText = DateFormat('MMM d').format(r.lastSeen);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.repeat,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          _capitalize(r.merchant),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                _PillChip(label: r.period, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                if (r.categoryName != null)
                  _PillChip(
                      label: r.categoryName!,
                      color: theme.colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r.occurrences} occurrences · last seen $lastSeenText',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$symbol${r.estimatedAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              '$symbol${r.estimatedMonthlyAmount.toStringAsFixed(0)}/mo',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Small helper widgets ─────────────────────────────────────────────────────

class _AmountChip extends StatelessWidget {
  final double amount;
  final String symbol;
  final Color color;

  const _AmountChip(
      {required this.amount, required this.symbol, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$symbol${amount.abs().toStringAsFixed(0)}',
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final Color color;

  const _CategoryChip({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        name,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PillChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load insights'),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
