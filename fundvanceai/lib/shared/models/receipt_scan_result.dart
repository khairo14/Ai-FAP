/// A single line item parsed from a receipt
class ReceiptItem {
  final String name;
  final double? price;

  const ReceiptItem({required this.name, this.price});
}

/// Result returned after scanning and parsing a receipt image
class ReceiptScanResult {
  /// Best-detected total amount (e.g. 23.50)
  final double? amount;

  /// Best-detected transaction date
  final DateTime? date;

  /// Merchant / store name (typically first prominent line)
  final String? merchant;

  /// Detected line items (name + optional price)
  final List<ReceiptItem> items;

  /// Full raw OCR text for reference / manual correction
  final String rawText;

  /// 0.0–1.0 confidence (based on how many fields were extracted)
  final double confidence;

  /// Suggested category name based on merchant/items (may be null)
  final String? suggestedCategoryName;

  const ReceiptScanResult({
    this.amount,
    this.date,
    this.merchant,
    this.items = const [],
    this.rawText = '',
    this.confidence = 0.0,
    this.suggestedCategoryName,
  });

  ReceiptScanResult copyWith({
    double? amount,
    DateTime? date,
    String? merchant,
    List<ReceiptItem>? items,
    String? rawText,
    double? confidence,
    String? suggestedCategoryName,
  }) {
    return ReceiptScanResult(
      amount: amount ?? this.amount,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      items: items ?? this.items,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      suggestedCategoryName:
          suggestedCategoryName ?? this.suggestedCategoryName,
    );
  }
}
