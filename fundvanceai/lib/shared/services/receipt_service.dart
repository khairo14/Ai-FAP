import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/receipt_scan_result.dart';
import 'auto_categorization_service.dart';

/// Handles receipt image capture, OCR, and text parsing
class ReceiptService {
  final _picker = ImagePicker();
  late final TextRecognizer _recognizer;

  ReceiptService() {
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Pick image from camera and process it
  Future<ReceiptScanResult?> scanFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file == null) return null;
    return _processFile(file);
  }

  /// Pick image from gallery and process it
  Future<ReceiptScanResult?> scanFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return null;
    return _processFile(file);
  }

  Future<ReceiptScanResult?> _processFile(XFile file) async {
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final recognized = await _recognizer.processImage(inputImage);
      final raw = recognized.text;
      if (raw.isEmpty) return null;
      final result = _parseText(raw);
      // Delete temp file
      try {
        await File(file.path).delete();
      } catch (_) {}
      return result;
    } catch (e) {
      return null;
    }
  }

  ReceiptScanResult _parseText(String raw) {
    final lines =
        raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final amount = _extractTotal(raw, lines);
    final date = _extractDate(raw);
    final merchant = _extractMerchant(lines);
    final items = _extractItems(lines);

    // Confidence: 1 point each for amount, date, merchant; max 1.0
    int hits = 0;
    if (amount != null) hits++;
    if (date != null) hits++;
    if (merchant != null) hits++;
    final confidence = hits / 3.0;

    final suggestedCategory =
        AutoCategorizationService.suggestFromMerchant(merchant ?? '') ??
            AutoCategorizationService.suggestFromItems(
                items.map((i) => i.name).toList());

    return ReceiptScanResult(
      amount: amount,
      date: date,
      merchant: merchant,
      items: items,
      rawText: raw,
      confidence: confidence,
      suggestedCategoryName: suggestedCategory,
    );
  }

  // ── Amount extraction ───────────────────────────────────────────────────────

  double? _extractTotal(String raw, List<String> lines) {
    // Pattern priority: "TOTAL", "AMOUNT DUE", "GRAND TOTAL", "SUBTOTAL"
    final priorityPatterns = [
      RegExp(r'(?:grand\s+)?total[:\s]*\$?\s*(\d{1,6}[.,]\d{2})',
          caseSensitive: false),
      RegExp(r'amount\s+due[:\s]*\$?\s*(\d{1,6}[.,]\d{2})',
          caseSensitive: false),
      RegExp(r'balance\s+due[:\s]*\$?\s*(\d{1,6}[.,]\d{2})',
          caseSensitive: false),
      RegExp(r'total\s+amount[:\s]*\$?\s*(\d{1,6}[.,]\d{2})',
          caseSensitive: false),
    ];

    for (final pattern in priorityPatterns) {
      final match = pattern.firstMatch(raw);
      if (match != null) {
        final cleaned = match.group(1)!.replaceAll(',', '.');
        return double.tryParse(cleaned);
      }
    }

    // Fallback: collect all dollar amounts; pick the largest that looks like a total
    final amountPattern =
        RegExp(r'\$?\s*(\d{1,6}[.,]\d{2})(?!\d)', caseSensitive: false);
    final amounts = amountPattern
        .allMatches(raw)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
        .whereType<double>()
        .toList();

    if (amounts.isEmpty) return null;

    // Sort descending — the largest amount is likely the total
    amounts.sort((a, b) => b.compareTo(a));
    return amounts.first;
  }

  // ── Date extraction ─────────────────────────────────────────────────────────

  DateTime? _extractDate(String raw) {
    final patterns = [
      // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'\b(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})\b'),
      // YYYY-MM-DD
      RegExp(r'\b(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})\b'),
      // DD MMM YYYY / MMM DD, YYYY
      RegExp(
          r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,]+(\d{4})\b',
          caseSensitive: false),
      RegExp(
          r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s.]+(\d{1,2})[\s,]+(\d{4})\b',
          caseSensitive: false),
    ];

    final monthMap = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    for (final p in patterns) {
      final match = p.firstMatch(raw);
      if (match == null) continue;

      try {
        // YYYY-MM-DD
        if (p.pattern.startsWith(r'\b(\d{4})')) {
          final y = int.parse(match.group(1)!);
          final m = int.parse(match.group(2)!);
          final d = int.parse(match.group(3)!);
          if (_validDate(y, m, d)) return DateTime(y, m, d);
        }
        // DD MMM YYYY
        else if (p.pattern.contains(r'(\d{1,2})\s+(Jan')) {
          final d = int.parse(match.group(1)!);
          final m = monthMap[match.group(2)!.toLowerCase().substring(0, 3)]!;
          final y = int.parse(match.group(3)!);
          if (_validDate(y, m, d)) return DateTime(y, m, d);
        }
        // MMM DD, YYYY
        else if (p.pattern.contains(r'(Jan|Feb')) {
          final m = monthMap[match.group(1)!.toLowerCase().substring(0, 3)]!;
          final d = int.parse(match.group(2)!);
          final y = int.parse(match.group(3)!);
          if (_validDate(y, m, d)) return DateTime(y, m, d);
        }
        // MM/DD/YYYY — try both orderings
        else {
          final a = int.parse(match.group(1)!);
          final b = int.parse(match.group(2)!);
          final y = int.parse(match.group(3)!);
          // Prefer MM/DD if a <= 12, else try DD/MM
          if (a <= 12 && _validDate(y, a, b)) return DateTime(y, a, b);
          if (b <= 12 && _validDate(y, b, a)) return DateTime(y, b, a);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  bool _validDate(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return false;
    if (y < 2000 || y > 2030) return false;
    return true;
  }

  // ── Merchant extraction ─────────────────────────────────────────────────────

  String? _extractMerchant(List<String> lines) {
    // Skip common receipt header junk; take first meaningful string
    final skip = RegExp(
        r'^\d|receipt|invoice|tax|welcome|thank|visit|www\.|http|tel:|phone|no\.|#|[:=]',
        caseSensitive: false);

    for (final line in lines.take(6)) {
      if (line.length < 3) continue;
      if (skip.hasMatch(line)) continue;
      // Skip lines that are mostly numbers/punctuation
      final alpha = line.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (alpha.length < 3) continue;
      return _titleCase(line.trim());
    }
    return null;
  }

  // ── Item extraction ─────────────────────────────────────────────────────────

  List<ReceiptItem> _extractItems(List<String> lines) {
    final itemPattern = RegExp(r'^(.+?)\s+[\$£€]?\s*(\d+[.,]\d{2})\s*$');
    final items = <ReceiptItem>[];
    final skipWords =
        RegExp(r'\btotal\b|\btax\b|\bsubtotal\b|\bdiscount\b|\bcash\b|\bchange\b|\bdue\b',
            caseSensitive: false);

    for (final line in lines) {
      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        if (name.length < 2 || skipWords.hasMatch(name)) continue;
        final price =
            double.tryParse(match.group(2)!.replaceAll(',', '.'));
        items.add(ReceiptItem(name: _titleCase(name), price: price));
      }
    }
    return items.take(20).toList(); // Cap at 20 items
  }

  String _titleCase(String s) =>
      s.toLowerCase().replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());

  void dispose() {
    _recognizer.close();
  }
}
