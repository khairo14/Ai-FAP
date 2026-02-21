import 'package:flutter/material.dart';

/// Type of AI-generated spending insight
enum InsightType {
  budgetAlert,
  anomaly,
  trend,
  recurring,
  milestone,
}

/// Visual / urgency level of an insight
enum InsightSeverity {
  positive,  // green  — good news
  info,      // blue   — neutral information
  warning,   // orange — attention needed
  critical,  // red    — action required
}

/// A single AI-generated financial insight card
class SpendingInsight {
  final InsightType type;
  final InsightSeverity severity;
  final String title;
  final String message;

  /// Related category name (optional)
  final String? category;

  /// Key monetary figure (optional, for display in the card)
  final double? amount;

  /// Label for the optional action button
  final String? actionLabel;

  /// Extra data (e.g. merchant name, budget id) for the action handler
  final Map<String, dynamic>? metadata;

  final DateTime generatedAt;

  const SpendingInsight({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.category,
    this.amount,
    this.actionLabel,
    this.metadata,
    required this.generatedAt,
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  IconData get icon {
    switch (type) {
      case InsightType.budgetAlert:
        return Icons.account_balance_wallet_outlined;
      case InsightType.anomaly:
        return Icons.trending_up;
      case InsightType.trend:
        return Icons.show_chart;
      case InsightType.recurring:
        return Icons.repeat;
      case InsightType.milestone:
        return Icons.emoji_events_outlined;
    }
  }

  Color get color {
    switch (severity) {
      case InsightSeverity.positive:
        return const Color(0xFF2E7D32); // dark green
      case InsightSeverity.info:
        return const Color(0xFF1565C0); // dark blue
      case InsightSeverity.warning:
        return const Color(0xFFE65100); // dark orange
      case InsightSeverity.critical:
        return const Color(0xFFC62828); // dark red
    }
  }

  Color get backgroundColor {
    switch (severity) {
      case InsightSeverity.positive:
        return const Color(0xFFE8F5E9);
      case InsightSeverity.info:
        return const Color(0xFFE3F2FD);
      case InsightSeverity.warning:
        return const Color(0xFFFFF3E0);
      case InsightSeverity.critical:
        return const Color(0xFFFFEBEE);
    }
  }

  String get severityLabel {
    switch (severity) {
      case InsightSeverity.positive:
        return 'Great news';
      case InsightSeverity.info:
        return 'Info';
      case InsightSeverity.warning:
        return 'Heads up';
      case InsightSeverity.critical:
        return 'Action needed';
    }
  }
}
