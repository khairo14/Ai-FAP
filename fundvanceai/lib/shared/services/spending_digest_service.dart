import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:intl/intl.dart';

/// Generates a plain-English spending digest for a given calendar month.
///
/// Uses the same Supabase data as SmartInsightsService, formatted into
/// human-friendly sentences using template-based NLG.
class SpendingDigestService {
  final _supabase = SupabaseConfig.client;

  /// Returns a structured digest for the month containing [date].
  Future<SpendingDigest> generateMonthlyDigest({DateTime? date}) async {
    final target = date ?? DateTime.now();
    final start = DateTime(target.year, target.month, 1);
    final end = DateTime(target.year, target.month + 1, 0);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return SpendingDigest.empty(target);
    }

    // Fetch current + previous month expenses and budgets in parallel
    final curFuture = _fetchExpenses(userId, start, end);
    final prevStart = DateTime(start.year, start.month - 1, 1);
    final prevEnd = DateTime(start.year, start.month, 0);
    final prevFuture = _fetchExpenses(userId, prevStart, prevEnd);
    final budgetsFuture = _fetchBudgets(userId);

    final current = await curFuture;
    final previous = await prevFuture;
    final budgets = await budgetsFuture;

    if (current.isEmpty) return SpendingDigest.empty(target);

    // ── Compute stats ───────────────────────────────────────────────────────

    final currTotal = current.fold<double>(
        0.0, (s, e) => s + (e['amount'] as num).toDouble());
    final prevTotal = previous.fold<double>(
        0.0, (s, e) => s + (e['amount'] as num).toDouble());
    final txCount = current.length;
    final avgTx = txCount > 0 ? currTotal / txCount : 0.0;

    // Category breakdown (sorted desc)
    final catTotals = <String, double>{};
    for (final e in current) {
      final cat =
          (e['expense_categories'] as Map?)?['name'] as String? ?? 'Uncategorized';
      catTotals[cat] = (catTotals[cat] ?? 0.0) + (e['amount'] as num).toDouble();
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Month-over-month change
    double momChange = 0;
    bool momIsIncrease = false;
    if (prevTotal > 0) {
      momChange = ((currTotal - prevTotal) / prevTotal) * 100;
      momIsIncrease = currTotal > prevTotal;
    }

    // Budget summary
    int budgetsOnTrack = 0;
    int budgetsOver = 0;
    final spendByCategoryId = <String, double>{};
    for (final e in current) {
      final id =
          (e['category_id'] as String?) ??
              (e['expense_categories'] as Map?)?['id'] as String?;
      if (id != null) {
        spendByCategoryId[id] =
            (spendByCategoryId[id] ?? 0.0) + (e['amount'] as num).toDouble();
      }
    }
    for (final b in budgets) {
      final id = b['expense_categories']?['id'] as String?;
      final budgetAmt = (b['amount'] as num).toDouble();
      final actual = id != null ? (spendByCategoryId[id] ?? 0.0) : 0.0;
      if (actual > budgetAmt) {
        budgetsOver++;
      } else {
        budgetsOnTrack++;
      }
    }

    // Top merchant
    final merchantTotals = <String, double>{};
    for (final e in current) {
      final m = (e['merchant'] as String?) ?? (e['description'] as String?);
      if (m != null && m.isNotEmpty) {
        merchantTotals[m] = (merchantTotals[m] ?? 0.0) + (e['amount'] as num).toDouble();
      }
    }
    String? topMerchant;
    if (merchantTotals.isNotEmpty) {
      topMerchant = (merchantTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;
    }

    // ── Generate NLG sentences ──────────────────────────────────────────────

    final lines = <DigestLine>[];
    final monthName = DateFormat('MMMM yyyy').format(target);
    final fmt = NumberFormat('#,##0.00');

    // 1. Summary sentence
    lines.add(DigestLine(
      emoji: '📊',
      text:
          'In $monthName you made $txCount transaction${txCount == 1 ? '' : 's'} '
          'totalling \$${fmt.format(currTotal)}, averaging \$${fmt.format(avgTx)} each.',
      type: DigestLineType.summary,
    ));

    // 2. Month-over-month
    if (prevTotal > 0) {
      final pct = momChange.abs().toStringAsFixed(0);
      if (momIsIncrease) {
        lines.add(DigestLine(
          emoji: '📈',
          text:
              'Spending is up $pct% vs last month — \$${fmt.format(currTotal - prevTotal)} more than ${DateFormat('MMMM').format(prevStart)}.',
          type: DigestLineType.trend,
          isPositive: false,
        ));
      } else {
        lines.add(DigestLine(
          emoji: '📉',
          text:
              'Great work! You\'ve spent $pct% less than last month, saving \$${fmt.format(prevTotal - currTotal)} vs ${DateFormat('MMMM').format(prevStart)}.',
          type: DigestLineType.trend,
          isPositive: true,
        ));
      }
    }

    // 3. Top category
    if (sortedCats.isNotEmpty) {
      final top = sortedCats.first;
      final topPct = currTotal > 0 ? (top.value / currTotal * 100).round() : 0;
      lines.add(DigestLine(
        emoji: '🏆',
        text:
            '${top.key} is your biggest spending category at \$${fmt.format(top.value)} ($topPct% of total).',
        type: DigestLineType.category,
      ));
    }

    // 4. Second category if notable
    if (sortedCats.length >= 2) {
      final second = sortedCats[1];
      lines.add(DigestLine(
        emoji: '💡',
        text:
            '${second.key} comes in second with \$${fmt.format(second.value)}.',
        type: DigestLineType.category,
      ));
    }

    // 5. Budget health
    if (budgets.isNotEmpty) {
      if (budgetsOver == 0) {
        lines.add(DigestLine(
          emoji: '✅',
          text:
              'All ${budgets.length} budget${budgets.length == 1 ? '' : 's'} are within limit. Keep it up!',
          type: DigestLineType.budget,
          isPositive: true,
        ));
      } else {
        lines.add(DigestLine(
          emoji: '⚠️',
          text:
              '$budgetsOver of ${budgets.length} budget${budgets.length == 1 ? '' : 's'} ${budgetsOver == 1 ? 'has' : 'have'} been exceeded. '
              '${budgetsOnTrack > 0 ? '$budgetsOnTrack on track.' : ''}',
          type: DigestLineType.budget,
          isPositive: false,
        ));
      }
    }

    // 6. Top merchant
    if (topMerchant != null) {
      final merchantAmt = merchantTotals[topMerchant]!;
      lines.add(DigestLine(
        emoji: '🏪',
        text:
            'Your most frequent merchant is "$topMerchant" with \$${fmt.format(merchantAmt)} spent.',
        type: DigestLineType.merchant,
      ));
    }

    return SpendingDigest(
      month: target,
      totalSpent: currTotal,
      transactionCount: txCount,
      topCategory: sortedCats.isNotEmpty ? sortedCats.first.key : null,
      momChangePercent: momChange,
      momIsIncrease: momIsIncrease,
      lines: lines,
      budgetsOnTrack: budgetsOnTrack,
      budgetsExceeded: budgetsOver,
    );
  }

  // ── Data helpers ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchExpenses(
      String userId, DateTime start, DateTime end) async {
    try {
      return await _supabase
          .from('expenses')
          .select(
              'id, amount, date, merchant, description, category_id, expense_categories(id, name)')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0]);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBudgets(String userId) async {
    try {
      return await _supabase
          .from('budgets')
          .select('id, amount, expense_categories(id, name)')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);
    } catch (_) {
      return [];
    }
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

enum DigestLineType { summary, trend, category, budget, merchant }

class DigestLine {
  final String emoji;
  final String text;
  final DigestLineType type;
  final bool isPositive;

  const DigestLine({
    required this.emoji,
    required this.text,
    required this.type,
    this.isPositive = true,
  });
}

class SpendingDigest {
  final DateTime month;
  final double totalSpent;
  final int transactionCount;
  final String? topCategory;
  final double momChangePercent;
  final bool momIsIncrease;
  final List<DigestLine> lines;
  final int budgetsOnTrack;
  final int budgetsExceeded;

  const SpendingDigest({
    required this.month,
    required this.totalSpent,
    required this.transactionCount,
    this.topCategory,
    required this.momChangePercent,
    required this.momIsIncrease,
    required this.lines,
    required this.budgetsOnTrack,
    required this.budgetsExceeded,
  });

  bool get isEmpty => lines.isEmpty;

  factory SpendingDigest.empty(DateTime month) => SpendingDigest(
        month: month,
        totalSpent: 0,
        transactionCount: 0,
        momChangePercent: 0,
        momIsIncrease: false,
        lines: [],
        budgetsOnTrack: 0,
        budgetsExceeded: 0,
      );
}
