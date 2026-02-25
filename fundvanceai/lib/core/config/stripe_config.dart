// DEPRECATED — Stripe pricing config has been replaced by RCWebConfig in
// rc_web_service.dart. This file is kept for reference only and is no longer
// imported by any app code. Safe to delete after migration is verified.

/// Stripe configuration constants (no longer active — see RCWebConfig).
///
class StripeConfig {
  StripeConfig._();

  /// Stripe publishable key (safe to include in client code).
  static const String publishableKey =
      'pk_test_51T3J02LnsadeMCrOEiUPFWkPznueJvHzriunUOBUlooSKsDm2qc14UT6T7MxfdUE1xHVqN3SCZArTwYGPyJkuBhf00ag298QlU';

  /// Stripe Price ID for the \$4.99 / month plan.
  static const String monthlyPriceId = 'price_1T3J4MLnsadeMCrODcfd0bnB';

  /// Stripe Price ID for the \$39.99 / year plan.
  static const String annualPriceId = 'price_1T3J4MLnsadeMCrOzhQxEEfw';

  /// Human-readable pricing strings used in the Paywall UI.
  static const String monthlyPrice = '\$4.99 / month';
  static const String annualPrice = '\$39.99 / year';
  static const String annualSavings = 'Save 33%';

  /// 14-day free trial is enabled in the Edge Function's checkout session.
  static const int trialDays = 14;
}
