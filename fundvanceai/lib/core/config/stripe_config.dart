/// Stripe configuration constants.
///
/// After creating your products in the Stripe Dashboard, replace the
/// placeholder price IDs with the real `price_xxx` values.
///
/// Stripe Dashboard → Products → Create "FundVanceAI Pro" →
///   Add price: $4.99 / month  → copy ID → monthlyPriceId
///   Add price: $39.99 / year  → copy ID → annualPriceId
class StripeConfig {
  StripeConfig._();

  /// Stripe publishable key (safe to include in client code).
  static const String publishableKey =
      'pk_test_51T3J02LnsadeMCrOEiUPFWkPznueJvHzriunUOBUlooSKsDm2qc14UT6T7MxfdUE1xHVqN3SCZArTwYGPyJkuBhf00ag298QlU';

  /// Stripe Price ID for the \$4.99 / month plan.
  static const String monthlyPriceId = 'price_1T3J4MLnsadeMCrOzhQxEEfw';

  /// Stripe Price ID for the \$39.99 / year plan.
  static const String annualPriceId = 'price_1T3J4MLnsadeMCrODcfd0bnB';

  /// Human-readable pricing strings used in the Paywall UI.
  static const String monthlyPrice = '\$4.99 / month';
  static const String annualPrice = '\$39.99 / year';
  static const String annualSavings = 'Save 33%';

  /// 14-day free trial is enabled in the Edge Function's checkout session.
  static const int trialDays = 14;
}
