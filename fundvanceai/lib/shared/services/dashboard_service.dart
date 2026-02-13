import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../models/expense.dart';
import '../models/account.dart';

/// Service for fetching dashboard data
class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get financial summary for a date range
  Future<Map<String, dynamic>> getFinancialSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Default to current month if dates not provided
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Get total expenses grouped by currency
      final expensesResponse = await _supabase
          .from(AppConstants.expensesTable)
          .select('amount, accounts(currency)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());

      // Group expenses by currency
      final expensesByCurrency = <String, double>{};
      for (final expense in expensesResponse as List) {
        // Get currency from account, fallback to USD if no account
        final currency = expense['accounts']?['currency'] as String? ?? 'USD';
        final amount = (expense['amount'] as num).toDouble();
        expensesByCurrency[currency] = (expensesByCurrency[currency] ?? 0.0) + amount;
      }

      // Get total income grouped by currency
      final incomeResponse = await _supabase
          .from(AppConstants.incomeTable)
          .select('amount, currency')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .gte('income_date', start.toIso8601String())
          .lte('income_date', end.toIso8601String());

      // Group income by currency
      final incomeByCurrency = <String, double>{};
      for (final income in incomeResponse as List) {
        final currency = income['currency'] as String? ?? 'USD';
        final amount = (income['amount'] as num).toDouble();
        incomeByCurrency[currency] = (incomeByCurrency[currency] ?? 0.0) + amount;
      }

      // Calculate net income by currency
      final netIncomeByCurrency = <String, double>{};
      final allCurrencies = {...expensesByCurrency.keys, ...incomeByCurrency.keys};
      for (final currency in allCurrencies) {
        final income = incomeByCurrency[currency] ?? 0.0;
        final expenses = expensesByCurrency[currency] ?? 0.0;
        netIncomeByCurrency[currency] = income - expenses;
      }

      // Get expense count
      final expenseCount = (expensesResponse as List).length;

      // Get income count
      final incomeCount = (incomeResponse as List).length;

      return {
        'expensesByCurrency': expensesByCurrency,
        'incomeByCurrency': incomeByCurrency,
        'netIncomeByCurrency': netIncomeByCurrency,
        'expenseCount': expenseCount,
        'incomeCount': incomeCount,
        'startDate': start,
        'endDate': end,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get account balances summary
  Future<Map<String, dynamic>> getAccountsSummary() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from(AppConstants.accountsTable)
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .eq('is_active', true);

      final accounts = (response as List)
          .map((json) => Account.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort: Non-zero balances first (by absolute value descending), then zero balances
      accounts.sort((a, b) {
        final aHasBalance = a.currentBalance != 0;
        final bHasBalance = b.currentBalance != 0;
        
        if (aHasBalance && !bHasBalance) return -1;
        if (!aHasBalance && bHasBalance) return 1;
        
        // Both have balance or both are zero - sort by absolute value descending
        return b.currentBalance.abs().compareTo(a.currentBalance.abs());
      });

      // Calculate totals grouped by currency
      final balancesByCurrency = <String, double>{};
      final creditAvailableByCurrency = <String, double>{};
      int accountCount = accounts.length;

      for (final account in accounts) {
        if (account.includeInTotal) {
          final currency = account.currency;
          balancesByCurrency[currency] = 
              (balancesByCurrency[currency] ?? 0.0) + account.currentBalance;
        }
        
        if (account.accountTypeName?.toLowerCase() == 'credit card' && account.creditLimit != null) {
          final currency = account.currency;
          final available = account.creditLimit! - account.currentBalance;
          creditAvailableByCurrency[currency] = 
              (creditAvailableByCurrency[currency] ?? 0.0) + available;
        }
      }

      return {
        'accounts': accounts,
        'balancesByCurrency': balancesByCurrency,
        'creditAvailableByCurrency': creditAvailableByCurrency,
        'accountCount': accountCount,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get recent transactions (expenses, income, transfers)
  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final transactions = <Map<String, dynamic>>[];

      // Get recent expenses
      final expensesResponse = await _supabase
          .from(AppConstants.expensesTable)
          .select('id, merchant, description, amount, date, categories(name, icon, color), accounts!expenses_account_id_fkey(currency)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false)
          .limit(limit);

      for (final expense in expensesResponse as List) {
        // Prioritize merchant name, then description, then category name
        final name = expense['merchant']?.toString().trim() ?? 
                     expense['description']?.toString().trim() ?? 
                     expense['categories']?['name']?.toString() ?? 
                     'Expense';
        
        transactions.add({
          'type': 'expense',
          'id': expense['id'],
          'description': name,
          'amount': expense['amount'],
          'currency': expense['accounts']?['currency'] ?? 'USD',
          'date': DateTime.parse(expense['date'] as String),
          'category': expense['categories']?['name'],
          'icon': expense['categories']?['icon'],
          'color': expense['categories']?['color'],
        });
      }

      // Get recent income
      final incomeResponse = await _supabase
          .from(AppConstants.incomeTable)
          .select('*, income_categories(name, icon, color)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('income_date', ascending: false)
          .limit(limit);

      for (final income in incomeResponse as List) {
        transactions.add({
          'type': 'income',
          'id': income['id'],
          'description': income['description'] ?? 'No description',
          'amount': income['amount'],
          'currency': income['currency'] ?? 'USD',
          'date': DateTime.parse(income['income_date'] as String),
          'category': income['income_categories']?['name'],
          'icon': income['income_categories']?['icon'],
          'color': income['income_categories']?['color'],
        });
      }

      // Get recent transfers
      final transfersResponse = await _supabase
          .from(AppConstants.transfersTable)
          .select('*, from_account:accounts!transfers_from_account_id_fkey(name), to_account:accounts!transfers_to_account_id_fkey(name)')
          .eq('user_id', userId)
          .order('transfer_date', ascending: false)
          .limit(limit);

      for (final transfer in transfersResponse as List) {
        transactions.add({
          'type': 'transfer',
          'id': transfer['id'],
          'description': 'Transfer from ${transfer['from_account']?['name']} to ${transfer['to_account']?['name']}',
          'amount': transfer['from_amount'],
          'currency': transfer['from_currency'] ?? 'USD',
          'date': DateTime.parse(transfer['transfer_date'] as String),
          'category': 'Transfer',
          'icon': 'swap_horiz',
          'color': Colors.blue.value.toRadixString(16).substring(2).toUpperCase(),
        });
      }

      // Sort by date descending
      transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // Return only the requested limit
      return transactions.take(limit).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get income vs expenses data for chart (last 6 months)
  Future<List<Map<String, dynamic>>> getIncomeVsExpensesData({int months = 6}) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();
      final data = <Map<String, dynamic>>[];

      for (int i = months - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

        // Get expenses for this month
        final expensesResponse = await _supabase
            .from(AppConstants.expensesTable)
            .select('amount')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .gte('date', monthDate.toIso8601String())
            .lte('date', monthEnd.toIso8601String());

        final totalExpenses = (expensesResponse as List).fold<double>(
          0.0,
          (sum, item) => sum + (item['amount'] as num).toDouble(),
        );

        // Get income for this month
        final incomeResponse = await _supabase
            .from(AppConstants.incomeTable)
            .select('amount')
            .eq('user_id', userId)
            .isFilter('deleted_at', null)
            .gte('income_date', monthDate.toIso8601String())
            .lte('income_date', monthEnd.toIso8601String());

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
    } catch (e) {
      rethrow;
    }
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
          insights.add('Excellent savings rate! You\'re saving 30%+ of your income.');
        } else if (savingsRate >= 0.20) {
          score += 25;
          insights.add('Good savings rate. You\'re saving 20%+ of your income.');
        } else if (savingsRate >= 0.10) {
          score += 15;
          insights.add('Fair savings rate. Try to save at least 20% of income.');
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
        final monthsOfExpenses = totalExpenses > 0 ? totalBalance / totalExpenses : 0;
        if (monthsOfExpenses >= 6) {
          score += 20;
          insights.add('Great emergency fund! You have 6+ months of expenses saved.');
        } else if (monthsOfExpenses >= 3) {
          score += 15;
          insights.add('Good emergency fund. You have 3-6 months of expenses.');
        } else if (monthsOfExpenses >= 1) {
          score += 10;
          insights.add('Building emergency fund. Aim for 3-6 months of expenses.');
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
