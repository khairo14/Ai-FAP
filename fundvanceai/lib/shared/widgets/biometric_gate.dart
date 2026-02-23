import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/settings/settings_provider.dart';
import 'package:fundvanceai/shared/services/biometric_service.dart';

/// Wraps the app's home. When [SettingsProvider.biometricLock] is enabled,
/// this widget shows a lock screen on startup and whenever the app resumes
/// from background. The user must authenticate to see the content.
class BiometricGate extends StatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLock();
    } else if (state == AppLifecycleState.paused) {
      final settings = context.read<SettingsProvider>();
      if (settings.biometricLock) {
        setState(() => _locked = true);
      }
    }
  }

  Future<void> _checkLock() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    if (!settings.biometricLock) {
      if (_locked) setState(() => _locked = false);
      return;
    }

    final available = await BiometricService.instance.isAvailable();
    if (!available) return; // biometrics not enroled — skip lock

    setState(() => _locked = true);
    await _authenticate();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final ok = await BiometricService.instance.authenticate();
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) _locked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;

    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'FundVance AI',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verify your identity to continue',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            if (_authenticating)
              const CircularProgressIndicator()
            else
              FilledButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Authenticate'),
              ),
          ],
        ),
      ),
    );
  }
}
