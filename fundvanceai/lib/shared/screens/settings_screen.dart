import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fundvanceai/core/constants/app_constants.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/settings/settings_provider.dart';
import 'package:fundvanceai/features/settings/screens/theme_selection_screen.dart';
import 'package:fundvanceai/shared/services/local_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exportingCsv = false;
  bool _clearingCache = false;
  bool _sendingReset = false;

  // ── Notification time picker ───────────────────────────────────────────────
  Future<void> _pickNotificationTime() async {
    final settings = context.read<SettingsProvider>();
    final picked = await showTimePicker(
      context: context,
      initialTime: settings.notificationTime,
    );
    if (picked != null) {
      await settings.setNotificationTime(picked);
    }
  }

  // ── CSV Export ─────────────────────────────────────────────────────────────
  Future<void> _exportCsv() async {
    final expenses = context.read<ExpenseProvider>().expenses;
    if (expenses.isEmpty) {
      _showSnack('No expense data to export.');
      return;
    }

    setState(() => _exportingCsv = true);
    try {
      final buf = StringBuffer();
      buf.writeln('Date,Merchant,Description,Category,Amount,Account,Notes');
      for (final e in expenses) {
        buf.writeln([
          DateFormat('yyyy-MM-dd').format(e.date),
          _csvEscape(e.merchant ?? ''),
          _csvEscape(e.description ?? ''),
          _csvEscape(e.categoryName ?? e.categoryId ?? ''),
          e.amount.toStringAsFixed(2),
          _csvEscape(e.accountName ?? e.accountId ?? ''),
          _csvEscape(e.notes ?? ''),
        ].join(','));
      }
      await Clipboard.setData(ClipboardData(text: buf.toString()));
      _showSnack('CSV data (${expenses.length} rows) copied to clipboard.');
    } catch (e) {
      _showSnack('Export failed: $e');
    } finally {
      setState(() => _exportingCsv = false);
    }
  }

  String _csvEscape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  // ── Clear cache ────────────────────────────────────────────────────────────
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local cache?'),
        content: const Text(
          'This removes all data stored on this device for offline access. '
          'Your data in the cloud is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _clearingCache = true);
    try {
      await LocalDatabase.instance.clearAllTables();
      _showSnack('Local cache cleared.');
    } catch (e) {
      _showSnack('Failed to clear cache: $e');
    } finally {
      setState(() => _clearingCache = false);
    }
  }

  // ── Change password ────────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final auth = context.read<AuthProvider>();
    final email = auth.currentUser?.email;
    if (email == null) {
      _showSnack('No account email found.');
      return;
    }

    setState(() => _sendingReset = true);
    try {
      final ok = await auth.resetPassword(email);
      if (!mounted) return;
      if (ok) {
        _showSnack('Password reset email sent to $email.');
      } else {
        _showSnack('Failed to send reset email. Try again.');
      }
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  // ── URL helpers ────────────────────────────────────────────────────────────
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open link.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Notifications ────────────────────────────────────────────────
          _SectionHeader(label: 'Notifications'),
          SwitchListTile(
            secondary: Icon(Icons.notifications_outlined,
                color: theme.colorScheme.primary),
            title: const Text('Budget alerts'),
            subtitle: const Text('Notify when a budget hits 80 % or over'),
            value: settings.budgetAlerts,
            onChanged: settings.setBudgetAlerts,
          ),
          const Divider(height: 1, indent: 72),
          SwitchListTile(
            secondary:
                Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
            title: const Text('Goal milestones'),
            subtitle: const Text('Notify when you reach a savings milestone'),
            value: settings.goalAlerts,
            onChanged: settings.setGoalAlerts,
          ),
          const Divider(height: 1, indent: 72),
          SwitchListTile(
            secondary: Icon(Icons.calendar_today_outlined,
                color: theme.colorScheme.primary),
            title: const Text('Weekly summary'),
            subtitle: const Text('Receive a weekly spending digest'),
            value: settings.weeklySummary,
            onChanged: settings.setWeeklySummary,
          ),
          const Divider(height: 1, indent: 72),
          SwitchListTile(
            secondary:
                Icon(Icons.repeat_outlined, color: theme.colorScheme.primary),
            title: const Text('Recurring reminders'),
            subtitle: const Text('Alert before a detected recurring charge'),
            value: settings.recurringReminders,
            onChanged: settings.setRecurringReminders,
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading:
                Icon(Icons.schedule_outlined, color: theme.colorScheme.primary),
            title: const Text('Preferred notification time'),
            subtitle: Text(settings.notificationTime.format(context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickNotificationTime,
          ),

          // ── Data & Backup ────────────────────────────────────────────────
          _SectionHeader(label: 'Data & Backup'),
          SwitchListTile(
            secondary:
                Icon(Icons.wifi_outlined, color: theme.colorScheme.primary),
            title: const Text('Auto-sync on Wi-Fi only'),
            subtitle: const Text('Reduce mobile data usage'),
            value: settings.autoSyncWifiOnly,
            onChanged: settings.setAutoSyncWifiOnly,
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: _exportingCsv
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.colorScheme.primary),
                  )
                : Icon(Icons.download_outlined,
                    color: theme.colorScheme.primary),
            title: const Text('Export data as CSV'),
            subtitle: const Text('Copies all expenses to clipboard as CSV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportingCsv ? null : _exportCsv,
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: _clearingCache
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.colorScheme.error),
                  )
                : Icon(Icons.delete_sweep_outlined,
                    color: theme.colorScheme.error),
            title: Text('Clear local cache',
                style: TextStyle(color: theme.colorScheme.error)),
            subtitle: const Text('Remove offline data from this device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearingCache ? null : _clearCache,
          ),

          // ── Security ─────────────────────────────────────────────────────
          _SectionHeader(label: 'Security'),
          SwitchListTile(
            secondary:
                Icon(Icons.fingerprint, color: theme.colorScheme.primary),
            title: const Text('Biometric lock'),
            subtitle: const Text('Require fingerprint / Face ID on open'),
            value: settings.biometricLock,
            onChanged: settings.setBiometricLock,
          ),
          const Divider(height: 1, indent: 72),
          SwitchListTile(
            secondary: Icon(Icons.visibility_off_outlined,
                color: theme.colorScheme.primary),
            title: const Text('Hide balances by default'),
            subtitle: const Text('Show blurred amounts until tapped'),
            value: settings.hideBalances,
            onChanged: settings.setHideBalances,
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: _sendingReset
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.colorScheme.primary),
                  )
                : Icon(Icons.lock_reset_outlined,
                    color: theme.colorScheme.primary),
            title: const Text('Change password'),
            subtitle: const Text('Send a password-reset email to your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _sendingReset ? null : _changePassword,
          ),

          // ── Appearance ───────────────────────────────────────────────────
          _SectionHeader(label: 'Appearance'),
          ListTile(
            leading:
                Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
            title: const Text('Themes'),
            subtitle: const Text('Choose from 6 free and premium themes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemeSelectionScreen()),
            ),
          ),
          const Divider(height: 1, indent: 72),
          SwitchListTile(
            secondary: Icon(Icons.view_compact_outlined,
                color: theme.colorScheme.primary),
            title: const Text('Compact transaction list'),
            subtitle: const Text('Show smaller rows in expense lists'),
            value: settings.compactList,
            onChanged: settings.setCompactList,
          ),

          // ── About ────────────────────────────────────────────────────────
          _SectionHeader(label: 'About'),
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: const Text('App version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined,
                color: theme.colorScheme.primary),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launch('https://fundvanceai.com/privacy'),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading:
                Icon(Icons.article_outlined, color: theme.colorScheme.primary),
            title: const Text('Terms of service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launch('https://fundvanceai.com/terms'),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: Icon(Icons.star_outline, color: theme.colorScheme.primary),
            title: const Text('Rate FundVance AI'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launch('https://fundvanceai.com/rate'),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
