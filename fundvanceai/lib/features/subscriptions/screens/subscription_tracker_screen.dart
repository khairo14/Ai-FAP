import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/shared/services/smart_insights_service.dart';
import 'package:fundvanceai/shared/widgets/premium_gate.dart';

class SubscriptionTrackerScreen extends StatefulWidget {
  const SubscriptionTrackerScreen({super.key});

  @override
  State<SubscriptionTrackerScreen> createState() =>
      _SubscriptionTrackerScreenState();
}

class _SubscriptionTrackerScreenState extends State<SubscriptionTrackerScreen> {
  final SmartInsightsService _service = SmartInsightsService();
  List<RecurringExpense> _subscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter / sort
  String _sortBy = 'amount'; // 'amount' | 'name' | 'period'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _service.detectRecurring();
      if (mounted) {
        setState(() {
          _subscriptions = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load subscriptions: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<RecurringExpense> get _sorted {
    final list = [..._subscriptions];
    switch (_sortBy) {
      case 'name':
        list.sort((a, b) =>
            a.merchant.toLowerCase().compareTo(b.merchant.toLowerCase()));
        break;
      case 'period':
        list.sort((a, b) => a.period.compareTo(b.period));
        break;
      case 'amount':
      default:
        list.sort((a, b) =>
            b.estimatedMonthlyAmount.compareTo(a.estimatedMonthlyAmount));
        break;
    }
    return list;
  }

  double get _totalMonthly =>
      _subscriptions.fold(0.0, (sum, s) => sum + s.estimatedMonthlyAmount);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        backgroundColor: colorScheme.surface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sortBy,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'amount', child: Text('Sort by Amount')),
              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'period', child: Text('Sort by Period')),
            ],
            onSelected: (v) => setState(() => _sortBy = v),
          ),
        ],
      ),
      body: PremiumGate(
        featureIcon: Icons.repeat_outlined,
        featureName: 'Subscription Tracker',
        featureDescription:
            'Automatically detect recurring charges and track your subscriptions in one place.',
        child: _buildBody(colorScheme),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning transactions...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat_outlined,
                size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No subscriptions detected',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'We scan your past 90 days of transactions\nfor repeating patterns.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final currency = NumberFormat.currency(symbol: '\$');
    final sorted = _sorted;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // ── Summary header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SummaryHeader(
              totalMonthly: _totalMonthly,
              count: _subscriptions.length,
              currency: currency,
            ),
          ),

          // ── List ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) =>
                    _SubscriptionCard(item: sorted[i], currency: currency),
                childCount: sorted.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final double totalMonthly;
  final int count;
  final NumberFormat currency;

  const _SummaryHeader(
      {required this.totalMonthly,
      required this.count,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            currency.format(totalMonthly),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
          Text(
            'estimated monthly spend',
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCol(
                value: '$count',
                label: 'subscriptions',
                color: colorScheme.onPrimaryContainer,
              ),
              _StatCol(
                value: currency.format(totalMonthly * 12),
                label: 'annual cost',
                color: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCol(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final RecurringExpense item;
  final NumberFormat currency;

  const _SubscriptionCard({required this.item, required this.currency});

  IconData get _periodIcon {
    switch (item.period.toLowerCase()) {
      case 'monthly':
        return Icons.calendar_month_outlined;
      case 'weekly':
        return Icons.calendar_view_week_outlined;
      case 'yearly':
      case 'annual':
        return Icons.calendar_today_outlined;
      default:
        return Icons.repeat;
    }
  }

  Color _periodColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (item.period.toLowerCase()) {
      case 'weekly':
        return Colors.orange;
      case 'yearly':
      case 'annual':
        return Colors.green;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _periodColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              radius: 22,
              child: Text(
                item.merchant.isNotEmpty ? item.merchant[0].toUpperCase() : '?',
                style: TextStyle(
                    fontSize: 20, color: color, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.merchant,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(_periodIcon, size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        _capitalise(item.period),
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                      if (item.categoryName != null) ...[
                        Text(' · ',
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant)),
                        Text(
                          item.categoryName!,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last seen: ${_formatDate(item.lastSeen)} · ${item.occurrences}x',
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Amounts
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(item.estimatedAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '/ ${_shortPeriod(item.period)}',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 11),
                ),
                if (item.period.toLowerCase() != 'monthly')
                  Text(
                    '≈ ${currency.format(item.estimatedMonthlyAmount)}/mo',
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _shortPeriod(String p) {
    switch (p.toLowerCase()) {
      case 'weekly':
        return 'week';
      case 'monthly':
        return 'month';
      case 'yearly':
      case 'annual':
        return 'year';
      default:
        return p;
    }
  }

  String _formatDate(DateTime d) => DateFormat.MMMd().format(d);
}
