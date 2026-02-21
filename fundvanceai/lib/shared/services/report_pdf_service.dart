import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data bundle passed from the screen to the service
// ─────────────────────────────────────────────────────────────────────────────

class ReportData {
  final String periodLabel;
  final DateTime periodStart;
  final DateTime periodEnd;

  // Spending
  final double totalSpending;
  final int transactionCount;
  final Map<String, double> categoryTotals; // category name → total amount
  final Map<String, double> dailyTotals; // formatted day label → amount

  // Goals
  final int activeGoals;
  final double totalSaved;
  final double totalGoalTarget;
  final int completedGoals;

  // Debts (optional — omit section if no active debts)
  final int activeDebts;
  final double totalDebtBalance;
  final double totalMinimumPayments;
  final double totalMonthlyInterest;

  const ReportData({
    required this.periodLabel,
    required this.periodStart,
    required this.periodEnd,
    required this.totalSpending,
    required this.transactionCount,
    required this.categoryTotals,
    required this.dailyTotals,
    required this.activeGoals,
    required this.totalSaved,
    required this.totalGoalTarget,
    required this.completedGoals,
    required this.activeDebts,
    required this.totalDebtBalance,
    required this.totalMinimumPayments,
    required this.totalMonthlyInterest,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class ReportPdfService {
  static const _primaryColor = PdfColor.fromInt(0xFF4ECDC4);
  static const _errorColor = PdfColor.fromInt(0xFFE57373);
  static const _successColor = PdfColor.fromInt(0xFF66BB6A);
  static const _textMuted = PdfColors.grey600;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Generates the PDF bytes and triggers the platform share / download sheet.
  static Future<void> shareReport(ReportData data) async {
    final bytes = await _generate(data);
    final dateStr =
        DateFormat('yyyyMMdd').format(data.periodStart);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'fundvance_report_${data.periodLabel.replaceAll(' ', '_')}_$dateStr.pdf',
    );
  }

  /// Returns raw PDF bytes (useful for preview / custom save logic).
  static Future<Uint8List> getBytes(ReportData data) => _generate(data);

  // ── PDF Builder ────────────────────────────────────────────────────────────

  static Future<Uint8List> _generate(ReportData data) async {
    final doc = pw.Document();
    final currency =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final currencyShort =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        header: (ctx) => _header(data, dateFormat),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 20),

          // ── Spending Summary ──────────────────────────────────────────
          _sectionTitle('Spending Summary'),
          pw.SizedBox(height: 8),
          _spendingCard(data, currency, currencyShort),
          pw.SizedBox(height: 20),

          // ── Top Categories ────────────────────────────────────────────
          if (data.categoryTotals.isNotEmpty) ...[
            _sectionTitle('Top Categories'),
            pw.SizedBox(height: 8),
            _categoriesSection(data, currency),
            pw.SizedBox(height: 20),
          ],

          // ── Daily Spending ────────────────────────────────────────────
          if (data.dailyTotals.isNotEmpty) ...[
            _sectionTitle('Daily Spending'),
            pw.SizedBox(height: 8),
            _dailyTable(data, currency),
            pw.SizedBox(height: 20),
          ],

          // ── Goals Snapshot ────────────────────────────────────────────
          _sectionTitle('Goals Snapshot'),
          pw.SizedBox(height: 8),
          _goalsCard(data, currency),
          pw.SizedBox(height: 20),

          // ── Debt Snapshot ─────────────────────────────────────────────
          if (data.activeDebts > 0) ...[
            _sectionTitle('Debt Snapshot'),
            pw.SizedBox(height: 8),
            _debtCard(data, currencyShort),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  static pw.Widget _header(ReportData data, DateFormat fmt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'FundVance AI',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            pw.Text(
              'Report',
              style: pw.TextStyle(
                  fontSize: 16,
                  color: _textMuted,
                  fontStyle: pw.FontStyle.italic),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${data.periodLabel}: ${fmt.format(data.periodStart)} – ${fmt.format(data.periodEnd)}',
              style: pw.TextStyle(fontSize: 11, color: _textMuted),
            ),
            pw.Text(
              'Generated ${fmt.format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: _textMuted),
            ),
          ],
        ),
        pw.Divider(color: _primaryColor, thickness: 1.5),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('FundVance AI – confidential',
            style: pw.TextStyle(fontSize: 9, color: _textMuted)),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: _textMuted)),
      ],
    );
  }

  // ── Section Title ──────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Spending Card ──────────────────────────────────────────────────────────

  static pw.Widget _spendingCard(
    ReportData data,
    NumberFormat currency,
    NumberFormat currencyShort,
  ) {
    final days = data.periodEnd.difference(data.periodStart).inDays + 1;
    final daily = days > 0 ? data.totalSpending / days : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _statCol('Total Spent',
              currency.format(data.totalSpending), _errorColor),
          _statCol('Transactions',
              '${data.transactionCount}', _primaryColor),
          _statCol('Daily Average',
              currencyShort.format(daily), _textMuted),
        ],
      ),
    );
  }

  // ── Categories Section ─────────────────────────────────────────────────────

  static pw.Widget _categoriesSection(
      ReportData data, NumberFormat currency) {
    final sorted = data.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(8).toList();
    final grandTotal = sorted.fold(0.0, (s, e) => s + e.value);
    final maxVal =
        top.isNotEmpty ? top.first.value : 1.0;

    return pw.Column(
      children: top.map((entry) {
        final pct = grandTotal > 0 ? entry.value / grandTotal : 0.0;
        final barFlex = maxVal > 0
            ? ((entry.value / maxVal) * 100).round().clamp(1, 100)
            : 1;
        final remainFlex = (100 - barFlex).clamp(0, 99);

        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(entry.key,
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                    '${currency.format(entry.value)}  (${(pct * 100).toStringAsFixed(0)}%)',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: barFlex,
                    child: pw.Container(
                        height: 6,
                        decoration: const pw.BoxDecoration(
                          color: _primaryColor,
                          borderRadius: pw.BorderRadius.all(
                              pw.Radius.circular(3)),
                        )),
                  ),
                  if (remainFlex > 0)
                    pw.Expanded(
                      flex: remainFlex,
                      child: pw.Container(
                          height: 6,
                          color: PdfColors.grey200),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Daily Table ────────────────────────────────────────────────────────────

  static pw.Widget _dailyTable(ReportData data, NumberFormat currency) {
    final sorted = data.dailyTotals.entries.toList();
    final total = sorted.fold(0.0, (s, e) => s + e.value);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableCell('Date', header: true),
            _tableCell('Amount', header: true),
            _tableCell('% of Period', header: true),
          ],
        ),
        // Data rows
        ...sorted.map((e) {
          final pct = total > 0 ? e.value / total * 100 : 0.0;
          return pw.TableRow(children: [
            _tableCell(e.key.replaceAll('\n', ' ')),
            _tableCell(currency.format(e.value)),
            _tableCell('${pct.toStringAsFixed(0)}%'),
          ]);
        }),
        // Total row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableCell('Total', header: true),
            _tableCell(currency.format(total), header: true),
            _tableCell('100%', header: true),
          ],
        ),
      ],
    );
  }

  // ── Goals Card ─────────────────────────────────────────────────────────────

  static pw.Widget _goalsCard(ReportData data, NumberFormat currency) {
    final pct = data.totalGoalTarget > 0
        ? data.totalSaved / data.totalGoalTarget
        : 0.0;
    final barFlex = (pct.clamp(0.0, 1.0) * 100).round().clamp(0, 100);
    final remainFlex = (100 - barFlex).clamp(0, 100);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statCol('Active Goals', '${data.activeGoals}', _primaryColor),
              _statCol('Completed', '${data.completedGoals}', _successColor),
              _statCol('Total Saved', currency.format(data.totalSaved),
                  _primaryColor),
            ],
          ),
          if (data.totalGoalTarget > 0) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              '${(pct * 100).toStringAsFixed(0)}% of ${currency.format(data.totalGoalTarget)} target',
              style: pw.TextStyle(fontSize: 10, color: _textMuted),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                if (barFlex > 0)
                  pw.Expanded(
                    flex: barFlex,
                    child: pw.Container(
                        height: 8,
                        decoration: const pw.BoxDecoration(
                          color: _primaryColor,
                          borderRadius: pw.BorderRadius.all(
                              pw.Radius.circular(4)),
                        )),
                  ),
                if (remainFlex > 0)
                  pw.Expanded(
                    flex: remainFlex,
                    child: pw.Container(
                        height: 8,
                        color: PdfColors.grey200),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Debt Card ──────────────────────────────────────────────────────────────

  static pw.Widget _debtCard(ReportData data, NumberFormat currency) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _statCol('${data.activeDebts} debts',
              currency.format(data.totalDebtBalance), _errorColor),
          _statCol('Min/Month',
              currency.format(data.totalMinimumPayments), PdfColors.orange700),
          _statCol('Interest/Mo',
              currency.format(data.totalMonthlyInterest), PdfColors.deepOrange700),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static pw.Widget _statCol(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color),
        ),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: _textMuted),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: header
            ? pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)
            : const pw.TextStyle(fontSize: 10),
      ),
    );
  }
}
