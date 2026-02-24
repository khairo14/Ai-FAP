import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fundvanceai/shared/services/premium_service.dart';
import 'package:fundvanceai/shared/services/stripe_service.dart';

class PremiumProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isPremium = false;
  bool _isInTrial = false;
  DateTime? _trialEnd;
  bool _isLoading = false;
  bool _initialized = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  String? _error;
  void Function(CustomerInfo)? _listener;
  /// Set to true after a Stripe checkout tab is opened; cleared on confirmation.
  bool _pendingStripeVerification = false;

  /// Whether [StripeService] should be used instead of RevenueCat.
  /// Stripe handles web and all desktop platforms; RevenueCat handles iOS/Android.
  static bool get useStripe {
    if (kIsWeb) return true;
    const desktopPlatforms = {
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    };
    return desktopPlatforms.contains(defaultTargetPlatform);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isPremium => _isPremium;
  bool get isInTrial => _isInTrial;
  DateTime? get trialEnd => _trialEnd;
  bool get isLoading => _isLoading;
  bool get pendingStripeVerification => _pendingStripeVerification;

  /// True once the first [initialize] call has completed.
  bool get isLoaded => useStripe ? _initialized : _offerings != null;
  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;
  String? get error => _error;

  /// The currently active revenueCat offering packages (monthly + annual).
  List<Package> get availablePackages {
    final offering = _offerings?.current ??
        _offerings?.getOffering(RevenueCatConfig.offeringId);
    return offering?.availablePackages ?? [];
  }

  Package? get monthlyPackage => availablePackages
      .where((p) => p.packageType == PackageType.monthly)
      .firstOrNull;

  Package? get annualPackage => availablePackages
      .where((p) => p.packageType == PackageType.annual)
      .firstOrNull;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (useStripe) {
        // ── Web / Desktop: read from Supabase profile ─────────────────────────
        final status = await StripeService.getSubscriptionStatus();
        _isPremium = status.isPremium;
        _isInTrial = status.isInTrial;
        _trialEnd = status.trialEnd;
      } else {
        // ── iOS / Android: RevenueCat primary, Supabase fallback ──────────────
        if (kIsWeb) return; // guard: purchases_flutter unsupported on web
        _offerings = await PremiumService.getOfferings();
        _customerInfo = await Purchases.getCustomerInfo();
        _isPremium = PremiumService.isActivePremium(_customerInfo!);
        _isInTrial = PremiumService.isInTrial(_customerInfo!);
        _trialEnd = PremiumService.trialEnd(_customerInfo!);

        // Fallback: if RevenueCat shows no active entitlement, check the
        // Supabase profile — covers users who subscribed via Stripe on web.
        if (!_isPremium) {
          try {
            final status = await StripeService.getSubscriptionStatus();
            if (status.isPremium) {
              _isPremium = true;
              _isInTrial = status.isInTrial;
              _trialEnd = status.trialEnd;
            }
          } catch (_) {}
        }

        // Listen for purchases made outside the app (App Store / Play Store)
        if (_listener != null) {
          PremiumService.removeCustomerInfoListener(_listener!);
        }
        _listener = (CustomerInfo info) {
          _customerInfo = info;
          _isPremium = PremiumService.isActivePremium(info);
          _isInTrial = PremiumService.isInTrial(info);
          _trialEnd = PremiumService.trialEnd(info);
          notifyListeners();
        };
        PremiumService.addCustomerInfoListener(_listener!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  /// Opens Stripe Checkout in the browser for [priceId].
  /// Returns a [StripeCheckoutResult]; [pendingVerification] is `true` when
  /// the browser was launched and we must wait for the webhook to process.
  Future<StripeCheckoutResult> startStripeCheckout(String priceId,
      {bool isAnnual = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result =
        await StripeService.startCheckout(priceId: priceId, isAnnual: isAnnual);

    if (!result.success) {
      _error = result.error;
    } else {
      // Mark pending so the lifecycle observer auto-verifies on app resume.
      _pendingStripeVerification = true;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Re-checks subscription status after the user returns from Stripe.
  /// Returns the full status so callers can surface detailed error messages.
  Future<StripeSubscriptionStatus> verifyStripePayment() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await StripeService.getSubscriptionStatus();
      _isPremium = status.isPremium;
      _isInTrial = status.isInTrial;
      _trialEnd = status.trialEnd;
      if (_isPremium) _pendingStripeVerification = false;
      _isLoading = false;
      notifyListeners();
      return status;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return StripeSubscriptionStatus(isPremium: false, status: 'error:$e');
    }
  }

  /// Silently re-checks subscription without showing the global loading spinner.
  /// Called when the app resumes from background (e.g., returning from the
  /// Stripe Checkout browser tab).
  Future<void> _silentStripeVerify() async {
    if (!useStripe) return;
    try {
      final status = await StripeService.getSubscriptionStatus();
      final changed = status.isPremium != _isPremium ||
          status.isInTrial != _isInTrial;
      _isPremium = status.isPremium;
      _isInTrial = status.isInTrial;
      _trialEnd = status.trialEnd;
      if (_isPremium) _pendingStripeVerification = false;
      if (changed) notifyListeners();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-detect subscription when the user returns from the Stripe browser.
    if (state == AppLifecycleState.resumed) {
      _silentStripeVerify();
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────────

  Future<PremiumPurchaseResult> purchase(Package package) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await PremiumService.purchase(package);

    if (result.success) {
      _customerInfo = await Purchases.getCustomerInfo();
      _isPremium = PremiumService.isActivePremium(_customerInfo!);
      _isInTrial = PremiumService.isInTrial(_customerInfo!);
      _trialEnd = PremiumService.trialEnd(_customerInfo!);
      // Write to Supabase so the Stripe-based fallback also sees premium.
      try {
        await StripeService.markPremiumFromRevenueCat(
          expiresAt: _trialEnd,
        );
      } catch (_) {}
    } else if (!result.cancelled) {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  Future<PremiumPurchaseResult> restore() async {
    if (useStripe) {
      // Web/desktop has no RevenueCat — re-check Stripe instead
      final status = await verifyStripePayment();
      return PremiumPurchaseResult(
        success: status.isPremium,
        error: status.isPremium ? null : 'No active subscription found.',
      );
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await PremiumService.restore();

    if (result.success) {
      // Re-fetch latest CustomerInfo so entitlements are up to date
      try {
        _customerInfo = await Purchases.getCustomerInfo();
        _isPremium = PremiumService.isActivePremium(_customerInfo!);
        _isInTrial = PremiumService.isInTrial(_customerInfo!);
        _trialEnd = PremiumService.trialEnd(_customerInfo!);
        // Write to Supabase so the Stripe-based fallback also sees premium.
        if (_isPremium) {
          await StripeService.markPremiumFromRevenueCat(
            expiresAt: _trialEnd,
          );
        }
      } catch (_) {}
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_listener != null) {
      PremiumService.removeCustomerInfoListener(_listener!);
    }
    super.dispose();
  }
}
