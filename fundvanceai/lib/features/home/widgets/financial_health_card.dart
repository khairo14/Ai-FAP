import 'package:flutter/material.dart';

/// Widget to display financial health score with factor breakdown and insights.
class FinancialHealthCard extends StatelessWidget {
  final double score;
  final String status;
  final List<String> insights;
  final List<Map<String, dynamic>> factors;

  const FinancialHealthCard({
    super.key,
    required this.score,
    required this.status,
    required this.insights,
    this.factors = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Financial Health',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Animated score bar + status + counter ─────────────────────
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: score),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, animatedScore, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: animatedScore / 100,
                        minHeight: 16,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '${animatedScore.toInt()}/100',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            // ── Factor breakdown ──────────────────────────────────────────
            if (factors.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Score Breakdown',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...factors.map((f) {
                final name = f['name'] as String? ?? '';
                final earned = (f['earned'] as int?) ?? 0;
                final max = (f['max'] as int?) ?? 1;
                final pct = max > 0 ? earned / max : 0.0;
                final barColor = pct >= 0.8
                    ? Colors.green
                    : pct >= 0.5
                        ? Colors.orange
                        : Colors.red;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600)),
                                Text('$earned/$max pts',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: barColor,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(barColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // ── Insights ──────────────────────────────────────────────────
            if (insights.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Insights',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...insights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _getInsightIcon(insight),
                          size: 16,
                          color: _getInsightColor(insight),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (score >= 85) {
      return Colors.green;
    } else if (score >= 70) {
      return Colors.lightGreen;
    } else if (score >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getInsightIcon(String insight) {
    if (insight.toLowerCase().contains('excellent') ||
        insight.toLowerCase().contains('great')) {
      return Icons.check_circle;
    } else if (insight.toLowerCase().contains('good')) {
      return Icons.thumb_up;
    } else if (insight.toLowerCase().contains('warning') ||
        insight.toLowerCase().contains('important')) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }

  Color _getInsightColor(String insight) {
    if (insight.toLowerCase().contains('excellent') ||
        insight.toLowerCase().contains('great')) {
      return Colors.green;
    } else if (insight.toLowerCase().contains('good')) {
      return Colors.lightGreen;
    } else if (insight.toLowerCase().contains('warning') ||
        insight.toLowerCase().contains('important')) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}
