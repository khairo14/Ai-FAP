import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fundvanceai/shared/services/premium_service.dart';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  String? _error;
  void Function(CustomerInfo)? _listener;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  bool get isLoaded => _offerings != null;
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
      _offerings = await PremiumService.getOfferings();
      _customerInfo = await Purchases.getCustomerInfo();
      _isPremium = PremiumService.isActivePremium(_customerInfo!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Listen for purchases made outside the app (e.g., App Store manage subs)
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
