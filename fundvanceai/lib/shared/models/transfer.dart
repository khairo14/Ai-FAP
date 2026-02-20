class Transfer {
  final String id;
  final String userId;
  final String? categoryId;
  final String fromAccountId;
  final String toAccountId;
  final double fromAmount;
  final String fromCurrency;
  final double toAmount;
  final String toCurrency;
  final double? exchangeRate;
  final String? exchangeRateSource;
  final bool isManualRate;
  final double transferFee;
  final String? feeCurrency;
  final String feeChargedTo;
  final String? feeDescription;
  final String? description;
  final DateTime transferDate;
  final String? referenceNumber;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Display fields (from joins)
  final String? fromAccountName;
  final String? toAccountName;

  Transfer({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.fromAmount,
    required this.fromCurrency,
    required this.toAmount,
    required this.toCurrency,
    this.exchangeRate,
    this.exchangeRateSource,
    this.isManualRate = false,
    this.transferFee = 0.0,
    this.feeCurrency,
    this.feeChargedTo = 'from',
    this.feeDescription,
    this.description,
    required this.transferDate,
    this.referenceNumber,
    this.status = 'completed',
    required this.createdAt,
    required this.updatedAt,
    this.fromAccountName,
    this.toAccountName,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    final fromAccount = json['from_account'] as Map<String, dynamic>?;
    final toAccount = json['to_account'] as Map<String, dynamic>?;
    return Transfer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      fromAccountId: json['from_account_id'] as String,
      toAccountId: json['to_account_id'] as String,
      fromAmount: (json['from_amount'] as num).toDouble(),
      fromCurrency: json['from_currency'] as String,
      toAmount: (json['to_amount'] as num).toDouble(),
      toCurrency: json['to_currency'] as String,
      exchangeRate: json['exchange_rate'] != null 
          ? (json['exchange_rate'] as num).toDouble() 
          : null,
      exchangeRateSource: json['exchange_rate_source'] as String?,
      isManualRate: json['is_manual_rate'] as bool? ?? false,
      transferFee: (json['transfer_fee'] as num?)?.toDouble() ?? 0.0,
      feeCurrency: json['fee_currency'] as String?,
      feeChargedTo: json['fee_charged_to'] as String? ?? 'from',
      feeDescription: json['fee_description'] as String?,
      description: json['description'] as String?,
      transferDate: DateTime.parse(json['transfer_date'] as String),
      referenceNumber: json['reference_number'] as String?,
      status: json['status'] as String? ?? 'completed',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fromAccountName: fromAccount?['name'] as String?,
      toAccountName: toAccount?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'from_amount': fromAmount,
      'from_currency': fromCurrency,
      'to_amount': toAmount,
      'to_currency': toCurrency,
      'exchange_rate': exchangeRate,
      'exchange_rate_source': exchangeRateSource,
      'is_manual_rate': isManualRate,
      'transfer_fee': transferFee,
      'fee_currency': feeCurrency,
      'fee_charged_to': feeChargedTo,
      'fee_description': feeDescription,
      'description': description,
      'transfer_date': transferDate.toIso8601String().split('T')[0],
      'reference_number': referenceNumber,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
