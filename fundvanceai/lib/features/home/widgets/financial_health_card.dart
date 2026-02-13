import 'package:flutter/material.dart';

/// Widget to display financial health score with insights
class FinancialHealthCard extends StatelessWidget {
  final double score;
  final String status;
  final List<String> insights;

  const FinancialHealthCard({
    super.key,
    required this.score,
    required this.status,
    required this.insights,
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
                Icon(
                  Icons.favorite,
                  color: color,
                  size: 24,
                ),
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

            // Score indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Score bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 16,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status and score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                              ),
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
                            '${score.toInt()}/100',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Insights
            if (insights.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Insights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
    if (score >= 80) {
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
