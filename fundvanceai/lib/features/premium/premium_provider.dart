import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fundvanceai/shared/services/premium_service.dart';
import 'package:fundvanceai/shared/services/rc_web_service.dart';

// ── SharedPreferences keys for subscription offline cache ─────────────────
const _kIsPremium = 'sub_is_premium';
const _kIsInTrial = 'sub_is_in_trial';
const _kTrialEnd = 'sub_trial_end'; // ISO-8601 string or empty

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
  RCWebOffering _webOffering = RCWebOffering.fallback;

  /// Set to true after a RC Web checkout tab is opened; cleared on confirmation.
  bool _pendingWebCheckout = false;

  /// Whether RC Web Billing (REST API) should be used instead of the native
  /// [purchases_flutter] SDK.
  /// Web and desktop use the RC REST API; iOS/Android use the native SDK.
  static bool get useRCWeb {
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
  bool get pendingWebCheckout => _pendingWebCheckout;

  /// Live pricing fetched from RC offerings (web/desktop).
  /// Falls back to [RCWebConfig] constants when not yet loaded.
  RCWebOffering get webOffering => _webOffering;

  /// True once the first [initialize] call has completed.
  bool get isLoaded => useRCWeb ? _initialized : _offerings != null;
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
      if (useRCWeb) {
        // ── Web / Desktop: RevenueCat REST API ────────────────────────────────
        // Load cached subscription state first so the UI is never blank while
        // the network call is in flight or when the device is offline.
        final prefs = await SharedPreferences.getInstance();
        _isPremium = prefs.getBool(_kIsPremium) ?? false;
        _isInTrial = prefs.getBool(_kIsInTrial) ?? false;
        final trialEndStr = prefs.getString(_kTrialEnd) ?? '';
        _trialEnd =
            trialEndStr.isNotEmpty ? DateTime.tryParse(trialEndStr) : null;

        try {
          // Fetch live status and pricing in parallel.
          final results = await Future.wait([
            RCWebService.getSubscriptionStatus(),
            RCWebService.getOfferings(),
          ]);
          final status = results[0] as RCWebSubscriptionStatus;
          final offering = results[1] as RCWebOffering;
          _isPremium = status.isPremium;
          _isInTrial = status.isInTrial;
          _trialEnd = status.trialEnd;
          _webOffering = offering;

          // Persist for next offline launch.
          await prefs.setBool(_kIsPremium, _isPremium);
          await prefs.setBool(_kIsInTrial, _isInTrial);
          await prefs.setString(_kTrialEnd, _trialEnd?.toIso8601String() ?? '');
        } catch (e) {
          // Offline or RC unreachable — cached values already applied above.
          debugPrint('[PremiumProvider] RC web offline, using cache: $e');
        }
      } else {
        // ── iOS / Android: RevenueCat native SDK ──────────────────────────────
        try {
          _offerings = await PremiumService.getOfferings();
          _customerInfo = await Purchases.getCustomerInfo();
          _isPremium = PremiumService.isActivePremium(_customerInfo!);
          _isInTrial = PremiumService.isInTrial(_customerInfo!);
          _trialEnd = PremiumService.trialEnd(_customerInfo!);
        } catch (e) {
          // RC native error (e.g. network, not configured yet)
          // Safe default: leave isPremium = false
          debugPrint('[PremiumProvider] RC native init error: $e');
          _error = e.toString();
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

  // ── Web checkout ──────────────────────────────────────────────

  /// Opens RC Web Billing checkout in the browser for [packageId].
  /// Returns an [RCWebCheckoutResult]; when [success] is true, the pending
  /// flag is set and the lifecycle observer will auto-verify on app resume.
  Future<RCWebCheckoutResult> startWebCheckout(
    String packageId, {
    bool isAnnual = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await RCWebService.startCheckout(
      packageId: packageId,
      isAnnual: isAnnual,
    );

    if (!result.success) {
      _error = result.error;
    } else {
      _pendingWebCheckout = true;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Re-checks subscription status after the user returns from RC checkout.
  /// Returns the full status so callers can surface detailed messages.
  Future<RCWebSubscriptionStatus> verifyWebPayment() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = await RCWebService.getSubscriptionStatus();
      _isPremium = status.isPremium;
      _isInTrial = status.isInTrial;
      _trialEnd = status.trialEnd;
      if (_isPremium) _pendingWebCheckout = false;

      // Update offline cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsPremium, _isPremium);
      await prefs.setBool(_kIsInTrial, _isInTrial);
      await prefs.setString(_kTrialEnd, _trialEnd?.toIso8601String() ?? '');

      _isLoading = false;
      notifyListeners();
      return status;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return const RCWebSubscriptionStatus(isPremium: false);
    }
  }

  /// Silently re-checks subscription without showing the global loading spinner.
  /// Called when the app resumes from background (returning from the checkout
  /// browser tab).
  Future<void> _silentWebVerify() async {
    if (!useRCWeb) return;
    try {
      final status = await RCWebService.getSubscriptionStatus();
      final changed =
          status.isPremium != _isPremium || status.isInTrial != _isInTrial;
      _isPremium = status.isPremium;
      _isInTrial = status.isInTrial;
      _trialEnd = status.trialEnd;
      if (_isPremium) _pendingWebCheckout = false;
      if (changed) notifyListeners();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-detect subscription when the user returns from the browser.
    if (state == AppLifecycleState.resumed) {
      _silentWebVerify();
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────────

  Future<PremiumPurchaseResult> purchase(Package package) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await PremiumService.purchase(package);

    if (result.success) {
      try {
        _customerInfo = await Purchases.getCustomerInfo();
        _isPremium = PremiumService.isActivePremium(_customerInfo!);
        _isInTrial = PremiumService.isInTrial(_customerInfo!);
        _trialEnd = PremiumService.trialEnd(_customerInfo!);
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
    if (useRCWeb) {
      // Web/desktop: re-check RC entitlement status
      final status = await verifyWebPayment();
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
      try {
        _customerInfo = await Purchases.getCustomerInfo();
        _isPremium = PremiumService.isActivePremium(_customerInfo!);
        _isInTrial = PremiumService.isInTrial(_customerInfo!);
        _trialEnd = PremiumService.trialEnd(_customerInfo!);
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
