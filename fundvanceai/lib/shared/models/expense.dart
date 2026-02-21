/// Expense model matching the expenses table in Supabase
class Expense {
  final String id;
  final String userId;
  final double amount;
  final String? categoryId;
  final String? accountId; // New field for account integration
  final String? merchant;
  final String? description;
  final DateTime date;
  final String? paymentMethod;
  final String? receiptUrl;
  final String? notes;
  final bool isRecurring;
  final String? recurringFrequency;  // daily, weekly, bi-weekly, monthly, yearly
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  
  // Display fields (populated from joins)
  final String? currency;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? accountName;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    this.categoryId,
    this.accountId, // New field
    this.merchant,
    this.description,
    required this.date,
    this.paymentMethod,
    this.receiptUrl,
    this.notes,
    this.isRecurring = false,
    this.recurringFrequency,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    // Display fields
    this.currency,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.accountName,
  });

  /// Create Expense from JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    // Extract nested data from joins
    final accountData = json['accounts'] as Map<String, dynamic>?;
    final categoryData = json['expense_categories'] as Map<String, dynamic>?;
    
    return Expense(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['category_id'] as String?,
      accountId: json['account_id'] as String?, // New field
      merchant: json['merchant'] as String?,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      paymentMethod: json['payment_method'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      notes: json['notes'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringFrequency: json['recurring_frequency'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      // Display fields from joins
      currency: accountData?['currency'] as String?,
      categoryName: categoryData?['name'] as String?,
      categoryIcon: categoryData?['icon'] as String?,
      categoryColor: categoryData?['color'] as String?,
      accountName: accountData?['name'] as String?,
    );
  }

  /// Convert Expense to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'category_id': categoryId,
      'account_id': accountId, // New field
      'merchant': merchant,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // Date only (YYYY-MM-DD)
      'payment_method': paymentMethod,
      'receipt_url': receiptUrl,
      'notes': notes,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Get display name (merchant or description or fallback)
  String get displayName {
    if (merchant != null && merchant!.isNotEmpty) return merchant!;
    if (description != null && description!.isNotEmpty) return description!;
    return categoryName ?? 'Expense';
  }
  
  /// Create a copy with updated fields
  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? categoryId,
    String? accountId, // New field
    String? merchant,
    String? description,
    DateTime? date,
    String? paymentMethod,
    String? receiptUrl,
    String? notes,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? currency,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? accountName,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId, // New field
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      // Display fields
      currency: currency ?? this.currency,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      accountName: accountName ?? this.accountName,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: \$$amount, merchant: $merchant, date: $date)';
  }
}
