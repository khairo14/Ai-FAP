import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';
import '../models/account_type.dart';

/// Service for managing user accounts (bank accounts, wallets, credit cards, etc.)
/// Implements CRUD operations with proper authentication and error handling
class AccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Safe auth getter with null check (following null value error fix pattern)
  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please login again.');
    }
    return user.id;
  }

  // Authentication status check
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Get all account types (for dropdown selection)
  Future<List<AccountType>> getAccountTypes() async {
    try {
      final response = await _supabase
          .from('account_types')
          .select()
          .eq('is_active', true)
          .order('category')
          .order('name');

      return (response as List)
          .map((json) => AccountType.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load account types: $e');
    }
  }

  /// Get all active accounts for current user
  Future<List<Account>> getAccounts({bool includeDeleted = false}) async {
    try {
      // Note: RLS policy already filters deleted_at IS NULL
      // For includeDeleted=true, would need separate query or policy adjustment
      final response = await _supabase
          .from('accounts')
          .select('''
            *,
            account_types(name, category)
          ''')
          .eq('user_id', _currentUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load accounts: $e');
    }
  }

  /// Get a single account by ID
  Future<Account?> getAccount(String accountId) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select('''
            *,
            account_types(name, category)
          ''')
          .eq('id', accountId)
          .eq('user_id', _currentUserId)
          .maybeSingle(); // Use maybeSingle for safer null handling

      if (response == null) return null;
      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load account: $e');
    }
  }

  /// Get accounts by type category
  Future<List<Account>> getAccountsByCategory(String category) async {
    try {
      // Note: RLS policy already filters deleted_at IS NULL
      final response = await _supabase
          .from('accounts')
          .select('''
            *,
            account_types!inner(category)
          ''')
          .eq('user_id', _currentUserId)
          .eq('account_types.category', category)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load accounts by category: $e');
    }
  }

  /// Create a new account
  Future<Account> createAccount({
    required String accountTypeId,
    required String name,
    String? description,
    required String currency,
    double initialBalance = 0,
    String? institutionName,
    String? accountNickname,
    double? creditLimit,
    bool includeInTotal = true,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final response = await _supabase.from('accounts').insert({
        'user_id': _currentUserId,
        'account_type_id': accountTypeId,
        'name': name,
        'description': description,
        'currency': currency,
        'initial_balance': initialBalance,
        'current_balance': initialBalance,
        'available_balance': initialBalance,
        'institution_name': institutionName,
        'account_nickname': accountNickname,
        'credit_limit': creditLimit,
        'credit_used': 0,
        'include_in_total': includeInTotal,
        'is_active': true,
        'is_hidden': false,
        'created_at': now,
        'updated_at': now,
      }).select('''
        *,
        account_types(name, category)
      ''').single();

      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  /// Update an existing account
  Future<Account> updateAccount({
    required String accountId,
    String? name,
    String? description,
    String? institutionName,
    String? accountNickname,
    double? creditLimit,
    bool? isActive,
    bool? includeInTotal,
    bool? isHidden,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (institutionName != null) updateData['institution_name'] = institutionName;
      if (accountNickname != null) updateData['account_nickname'] = accountNickname;
      if (creditLimit != null) updateData['credit_limit'] = creditLimit;
      if (isActive != null) updateData['is_active'] = isActive;
      if (includeInTotal != null) updateData['include_in_total'] = includeInTotal;
      if (isHidden != null) updateData['is_hidden'] = isHidden;

      final response = await _supabase
          .from('accounts')
          .update(updateData)
          .eq('id', accountId)
          .eq('user_id', _currentUserId)
          .select('''
            *,
            account_types(name, category)
          ''')
          .single();

      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update account: $e');
    }
  }

  /// Soft delete an account
  Future<void> deleteAccount(String accountId) async {
    try {
      await _supabase
          .from('accounts')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', accountId)
          .eq('user_id', _currentUserId);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Restore a soft-deleted account
  Future<Account> restoreAccount(String accountId) async {
    try {
      final response = await _supabase
          .from('accounts')
          .update({
            'deleted_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', accountId)
          .eq('user_id', _currentUserId)
          .select('''
            *,
            account_types(name, category)
          ''')
          .single();

      return Account.fromJson(response);
    } catch (e) {
      throw Exception('Failed to restore account: $e');
    }
  }

  /// Permanently delete an account (hard delete)
  Future<void> permanentDeleteAccount(String accountId) async {
    try {
      await _supabase
          .from('accounts')
          .delete()
          .eq('id', accountId)
          .eq('user_id', _currentUserId);
    } catch (e) {
      throw Exception('Failed to permanently delete account: $e');
    }
  }

  /// Get deleted accounts
  Future<List<Account>> getDeletedAccounts() async {
    try {
      final response = await _supabase
          .from('accounts')
          .select('''
            *,
            account_types(name, category)
          ''')
          .eq('user_id', _currentUserId)
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);

      return (response as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load deleted accounts: $e');
    }
  }

  /// Update account balance (called by expense/income operations)
  Future<Account> updateAccountBalance({
    required String accountId,
    required double amountChange,
    required String operation, // 'add' or 'subtract'
  }) async {
    try {
      // Use the database function for atomic balance updates
      await _supabase.rpc(
        'update_account_balance',
        params: {
          'account_id': accountId,
          'amount_change': amountChange,
          'operation': operation,
        },
      );

      // Fetch updated account
      final account = await getAccount(accountId);
      if (account == null) {
        throw Exception('Account not found after balance update');
      }
      return account;
    } catch (e) {
      throw Exception('Failed to update account balance: $e');
    }
  }

  /// Get total balance across all accounts (by currency)
  Future<Map<String, double>> getTotalBalances() async {
    try {
      final response = await _supabase.rpc(
        'get_user_total_balance',
        params: {'user_id': _currentUserId},
      );

      final Map<String, double> balances = {};
      for (final row in response as List) {
        balances[row['currency'] as String] = 
            (row['total_balance'] as num).toDouble();
      }
      return balances;
    } catch (e) {
      throw Exception('Failed to get total balances: $e');
    }
  }

  /// Get account summary (for dashboard)
  Future<List<Map<String, dynamic>>> getAccountsSummary() async {
    try {
      final response = await _supabase.rpc(
        'get_user_accounts_summary',
        params: {'user_id': _currentUserId},
      );

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get accounts summary: $e');
    }
  }

  /// Toggle account active status
  Future<Account> toggleAccountStatus(String accountId) async {
    try {
      final account = await getAccount(accountId);
      if (account == null) {
        throw Exception('Account not found');
      }

      return await updateAccount(
        accountId: accountId,
        isActive: !account.isActive,
      );
    } catch (e) {
      throw Exception('Failed to toggle account status: $e');
    }
  }

  /// Toggle include in total
  Future<Account> toggleIncludeInTotal(String accountId) async {
    try {
      final account = await getAccount(accountId);
      if (account == null) {
        throw Exception('Account not found');
      }

      return await updateAccount(
        accountId: accountId,
        includeInTotal: !account.includeInTotal,
      );
    } catch (e) {
      throw Exception('Failed to toggle include in total: $e');
    }
  }
}
