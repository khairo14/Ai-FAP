import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Runs once-per-day background scheduling tasks:
///
///  A. Auto-create recurring expense entries
///  B. Auto-create recurring income entries
///  C. Schedule debt-due-date reminder notifications
///  D. Nudge users about inactive savings goals (monthly)
///  E. Budget period-start notifications (1st of month)
///
/// Notification ID ranges (avoid collisions with 1–3 in LocalNotificationService):
///   10  = budget period alert (current month)
///   100 + expense index = upcoming recurring expense reminder
///   200 + debt index    = debt payment due reminder
///   300 + goal index    = goal contribution nudge
class RecurringSchedulerService {
  RecurringSchedulerService._();

  static const _kLastRunKey = 'recurringSchedulerLastRun';

  static final _supabase = Supabase.instance.client;
  static String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  static final _notifPlugin = FlutterLocalNotificationsPlugin();

  // ── Public entry point ────────────────────────────────────────────────────

  /// Call this at startup. Skips if already ran today.
  static Future<void> runIfNeeded() async {
    // Web / unauthenticated guard
    if (kIsWeb) return;
    try {
      if (_supabase.auth.currentUser == null) return;
    } catch (_) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRun = prefs.getString(_kLastRunKey);
      final today = _todayKey();
      if (lastRun == today) return; // already ran today

      await Future.wait([
        _runExpenses(),
        _runIncome(),
        _runDebt(),
        _runGoals(),
        _runBudgets(),
      ]);

      await prefs.setString(_kLastRunKey, today);
    } catch (e) {
      debugPrint('[RecurringScheduler] Error: $e');
    }
  }

  // ── A. Recurring Expenses ─────────────────────────────────────────────────

  static Future<void> _runExpenses() async {
    try {
      final rows = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', _userId)
          .eq('is_recurring', true)
          .eq('is_paused', false)
          .filter('deleted_at', 'is', null);

      final now = DateTime.now();

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final frequency = row['recurring_frequency'] as String?;
        if (frequency == null) continue;

        // Determine when this should next auto-create
        final lastAutoRaw = row['last_auto_created_at'] as String?;
        final baseDate = lastAutoRaw != null
            ? DateTime.parse(lastAutoRaw)
            : DateTime.parse(row['date'] as String);

        // Check if there's an end date and we've passed it
        final endDateRaw = row['recurring_end_date'] as String?;
        if (endDateRaw != null) {
          final endDate = DateTime.parse(endDateRaw);
          if (now.isAfter(endDate)) continue;
        }

        final nextDue = _addInterval(baseDate, frequency);
        if (now.isBefore(nextDue)) {
          // Not yet due — but schedule ahead-of-time reminder notification
          final reminderDate = nextDue.subtract(const Duration(days: 1));
          if (_sameDay(reminderDate, now) || reminderDate.isBefore(now)) {
            final merchant = row['merchant'] as String? ?? 'Recurring expense';
            final amount = row['amount'];
            await _showImmediateNotification(
              id: 100 + i,
              title: 'Recurring expense due tomorrow',
              body: '$merchant — ${row['currency'] ?? ''} $amount',
              channelId: 'recurring_expenses',
              channelName: 'Recurring Expenses',
            );
          }
          continue;
        }

        // Due — auto-create a copy with today's date
        await _createExpenseCopy(row, now);

        // Update last_auto_created_at
        await _supabase
            .from('expenses')
            .update({'last_auto_created_at': now.toIso8601String()})
            .eq('id', row['id'] as String)
            .eq('user_id', _userId);
      }
    } catch (e) {
      debugPrint('[RecurringScheduler] expenses error: $e');
    }
  }

  static Future<void> _createExpenseCopy(
      Map<String, dynamic> source, DateTime date) async {
    final copy = <String, dynamic>{
      'user_id': _userId,
      'amount': source['amount'],
      'currency': source['currency'],
      'date': _dateKey(date),
      'category_id': source['category_id'],
      'account_id': source['account_id'],
      'merchant': source['merchant'],
      'description': source['description'],
      'notes': 'Auto-created from recurring expense',
      'payment_method': source['payment_method'],
      'tags': source['tags'],
      'is_recurring': false, // copy is a single entry, not itself recurring
    };
    // Remove null values
    copy.removeWhere((k, v) => v == null);
    await _supabase.from('expenses').insert(copy);
  }

  // ── B. Recurring Income ───────────────────────────────────────────────────

  static Future<void> _runIncome() async {
    try {
      final rows = await _supabase
          .from('income_records')
          .select()
          .eq('user_id', _userId)
          .eq('is_recurring', true)
          .eq('is_paused', false)
          .filter('deleted_at', 'is', null);

      final now = DateTime.now();

      for (final r in rows) {
        final nextOccurrenceRaw = r['next_occurrence'] as String?;
        if (nextOccurrenceRaw == null) continue;

        final nextOccurrence = DateTime.parse(nextOccurrenceRaw);
        if (now.isBefore(nextOccurrence)) continue;

        // Due — auto-create a copy
        await _createIncomeCopy(r, now);

        // Advance next_occurrence by the recurrence pattern
        final pattern = r['recurrence_pattern'] as String? ?? 'monthly';
        final newNext = _addInterval(nextOccurrence, pattern);
        await _supabase
            .from('income_records')
            .update({
              'next_occurrence': newNext.toIso8601String(),
              'last_auto_created_at': now.toIso8601String(),
            })
            .eq('id', r['id'] as String)
            .eq('user_id', _userId);
      }
    } catch (e) {
      debugPrint('[RecurringScheduler] income error: $e');
    }
  }

  static Future<void> _createIncomeCopy(
      Map<String, dynamic> source, DateTime date) async {
    final copy = <String, dynamic>{
      'user_id': _userId,
      'amount': source['amount'],
      'currency': source['currency'],
      'income_date': _dateKey(date),
      'category_id': source['category_id'],
      'account_id': source['account_id'],
      'description': source['description'],
      'notes': 'Auto-created from recurring income',
      'tags': source['tags'],
      'is_recurring': false,
    };
    copy.removeWhere((k, v) => v == null);
    await _supabase.from('income_records').insert(copy);
  }

  // ── C. Debt Reminders ─────────────────────────────────────────────────────

  static Future<void> _runDebt() async {
    try {
      final rows = await _supabase
          .from('debts')
          .select()
          .eq('user_id', _userId)
          .eq('is_paid_off', false)
          .filter('deleted_at', 'is', null)
          .not('payment_due_day', 'is', null);

      final now = DateTime.now();

      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final dueDay = r['payment_due_day'] as int?;
        if (dueDay == null) continue;

        final reminderDays = (r['payment_reminder_days'] as int?) ?? 3;

        // Calculate this month's due date
        final dueThisMonth = DateTime(now.year, now.month, dueDay.clamp(1, 28));
        final reminderDate =
            dueThisMonth.subtract(Duration(days: reminderDays));

        if (_sameDay(reminderDate, now)) {
          final name = r['name'] as String? ?? 'Debt';
          final balance = r['current_balance'];
          final currency = r['currency'] as String? ?? '';
          final daysLabel =
              reminderDays == 1 ? 'tomorrow' : 'in $reminderDays days';
          await _showImmediateNotification(
            id: 200 + i,
            title: 'Payment due $daysLabel',
            body: '$name — $currency $balance due on day $dueDay',
            channelId: 'debt_reminders',
            channelName: 'Debt Reminders',
          );
        }
      }
    } catch (e) {
      debugPrint('[RecurringScheduler] debt error: $e');
    }
  }

  // ── D. Goal Nudges ────────────────────────────────────────────────────────

  static Future<void> _runGoals() async {
    // Nudge on the 5th of each month only
    final now = DateTime.now();
    if (now.day != 5) return;

    try {
      final rows = await _supabase
          .from('goals')
          .select()
          .eq('user_id', _userId)
          .eq('is_completed', false)
          .filter('deleted_at', 'is', null);

      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final target = (r['target_amount'] as num?)?.toDouble() ?? 0;
        final saved = (r['saved_amount'] as num?)?.toDouble() ?? 0;
        if (target <= 0 || saved >= target) continue;

        // Check last contribution date
        final contributions = await _supabase
            .from('goal_contributions')
            .select('contributed_at')
            .eq('goal_id', r['id'] as String)
            .order('contributed_at', ascending: false)
            .limit(1);

        bool shouldNudge = true;
        if (contributions.isNotEmpty) {
          final lastRaw = contributions[0]['contributed_at'] as String?;
          if (lastRaw != null) {
            final last = DateTime.parse(lastRaw);
            if (now.difference(last).inDays < 25) shouldNudge = false;
          }
        }

        if (shouldNudge) {
          final name = r['name'] as String? ?? 'Savings goal';
          final progressPct =
              target > 0 ? ((saved / target) * 100).toStringAsFixed(0) : '0';
          await _showImmediateNotification(
            id: 300 + i,
            title: 'Keep your goal on track',
            body: '$name is at $progressPct% — consider adding a contribution!',
            channelId: 'goal_nudges',
            channelName: 'Goal Nudges',
          );
        }
      }
    } catch (e) {
      debugPrint('[RecurringScheduler] goals error: $e');
    }
  }

  // ── E. Budget Period Alerts ───────────────────────────────────────────────

  static Future<void> _runBudgets() async {
    final now = DateTime.now();
    if (now.day != 1) return; // Only on the 1st of the month

    try {
      final rows = await _supabase
          .from('budgets')
          .select('name, amount, currency')
          .eq('user_id', _userId)
          .filter('deleted_at', 'is', null);

      if ((rows as List).isEmpty) return;

      final count = rows.length;
      await _showImmediateNotification(
        id: 10,
        title: 'New budget period started',
        body:
            'You have $count active budget${count == 1 ? '' : 's'} for ${_monthName(now.month)}. Stay on track!',
        channelId: 'budget_alerts',
        channelName: 'Budget Alerts',
      );
    } catch (e) {
      debugPrint('[RecurringScheduler] budgets error: $e');
    }
  }

  // ── Notification helper ───────────────────────────────────────────────────

  static Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    try {
      await _notifPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('[RecurringScheduler] notification error: $e');
    }
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _addInterval(DateTime from, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'bi-weekly':
      case 'biweekly':
        return from.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  static String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return (month >= 1 && month <= 12) ? names[month] : '';
  }
}
