import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fundvanceai/shared/services/premium_service.dart';
import 'package:fundvanceai/shared/services/stripe_service.dart';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _isInTrial = false;
  DateTime? _trialEnd;
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
  bool get isInTrial => _isInTrial;
  DateTime? get trialEnd => _trialEnd;
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
        // ── Web / Desktop: read from Supabase profile ─────────────────────────
        final status = await StripeService.getSubscriptionStatus();
        _isPremium = status.isPremium;
        _isInTrial = status.isInTrial;
        _trialEnd = status.trialEnd;
      } else {
        // ── iOS / Android: RevenueCat ─────────────────────────────────────────
        if (kIsWeb) return; // guard: purchases_flutter unsupported on web
        _offerings = await PremiumService.getOfferings();
        _customerInfo = await Purchases.getCustomerInfo();
        _isPremium = PremiumService.isActivePremium(_customerInfo!);
        _isInTrial = PremiumService.isInTrial(_customerInfo!);
        _trialEnd = PremiumService.trialEnd(_customerInfo!);

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
