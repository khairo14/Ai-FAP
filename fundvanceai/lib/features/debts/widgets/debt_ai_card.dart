import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/debt.dart';
import '../../../shared/services/debt_ai_service.dart';
import '../../../features/income/income_provider.dart';
import '../../../features/premium/premium_provider.dart';
import '../../../features/premium/screens/paywall_screen.dart';

/// Collapsible AI coaching card for debt detail screen.
/// Shows strategy recommendation, payoff projection, what-if scenarios,
/// and income-debt insight. Gated behind Premium.
class DebtAICard extends StatefulWidget {
  final Debt debt;
  final List<Debt> allActiveDebts;

  const DebtAICard({
    super.key,
    required this.debt,
    required this.allActiveDebts,
  });

  @override
  State<DebtAICard> createState() => _DebtAICardState();
}

class _DebtAICardState extends State<DebtAICard> {
  final _ai = DebtAIService();
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final theme = Theme.of(context);

    final milestone = _ai.getMilestone(widget.debt);
    final milestoneMsg = _ai.milestoneMessage(milestone, widget.debt.name);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap:
                isPremium ? () => setState(() => _expanded = !_expanded) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.psychology_outlined,
                        size: 18, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI Coach',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
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
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Personalised debt payoff coaching',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (isPremium)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),

          // ── Milestone banner (always visible) ────────────────────────────
          if (milestone != DebtMilestone.none)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.35), width: 1),
              ),
              child: Text(
                milestoneMsg,
                style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),

          // ── Locked teaser for free users ─────────────────────────────────
          if (!isPremium) ...[
            const SizedBox(height: 8),
            _LockedTeaser(debt: widget.debt, ai: _ai),
            const SizedBox(height: 4),
          ],

          // ── Full AI content for premium users ────────────────────────────
          if (isPremium && _expanded) ...[
            const SizedBox(height: 4),
            _PremiumContent(
                debt: widget.debt,
                allActiveDebts: widget.allActiveDebts,
                ai: _ai),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Locked teaser shown to free users
// ─────────────────────────────────────────────────────────────────────────────

class _LockedTeaser extends StatelessWidget {
  final Debt debt;
  final DebtAIService ai;

  const _LockedTeaser({required this.debt, required this.ai});

  @override
  Widget build(BuildContext context) {
    final projection = ai.projectDebt(debt);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Teaser: payoff date (blurred-like with low opacity)
          Opacity(
            opacity: 0.35,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TeaserStat(
                      label: 'Payoff date',
                      value: DateFormat('MMM yyyy')
                          .format(projection.estimatedPayoffDate)),
                  _TeaserStat(
                      label: 'Months left',
                      value: '${projection.monthsRemaining}'),
                  _TeaserStat(
                      label: 'Interest left',
                      value: fmt.format(projection.totalInterestRemaining)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Upgrade CTA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen())),
              icon: const Icon(Icons.lock_open_rounded, size: 16),
              label: const Text('Unlock AI Coaching — Upgrade to Pro'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TeaserStat extends StatelessWidget {
  final String label;
  final String value;

  const _TeaserStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full premium AI content
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumContent extends StatelessWidget {
  final Debt debt;
  final List<Debt> allActiveDebts;
  final DebtAIService ai;

  const _PremiumContent({
    required this.debt,
    required this.allActiveDebts,
    required this.ai,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final fmt2 = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final projection = ai.projectDebt(debt);
    final strategy = ai.recommendStrategy(allActiveDebts);
    final whatIfs = ai.suggestedWhatIfs(allActiveDebts);

    // Estimate monthly income from loaded income list (last 90 days / 3)
    final incomeProvider = context.watch<IncomeProvider>();
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 90));
    final recentIncome = incomeProvider.incomeList
        .where((i) => i.incomeDate.isAfter(cutoff))
        .fold(0.0, (sum, i) => sum + i.netAmount);
    final avgMonthlyIncome = recentIncome / 3.0;
    final incomeInsight = ai.incomeInsight(allActiveDebts, avgMonthlyIncome);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Payoff Projection ──────────────────────────────────────────
          _SectionHeader(
              icon: Icons.event_available, label: 'Payoff Projection'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBlock(
                  label: 'Est. payoff',
                  value: projection.monthsRemaining >= 999
                      ? 'Never*'
                      : DateFormat('MMM yyyy')
                          .format(projection.estimatedPayoffDate),
                  color: Colors.teal,
                ),
                _StatBlock(
                  label: 'Months left',
                  value: projection.monthsRemaining >= 999
                      ? '—'
                      : '${projection.monthsRemaining}',
                  color: Colors.teal,
                ),
                _StatBlock(
                  label: 'Interest left',
                  value: projection.totalInterestRemaining == double.infinity
                      ? '—'
                      : fmt.format(projection.totalInterestRemaining),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          if (projection.monthsRemaining >= 999) ...[
            const SizedBox(height: 4),
            Text(
              '* Your minimum payment does not cover the monthly interest. '
              'Increase your payment to start reducing this balance.',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),

          // ── Strategy Recommendation ────────────────────────────────────
          if (allActiveDebts.length > 1) ...[
            _SectionHeader(
                icon: Icons.route_outlined, label: 'Strategy for All Debts'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _strategyColor(strategy.recommended)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _strategyColor(strategy.recommended)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_strategyIcon(strategy.recommended),
                          size: 18,
                          color: _strategyColor(strategy.recommended)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          strategy.headline,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _strategyColor(strategy.recommended),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (strategy.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      strategy.explanation,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── What-If Scenarios ──────────────────────────────────────────
          if (whatIfs.isNotEmpty) ...[
            _SectionHeader(
                icon: Icons.tune_outlined, label: 'What If You Pay More?'),
            const SizedBox(height: 8),
            ...whatIfs.map((w) => _WhatIfRow(result: w, fmt: fmt, fmt2: fmt2)),
            const SizedBox(height: 16),
          ],

          // ── Income Insight ─────────────────────────────────────────────
          _SectionHeader(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Debt-to-Income'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _dtiColor(incomeInsight.ratingLabel).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    _dtiColor(incomeInsight.ratingLabel).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _dtiColor(incomeInsight.ratingLabel)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        incomeInsight.ratingLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _dtiColor(incomeInsight.ratingLabel),
                        ),
                      ),
                    ),
                    if (incomeInsight.debtToIncomeRatio > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${(incomeInsight.debtToIncomeRatio * 100).toStringAsFixed(0)}% of income',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  incomeInsight.advice,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _strategyColor(String strategy) {
    switch (strategy) {
      case 'avalanche':
        return Colors.orange;
      case 'snowball':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  IconData _strategyIcon(String strategy) {
    switch (strategy) {
      case 'avalanche':
        return Icons.local_fire_department_outlined;
      case 'snowball':
        return Icons.ac_unit;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _dtiColor(String label) {
    switch (label) {
      case 'Healthy':
        return Colors.green;
      case 'Moderate':
        return Colors.amber;
      case 'High':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.4,
              ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBlock(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _WhatIfRow extends StatelessWidget {
  final WhatIfResult result;
  final NumberFormat fmt;
  final NumberFormat fmt2;

  const _WhatIfRow(
      {required this.result, required this.fmt, required this.fmt2});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSavings = result.monthsSaved > 0 || result.interestSaved > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasSavings
            ? Colors.green.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline,
              size: 16,
              color: hasSavings
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '+${fmt2.format(result.extraPerMonth)}/mo',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color:
                      hasSavings ? Colors.green : theme.colorScheme.onSurface),
            ),
          ),
          if (hasSavings) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (result.monthsSaved > 0)
                  Text(
                    '${result.monthsSaved} mo earlier',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                if (result.interestSaved > 0)
                  Text(
                    'save ${fmt.format(result.interestSaved)} interest',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11),
                  ),
              ],
            ),
          ] else
            Text('No difference',
                style: TextStyle(
                    fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
