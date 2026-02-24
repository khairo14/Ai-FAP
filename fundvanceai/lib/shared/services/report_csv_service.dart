import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/income.dart';

/// Generates an RFC 4180–compliant CSV string from expense and income records.
///
/// Columns: Date, Type, Merchant/Source, Category, Amount, Currency, Account, Notes
///
/// Usage:
///   final csv = ReportCsvService.buildCsv(expenses: filtered, income: filteredIncome);
///   // Then copy to clipboard or save to file.
class ReportCsvService {
  ReportCsvService._();

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  /// Builds a combined expense + income CSV string for the given lists.
  static String buildCsv({
    required List<Expense> expenses,
    required List<Income> income,
    String periodLabel = '',
  }) {
    final buf = StringBuffer();

    // Header comment (optional metadata row — prefixed with #)
    if (periodLabel.isNotEmpty) {
      buf.writeln('# FundVance AI — Export for $periodLabel');
      buf.writeln('# Generated ${_dateFmt.format(DateTime.now())}');
      buf.writeln('#');
    }

    // Column headers
    buf.writeln(
        'Date,Type,Merchant / Source,Category,Amount,Currency,Account,Notes,Tags');

    // Expense rows
    for (final e in expenses) {
      buf.writeln([
        _dateFmt.format(e.date),
        'Expense',
        _esc(e.merchant ?? ''),
        _esc(e.categoryName ?? e.categoryId ?? 'Uncategorized'),
        (-e.amount).toStringAsFixed(2), // negative to show outflow
        _esc(e.currency ?? ''),
        _esc(e.accountName ?? e.accountId ?? ''),
        _esc(e.notes ?? ''),
        _esc(e.tags.join('; ')),
      ].join(','));
    }

    // Income rows
    for (final i in income) {
      buf.writeln([
        _dateFmt.format(i.incomeDate),
        'Income',
        _esc(i.description ?? ''),
        _esc(i.categoryName ?? i.categoryId),
        i.amount.toStringAsFixed(2), // positive for inflow
        _esc(i.currency),
        _esc(i.accountName ?? i.accountId ?? ''),
        '', // no separate notes field on income
        _esc(i.tags.join('; ')),
      ].join(','));
    }

    return buf.toString();
  }

  /// Escapes a field value for RFC 4180 CSV.
  static String _esc(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
