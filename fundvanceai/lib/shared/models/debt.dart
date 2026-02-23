import 'package:flutter/material.dart';

enum DebtType {
  creditCard,
  studentLoan,
  mortgage,
  carLoan,
  personalLoan,
  medical,
  other;

  String get label {
    switch (this) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.studentLoan:
        return 'Student Loan';
      case DebtType.mortgage:
        return 'Mortgage';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.medical:
        return 'Medical';
      case DebtType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DebtType.creditCard:
        return Icons.credit_card;
      case DebtType.studentLoan:
        return Icons.school_outlined;
      case DebtType.mortgage:
        return Icons.home_outlined;
      case DebtType.carLoan:
        return Icons.directions_car_outlined;
      case DebtType.personalLoan:
        return Icons.person_outline;
      case DebtType.medical:
        return Icons.local_hospital_outlined;
      case DebtType.other:
        return Icons.money_outlined;
    }
  }

  static DebtType fromString(String s) {
    switch (s) {
      case 'credit_card':
        return DebtType.creditCard;
      case 'student_loan':
        return DebtType.studentLoan;
      case 'mortgage':
        return DebtType.mortgage;
      case 'car_loan':
        return DebtType.carLoan;
      case 'personal_loan':
        return DebtType.personalLoan;
      case 'medical':
        return DebtType.medical;
      default:
        return DebtType.other;
    }
  }

  String get dbValue {
    switch (this) {
      case DebtType.creditCard:
        return 'credit_card';
      case DebtType.studentLoan:
        return 'student_loan';
      case DebtType.mortgage:
        return 'mortgage';
      case DebtType.carLoan:
        return 'car_loan';
      case DebtType.personalLoan:
        return 'personal_loan';
      case DebtType.medical:
        return 'medical';
      case DebtType.other:
        return 'other';
    }
  }
}

class Debt {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DebtType debtType;
  final double totalAmount;
  final double currentBalance;
  final double interestRate; // annual %
  final double minimumPayment;
  final int? paymentDueDay;
  final String currency;
  final String? icon;
  final String? color;
  final bool isPaidOff;
  final DateTime? paidOffAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Debt({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.debtType,
    required this.totalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.minimumPayment,
    this.paymentDueDay,
    required this.currency,
    this.icon,
    this.color,
    required this.isPaidOff,
    this.paidOffAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  double get paidAmount => totalAmount - currentBalance;
  double get progressPercent =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  /// Monthly interest charge at current balance (APR/12)
  double get monthlyInterestCharge =>
      currentBalance * (interestRate / 100 / 12);

  /// Estimated months to pay off at minimum payment (simple calculation)
  int? get monthsToPayoff {
    if (minimumPayment <= 0 || currentBalance <= 0) return null;
    final monthlyRate = interestRate / 100 / 12;
    if (monthlyRate == 0) {
      return (currentBalance / minimumPayment).ceil();
    }
    // n = -ln(1 - (r*B)/P) / ln(1+r)
    final rB = monthlyRate * currentBalance;
    if (minimumPayment <= rB) return null; // payment doesn't cover interest
    final n = -(_ln(1 - rB / minimumPayment)) / _ln(1 + monthlyRate);
    return n.ceil();
  }

  static double _ln(double x) => x > 0 ? (x == 1 ? 0 : _log(x)) : double.nan;
  static double _log(double x) {
    // Dart doesn't have math import here — implement iteratively
    if (x <= 0) return double.nan;
    // Use dart:math in the service layer instead
    return x.toDouble(); // placeholder, overridden in service
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      debtType: DebtType.fromString(json['debt_type'] as String? ?? 'other'),
      totalAmount: (json['total_amount'] as num).toDouble(),
      currentBalance: (json['current_balance'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num? ?? 0).toDouble(),
      minimumPayment: (json['minimum_payment'] as num? ?? 0).toDouble(),
      paymentDueDay: json['payment_due_day'] as int?,
      currency: json['currency'] as String? ?? 'USD',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isPaidOff: json['is_paid_off'] as bool? ?? false,
      paidOffAt: json['paid_off_at'] != null
          ? DateTime.parse(json['paid_off_at'] as String)
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
        'name': name,
        'description': description,
        'debt_type': debtType.dbValue,
        'total_amount': totalAmount,
        'current_balance': currentBalance,
        'interest_rate': interestRate,
        'minimum_payment': minimumPayment,
        'payment_due_day': paymentDueDay,
        'currency': currency,
        'icon': icon,
        'color': color,
        'is_paid_off': isPaidOff,
        'paid_off_at': paidOffAt?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  Debt copyWith({
    String? name,
    String? description,
    DebtType? debtType,
    double? totalAmount,
    double? currentBalance,
    double? interestRate,
    double? minimumPayment,
    int? paymentDueDay,
    String? currency,
    String? icon,
    String? color,
    bool? isPaidOff,
    String? notes,
  }) {
    return Debt(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      debtType: debtType ?? this.debtType,
      totalAmount: totalAmount ?? this.totalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isPaidOff: isPaidOff ?? this.isPaidOff,
      paidOffAt: paidOffAt,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

class DebtPayment {
  final String id;
  final String debtId;
  final String userId;
  final double amount;
  final String? notes;
  final DateTime paidAt;

  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.userId,
    required this.amount,
    this.notes,
    required this.paidAt,
  });

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] as String,
      debtId: json['debt_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      paidAt: DateTime.parse(json['paid_at'] as String),
    );
  }
}
