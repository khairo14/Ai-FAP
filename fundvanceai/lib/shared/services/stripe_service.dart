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

/// Result of a Stripe subscription status check.
class StripeSubscriptionStatus {
  final bool isPremium;
  final bool isInTrial;
  final DateTime? trialEnd;
  final String? status; // mirrors Stripe status: active | trialing | canceled…

  const StripeSubscriptionStatus({
    required this.isPremium,
    this.isInTrial = false,
    this.trialEnd,
    this.status,
  });
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
    bool isAnnual = false,
  }) async {
    try {
      final successUrl = _buildRedirectUrl('/premium/success');
      final cancelUrl = _buildRedirectUrl('/premium/cancel');

      final response = await _supabase.functions.invoke(
        'create-checkout-session',
        body: {
          'priceId': priceId,
          'planType': isAnnual ? 'annual' : 'monthly',
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        },
      );

      if (response.status != 200) {
        final errorMsg = response.data?['error'] ?? 'Checkout creation failed';
        return StripeCheckoutResult(
            launched: false, error: errorMsg.toString());
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

  /// Reads subscription fields from `profiles` for the current user.
  ///
  /// Returns `true` when the user has an active or trialing subscription.
  static Future<bool> verifyPremiumStatus() async {
    final result = await getSubscriptionStatus();
    return result.isPremium;
  }

  /// Full subscription details — calls the `sync-subscription` Edge Function
  /// to pull live data from Stripe and update the profiles table, then returns
  /// the result. Throws on error so the caller can surface the message.
  static Future<StripeSubscriptionStatus> getSubscriptionStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const StripeSubscriptionStatus(isPremium: false);

    // ── Call sync-subscription edge function ─────────────────────────────
    // This queries Stripe directly and writes the result to profiles,
    // so the webhook not having fired is not a problem.
    final response = await _supabase.functions.invoke('sync-subscription');
    if (response.status == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final isPremium = (data['isPremium'] as bool?) ?? false;
      final status = data['status'] as String?;
      final expiresAtRaw = data['expiresAt'] as String?;
      final expiresAt =
          expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;
      final isInTrial = status == 'trialing';
      return StripeSubscriptionStatus(
        isPremium: isPremium,
        isInTrial: isInTrial,
        trialEnd: isInTrial ? expiresAt : null,
        status: status,
      );
    }

    // Non-200 response — surface the error message
    final errData = response.data;
    debugPrint(
        '[StripeService] sync-subscription non-200 (${response.status}): $errData');
    throw Exception('Sync failed (${response.status}): $errData');
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
