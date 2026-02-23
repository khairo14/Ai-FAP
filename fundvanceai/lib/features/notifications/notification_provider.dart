import 'package:flutter/foundation.dart';
import 'package:fundvanceai/shared/models/app_notification.dart';
import 'package:fundvanceai/shared/services/smart_insights_service.dart';
import 'package:fundvanceai/shared/models/spending_insight.dart';

/// In-memory notification centre: converts SmartInsights → AppNotifications
/// and provides unread-count badge state.
class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  bool _loading = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  bool get isLoading => _loading;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Pull fresh alerts from SmartInsightsService and convert to notifications.
  /// Call this on login and on each app resume after 1 minute idle.
  Future<void> refreshAlerts() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);

      final insights = await SmartInsightsService().generateInsights(
        startDate: start,
        endDate: end,
      );

      // De-duplicate: keep only insights whose title not already in list
      final existingTitles = _notifications.map((n) => n.title).toSet();

      for (final insight in insights) {
        if (existingTitles.contains(insight.title)) continue;
        // Skip positive / info insights with low impact to avoid noise
        if (insight.severity == InsightSeverity.positive &&
            insight.type == InsightType.budgetAlert) {
          continue;
        }

        _notifications.insert(0, _fromInsight(insight));
        existingTitles.add(insight.title);
      }
    } catch (_) {
      // Silently fail — notifications are non-critical
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void dismiss(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  // Also expose a way to add a monthly summary notification
  void addMonthlySummaryNotification({
    required String monthName,
    required double totalSpent,
    required int txCount,
  }) {
    final note = AppNotification(
      id: 'summary_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.monthlySummary,
      severity: NotificationSeverity.info,
      title: '$monthName Spending Summary',
      body:
          'You made $txCount transactions totalling \$${totalSpent.toStringAsFixed(2)} in $monthName.',
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, note);
    notifyListeners();
  }

  // ── Conversion ──────────────────────────────────────────────────────────────

  AppNotification _fromInsight(SpendingInsight insight) {
    return AppNotification(
      id: '${insight.type.name}_${insight.title.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
      type: _mapType(insight.type),
      severity: _mapSeverity(insight.severity),
      title: insight.title,
      body: insight.message,
      createdAt: insight.generatedAt,
      categoryName: insight.category,
      amount: insight.amount,
    );
  }

  NotificationType _mapType(InsightType t) {
    switch (t) {
      case InsightType.budgetAlert:
        return NotificationType.budgetExceeded;
      case InsightType.anomaly:
        return NotificationType.spendingSpike;
      case InsightType.trend:
        return NotificationType.spendingSpike;
      case InsightType.recurring:
        return NotificationType.monthlySummary;
      case InsightType.milestone:
        return NotificationType.milestone;
      case InsightType.savingsOpportunity:
        return NotificationType.milestone;
      case InsightType.spendingPattern:
        return NotificationType.spendingSpike;
    }
  }

  NotificationSeverity _mapSeverity(InsightSeverity s) {
    switch (s) {
      case InsightSeverity.critical:
        return NotificationSeverity.critical;
      case InsightSeverity.warning:
        return NotificationSeverity.warning;
      case InsightSeverity.info:
        return NotificationSeverity.info;
      case InsightSeverity.positive:
        return NotificationSeverity.positive;
    }
  }
}
