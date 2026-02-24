import 'dart:math' as math;
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

  /// Get financial health score (0–100) across 5 factors:
  ///   Savings Rate (30) + Budget Adherence (25) + Emergency Fund (10)
  ///   + Debt Management (20) + Spending Consistency (15) = 100
  Future<Map<String, dynamic>> getFinancialHealthScore() async {
    try {
      final userId = _currentUserId;
      final now = DateTime.now();
      final monthStartStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final monthEndStr =
          '${monthEnd.year}-${monthEnd.month.toString().padLeft(2, '0')}-${monthEnd.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        getFinancialSummary(),
        getAccountsSummary(),
        _fetchDebtTotal(userId),
        _fetchBudgetAdherence(userId, monthStartStr, monthEndStr),
        _fetchSpendingConsistency(userId, now),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final accountsSummary = results[1] as Map<String, dynamic>;
      final debtTotal = results[2] as double;
      final budgetAdherence = results[3] as double;
      final consistencyCV = results[4] as double;

      double score = 0.0;
      final List<String> insights = [];
      final List<Map<String, dynamic>> factors = [];

      final totalIncome = summary['totalIncome'] as double;
      final totalExpenses = summary['totalExpenses'] as double;
      final netIncome = summary['netIncome'] as double;
      final totalBalance = accountsSummary['totalBalance'] as double;

      // ── Factor 1: Savings Rate (30 pts) ───────────────────────────────────
      double savingsEarned = 0.0;
      if (totalIncome > 0) {
        final rate = netIncome / totalIncome;
        if (rate >= 0.30) {
          savingsEarned = 30;
          insights
              .add('Excellent savings rate! You\'re saving 30%+ of income.');
        } else if (rate >= 0.20) {
          savingsEarned = 24;
          insights.add('Good savings rate. You\'re saving 20%+ of income.');
        } else if (rate >= 0.10) {
          savingsEarned = 16;
          insights
              .add('Fair savings rate. Try to save at least 20% of income.');
        } else if (rate >= 0.0) {
          savingsEarned = 6;
          insights.add('Low savings rate. Consider reducing your expenses.');
        } else {
          savingsEarned = 0;
          insights.add('Warning: Spending more than you earn this month!');
        }
      } else {
        savingsEarned = 15; // neutral — no income logged
      }
      score += savingsEarned;
      factors.add(
          {'name': 'Savings Rate', 'earned': savingsEarned.toInt(), 'max': 30});

      // ── Factor 2: Budget Adherence (25 pts) ──────────────────────────────
      double budgetEarned = 0.0;
      if (budgetAdherence < 0) {
        budgetEarned = 15; // neutral — no budgets set
        insights.add(
            'Set monthly budgets to track your spending discipline score.');
      } else if (budgetAdherence >= 0.90) {
        budgetEarned = 25;
        insights.add(
            'Great budget discipline! You\'re on track with your budgets.');
      } else if (budgetAdherence >= 0.70) {
        budgetEarned = 18;
        insights.add(
            'Good budget control — a few categories are over. Rein them in.');
      } else if (budgetAdherence >= 0.50) {
        budgetEarned = 10;
        insights.add(
            'Budget adherence needs work. Over half your budgets are overspent.');
      } else {
        budgetEarned = 3;
        insights.add('Warning: Most budgets overspent this month.');
      }
      score += budgetEarned;
      factors.add({
        'name': 'Budget Adherence',
        'earned': budgetEarned.toInt(),
        'max': 25
      });

      // ── Factor 3: Emergency Fund (10 pts) ────────────────────────────────
      double emergencyEarned = 0.0;
      if (totalExpenses > 0) {
        final months = totalBalance / totalExpenses;
        if (months >= 6) {
          emergencyEarned = 10;
          insights.add('Great emergency fund! 6+ months of expenses covered.');
        } else if (months >= 3) {
          emergencyEarned = 7;
          insights.add('Good emergency fund — 3–6 months of expenses covered.');
        } else if (months >= 1) {
          emergencyEarned = 4;
          insights
              .add('Building emergency fund. Aim for 3–6 months of expenses.');
        } else {
          emergencyEarned = 0;
          insights.add('Important: Start building an emergency fund.');
        }
      } else {
        emergencyEarned = 5; // neutral
      }
      score += emergencyEarned;
      factors.add({
        'name': 'Emergency Fund',
        'earned': emergencyEarned.toInt(),
        'max': 10
      });

      // ── Factor 4: Debt Management (20 pts) ───────────────────────────────
      double debtEarned = 0.0;
      if (debtTotal < 0) {
        debtEarned = 10; // offline/unavailable — neutral
      } else if (debtTotal == 0) {
        debtEarned = 20;
        insights.add('Debt-free! Excellent financial position.');
      } else if (totalIncome > 0) {
        final ratio = debtTotal / (totalIncome * 12);
        if (ratio < 0.25) {
          debtEarned = 16;
          insights
              .add('Low debt-to-income ratio — you\'re managing debt well.');
        } else if (ratio < 0.50) {
          debtEarned = 12;
          insights.add('Moderate debt level. Keep making regular payments.');
        } else if (ratio < 1.0) {
          debtEarned = 7;
          insights
              .add('Debt is above 50% of annual income. Prioritise payoff.');
        } else if (ratio < 2.0) {
          debtEarned = 3;
          insights
              .add('High debt load. Focus on the highest-interest debt first.');
        } else {
          debtEarned = 0;
          insights.add(
              'Warning: Debt exceeds 2× annual income. Seek a payoff plan.');
        }
      } else {
        debtEarned = 5; // income not logged but has debt
      }
      score += debtEarned;
      factors.add(
          {'name': 'Debt Management', 'earned': debtEarned.toInt(), 'max': 20});

      // ── Factor 5: Spending Consistency (15 pts) ──────────────────────────
      double consistencyEarned = 0.0;
      if (consistencyCV < 0) {
        consistencyEarned = 8; // insufficient data — neutral
      } else if (consistencyCV < 0.10) {
        consistencyEarned = 15;
        insights.add('Very consistent spending! Monthly habits are stable.');
      } else if (consistencyCV < 0.20) {
        consistencyEarned = 11;
        insights.add('Fairly consistent spending across months.');
      } else if (consistencyCV < 0.35) {
        consistencyEarned = 7;
        insights.add(
            'Some spending variability — try to even out monthly expenses.');
      } else {
        consistencyEarned = 3;
        insights.add(
            'High spending variability month-to-month. Consistent budgeting helps.');
      }
      score += consistencyEarned;
      factors.add({
        'name': 'Spending Consistency',
        'earned': consistencyEarned.toInt(),
        'max': 15
      });

      score = score.clamp(0.0, 100.0);
      String status;
      if (score >= 85) {
        status = 'Excellent';
      } else if (score >= 70) {
        status = 'Good';
      } else if (score >= 50) {
        status = 'Fair';
      } else {
        status = 'Needs Improvement';
      }

      return {
        'score': score,
        'status': status,
        'insights': insights,
        'factors': factors,
      };
    } catch (e) {
      return {
        'score': 0.0,
        'status': 'Unknown',
        'insights': ['Unable to calculate financial health score'],
        'factors': <Map<String, dynamic>>[],
      };
    }
  }

  // ── Health score helpers ───────────────────────────────────────────────────

  /// Returns total active debt balance, or -1.0 if offline/unavailable.
  Future<double> _fetchDebtTotal(String userId) async {
    if (!_isOnline) return -1.0;
    try {
      final rows = await _supabase
          .from('debts')
          .select('current_balance')
          .eq('user_id', userId)
          .eq('is_deleted', false) as List;
      return rows.fold<double>(
          0.0,
          (sum, row) =>
              sum + ((row['current_balance'] as num?)?.toDouble() ?? 0.0));
    } catch (_) {
      return -1.0;
    }
  }

  /// Returns fraction of budgets on track (0.0–1.0), or -1.0 if no budgets.
  Future<double> _fetchBudgetAdherence(
      String userId, String startStr, String endStr) async {
    if (!_isOnline) return -1.0;
    try {
      final budgets = await _supabase
          .from('budgets')
          .select('category_id, budget_amount')
          .eq('user_id', userId)
          .eq('is_deleted', false) as List;
      if (budgets.isEmpty) return -1.0;

      final expenses = await _supabase
          .from('expenses')
          .select('category_id, amount')
          .eq('user_id', userId)
          .gte('date', startStr)
          .lte('date', endStr)
          .eq('is_deleted', false) as List;

      final Map<String, double> spent = {};
      for (final e in expenses) {
        final cat = e['category_id'] as String? ?? '';
        spent[cat] =
            (spent[cat] ?? 0) + ((e['amount'] as num?)?.toDouble() ?? 0.0);
      }

      int onTrack = 0;
      for (final b in budgets) {
        final cat = b['category_id'] as String? ?? '';
        final limit = (b['budget_amount'] as num?)?.toDouble() ?? 0.0;
        if (limit <= 0 || (spent[cat] ?? 0.0) <= limit) onTrack++;
      }
      return onTrack / budgets.length;
    } catch (_) {
      return -1.0;
    }
  }

  /// Returns coefficient of variation of monthly spend over last 3 months,
  /// or -1.0 if insufficient data or offline.
  Future<double> _fetchSpendingConsistency(String userId, DateTime now) async {
    if (!_isOnline) return -1.0;
    try {
      final threeAgo = DateTime(now.year, now.month - 2, 1);
      final startStr =
          '${threeAgo.year}-${threeAgo.month.toString().padLeft(2, '0')}-01';

      final rows = await _supabase
          .from('expenses')
          .select('date, amount')
          .eq('user_id', userId)
          .gte('date', startStr)
          .eq('is_deleted', false) as List;

      if (rows.isEmpty) return -1.0;

      final Map<String, double> byMonth = {};
      for (final r in rows) {
        final ym = (r['date'] as String).substring(0, 7); // 'YYYY-MM'
        byMonth[ym] =
            (byMonth[ym] ?? 0) + ((r['amount'] as num?)?.toDouble() ?? 0.0);
      }

      if (byMonth.length < 2) return -1.0;

      final vals = byMonth.values.toList();
      final mean = vals.reduce((a, b) => a + b) / vals.length;
      if (mean == 0) return -1.0;

      final variance =
          vals.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
              vals.length;
      return math.sqrt(variance) / mean;
    } catch (_) {
      return -1.0;
    }
  }
}
