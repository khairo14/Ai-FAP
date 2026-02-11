/// Expense model matching the expenses table in Supabase
class Expense {
  final String id;
  final String userId;
  final double amount;
  final String? categoryId;
  final String? merchant;
  final String? description;
  final DateTime date;
  final String? paymentMethod;
  final String? receiptUrl;
  final String? notes;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    this.categoryId,
    this.merchant,
    this.description,
    required this.date,
    this.paymentMethod,
    this.receiptUrl,
    this.notes,
    this.isRecurring = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Expense from JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['category_id'] as String?,
      merchant: json['merchant'] as String?,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['payment_method'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      notes: json['notes'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Expense to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'category_id': categoryId,
      'merchant': merchant,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // Date only (YYYY-MM-DD)
      'payment_method': paymentMethod,
      'receipt_url': receiptUrl,
      'notes': notes,
      'is_recurring': isRecurring,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? categoryId,
    String? merchant,
    String? description,
    DateTime? date,
    String? paymentMethod,
    String? receiptUrl,
    String? notes,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: \$$amount, merchant: $merchant, date: $date)';
  }
}
