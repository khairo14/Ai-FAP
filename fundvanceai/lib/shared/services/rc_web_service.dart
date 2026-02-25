import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

class RCWebConfig {
  RCWebConfig._();

  // ── Web Purchase Link base URLs ─────────────────────────────────────────
  // Obtained from RC Dashboard → Web → [your purchase link] → Share URL.
  // Format: https://pay.rev.cat/{token}
  // The App User ID and optional package_id are appended at runtime.
  static const String _productionWplBase =
      'https://pay.rev.cat/ubysptgzeihpughw';
  static const String _sandboxWplBase =
      'https://pay.rev.cat/sandbox/tbkbfsqesszkjnxy';

  /// Returns the correct base URL for the current build mode.
  static String get wplBase =>
      kDebugMode ? _sandboxWplBase : _productionWplBase;

  // ── RC v1 REST API public key (used only for subscriber status checks) ──
  // These are public keys — safe to include in client code.
  static const String _productionKey = 'rcb_EImHdPbIwZIURqbZcebpaOGDfGfY';
  static const String _sandboxKey = 'rcb_sb_uVEiVxSxehqABuNAFOiTwqloM';

  /// Returns the sandbox key in debug mode, production key in release mode.
  static String get apiKey => kDebugMode ? _sandboxKey : _productionKey;

  /// Must match the entitlement identifier in RC Dashboard exactly.
  static const String entitlementId = 'FundVance Ai Pro';

  /// RC package identifiers — must match the package lookup_keys in RC Dashboard.
  /// Used as the `package_id` URL parameter to pre-select a plan.
  /// RC default identifiers use the $rc_ prefix (raw string to avoid Dart interpolation).
  static const String monthlyPackageId = r'$rc_monthly';
  static const String annualPackageId = r'$rc_annual';

  // ── Fallback pricing (shown while offerings are loading or on API error) ─
  // These are ONLY used as a loading fallback. Live prices come from RC via
  // [RCWebService.getOfferings] and are stored in [RCWebOffering].
  static const String monthlyPrice = r'$4.99/month';
  static const String annualPrice = r'$39.99/year';
  static const String annualPerMonth = r'$3.33/mo';
  static const String annualSavings = 'Save 33%';
  static const int trialDays = 14;
}

// ─────────────────────────────────────────────────────────────────────────────
// Live offering / pricing returned by [RCWebService.getOfferings]
// ─────────────────────────────────────────────────────────────────────────────

/// Pricing data fetched live from RC's offerings endpoint.
/// Both web and mobile share this as the single source of truth for displayed
/// prices — no hardcoded price strings needed in the UI.
class RCWebOffering {
  /// e.g. "\$4.99/month"
  final String monthlyPrice;

  /// e.g. "\$39.99/year"
  final String annualPrice;

  /// e.g. "\$3.33/mo"  (annual amount ÷ 12)
  final String annualPerMonth;

  /// e.g. "Save 33%"
  final String annualSavings;

  /// 14
  final int trialDays;

  const RCWebOffering({
    required this.monthlyPrice,
    required this.annualPrice,
    required this.annualPerMonth,
    required this.annualSavings,
    required this.trialDays,
  });

  /// Fallback populated from [RCWebConfig] constants.
  static const RCWebOffering fallback = RCWebOffering(
    monthlyPrice: RCWebConfig.monthlyPrice,
    annualPrice: RCWebConfig.annualPrice,
    annualPerMonth: RCWebConfig.annualPerMonth,
    annualSavings: RCWebConfig.annualSavings,
    trialDays: RCWebConfig.trialDays,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

class RCWebSubscriptionStatus {
  final bool isPremium;
  final bool isInTrial;
  final DateTime? trialEnd;
  final DateTime? expiresDate;

  const RCWebSubscriptionStatus({
    required this.isPremium,
    this.isInTrial = false,
    this.trialEnd,
    this.expiresDate,
  });
}

class RCWebCheckoutResult {
  final bool launched;
  final String? error;

  const RCWebCheckoutResult({required this.launched, this.error});

  bool get success => launched && error == null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Handles RevenueCat Web Billing subscription state and checkout for
/// web and desktop platforms via RC's REST API.
///
/// On iOS/Android the [purchases_flutter] SDK is used instead (see
/// [PremiumService]). This class is only called when
/// [PremiumProvider.useRCWeb] is true.
class RCWebService {
  RCWebService._();

  static const _apiBase = 'https://api.revenuecat.com';

  static Dio get _dio => Dio(
        BaseOptions(
          baseUrl: _apiBase,
          headers: {
            'Authorization': 'Bearer ${RCWebConfig.apiKey}',
            'Content-Type': 'application/json',
            'X-Platform': 'web',
            'X-RevenueCat-Version': '1',
          },
        ),
      );

  static String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  // ── Offerings / live pricing ──────────────────────────────────────────────

  /// Fetches the current RC offering for this user and extracts live pricing
  /// from the `rc_billing_product` attached to each package.
  ///
  /// Returns [RCWebOffering.fallback] on any error so the UI always has
  /// something to display.
  static Future<RCWebOffering> getOfferings() async {
    try {
      final uid = _userId;
      if (uid.isEmpty) return RCWebOffering.fallback;

      final response = await _dio.get(
        '/v1/subscribers/$uid/offerings',
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return RCWebOffering.fallback;

      // Find the default offering
      final offeringsRaw = data['offerings'] as List<dynamic>?;
      if (offeringsRaw == null || offeringsRaw.isEmpty) {
        return RCWebOffering.fallback;
      }
      final currentId = data['current_offering_id'] as String? ?? 'default';
      final offeringMap =
          offeringsRaw.whereType<Map<String, dynamic>>().firstWhere(
                (o) => o['identifier'] == currentId,
                orElse: () => offeringsRaw.first as Map<String, dynamic>,
              );

      final packages = offeringMap['packages'] as List<dynamic>? ?? [];

      double? monthlyAmountUsd;
      double? annualAmountUsd;
      String? monthlyCurrency;
      String? annualCurrency;
      int monthlyTrialDays = RCWebConfig.trialDays;
      int annualTrialDays = RCWebConfig.trialDays;

      for (final pkg in packages.whereType<Map<String, dynamic>>()) {
        final id = pkg['identifier'] as String? ?? '';
        final product = pkg['rc_billing_product'] as Map<String, dynamic>?;
        if (product == null) continue;

        final priceMap = product['current_price'] as Map<String, dynamic>?;
        // RC returns price in cents (integer) or unit amount
        final amountRaw = priceMap?['amount'];
        final double? amount = amountRaw != null
            ? (amountRaw is int
                ? amountRaw / 100.0
                : (amountRaw as num).toDouble())
            : null;
        final currency =
            (priceMap?['currency'] as String?)?.toUpperCase() ?? 'USD';

        final trialStr = product['trial_period_duration'] as String?;
        final parsedTrial = _parseDaysDuration(trialStr);

        if (id == RCWebConfig.monthlyPackageId && amount != null) {
          monthlyAmountUsd = amount;
          monthlyCurrency = currency;
          if (parsedTrial != null) monthlyTrialDays = parsedTrial;
        } else if (id == RCWebConfig.annualPackageId && amount != null) {
          annualAmountUsd = amount;
          annualCurrency = currency;
          if (parsedTrial != null) annualTrialDays = parsedTrial;
        }
      }

      if (monthlyAmountUsd == null || annualAmountUsd == null) {
        return RCWebOffering.fallback;
      }

      final sym = _currencySymbol(monthlyCurrency ?? 'USD');
      final aSym = _currencySymbol(annualCurrency ?? 'USD');

      final annualPerMonthVal = annualAmountUsd / 12;
      final savingsPct =
          ((1 - (annualPerMonthVal / monthlyAmountUsd)) * 100).round();

      return RCWebOffering(
        monthlyPrice: '$sym${monthlyAmountUsd.toStringAsFixed(2)}/month',
        annualPrice: '$aSym${annualAmountUsd.toStringAsFixed(2)}/year',
        annualPerMonth: '$sym${annualPerMonthVal.toStringAsFixed(2)}/mo',
        annualSavings: 'Save $savingsPct%',
        trialDays: (monthlyTrialDays > 0 ? monthlyTrialDays : annualTrialDays),
      );
    } catch (e) {
      debugPrint('[RCWebService] getOfferings error: $e');
      return RCWebOffering.fallback;
    }
  }

  /// Parses an ISO-8601 duration string like `P14D` → `14`.
  static int? _parseDaysDuration(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final match = RegExp(r'P(\d+)D').firstMatch(iso);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// Returns the currency symbol for common ISO 4217 codes.
  static String _currencySymbol(String code) {
    const map = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CAD': r'CA$',
      'AUD': r'A$',
      'SGD': r'S$',
      'MYR': 'RM',
      'PHP': '₱',
      'IDR': 'Rp',
      'THB': '฿',
      'VND': '₫',
    };
    return map[code.toUpperCase()] ?? '$code ';
  }

  // ── Subscription status ────────────────────────────────────────────────────

  /// Fetches the active subscription status for the current user directly
  /// from RevenueCat's REST API.
  ///
  /// Returns [isPremium: false] when the user is not authenticated or has no
  /// active entitlement.  Throws on network/server error so callers can
  /// surface the message.
  static Future<RCWebSubscriptionStatus> getSubscriptionStatus() async {
    if (_userId.isEmpty) {
      return const RCWebSubscriptionStatus(isPremium: false);
    }

    try {
      final response = await _dio.get('/v1/subscribers/$_userId');
      return _parseSubscriberResponse(response.data);
    } on DioException catch (e) {
      // 404 means this user has never been seen by RC — treat as free user.
      if (e.response?.statusCode == 404) {
        return const RCWebSubscriptionStatus(isPremium: false);
      }
      debugPrint('[RCWebService] getSubscriptionStatus error: ${e.message}');
      rethrow;
    }
  }

  /// Parses the `GET /v1/subscribers/{id}` response into a status object.
  static RCWebSubscriptionStatus _parseSubscriberResponse(dynamic data) {
    final subscriber =
        (data as Map<String, dynamic>?)?['subscriber'] as Map<String, dynamic>?;
    final entitlements = subscriber?['entitlements'] as Map<String, dynamic>?;
    final entitlement =
        entitlements?[RCWebConfig.entitlementId] as Map<String, dynamic>?;

    if (entitlement == null) {
      return const RCWebSubscriptionStatus(isPremium: false);
    }

    final expiresDateStr = entitlement['expires_date'] as String?;
    final expiresDate =
        expiresDateStr != null ? DateTime.tryParse(expiresDateStr) : null;

    // null expiresDate means a lifetime entitlement (always active)
    final isActive =
        expiresDate == null || expiresDate.isAfter(DateTime.now().toUtc());

    if (!isActive) {
      return const RCWebSubscriptionStatus(isPremium: false);
    }

    final periodType = entitlement['period_type'] as String?;
    final isInTrial = periodType == 'trial';

    return RCWebSubscriptionStatus(
      isPremium: true,
      isInTrial: isInTrial,
      trialEnd: isInTrial ? expiresDate : null,
      expiresDate: expiresDate,
    );
  }

  // ── Checkout via Web Purchase Link ────────────────────────────────────────

  /// Opens the RevenueCat-hosted Web Purchase Link for [packageId] in the
  /// system browser.
  ///
  /// The link format is:
  ///   `https://pay.rev.cat/{token}/{urlEncodedUserId}?package_id={packageId}`
  ///
  /// The `package_id` pre-selects the plan so the user lands directly on the
  /// checkout page instead of the plan-selection page.
  ///
  /// Returns [RCWebCheckoutResult.launched] = true on success, or an error
  /// string on failure.
  static Future<RCWebCheckoutResult> startCheckout({
    required String packageId,
    required bool isAnnual,
  }) async {
    if (_userId.isEmpty) {
      return const RCWebCheckoutResult(
          launched: false, error: 'User not authenticated');
    }

    try {
      final encodedUserId = Uri.encodeComponent(_userId);
      final uri = Uri.parse(
        '${RCWebConfig.wplBase}/$encodedUserId?package_id=${Uri.encodeComponent(packageId)}',
      );

      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        return const RCWebCheckoutResult(
            launched: false, error: 'Cannot open browser');
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return const RCWebCheckoutResult(launched: true);
    } catch (e) {
      debugPrint('[RCWebService] startCheckout error: $e');
      return RCWebCheckoutResult(launched: false, error: e.toString());
    }
  }
}
