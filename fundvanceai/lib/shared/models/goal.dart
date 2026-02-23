import 'package:flutter/material.dart';

enum GoalType {
  savings,
  debtPayoff,
  purchase,
  emergencyFund,
  investment;

  String get label {
    switch (this) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.debtPayoff:
        return 'Debt Payoff';
      case GoalType.purchase:
        return 'Purchase';
      case GoalType.emergencyFund:
        return 'Emergency Fund';
      case GoalType.investment:
        return 'Investment';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalType.savings:
        return Icons.savings_outlined;
      case GoalType.debtPayoff:
        return Icons.credit_card_off_outlined;
      case GoalType.purchase:
        return Icons.shopping_bag_outlined;
      case GoalType.emergencyFund:
        return Icons.health_and_safety_outlined;
      case GoalType.investment:
        return Icons.trending_up;
    }
  }

  static GoalType fromString(String s) {
    switch (s) {
      case 'debt_payoff':
        return GoalType.debtPayoff;
      case 'purchase':
        return GoalType.purchase;
      case 'emergency_fund':
        return GoalType.emergencyFund;
      case 'investment':
        return GoalType.investment;
      default:
        return GoalType.savings;
    }
  }

  String get dbValue {
    switch (this) {
      case GoalType.savings:
        return 'savings';
      case GoalType.debtPayoff:
        return 'debt_payoff';
      case GoalType.purchase:
        return 'purchase';
      case GoalType.emergencyFund:
        return 'emergency_fund';
      case GoalType.investment:
        return 'investment';
    }
  }
}

class Goal {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final GoalType goalType;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime? targetDate;
  final String? icon;
  final String? color;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.goalType,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    this.targetDate,
    this.icon,
    this.color,
    required this.isCompleted,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  /// Days remaining to target date (null if no target date set).
  int? get daysRemaining {
    if (targetDate == null) return null;
    final diff = targetDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Required daily saving rate to reach goal by target date.
  double? get requiredDailySaving {
    final days = daysRemaining;
    if (days == null || days <= 0) return null;
    return remainingAmount / days;
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      goalType: GoalType.fromString(json['goal_type'] as String? ?? 'savings'),
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'goal_type': goalType.dbValue,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'currency': currency,
        'target_date': targetDate?.toIso8601String().split('T')[0],
        'icon': icon,
        'color': color,
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  Goal copyWith({
    String? title,
    String? description,
    GoalType? goalType,
    double? targetAmount,
    double? currentAmount,
    String? currency,
    DateTime? targetDate,
    String? icon,
    String? color,
    bool? isCompleted,
    DateTime? completedAt,
    String? notes,
  }) {
    return Goal(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currency: currency ?? this.currency,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

class GoalContribution {
  final String id;
  final String goalId;
  final String userId;
  final double amount;
  final String? notes;
  final String? accountId;
  final DateTime contributedAt;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    this.notes,
    this.accountId,
    required this.contributedAt,
  });

  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    return GoalContribution(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      accountId: json['account_id'] as String?,
      contributedAt: DateTime.parse(json['contributed_at'] as String),
    );
  }
}
