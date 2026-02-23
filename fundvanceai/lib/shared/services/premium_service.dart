import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

class RevenueCatConfig {
  RevenueCatConfig._();

  // ⚠️  Replace with platform-specific production keys before App Store / Play
  // Store submission:
  //   iOS  → Dashboard › Project › API Keys › App-specific › appl_…
  //   Android → Dashboard › Project › API Keys › App-specific › goog_…
  static const String androidApiKey = 'test_TphBgpXyklOdIrTsqMDJshUJYpw';
  static const String iosApiKey = 'test_TphBgpXyklOdIrTsqMDJshUJYpw';

  /// The entitlement identifier created in RevenueCat dashboard.
  static const String entitlementId = 'FundVance Ai Pro';

  /// RevenueCat "Offerings" identifier — must match the identifier in the
  /// RevenueCat dashboard (Product catalog → Offerings).
  static const String offeringId = 'default';
}

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

class PurchaseResult {
  final bool success;
  final bool cancelled;
  final String? error;
  const PurchaseResult({
    required this.success,
    this.cancelled = false,
    this.error,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class PremiumService {
  PremiumService._();

  static bool _configured = false;

  // ── Init ───────────────────────────────────────────────────────────────────

  static Future<void> configure({String? userId}) async {
    if (kIsWeb || _configured) return;

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? RevenueCatConfig.iosApiKey
        : RevenueCatConfig.androidApiKey;

    final config = PurchasesConfiguration(apiKey);
    if (userId != null) config.appUserID = userId;

    await Purchases.configure(config);
    _configured = true;
  }

  // ── Identity ───────────────────────────────────────────────────────────────

  /// Call after login to tie purchases to the Supabase user ID.
  static Future<void> logIn(String userId) async {
    if (kIsWeb) return;
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  /// Call on sign-out so purchases aren't shared between users on same device.
  static Future<void> logOut() async {
    if (kIsWeb) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  // ── Entitlement check ──────────────────────────────────────────────────────

  static Future<bool> isPremium() async {
    if (kIsWeb) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active
          .containsKey(RevenueCatConfig.entitlementId);
    } catch (_) {
      return false;
    }
  }

  static bool isActivePremium(CustomerInfo info) =>
      info.entitlements.active.containsKey(RevenueCatConfig.entitlementId);

  /// True when the active entitlement is a free trial period.
  static bool isInTrial(CustomerInfo info) {
    final entitlement =
        info.entitlements.active[RevenueCatConfig.entitlementId];
    return entitlement?.periodType == PeriodType.trial;
  }

  /// Trial end date from the active entitlement, if currently in trial.
  static DateTime? trialEnd(CustomerInfo info) {
    final entitlement =
        info.entitlements.active[RevenueCatConfig.entitlementId];
    if (entitlement?.periodType != PeriodType.trial) return null;
    final expiryStr = entitlement?.expirationDate;
    return expiryStr != null ? DateTime.tryParse(expiryStr) : null;
  }

  // ── Offerings ──────────────────────────────────────────────────────────────

  static Future<Offerings?> getOfferings() async {
    if (kIsWeb) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // ── Purchase ───────────────────────────────────────────────────────────────

  static Future<PurchaseResult> purchase(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return const PurchaseResult(success: true);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult(success: false, cancelled: true);
      }
      return PurchaseResult(success: false, error: e.name);
    } catch (e) {
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  // ── Restore ────────────────────────────────────────────────────────────────

  static Future<PurchaseResult> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final active =
          info.entitlements.active.containsKey(RevenueCatConfig.entitlementId);
      if (active) return const PurchaseResult(success: true);
      return const PurchaseResult(
          success: false,
          error: 'No active subscription found for this account.');
    } catch (e) {
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  // ── Customer info listener ──────────────────────────────────────────────────

  /// Registers a callback invoked whenever CustomerInfo changes
  /// (e.g., subscription renewed or cancelled from outside the app).
  static void addCustomerInfoListener(void Function(CustomerInfo) onUpdate) {
    Purchases.addCustomerInfoUpdateListener(onUpdate);
  }

  static void removeCustomerInfoListener(void Function(CustomerInfo) onUpdate) {
    Purchases.removeCustomerInfoUpdateListener(onUpdate);
  }
}
