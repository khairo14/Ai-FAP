import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../models/account.dart';
import 'local_database.dart';
import 'connectivity_service.dart';

/// Service for fetching dashboard data
class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool get _isOnline => ConnectivityService.instance.isOnline;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  /// Get financial summary for a date range
  Future<Map<String, dynamic>> getFinancialSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    if (_isOnline) {
      try {
        final userId = _currentUserId;

        final expensesResponse = await _supabase
            .from(AppConstants.expensesTable)
            .select('amount, accounts(currency)')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .gte('date', startStr)
            .lte('date', endStr);

        final expensesByCurrency = <String, double>{};
        for (final expense in expensesResponse as List) {
          final currency = expense['accounts']?['currency'] as String? ?? 'USD';
          final amount = (expense['amount'] as num).toDouble();
          expensesByCurrency[currency] =
              (expensesByCurrency[currency] ?? 0.0) + amount;
        }

        final incomeResponse = await _supabase
            .from(AppConstants.incomeTable)
            .select('amount, currency')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .gte('income_date', startStr)
            .lte('income_date', endStr);

        final incomeByCurrency = <String, double>{};
        for (final income in incomeResponse as List) {
          final currency = income['currency'] as String? ?? 'USD';
          final amount = (income['amount'] as num).toDouble();
          incomeByCurrency[currency] =
              (incomeByCurrency[currency] ?? 0.0) + amount;
        }

        final netIncomeByCurrency = <String, double>{};
        final allOnlineCurrencies = <String>{
          ...expensesByCurrency.keys,
          ...incomeByCurrency.keys,
        };
        for (final currency in allOnlineCurrencies) {
          netIncomeByCurrency[currency] = (incomeByCurrency[currency] ?? 0.0) -
              (expensesByCurrency[currency] ?? 0.0);
        }

        return {
          'expensesByCurrency': expensesByCurrency,
          'incomeByCurrency': incomeByCurrency,
          'netIncomeByCurrency': netIncomeByCurrency,
          'expenseCount': (expensesResponse as List).length,
          'incomeCount': (incomeResponse as List).length,
          'startDate': start,
          'endDate': end,
        };
      } catch (_) {
        // Fall through to offline computation
      }
    }

    // --- Offline / fallback: compute from SQLite cache ---
    final userId = _currentUserId;
    final accRows =
        await LocalDatabase.instance.getRows(table: 'accounts', userId: userId);
    final accMap = {for (final a in accRows) a['id'] as String: a};

    final expRows =
        await LocalDatabase.instance.getRows(table: 'expenses', userId: userId);
    final expensesByCurrency = <String, double>{};
    int expenseCount = 0;
    for (final row in expRows) {
      if (row['deleted_at'] != null) {
        continue;
      }
      final dateStr = (row['date'] as String? ?? '');
      if (dateStr.compareTo(startStr) < 0 || dateStr.compareTo(endStr) > 0) {
        continue;
      }
      // Currency from join if cached, otherwise look up account
      String currency = (row['accounts'] as Map?)?['currency'] as String? ?? '';
      if (currency.isEmpty) {
        final accId = row['account_id'] as String?;
        final accData = accId != null ? accMap[accId] : null;
        currency =
            (accData != null ? accData['currency'] as String? : null) ?? 'USD';
      }
      final amount = (row['amount'] as num).toDouble();
      expensesByCurrency[currency] =
          (expensesByCurrency[currency] ?? 0.0) + amount;
      expenseCount++;
    }

    final incRows = await LocalDatabase.instance
        .getRows(table: 'income_records', userId: userId);
    final incomeByCurrency = <String, double>{};
    int incomeCount = 0;
    for (final row in incRows) {
      if (row['deleted_at'] != null) {
        continue;
      }
      final dateStr = (row['income_date'] as String? ?? '');
      if (dateStr.compareTo(startStr) < 0 || dateStr.compareTo(endStr) > 0) {
        continue;
      }
      final currency = row['currency'] as String? ?? 'USD';
      final amount = (row['amount'] as num).toDouble();
      incomeByCurrency[currency] = (incomeByCurrency[currency] ?? 0.0) + amount;
      incomeCount++;
    }

    final netIncomeByCurrency = <String, double>{};
    final allCurrencies = <String>{
      ...expensesByCurrency.keys,
      ...incomeByCurrency.keys,
    };
    for (final currency in allCurrencies) {
      netIncomeByCurrency[currency] = (incomeByCurrency[currency] ?? 0.0) -
          (expensesByCurrency[currency] ?? 0.0);
    }

    return {
      'expensesByCurrency': expensesByCurrency,
      'incomeByCurrency': incomeByCurrency,
      'netIncomeByCurrency': netIncomeByCurrency,
      'expenseCount': expenseCount,
      'incomeCount': incomeCount,
      'startDate': start,
      'endDate': end,
    };
  }

  /// Get account balances summary
  Future<Map<String, dynamic>> getAccountsSummary() async {
    if (_isOnline) {
      try {
        final userId = _currentUserId;
        final response = await _supabase
            .from(AppConstants.accountsTable)
            .select('*, account_types(name, category)')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .eq('is_active', true);

        final accounts = (response as List)
            .map((json) => Account.fromJson(json as Map<String, dynamic>))
            .toList();

        accounts.sort((a, b) {
          final aHasBalance = a.currentBalance != 0;
          final bHasBalance = b.currentBalance != 0;
          if (aHasBalance && !bHasBalance) return -1;
          if (!aHasBalance && bHasBalance) return 1;
          return b.currentBalance.abs().compareTo(a.currentBalance.abs());
        });

        final balancesByCurrency = <String, double>{};
        final creditAvailableByCurrency = <String, double>{};

        for (final account in accounts) {
          if (account.includeInTotal) {
            balancesByCurrency[account.currency] =
                (balancesByCurrency[account.currency] ?? 0.0) +
                    account.currentBalance;
          }
          if (account.accountTypeName?.toLowerCase() == 'credit card' &&
              account.creditLimit != null) {
            final available = account.creditLimit! - account.currentBalance;
            creditAvailableByCurrency[account.currency] =
                (creditAvailableByCurrency[account.currency] ?? 0.0) +
                    available;
          }
        }

        return {
          'accounts': accounts,
          'balancesByCurrency': balancesByCurrency,
          'creditAvailableByCurrency': creditAvailableByCurrency,
          'accountCount': accounts.length,
        };
      } catch (_) {
        // Fall through to cache
      }
    }

    // --- Offline / fallback: read from SQLite account cache ---
    final accRows = await LocalDatabase.instance
        .getRows(table: 'accounts', userId: _currentUserId);
    final accounts = accRows
        .where(
            (r) => r['deleted_at'] == null && (r['is_active'] as bool? ?? true))
        .map((r) => Account.fromJson(r))
        .toList();

    accounts.sort((a, b) {
      final aHasBalance = a.currentBalance != 0;
      final bHasBalance = b.currentBalance != 0;
      if (aHasBalance && !bHasBalance) return -1;
      if (!aHasBalance && bHasBalance) return 1;
      return b.currentBalance.abs().compareTo(a.currentBalance.abs());
    });

    final balancesByCurrency = <String, double>{};
    final creditAvailableByCurrency = <String, double>{};
    for (final account in accounts) {
      if (account.includeInTotal) {
        balancesByCurrency[account.currency] =
            (balancesByCurrency[account.currency] ?? 0.0) +
                account.currentBalance;
      }
      if (account.accountTypeName?.toLowerCase() == 'credit card' &&
          account.creditLimit != null) {
        final available = account.creditLimit! - account.currentBalance;
        creditAvailableByCurrency[account.currency] =
            (creditAvailableByCurrency[account.currency] ?? 0.0) + available;
      }
    }

    return {
      'accounts': accounts,
      'balancesByCurrency': balancesByCurrency,
      'creditAvailableByCurrency': creditAvailableByCurrency,
      'accountCount': accounts.length,
    };
  }

  /// Get recent transactions (expenses, income, transfers)
  Future<List<Map<String, dynamic>>> getRecentTransactions(
      {int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final transactions = <Map<String, dynamic>>[];

      // Get recent expenses
      final expensesResponse = await _supabase
          .from(AppConstants.expensesTable)
          .select(
              'id, merchant, description, amount, date, expense_categories(name, icon, color), accounts!expenses_account_id_fkey(currency)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false)
          .limit(limit);

      for (final expense in expensesResponse as List) {
        // Prioritize merchant name, then description, then category name
        final name = expense['merchant']?.toString().trim() ??
            expense['description']?.toString().trim() ??
            expense['expense_categories']?['name']?.toString() ??
            'Expense';

        transactions.add({
          'type': 'expense',
          'id': expense['id'],
          'description': name,
          'amount': expense['amount'],
          'currency': expense['accounts']?['currency'] ?? 'USD',
          'date': DateTime.parse(expense['date'] as String),
          'category': expense['expense_categories']?['name'],
          'icon': expense['expense_categories']?['icon'],
          'color': expense['expense_categories']?['color'],
        });
      }

      // Get recent income
      final incomeResponse = await _supabase
          .from(AppConstants.incomeTable)
          .select('*, income_categories(name, icon, color), accounts(name)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('income_date', ascending: false)
          .limit(limit);

      for (final income in incomeResponse as List) {
        transactions.add({
          'type': 'income',
          'id': income['id'],
          'description': income['income_categories']?['name'] ?? 'Income',
          'amount': income['amount'],
          'currency': income['currency'] ?? 'USD',
          'date': DateTime.parse(income['income_date'] as String),
          'category': income['income_categories']?['name'],
          'accountName': income['accounts']?['name'],
          'icon': income['income_categories']?['icon'],
          'color': income['income_categories']?['color'],
        });
      }

      // Get recent transfers
      final transfersResponse = await _supabase
          .from(AppConstants.transfersTable)
          .select(
              '*, from_account:accounts!transfers_from_account_id_fkey(name), to_account:accounts!transfers_to_account_id_fkey(name)')
          .eq('user_id', userId)
          .order('transfer_date', ascending: false)
          .limit(limit);

      for (final transfer in transfersResponse as List) {
        transactions.add({
          'type': 'transfer',
          'id': transfer['id'],
          'description':
              'Transfer from ${transfer['from_account']?['name']} to ${transfer['to_account']?['name']}',
          'amount': transfer['from_amount'],
          'currency': transfer['from_currency'] ?? 'USD',
          'date': DateTime.parse(transfer['transfer_date'] as String),
          'category': 'Transfer',
          'icon': 'swap_horiz',
          'color': Colors.blue
              .toARGB32()
              .toRadixString(16)
              .substring(2)
              .toUpperCase(),
        });
      }

      // Sort by date descending
      transactions.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // Return only the requested limit
      return transactions.take(limit).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get income vs expenses data for chart (last 6 months)
  Future<List<Map<String, dynamic>>> getIncomeVsExpensesData(
      {int months = 6}) async {
    final now = DateTime.now();

    if (_isOnline) {
      try {
        final userId = _currentUserId;
        final data = <Map<String, dynamic>>[];

        for (int i = months - 1; i >= 0; i--) {
          final monthDate = DateTime(now.year, now.month - i, 1);
          final monthEnd =
              DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
          final monthStartStr = monthDate.toIso8601String().split('T')[0];
          final monthEndStr = monthEnd.toIso8601String().split('T')[0];

          final expensesResponse = await _supabase
              .from(AppConstants.expensesTable)
              .select('amount')
              .eq('user_id', userId)
              .isFilter('deleted_at', null)
              .gte('date', monthStartStr)
              .lte('date', monthEndStr);

          final totalExpenses = (expensesResponse as List).fold<double>(
            0.0,
            (sum, item) => sum + (item['amount'] as num).toDouble(),
          );

          final incomeResponse = await _supabase
              .from(AppConstants.incomeTable)
              .select('amount')
              .eq('user_id', userId)
              .isFilter('deleted_at', null)
              .gte('income_date', monthStartStr)
              .lte('income_date', monthEndStr);

          final totalIncome = (incomeResponse as List).fold<double>(
            0.0,
            (sum, item) => sum + (item['amount'] as num).toDouble(),
          );

          data.add({
            'month': monthDate,
            'income': totalIncome,
            'expenses': totalExpenses,
            'net': totalIncome - totalExpenses,
          });
        }
        return data;
      } catch (_) {
        // Fall through to cache
      }
    }

    // --- Offline / fallback: aggregate from SQLite ---
    final userId = _currentUserId;
    final expRows =
        await LocalDatabase.instance.getRows(table: 'expenses', userId: userId);
    final incRows = await LocalDatabase.instance
        .getRows(table: 'income_records', userId: userId);
    final data = <Map<String, dynamic>>[];

    for (int i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthEnd =
          DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
      final startStr = monthDate.toIso8601String().split('T')[0];
      final endStr = monthEnd.toIso8601String().split('T')[0];

      double totalExpenses = 0.0;
      for (final row in expRows) {
        if (row['deleted_at'] != null) {
          continue;
        }
        final dateStr = row['date'] as String? ?? '';
        if (dateStr.compareTo(startStr) < 0 || dateStr.compareTo(endStr) > 0) {
          continue;
        }
        totalExpenses += (row['amount'] as num).toDouble();
      }

      double totalIncome = 0.0;
      for (final row in incRows) {
        if (row['deleted_at'] != null) {
          continue;
        }
        final dateStr = row['income_date'] as String? ?? '';
        if (dateStr.compareTo(startStr) < 0 || dateStr.compareTo(endStr) > 0) {
          continue;
        }
        totalIncome += (row['amount'] as num).toDouble();
      }

      data.add({
        'month': monthDate,
        'income': totalIncome,
        'expenses': totalExpenses,
        'net': totalIncome - totalExpenses,
      });
    }
    return data;
  }

  /// Get financial health score (0-100)
  Future<Map<String, dynamic>> getFinancialHealthScore() async {
    try {
      final summary = await getFinancialSummary();
      final accountsSummary = await getAccountsSummary();

      double score = 50.0; // Base score
      String status = 'Fair';
      List<String> insights = [];

      final totalIncome = summary['totalIncome'] as double;
      final totalExpenses = summary['totalExpenses'] as double;
      final netIncome = summary['netIncome'] as double;
      final totalBalance = accountsSummary['totalBalance'] as double;

      // Income vs Expenses ratio (max 30 points)
      if (totalIncome > 0) {
        final savingsRate = netIncome / totalIncome;
        if (savingsRate >= 0.30) {
          score += 30;
          insights.add(
              'Excellent savings rate! You\'re saving 30%+ of your income.');
        } else if (savingsRate >= 0.20) {
          score += 25;
          insights
              .add('Good savings rate. You\'re saving 20%+ of your income.');
        } else if (savingsRate >= 0.10) {
          score += 15;
          insights
              .add('Fair savings rate. Try to save at least 20% of income.');
        } else if (savingsRate >= 0) {
          score += 5;
          insights.add('Low savings rate. Consider reducing expenses.');
        } else {
          score -= 10;
          insights.add('Warning: Spending more than you earn!');
        }
      }

      // Emergency fund (max 20 points)
      if (totalIncome > 0) {
        final monthsOfExpenses =
            totalExpenses > 0 ? totalBalance / totalExpenses : 0;
        if (monthsOfExpenses >= 6) {
          score += 20;
          insights.add(
              'Great emergency fund! You have 6+ months of expenses saved.');
        } else if (monthsOfExpenses >= 3) {
          score += 15;
          insights.add('Good emergency fund. You have 3-6 months of expenses.');
        } else if (monthsOfExpenses >= 1) {
          score += 10;
          insights
              .add('Building emergency fund. Aim for 3-6 months of expenses.');
        } else {
          insights.add('Important: Start building an emergency fund.');
        }
      }

      // Determine status based on score
      if (score >= 80) {
        status = 'Excellent';
      } else if (score >= 70) {
        status = 'Good';
      } else if (score >= 50) {
        status = 'Fair';
      } else {
        status = 'Needs Improvement';
      }

      // Ensure score is within 0-100
      score = score.clamp(0.0, 100.0);

      return {
        'score': score,
        'status': status,
        'insights': insights,
      };
    } catch (e) {
      return {
        'score': 0.0,
        'status': 'Unknown',
        'insights': ['Unable to calculate financial health score'],
      };
    }
  }
}
