import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transfer.dart';

class TransferService {
  final _supabase = Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  /// Create a new transfer between accounts
  Future<Transfer> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double fromAmount,
    required String fromCurrency,
    required double toAmount,
    required String toCurrency,
    double? exchangeRate,
    double transferFee = 0.0,
    String? feeCurrency,
    String feeChargedTo = 'from',
    String? feeDescription,
    String? description,
    DateTime? transferDate,
    String? referenceNumber,
  }) async {
    try {
      final response = await _supabase
          .from('transfers')
          .insert({
            'user_id': _currentUserId,
            'from_account_id': fromAccountId,
            'to_account_id': toAccountId,
            'from_amount': fromAmount,
            'from_currency': fromCurrency,
            'to_amount': toAmount,
            'to_currency': toCurrency,
            'exchange_rate': exchangeRate,
            'is_manual_rate': exchangeRate != null,
            'transfer_fee': transferFee,
            'fee_currency': feeCurrency ?? fromCurrency,
            'fee_charged_to': feeChargedTo,
            'fee_description': feeDescription,
            'description': description,
            'transfer_date': (transferDate ?? DateTime.now())
                .toIso8601String()
                .split('T')[0],
            'reference_number': referenceNumber,
            'status': 'completed',
          })
          .select()
          .single();

      return Transfer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create transfer: $e');
    }
  }

  /// Get all transfers for the current user
  Future<List<Transfer>> getTransfers({
    int limit = 50,
    int offset = 0,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('transfers')
          .select()
          .eq('user_id', _currentUserId);

      // Filter by account (either from or to)
      if (accountId != null) {
        query = query.or('from_account_id.eq.$accountId,to_account_id.eq.$accountId');
      }

      if (startDate != null) {
        query = query.gte('transfer_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('transfer_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('transfer_date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Transfer.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load transfers: $e');
    }
  }

  /// Get a single transfer by ID
  Future<Transfer?> getTransfer(String id) async {
    try {
      final response = await _supabase
          .from('transfers')
          .select()
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .maybeSingle();

      if (response == null) return null;
      return Transfer.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update transfer
  Future<Transfer> updateTransfer({
    required String id,
    String? description,
    String? referenceNumber,
    double? transferFee,
    String? feeDescription,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (description != null) updateData['description'] = description;
      if (referenceNumber != null) updateData['reference_number'] = referenceNumber;
      if (transferFee != null) updateData['transfer_fee'] = transferFee;
      if (feeDescription != null) updateData['fee_description'] = feeDescription;

      final response = await _supabase
          .from('transfers')
          .update(updateData)
          .eq('id', id)
          .eq('user_id', _currentUserId)
          .select()
          .single();

      return Transfer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update transfer: $e');
    }
  }

  /// Delete transfer
  Future<void> deleteTransfer(String id) async {
    try {
      await _supabase
          .from('transfers')
          .delete()
          .eq('id', id)
          .eq('user_id', _currentUserId);
    } catch (e) {
      throw Exception('Failed to delete transfer: $e');
    }
  }

  /// Calculate exchange rate between currencies (mock implementation)
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    // TODO: Integrate with real exchange rate API
    // For now, return 1.0 if same currency, or placeholder rate
    if (fromCurrency == toCurrency) return 1.0;
    
    // Placeholder rates - replace with real API
    final rates = {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 149.50,
      'PHP': 56.50,
      'CNY': 7.24,
      'INR': 83.12,
    };

    final fromRate = rates[fromCurrency] ?? 1.0;
    final toRate = rates[toCurrency] ?? 1.0;
    
    return toRate / fromRate;
  }
}
