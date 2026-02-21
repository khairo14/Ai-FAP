import 'package:flutter/material.dart';

enum NotificationType {
  budgetExceeded,
  budgetWarning,
  spendingSpike,
  largePurchase,
  monthlySummary,
  milestone,
}

enum NotificationSeverity { critical, warning, info, positive }

class AppNotification {
  final String id;
  final NotificationType type;
  final NotificationSeverity severity;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  // Optional context data
  final String? categoryId;
  final String? categoryName;
  final double? amount;

  AppNotification({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.categoryId,
    this.categoryName,
    this.amount,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.budgetExceeded:
        return Icons.warning_rounded;
      case NotificationType.budgetWarning:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.spendingSpike:
        return Icons.trending_up;
      case NotificationType.largePurchase:
        return Icons.receipt_long;
      case NotificationType.monthlySummary:
        return Icons.summarize_outlined;
      case NotificationType.milestone:
        return Icons.emoji_events_outlined;
    }
  }

  Color get color {
    switch (severity) {
      case NotificationSeverity.critical:
        return const Color(0xFFC62828);
      case NotificationSeverity.warning:
        return const Color(0xFFE65100);
      case NotificationSeverity.info:
        return const Color(0xFF1565C0);
      case NotificationSeverity.positive:
        return const Color(0xFF2E7D32);
    }
  }

  Color get backgroundColor {
    switch (severity) {
      case NotificationSeverity.critical:
        return const Color(0xFFFFEBEE);
      case NotificationSeverity.warning:
        return const Color(0xFFFFF3E0);
      case NotificationSeverity.info:
        return const Color(0xFFE3F2FD);
      case NotificationSeverity.positive:
        return const Color(0xFFE8F5E9);
    }
  }
}
