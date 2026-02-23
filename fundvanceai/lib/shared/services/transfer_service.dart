import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/transfer.dart';
import 'connectivity_service.dart';
import 'local_database.dart';

class TransferService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  bool get _isOnline => ConnectivityService.instance.isOnline;

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

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  /// Enriches transfer row maps with nested [transfer_category], [from_account]
  /// and [to_account] data from SQLite so display names resolve when offline.
  Future<List<Map<String, dynamic>>> _enrichTransfers(
      List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return rows;
    final catRows = await LocalDatabase.instance.getRows(
      table: 'transfer_categories_cache',
      userId: '_system_',
    );
    final accRows = await LocalDatabase.instance.getRows(
      table: 'accounts',
      userId: _currentUserId,
    );
    final catMap = {for (final c in catRows) c['id'] as String: c};
    final accMap = {for (final a in accRows) a['id'] as String: a};
    return rows.map((row) {
      final catId = row['category_id'] as String?;
      final fromId = row['from_account_id'] as String?;
      final toId = row['to_account_id'] as String?;
      return <String, dynamic>{
        ...row,
        if (catId != null && catMap.containsKey(catId))
          'transfer_category': {
            'name': catMap[catId]!['name'],
            'icon': catMap[catId]!['icon'],
            'color': catMap[catId]!['color'],
          },
        if (fromId != null && accMap.containsKey(fromId))
          'from_account': {'name': accMap[fromId]!['name']},
        if (toId != null && accMap.containsKey(toId))
          'to_account': {'name': accMap[toId]!['name']},
      };
    }).toList();
  }

  /// Create a new transfer between accounts
  Future<Transfer> createTransfer({
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
    final userId = _currentUserId;
    final now = DateTime.now();
    final data = <String, dynamic>{
      'id': _uuid.v4(),
      'user_id': userId,
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
      'transfer_date': (transferDate ?? now).toIso8601String().split('T')[0],
      'reference_number': referenceNumber,
      'status': 'completed',
      'category_id': categoryId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    if (_isOnline) {
      try {
        final response = await _supabase
            .from('transfers')
            .insert(data)
            .select(
                '*, from_account:accounts!transfers_from_account_id_fkey(name), to_account:accounts!transfers_to_account_id_fkey(name), transfer_category:transfer_categories(name, icon, color)')
            .single();

        final transfer = Transfer.fromJson(response);
        // Cache the created transfer (with join data)
        await LocalDatabase.instance.upsertRow(
          table: 'transfers',
          id: transfer.id,
          userId: userId,
          payload: Map<String, dynamic>.from(response),
        );
        return transfer;
      } catch (e) {
        if (!_isNetworkError(e)) {
          throw Exception('Failed to create transfer: $e');
        }
        // Fall through to offline path
      }
    }

    // Offline: store locally + enqueue for sync
    await LocalDatabase.instance.upsertRow(
      table: 'transfers',
      id: data['id'] as String,
      userId: userId,
      payload: data,
    );
    await LocalDatabase.instance.enqueuePendingOp(
      operation: 'INSERT',
      tableName: 'transfers',
      recordId: data['id'] as String,
      payload: data,
    );
    // Enrich with cached names so UI resolves account/category labels immediately
    final enriched = await _enrichTransfers([data]);
    return Transfer.fromJson(enriched.first);
  }

  /// Get all transfers for the current user
  Future<List<Transfer>> getTransfers({
    int limit = 50,
    int offset = 0,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _currentUserId;

    if (_isOnline) {
      try {
        var query = _supabase
            .from('transfers')
            .select(
                '*, from_account:accounts!transfers_from_account_id_fkey(name), to_account:accounts!transfers_to_account_id_fkey(name), transfer_category:transfer_categories(name, icon, color)')
            .eq('user_id', userId)
            .filter('deleted_at', 'is', null);

        if (accountId != null) {
          query = query
              .or('from_account_id.eq.$accountId,to_account_id.eq.$accountId');
        }

        if (startDate != null) {
          query = query.gte(
              'transfer_date', startDate.toIso8601String().split('T')[0]);
        }

        if (endDate != null) {
          query = query.lte(
              'transfer_date', endDate.toIso8601String().split('T')[0]);
        }

        final response = await query
            .order('transfer_date', ascending: false)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final transfers =
            (response as List).map((json) => Transfer.fromJson(json)).toList();

        // Cache the full list (no filters) for offline use
        if (accountId == null && startDate == null && endDate == null) {
          await LocalDatabase.instance.upsertRows(
            table: 'transfers',
            userId: userId,
            rows: (response as List).cast<Map<String, dynamic>>(),
            idGetter: (row) => row['id'] as String,
          );
        }

        return transfers;
      } catch (e) {
        if (!_isNetworkError(e)) {
          throw Exception('Failed to load transfers: $e');
        }
        // Fall through to cache
      }
    }

    // Offline or network error — serve from local cache
    final cached = await LocalDatabase.instance.getRows(
      table: 'transfers',
      userId: userId,
    );
    final enriched = await _enrichTransfers(cached);
    return enriched.map((json) => Transfer.fromJson(json)).toList();
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
      if (referenceNumber != null) {
        updateData['reference_number'] = referenceNumber;
      }
      if (transferFee != null) updateData['transfer_fee'] = transferFee;
      if (feeDescription != null) {
        updateData['fee_description'] = feeDescription;
      }

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
