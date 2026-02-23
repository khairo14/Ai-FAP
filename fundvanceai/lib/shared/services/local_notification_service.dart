import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Manages all scheduled local notifications for the app.
///
/// Notification IDs:
///   1 — weekly spending summary
///   2 — budget alert reminder (daily)
///   3 — recurring expense reminder (monthly prompt)
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // ── Weekly summary ─────────────────────────────────────────────────────────

  /// Schedule (or reschedule) the weekly summary notification.
  /// Fires every Sunday at [hour]:[minute].
  Future<void> scheduleWeeklySummary(int hour, int minute) async {
    await _plugin.cancel(1);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = _nextWeekday(now, DateTime.sunday, hour, minute);
    // If less than 30 seconds away, push to next week
    if (scheduled.difference(now).inSeconds < 30) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      1,
      'Weekly Spending Summary',
      'Your weekly spending digest is ready. Tap to view.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summary',
          'Weekly Summary',
          channelDescription: 'Weekly spending summaries',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelWeeklySummary() async => _plugin.cancel(1);

  // ── Budget alert reminder ──────────────────────────────────────────────────

  /// Schedule a daily nudge at [hour]:[minute] to check budget usage.
  Future<void> scheduleBudgetReminder(int hour, int minute) async {
    await _plugin.cancel(2);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = _nextTime(now, hour, minute);
    if (scheduled.difference(now).inSeconds < 30) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      2,
      'Budget Check',
      'How are your budgets looking today?',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Budget overspend alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelBudgetReminder() async => _plugin.cancel(2);

  // ── Recurring expense reminder ─────────────────────────────────────────────

  /// Schedule a monthly prompt on the 1st of each month at [hour]:[minute].
  Future<void> scheduleRecurringReminder(int hour, int minute) async {
    await _plugin.cancel(3);
    final now = tz.TZDateTime.now(tz.local);
    var candidate =
        tz.TZDateTime(tz.local, now.year, now.month, 1, hour, minute);
    if (candidate.isBefore(now)) {
      candidate =
          tz.TZDateTime(tz.local, now.year, now.month + 1, 1, hour, minute);
    }

    await _plugin.zonedSchedule(
      3,
      'Recurring Expenses',
      'Check your upcoming recurring charges for this month.',
      candidate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recurring_reminders',
          'Recurring Reminders',
          channelDescription: 'Monthly recurring expense reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> cancelRecurringReminder() async => _plugin.cancel(3);

  // ── Cancel all ─────────────────────────────────────────────────────────────
  Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Helpers ────────────────────────────────────────────────────────────────
  tz.TZDateTime _nextTime(tz.TZDateTime from, int hour, int minute) {
    var d =
        tz.TZDateTime(tz.local, from.year, from.month, from.day, hour, minute);
    if (d.isBefore(from)) d = d.add(const Duration(days: 1));
    return d;
  }

  tz.TZDateTime _nextWeekday(
      tz.TZDateTime from, int weekday, int hour, int minute) {
    var d =
        tz.TZDateTime(tz.local, from.year, from.month, from.day, hour, minute);
    while (d.weekday != weekday || d.isBefore(from)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }
}
