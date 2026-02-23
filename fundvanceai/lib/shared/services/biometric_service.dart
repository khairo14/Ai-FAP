import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps the [LocalAuthentication] plugin with a clean, testable API.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device has biometric hardware AND enrolled credentials.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user to authenticate with fingerprint / Face ID.
  /// Returns true on success, false on failure or cancellation.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock FundVance AI',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN/pattern fallback
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
