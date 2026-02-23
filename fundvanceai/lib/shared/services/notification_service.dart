import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Wraps flutter_local_notifications for OS-level local alerts.
/// All methods are static — call NotificationService.init() once at startup.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialised = false;

  // ── Channel IDs ────────────────────────────────────────────────────────────
  static const _channelBudget = 'fv_budget';
  static const _channelGoal = 'fv_goal';
  static const _channelWeekly = 'fv_weekly';

  // ── Notification IDs ───────────────────────────────────────────────────────
  static const _idBudgetBase = 1000; // 1000 + hash of category
  static const _idGoalBase = 2000; // 2000 + hash of goal id
  static const _idWeekly = 9001;

  // ── Init ───────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialised) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    // Android: create channels
    if (!kIsWeb) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelBudget,
            'Budget Alerts',
            description: 'Notifies when you approach or exceed a budget limit',
            importance: Importance.high,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelGoal,
            'Goal Milestones',
            description: 'Celebrates progress towards your savings goals',
            importance: Importance.defaultImportance,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelWeekly,
            'Weekly Summary',
            description: 'Weekly financial recap every Sunday morning',
            importance: Importance.low,
          ),
        );
      }
    }

    _initialised = true;
  }

  // ── Budget Alert ───────────────────────────────────────────────────────────

  /// Call after an expense is added. Fires if `spentPercent >= 0.9`.
  static Future<void> checkBudgetAlert({
    required String categoryName,
    required double spent,
    required double budget,
  }) async {
    if (!_initialised || budget <= 0) return;

    final pct = spent / budget;
    if (pct < 0.9) return; // below threshold — stay quiet

    final title = pct >= 1.0
        ? '⚠️ Budget exceeded: $categoryName'
        : '🔔 Budget alert: $categoryName';
    final body = pct >= 1.0
        ? 'You\'ve spent \$${spent.toStringAsFixed(0)} — \$${(spent - budget).toStringAsFixed(0)} over your \$${budget.toStringAsFixed(0)} budget.'
        : 'You\'ve used ${(pct * 100).toStringAsFixed(0)}% (\$${spent.toStringAsFixed(0)} of \$${budget.toStringAsFixed(0)}) this period.';

    await _show(
      id: _idBudgetBase + categoryName.hashCode.abs() % 900,
      title: title,
      body: body,
      channelId: _channelBudget,
      channelName: 'Budget Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  // ── Goal Milestone ─────────────────────────────────────────────────────────

  /// Call after a contribution is saved.
  /// Fires at 25 / 50 / 75 / 100 % milestones.
  static Future<void> checkGoalMilestone({
    required String goalId,
    required String goalTitle,
    required double currentAmount,
    required double targetAmount,
  }) async {
    if (!_initialised || targetAmount <= 0) return;

    final pct = (currentAmount / targetAmount).clamp(0.0, 1.0);
    final milestone = _nearestMilestone(pct);
    if (milestone == null) return;

    final isComplete = milestone == 100;
    final title = isComplete
        ? '🎉 Goal reached: $goalTitle'
        : '🚀 ${milestone.toStringAsFixed(0)}% there: $goalTitle';
    final body = isComplete
        ? 'Congratulations! You\'ve fully funded your "$goalTitle" goal!'
        : 'You\'ve saved \$${currentAmount.toStringAsFixed(0)} of your \$${targetAmount.toStringAsFixed(0)} goal.';

    await _show(
      id: _idGoalBase + goalId.hashCode.abs() % 900,
      title: title,
      body: body,
      channelId: _channelGoal,
      channelName: 'Goal Milestones',
      importance: isComplete ? Importance.high : Importance.defaultImportance,
      priority: isComplete ? Priority.high : Priority.defaultPriority,
    );
  }

  static int? _nearestMilestone(double pct) {
    const milestones = [0.25, 0.50, 0.75, 1.0];
    for (final m in milestones) {
      // Within 2% of milestone
      if ((pct - m).abs() <= 0.02) return (m * 100).round();
    }
    return null;
  }

  // ── Weekly Summary ─────────────────────────────────────────────────────────

  /// Schedules a weekly summary notification every Sunday at 09:00.
  /// Safe to call repeatedly — cancels any existing weekly notification first.
  static Future<void> scheduleWeeklySummary() async {
    if (!_initialised || kIsWeb) return;

    await _plugin.cancel(_idWeekly);

    final now = tz.TZDateTime.now(tz.local);
    // Find next Sunday at 09:00
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0, 0);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    while (next.weekday != DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idWeekly,
      '📊 Your weekly financial recap',
      'Open FundVance AI to see how you did this week.',
      next,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelWeekly,
          'Weekly Summary',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ── Cancel All ─────────────────────────────────────────────────────────────

  static Future<void> cancelAll() async {
    if (!_initialised) return;
    await _plugin.cancelAll();
  }

  // ── Internal helper ────────────────────────────────────────────────────────

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: importance,
          priority: priority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
