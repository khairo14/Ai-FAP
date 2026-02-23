import 'package:flutter/foundation.dart';
import '../../shared/models/transfer.dart';
import '../../shared/services/transfer_service.dart';
import '../../shared/services/connectivity_service.dart';

class TransferProvider extends ChangeNotifier {
  final TransferService _service = TransferService();

  List<Transfer> _transfers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Transfer> get transfers => _transfers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get _isOffline => !ConnectivityService.instance.isOnline;

  static bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('errno = 7') ||
        msg.contains('no address associated') ||
        msg.contains('authretryable') ||
        msg.contains('clientexception');
  }

  /// Load all transfers
  Future<void> loadTransfers({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_isOffline) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _transfers = await _service.getTransfers(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );
      _errorMessage = null;
    } catch (e) {
      if (!_isNetworkError(e)) {
        _errorMessage = 'Failed to load transfers: ${e.toString()}';
        _transfers = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new transfer
  Future<bool> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double fromAmount,
    required String fromCurrency,
    required double toAmount,
    required String toCurrency,
    String? categoryId,
    double? exchangeRate,
    double transferFee = 0.0,
    String? feeCurrency,
    String feeChargedTo = 'from',
    String? feeDescription,
    String? description,
    DateTime? transferDate,
    String? referenceNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transfer = await _service.createTransfer(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        fromAmount: fromAmount,
        fromCurrency: fromCurrency,
        toAmount: toAmount,
        toCurrency: toCurrency,
        categoryId: categoryId,
        exchangeRate: exchangeRate,
        transferFee: transferFee,
        feeCurrency: feeCurrency,
        feeChargedTo: feeChargedTo,
        feeDescription: feeDescription,
        description: description,
        transferDate: transferDate,
        referenceNumber: referenceNumber,
      );

      _transfers.insert(0, transfer);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to create transfer: $e');
      return false;
    }
  }

  /// Update a transfer
  Future<bool> updateTransfer({
    required String id,
    String? description,
    String? referenceNumber,
    double? transferFee,
    String? feeDescription,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTransfer = await _service.updateTransfer(
        id: id,
        description: description,
        referenceNumber: referenceNumber,
        transferFee: transferFee,
        feeDescription: feeDescription,
      );

      final index = _transfers.indexWhere((t) => t.id == id);
      if (index != -1) {
        _transfers[index] = updatedTransfer;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to update transfer: $e');
      return false;
    }
  }

  /// Delete a transfer
  Future<bool> deleteTransfer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteTransfer(id);
      _transfers.removeWhere((t) => t.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to delete transfer: $e');
      return false;
    }
  }

  /// Get exchange rate between two currencies
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    try {
      return await _service.getExchangeRate(fromCurrency, toCurrency);
    } catch (e) {
      debugPrint('Failed to get exchange rate: $e');
      return 1.0;
    }
  }
}
