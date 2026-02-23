import 'package:flutter/foundation.dart';
import '../../shared/models/account.dart';
import '../../shared/models/account_type.dart';
import '../../shared/services/account_service.dart';

/// Provider for managing account state with proper error handling
/// Follows the same patterns from null value error fixes
class AccountProvider with ChangeNotifier {
  final AccountService _service = AccountService();

  List<Account> _accounts = [];
  List<AccountType> _accountTypes = [];
  List<Account> _deletedAccounts = [];
  Map<String, double> _totalBalances = {};
  Account? _selectedAccount;
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Account> get accounts => _accounts;
  List<AccountType> get accountTypes => _accountTypes;
  List<Account> get deletedAccounts => _deletedAccounts;
  Map<String, double> get totalBalances => _totalBalances;
  Account? get selectedAccount => _selectedAccount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Get active accounts only
  List<Account> get activeAccounts => 
      _accounts.where((a) => a.isActive && !a.isDeleted).toList();

  /// Get accounts that should be included in total calculations
  List<Account> get accountsInTotal => 
      _accounts.where((a) => a.includeInTotal && a.isActive && !a.isDeleted).toList();

  /// Get accounts by type category
  List<Account> getAccountsByCategory(String category) {
    // Would need to join with account types - for now filter in memory after loading
    return _accounts.where((a) => !a.isDeleted).toList();
  }

  /// Initialize provider - load accounts and types
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Pre-authentication check (following null value error fix pattern)
      if (!_service.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      await Future.wait([
        loadAccounts(),
        loadAccountTypes(),
        loadTotalBalances(),
      ]);
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _accounts = [];
      _accountTypes = [];
      debugPrint('AccountProvider error: $e');
    } catch (e) {
      _errorMessage = 'Failed to initialize: Unexpected error occurred';
      _accounts = [];
      _accountTypes = [];
      debugPrint('Unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all accounts
  Future<void> loadAccounts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _accounts = await _service.getAccounts();
      _errorMessage = null;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _accounts = [];
      debugPrint('Failed to load accounts: $e');
    } catch (e) {
      _errorMessage = 'Failed to load accounts: Unexpected error';
      _accounts = [];
      debugPrint('Unexpected error loading accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load account types
  Future<void> loadAccountTypes() async {
    try {
      _accountTypes = await _service.getAccountTypes();
    } on Exception catch (e) {
      debugPrint('Failed to load account types: $e');
      _accountTypes = [];
    } catch (e) {
      debugPrint('Unexpected error loading account types: $e');
      _accountTypes = [];
    }
  }

  /// Load total balances
  Future<void> loadTotalBalances() async {
    try {
      _totalBalances = await _service.getTotalBalances();
    } on Exception catch (e) {
      debugPrint('Failed to load total balances: $e');
      _totalBalances = {};
    } catch (e) {
      debugPrint('Unexpected error loading total balances: $e');
      _totalBalances = {};
    }
  }

  /// Load deleted accounts
  Future<void> loadDeletedAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _deletedAccounts = await _service.getDeletedAccounts();
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _deletedAccounts = [];
      debugPrint('Failed to load deleted accounts: $e');
    } catch (e) {
      _errorMessage = 'Failed to load deleted accounts: Unexpected error';
      _deletedAccounts = [];
      debugPrint('Unexpected error loading deleted accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new account
  Future<bool> createAccount({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final account = await _service.createAccount(
        accountTypeId: accountTypeId,
        name: name,
        description: description,
        currency: currency,
        initialBalance: initialBalance,
        institutionName: institutionName,
        accountNickname: accountNickname,
        creditLimit: creditLimit,
        includeInTotal: includeInTotal,
      );

      _accounts.insert(0, account);
      await loadTotalBalances();
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to create account: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create account: Unexpected error';
      _isLoading = false;
      notifyListeners();
      debugPrint('Unexpected error creating account: $e');
      return false;
    }
  }

  /// Update an account
  Future<bool> updateAccount({
    required String accountId,
    String? name,
    String? description,
    String? institutionName,
    String? accountNickname,
    String? currency,
    double? initialBalance,
    double? creditLimit,
    bool? isActive,
    bool? includeInTotal,
    bool? isHidden,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedAccount = await _service.updateAccount(
        accountId: accountId,
        name: name,
        description: description,
        institutionName: institutionName,
        accountNickname: accountNickname,
        currency: currency,
        initialBalance: initialBalance,
        creditLimit: creditLimit,
        isActive: isActive,
        includeInTotal: includeInTotal,
        isHidden: isHidden,
      );

      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        _accounts[index] = updatedAccount;
      }

      if (includeInTotal != null) {
        await loadTotalBalances();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to update account: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update account: Unexpected error';
      _isLoading = false;
      notifyListeners();
      debugPrint('Unexpected error updating account: $e');
      return false;
    }
  }

  /// Delete an account (soft delete)
  Future<bool> deleteAccount(String accountId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteAccount(accountId);
      
      _accounts.removeWhere((a) => a.id == accountId);
      await loadTotalBalances();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to delete account: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete account: Unexpected error';
      _isLoading = false;
      notifyListeners();
      debugPrint('Unexpected error deleting account: $e');
      return false;
    }
  }

  /// Restore a deleted account
  Future<bool> restoreAccount(String accountId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final restoredAccount = await _service.restoreAccount(accountId);
      
      _accounts.insert(0, restoredAccount);
      _deletedAccounts.removeWhere((a) => a.id == accountId);
      await loadTotalBalances();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to restore account: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to restore account: Unexpected error';
      _isLoading = false;
      notifyListeners();
      debugPrint('Unexpected error restoring account: $e');
      return false;
    }
  }

  /// Permanently delete an account (hard delete)
  Future<bool> permanentDeleteAccount(String accountId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.permanentDeleteAccount(accountId);
      
      _deletedAccounts.removeWhere((a) => a.id == accountId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Failed to permanently delete account: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to permanently delete account: Unexpected error';
      _isLoading = false;
      notifyListeners();
      debugPrint('Unexpected error permanently deleting account: $e');
      return false;
    }
  }

  /// Toggle account active status
  Future<bool> toggleAccountStatus(String accountId) async {
    try {
      final updatedAccount = await _service.toggleAccountStatus(accountId);
      
      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        _accounts[index] = updatedAccount;
        notifyListeners();
      }
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      debugPrint('Failed to toggle account status: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to toggle account status: Unexpected error';
      debugPrint('Unexpected error toggling account status: $e');
      return false;
    }
  }

  /// Toggle include in total
  Future<bool> toggleIncludeInTotal(String accountId) async {
    try {
      final updatedAccount = await _service.toggleIncludeInTotal(accountId);
      
      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        _accounts[index] = updatedAccount;
        await loadTotalBalances();
        notifyListeners();
      }
      return true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      debugPrint('Failed to toggle include in total: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to toggle include in total: Unexpected error';
      debugPrint('Unexpected error toggling include in total: $e');
      return false;
    }
  }

  /// Select an account
  void selectAccount(Account? account) {
    _selectedAccount = account;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}
