import 'package:fundvanceai/core/config/supabase_config.dart';

class AnalyticsService {
  final _supabase = SupabaseConfig.client;

  /// Get spending by category for a date range
  Future<Map<String, double>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get expenses with category names
      final response = await _supabase
          .from('expenses')
          .select('amount, expense_categories(name)')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      final Map<String, double> breakdown = {};

      for (var item in response) {
        final amount = (item['amount'] as num).toDouble();
        final categoryName = item['expense_categories']?['name'] ?? 'Uncategorized';
        
        breakdown[categoryName] = (breakdown[categoryName] ?? 0.0) + amount;
      }

      return breakdown;
    } catch (e) {
      throw Exception('Failed to get category breakdown: $e');
    }
  }

  /// Get daily spending totals for a date range
  Future<Map<DateTime, double>> getDailySpending({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('expenses')
          .select('date, amount')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date');

      final Map<DateTime, double> dailySpending = {};

      for (var item in response) {
        final date = DateTime.parse(item['date']);
        final amount = (item['amount'] as num).toDouble();
        
        dailySpending[date] = (dailySpending[date] ?? 0.0) + amount;
      }

      return dailySpending;
    } catch (e) {
      throw Exception('Failed to get daily spending: $e');
    }
  }

  /// Get top spending categories (limit to top N)
  Future<List<Map<String, dynamic>>> getTopCategories({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    try {
      final breakdown = await getCategoryBreakdown(
        startDate: startDate,
        endDate: endDate,
      );

      final sortedCategories = breakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.take(limit).map((entry) {
        return {
          'category': entry.key,
          'amount': entry.value,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get top categories: $e');
    }
  }

  /// Get budget vs actual spending for all budgets
  Future<List<Map<String, dynamic>>> getBudgetComparison({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get all active budgets
      final budgetsResponse = await _supabase
          .from('budgets')
          .select('id, amount, period, expense_categories(id, name)')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);

      final List<Map<String, dynamic>> comparisons = [];

      for (var budget in budgetsResponse) {
        final categoryId = budget['expense_categories']?['id'];
        final categoryName = budget['expense_categories']?['name'] ?? 'Uncategorized';
        final budgetAmount = (budget['amount'] as num).toDouble();

        // Get actual spending for this category
        double actualSpending = 0.0;
        
        if (categoryId != null) {
          final expensesResponse = await _supabase
              .from('expenses')
              .select('amount')
              .eq('user_id', userId)
              .eq('category_id', categoryId)
              .filter('deleted_at', 'is', null)
              .gte('date', startDate.toIso8601String().split('T')[0])
              .lte('date', endDate.toIso8601String().split('T')[0]);

          for (var expense in expensesResponse) {
            actualSpending += (expense['amount'] as num).toDouble();
          }
        }

        comparisons.add({
          'category': categoryName,
          'budget': budgetAmount,
          'actual': actualSpending,
          'percentage': budgetAmount > 0 ? (actualSpending / budgetAmount) * 100 : 0.0,
          'period': budget['period'],
        });
      }

      return comparisons;
    } catch (e) {
      throw Exception('Failed to get budget comparison: $e');
    }
  }

  /// Get summary statistics
  Future<Map<String, dynamic>> getSummaryStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('expenses')
          .select('amount')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      double totalSpending = 0.0;
      int transactionCount = response.length;

      for (var expense in response) {
        totalSpending += (expense['amount'] as num).toDouble();
      }

      final averagePerTransaction = transactionCount > 0 
          ? totalSpending / transactionCount 
          : 0.0;

      final days = endDate.difference(startDate).inDays + 1;
      final averagePerDay = days > 0 ? totalSpending / days : 0.0;

      return {
        'total': totalSpending,
        'count': transactionCount,
        'averagePerTransaction': averagePerTransaction,
        'averagePerDay': averagePerDay,
        'period': days,
      };
    } catch (e) {
      throw Exception('Failed to get summary stats: $e');
    }
  }

  /// Compare current period with previous period
  Future<Map<String, dynamic>> getPeriodComparison({
    required DateTime currentStart,
    required DateTime currentEnd,
  }) async {
    try {
      final currentPeriod = await getSummaryStats(
        startDate: currentStart,
        endDate: currentEnd,
      );

      // Calculate previous period dates
      final periodDays = currentEnd.difference(currentStart).inDays + 1;
      final previousEnd = currentStart.subtract(const Duration(days: 1));
      final previousStart = previousEnd.subtract(Duration(days: periodDays - 1));

      final previousPeriod = await getSummaryStats(
        startDate: previousStart,
        endDate: previousEnd,
      );

      final currentTotal = currentPeriod['total'] as double;
      final previousTotal = previousPeriod['total'] as double;

      double changeAmount = currentTotal - previousTotal;
      double changePercentage = previousTotal > 0 
          ? (changeAmount / previousTotal) * 100 
          : 0.0;

      return {
        'current': currentPeriod,
        'previous': previousPeriod,
        'changeAmount': changeAmount,
        'changePercentage': changePercentage,
        'isIncrease': changeAmount > 0,
      };
    } catch (e) {
      throw Exception('Failed to get period comparison: $e');
    }
  }
}
