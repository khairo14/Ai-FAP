/// Income model matching the income table in Supabase
class Income {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String currency;
  final String? description;
  final DateTime incomeDate;
  
  // Tax fields
  final String? taxType;
  final double? taxPercentage;
  final double? taxFixedAmount;
  final double? taxCalculated;
  final double netAmount;
  
  // Recurrence fields
  final Map<String, dynamic>? sourceDetails;
  final bool isRecurring;
  final String? recurrencePattern;
  final DateTime? nextOccurrence;
  
  // Audit fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  
  // Account link
  final String? accountId;

  // Display fields (from joins)
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  Income({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.currency,
    this.description,
    required this.incomeDate,
    this.taxType,
    this.taxPercentage,
    this.taxFixedAmount,
    this.taxCalculated,
    required this.netAmount,
    this.sourceDetails,
    this.isRecurring = false,
    this.recurrencePattern,
    this.nextOccurrence,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.accountId,
    // Display fields
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  /// Create Income from JSON
  factory Income.fromJson(Map<String, dynamic> json) {
    // Extract nested data from joins
    final categoryData = json['income_categories'] as Map<String, dynamic>?;
    
    return Income(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String?,
      incomeDate: DateTime.parse(json['income_date'] as String),
      taxType: json['tax_type'] as String?,
      taxPercentage: json['tax_percentage'] != null 
          ? (json['tax_percentage'] as num).toDouble() 
          : null,
      taxFixedAmount: json['tax_fixed_amount'] != null 
          ? (json['tax_fixed_amount'] as num).toDouble() 
          : null,
      taxCalculated: json['tax_calculated'] != null 
          ? (json['tax_calculated'] as num).toDouble() 
          : null,
      netAmount: (json['net_amount'] as num).toDouble(),
      sourceDetails: json['source_details'] as Map<String, dynamic>?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as String?,
      nextOccurrence: json['next_occurrence'] != null
          ? DateTime.parse(json['next_occurrence'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      accountId: json['account_id'] as String?,
      // Display fields from joins
      categoryName: categoryData?['name'] as String?,
      categoryIcon: categoryData?['icon'] as String?,
      categoryColor: categoryData?['color'] as String?,
    );
  }

  /// Convert Income to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'income_date': incomeDate.toIso8601String().split('T')[0],
      'tax_type': taxType,
      'tax_percentage': taxPercentage,
      'tax_fixed_amount': taxFixedAmount,
      'tax_calculated': taxCalculated,
      'net_amount': netAmount,
      'source_details': sourceDetails,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'next_occurrence': nextOccurrence?.toIso8601String().split('T')[0],
      'account_id': accountId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Income copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? currency,
    String? description,
    DateTime? incomeDate,
    String? taxType,
    double? taxPercentage,
    double? taxFixedAmount,
    double? taxCalculated,
    double? netAmount,
    Map<String, dynamic>? sourceDetails,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? nextOccurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? accountId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      incomeDate: incomeDate ?? this.incomeDate,
      taxType: taxType ?? this.taxType,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxFixedAmount: taxFixedAmount ?? this.taxFixedAmount,
      taxCalculated: taxCalculated ?? this.taxCalculated,
      netAmount: netAmount ?? this.netAmount,
      sourceDetails: sourceDetails ?? this.sourceDetails,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      accountId: accountId ?? this.accountId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  @override
  String toString() {
    return 'Income(id: $id, amount: $amount, category: $categoryName, date: $incomeDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Income && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Income category model
class IncomeCategory {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final bool isActive;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  IncomeCategory({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    this.isActive = true,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory IncomeCategory.fromJson(Map<String, dynamic> json) {
    return IncomeCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'money',
      color: json['color'] as String? ?? '#4CAF50',
      isActive: json['is_active'] as bool? ?? true,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'is_system': isSystem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
