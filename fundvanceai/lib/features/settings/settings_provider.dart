import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fundvanceai/shared/services/local_notification_service.dart';

/// Persists all user-configurable toggles/preferences to SharedPreferences.
///
/// Keys are prefixed with `settings_` to avoid collisions.
class SettingsProvider extends ChangeNotifier {
  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const _kBudgetAlerts = 'settings_budget_alerts';
  static const _kGoalAlerts = 'settings_goal_alerts';
  static const _kWeeklySummary = 'settings_weekly_summary';
  static const _kRecurringReminders = 'settings_recurring_reminders';
  static const _kNotifyHour = 'settings_notify_hour';
  static const _kNotifyMinute = 'settings_notify_minute';
  static const _kAutoSyncWifiOnly = 'settings_auto_sync_wifi_only';
  static const _kBiometricLock = 'settings_biometric_lock';
  static const _kHideBalances = 'settings_hide_balances';
  static const _kCompactList = 'settings_compact_list';

  // ── State ──────────────────────────────────────────────────────────────────
  bool _budgetAlerts = true;
  bool _goalAlerts = true;
  bool _weeklySummary = false;
  bool _recurringReminders = true;
  int _notifyHour = 9;
  int _notifyMinute = 0;
  bool _autoSyncWifiOnly = false;
  bool _biometricLock = false;
  bool _hideBalances = false;
  bool _compactList = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get budgetAlerts => _budgetAlerts;
  bool get goalAlerts => _goalAlerts;
  bool get weeklySummary => _weeklySummary;
  bool get recurringReminders => _recurringReminders;
  TimeOfDay get notificationTime =>
      TimeOfDay(hour: _notifyHour, minute: _notifyMinute);
  bool get autoSyncWifiOnly => _autoSyncWifiOnly;
  bool get biometricLock => _biometricLock;
  bool get hideBalances => _hideBalances;
  bool get compactList => _compactList;

  // ── Initialisation ─────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _budgetAlerts = prefs.getBool(_kBudgetAlerts) ?? true;
    _goalAlerts = prefs.getBool(_kGoalAlerts) ?? true;
    _weeklySummary = prefs.getBool(_kWeeklySummary) ?? false;
    _recurringReminders = prefs.getBool(_kRecurringReminders) ?? true;
    _notifyHour = prefs.getInt(_kNotifyHour) ?? 9;
    _notifyMinute = prefs.getInt(_kNotifyMinute) ?? 0;
    _autoSyncWifiOnly = prefs.getBool(_kAutoSyncWifiOnly) ?? false;
    _biometricLock = prefs.getBool(_kBiometricLock) ?? false;
    _hideBalances = prefs.getBool(_kHideBalances) ?? false;
    _compactList = prefs.getBool(_kCompactList) ?? false;
    notifyListeners();
  }

  // ── Setters ────────────────────────────────────────────────────────────────
  Future<void> setBudgetAlerts(bool v) async {
    await _set(_kBudgetAlerts, () => _budgetAlerts = v);
    if (v) {
      await LocalNotificationService.instance
          .scheduleBudgetReminder(_notifyHour, _notifyMinute);
    } else {
      await LocalNotificationService.instance.cancelBudgetReminder();
    }
  }

  Future<void> setGoalAlerts(bool v) =>
      _set(_kGoalAlerts, () => _goalAlerts = v);

  Future<void> setWeeklySummary(bool v) async {
    await _set(_kWeeklySummary, () => _weeklySummary = v);
    if (v) {
      await LocalNotificationService.instance
          .scheduleWeeklySummary(_notifyHour, _notifyMinute);
    } else {
      await LocalNotificationService.instance.cancelWeeklySummary();
    }
  }

  Future<void> setRecurringReminders(bool v) async {
    await _set(_kRecurringReminders, () => _recurringReminders = v);
    if (v) {
      await LocalNotificationService.instance
          .scheduleRecurringReminder(_notifyHour, _notifyMinute);
    } else {
      await LocalNotificationService.instance.cancelRecurringReminder();
    }
  }

  Future<void> setAutoSyncWifiOnly(bool v) =>
      _set(_kAutoSyncWifiOnly, () => _autoSyncWifiOnly = v);
  Future<void> setBiometricLock(bool v) =>
      _set(_kBiometricLock, () => _biometricLock = v);
  Future<void> setHideBalances(bool v) =>
      _set(_kHideBalances, () => _hideBalances = v);
  Future<void> setCompactList(bool v) =>
      _set(_kCompactList, () => _compactList = v);

  Future<void> setNotificationTime(TimeOfDay time) async {
    _notifyHour = time.hour;
    _notifyMinute = time.minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kNotifyHour, time.hour);
    await prefs.setInt(_kNotifyMinute, time.minute);
    // Reschedule all active notification types with the new time
    if (_budgetAlerts) {
      await LocalNotificationService.instance
          .scheduleBudgetReminder(time.hour, time.minute);
    }
    if (_weeklySummary) {
      await LocalNotificationService.instance
          .scheduleWeeklySummary(time.hour, time.minute);
    }
    if (_recurringReminders) {
      await LocalNotificationService.instance
          .scheduleRecurringReminder(time.hour, time.minute);
    }
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Future<void> _set(String key, void Function() update) async {
    update();
    final prefs = await SharedPreferences.getInstance();
    if (key == _kBudgetAlerts) await prefs.setBool(key, _budgetAlerts);
    if (key == _kGoalAlerts) await prefs.setBool(key, _goalAlerts);
    if (key == _kWeeklySummary) await prefs.setBool(key, _weeklySummary);
    if (key == _kRecurringReminders) {
      await prefs.setBool(key, _recurringReminders);
    }
    if (key == _kAutoSyncWifiOnly) await prefs.setBool(key, _autoSyncWifiOnly);
    if (key == _kBiometricLock) await prefs.setBool(key, _biometricLock);
    if (key == _kHideBalances) await prefs.setBool(key, _hideBalances);
    if (key == _kCompactList) await prefs.setBool(key, _compactList);
    notifyListeners();
  }
}
