/// Budget model matching the budgets table in Supabase
class Budget {
  final String id;
  final String userId;
  final String? categoryId;
  final double amount;
  final String period; // 'monthly', 'weekly', 'yearly'
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime? deletedAt;

  Budget({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.period,
    this.startDate,
    this.endDate,
    required this.createdAt,
    this.deletedAt,
  });

  /// Create Budget from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Convert Budget to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'period': period,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Check if this budget is currently active
  bool isActive() {
    final now = DateTime.now();
    if (startDate == null && endDate == null) return true;
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Get the period display name
  String get periodDisplay {
    switch (period.toLowerCase()) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return period;
    }
  }

  @override
  String toString() {
    return 'Budget(id: $id, amount: \$$amount, period: $period, category: $categoryId)';
  }
}
