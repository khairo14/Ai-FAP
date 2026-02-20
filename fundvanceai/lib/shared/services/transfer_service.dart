import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
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
          .select('*, from_account:accounts!transfers_from_account_id_fkey(name), to_account:accounts!transfers_to_account_id_fkey(name)')
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
          .select('*, from_account:accounts!transfers_from_account_id_fkey(name), to_account:accounts!transfers_to_account_id_fkey(name)')
          .eq('user_id', _currentUserId)
          .filter('deleted_at', 'is', null);

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

  // Cache: base currency → {rates map, fetchedAt}
  static final Map<String, Map<String, dynamic>> _rateCache = {};
  static const _cacheDuration = Duration(hours: 1);

  /// Fetch live exchange rate from open.er-api.com (no API key required).
  /// Results are cached for 1 hour to stay within the free-tier limit.
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;

    // Check cache
    final cached = _rateCache[fromCurrency];
    if (cached != null) {
      final fetchedAt = cached['fetchedAt'] as DateTime;
      if (DateTime.now().difference(fetchedAt) < _cacheDuration) {
        final rates = cached['rates'] as Map<String, dynamic>;
        return (rates[toCurrency] as num?)?.toDouble() ?? 1.0;
      }
    }

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://open.er-api.com/v6/latest/$fromCurrency',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode == 200 && response.data['result'] == 'success') {
        final rates = Map<String, dynamic>.from(response.data['rates'] as Map);
        _rateCache[fromCurrency] = {
          'rates': rates,
          'fetchedAt': DateTime.now(),
        };
        return (rates[toCurrency] as num?)?.toDouble() ?? 1.0;
      }
    } catch (_) {
      // Network error – fall back silently
    }

    // Fallback: 1.0 so UI doesn't crash
    return 1.0;
  }
}
