import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fundvanceai/shared/services/premium_service.dart';
import 'package:fundvanceai/shared/services/stripe_service.dart';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = false;
  bool _initialized = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  String? _error;
  void Function(CustomerInfo)? _listener;

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
  bool get isLoading => _isLoading;
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (useStripe) {
        // ── Web / Desktop: read is_premium from Supabase profile ─────────────
        _isPremium = await StripeService.verifyPremiumStatus();
      } else {
        // ── iOS / Android: RevenueCat ─────────────────────────────────────────
        if (kIsWeb) return; // guard: purchases_flutter unsupported on web
        _offerings = await PremiumService.getOfferings();
        _customerInfo = await Purchases.getCustomerInfo();
        _isPremium = PremiumService.isActivePremium(_customerInfo!);

        // Listen for purchases made outside the app (App Store / Play Store)
        if (_listener != null) {
          PremiumService.removeCustomerInfoListener(_listener!);
        }
        _listener = (CustomerInfo info) {
          _customerInfo = info;
          _isPremium = PremiumService.isActivePremium(info);
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
  Future<StripeCheckoutResult> startStripeCheckout(String priceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await StripeService.startCheckout(priceId: priceId);

    if (!result.success) {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Re-checks `profiles.is_premium` after the user returns from Stripe.
  Future<bool> verifyStripePayment() async {
    _isLoading = true;
    notifyListeners();

    _isPremium = await StripeService.verifyPremiumStatus();

    _isLoading = false;
    notifyListeners();
    return _isPremium;
  }

  // ── Purchase ──────────────────────────────────────────────────────────────

  Future<PurchaseResult> purchase(Package package) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await PremiumService.purchase(package);

    if (result.success) {
      _customerInfo = await Purchases.getCustomerInfo();
      _isPremium = PremiumService.isActivePremium(_customerInfo!);
    } else if (!result.cancelled) {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  Future<PurchaseResult> restore() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await PremiumService.restore();

    if (result.success) {
      _customerInfo = await Purchases.getCustomerInfo();
      _isPremium = PremiumService.isActivePremium(_customerInfo!);
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
    if (_listener != null) {
      PremiumService.removeCustomerInfoListener(_listener!);
    }
    super.dispose();
  }
}
