import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of a Stripe checkout initiation.
class StripeCheckoutResult {
  final bool launched;
  final bool pendingVerification;
  final String? error;

  const StripeCheckoutResult({
    required this.launched,
    this.pendingVerification = false,
    this.error,
  });

  bool get success => launched && error == null;
}

/// Handles Stripe-powered premium subscriptions for web and desktop platforms.
///
/// Flow:
///   1. [startCheckout] calls the `create-checkout-session` Supabase Edge
///      Function, which creates (or reuses) a Stripe Customer and returns a
///      hosted Checkout URL.
///   2. [url_launcher] opens the URL in the system browser.
///   3. After the user completes payment, the `stripe-webhook` Edge Function
///      updates `profiles.is_premium = true`.
///   4. [verifyPremiumStatus] re-reads the profile to confirm the upgrade.
class StripeService {
  StripeService._();

  static SupabaseClient get _supabase => Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Starts a Stripe Checkout session for [priceId] and launches the browser.
  ///
  /// [priceId] must be a valid Stripe Price ID (`price_xxx`).
  static Future<StripeCheckoutResult> startCheckout({
    required String priceId,
  }) async {
    try {
      final successUrl = _buildRedirectUrl('/premium/success');
      final cancelUrl = _buildRedirectUrl('/premium/cancel');

      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'priceId': priceId,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        },
      );

      if (response.status != 200) {
        final errorMsg = response.data?['error'] ?? 'Checkout creation failed';
        return StripeCheckoutResult(launched: false, error: errorMsg.toString());
      }

      final checkoutUrl = response.data?['url'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        return const StripeCheckoutResult(
            launched: false, error: 'No checkout URL returned');
      }

      final uri = Uri.parse(checkoutUrl);
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        return const StripeCheckoutResult(
            launched: false, error: 'Cannot open browser');
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      return const StripeCheckoutResult(
          launched: true, pendingVerification: true);
    } catch (e) {
      return StripeCheckoutResult(launched: false, error: e.toString());
    }
  }

  /// Reads `profiles.is_premium` for the currently signed-in user.
  ///
  /// Returns `false` if the user is not signed in or if any error occurs.
  static Future<bool> verifyPremiumStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await _supabase
          .from('profiles')
          .select('is_premium')
          .eq('id', userId)
          .single();

      return (data['is_premium'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds a redirect URL that works on both web and desktop deep-link.
  static String _buildRedirectUrl(String path) {
    if (kIsWeb) {
      // Use the current browser origin so Stripe can redirect back.
      final origin = Uri.base.origin;
      return '$origin$path';
    }
    // Deep-link for desktop native (registered in app config).
    return 'fundvanceai:/$path';
  }
}
