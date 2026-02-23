import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/services/goal_ai_service.dart';
import '../../../shared/services/goal_service.dart';
import '../../../features/income/income_provider.dart';
import '../../../features/expenses/expense_provider.dart';
import '../../premium/premium_provider.dart';
import '../../premium/screens/paywall_screen.dart';

/// Collapsible AI coaching card shown on the Goal Detail screen.
class GoalAICard extends StatefulWidget {
  final Goal goal;

  const GoalAICard({super.key, required this.goal});

  @override
  State<GoalAICard> createState() => _GoalAICardState();
}

class _GoalAICardState extends State<GoalAICard> {
  final _service = GoalAIService();
  final _goalService = GoalService();

  List<GoalContribution> _contributions = [];
  bool _expanded = true;
  bool _loading = true;
  GoalAIInsight? _insight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _compute());
  }

  Future<void> _compute() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _contributions = await _goalService.getContributions(widget.goal.id);
    } catch (_) {}

    if (!mounted) return;

    final incomeProvider = context.read<IncomeProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    final insight = _service.analyze(
      goal: widget.goal,
      recentIncome: incomeProvider.incomeList,
      recentExpenses: expenseProvider.expenses,
      contributions: _contributions,
    );

    if (mounted) {
      setState(() {
        _insight = insight;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (always visible) ──────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap:
                isPremium ? () => setState(() => _expanded = !_expanded) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.auto_awesome, size: 18, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'AI Goal Coach',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (!isPremium) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB347),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isPremium)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),

          // ── Locked teaser for free users ─────────────────────────────
          if (!isPremium) ...[
            _LockedTeaser(),
          ],

          // ── Full content for premium users ───────────────────────────
          if (isPremium && _expanded) ...[
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_insight == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load insights.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: _InsightBody(
                  insight: _insight!,
                  goal: widget.goal,
                  currency: currency,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Locked teaser
// ─────────────────────────────────────────────────────────────────────────────

class _LockedTeaser extends StatelessWidget {
  const _LockedTeaser();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          // Blurred preview
          Opacity(
            opacity: 0.35,
            child: Column(
              children: [
                _PreviewRow(
                    icon: Icons.savings_outlined,
                    label: 'Required contribution / month',
                    value: '—'),
                _PreviewRow(
                    icon: Icons.trending_up,
                    label: 'Monthly surplus',
                    value: '—'),
                _PreviewRow(
                    icon: Icons.hourglass_bottom,
                    label: 'Months to goal',
                    value: '—'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.lock_open_outlined, size: 16),
              label: const Text('Unlock AI Goal Coach'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PreviewRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant))),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InsightBody extends StatelessWidget {
  final GoalAIInsight insight;
  final Goal goal;
  final NumberFormat currency;

  const _InsightBody({
    required this.insight,
    required this.goal,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Milestone banner ─────────────────────────────────────────────
        if (insight.milestoneLabel != null) ...[
          _Banner(
            color: Colors.green,
            icon: Icons.emoji_events_outlined,
            text: insight.milestoneLabel!,
          ),
          const SizedBox(height: 12),
        ],

        // ── At-risk alert ────────────────────────────────────────────────
        if (insight.isAtRisk) ...[
          _Banner(
            color: Colors.orange,
            icon: Icons.warning_amber_outlined,
            text: 'No contribution in ${insight.daysSinceLastContribution} days'
                ' — your goal may fall behind.',
          ),
          const SizedBox(height: 12),
        ],

        // ── Pacing summary ───────────────────────────────────────────────
        _SectionTitle('Pacing'),
        const SizedBox(height: 8),
        _StatRow(
          label: 'Monthly income (avg)',
          value: currency.format(insight.avgMonthlyIncome),
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        _StatRow(
          label: 'Monthly expenses (avg)',
          value: currency.format(insight.avgMonthlyExpenses),
          icon: Icons.trending_down,
          color: Colors.red,
        ),
        _StatRow(
          label: 'Estimated surplus',
          value: currency.format(insight.estimatedSurplus),
          icon: Icons.savings_outlined,
          color: insight.estimatedSurplus >= 0 ? Colors.teal : Colors.red,
        ),

        if (insight.requiredMonthlyContribution != null) ...[
          const Divider(height: 20),
          _StatRow(
            label: 'Required / month to hit target',
            value: currency.format(insight.requiredMonthlyContribution),
            icon: Icons.calendar_month_outlined,
            color: cs.primary,
          ),
          if (insight.monthsToTarget != null)
            _StatRow(
              label: 'Months remaining',
              value: '${insight.monthsToTarget}',
              icon: Icons.hourglass_bottom,
              color: cs.onSurfaceVariant,
            ),
        ],

        // ── Recommendation ───────────────────────────────────────────────
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _buildRecommendation(insight, goal, currency),
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
                ),
              ),
            ],
          ),
        ),

        // ── Catch-up prompt ──────────────────────────────────────────────
        if (insight.behindPaceAmount > 0 && insight.catchUpThisMonth > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'re ${currency.format(insight.behindPaceAmount)} behind pace. '
                    'Contributing ${currency.format(insight.catchUpThisMonth)} this month '
                    'gets you back on track.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _buildRecommendation(
      GoalAIInsight insight, Goal goal, NumberFormat fmt) {
    if (goal.isCompleted) {
      return 'Congratulations! Consider starting a new goal to keep building your financial strength.';
    }
    if (insight.requiredMonthlyContribution == null) {
      if (insight.estimatedSurplus > 0) {
        return 'Set a target date to get a personalized monthly contribution plan. '
            'Your current surplus of ${fmt.format(insight.estimatedSurplus)}/mo '
            'is already a strong foundation.';
      }
      return 'Add a target date to your goal to unlock a personalised saving plan.';
    }
    if (insight.surplusCoversContribution) {
      return 'Your surplus comfortably covers the required ${fmt.format(insight.requiredMonthlyContribution)}/mo. '
          'Automate a monthly transfer to stay on track effortlessly.';
    }
    final gap = insight.requiredMonthlyContribution! - insight.estimatedSurplus;
    return 'Your surplus is ${fmt.format(insight.estimatedSurplus)}/mo but you need '
        '${fmt.format(insight.requiredMonthlyContribution)}/mo. Consider reducing spending by '
        '${fmt.format(gap)}/mo or extending your target date.';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Banner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
