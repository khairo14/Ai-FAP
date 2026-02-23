import 'dart:math';
import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/shared/models/debt.dart';

/// Result of a snowball or avalanche payoff simulation.
class PayoffSimulation {
  final String strategy; // 'snowball' | 'avalanche'
  final int totalMonths;
  final double totalInterestPaid;
  final double totalPaid;
  final List<PayoffOrder> order;

  const PayoffSimulation({
    required this.strategy,
    required this.totalMonths,
    required this.totalInterestPaid,
    required this.totalPaid,
    required this.order,
  });
}

class PayoffOrder {
  final String debtName;
  final double balance;
  final double interestRate;
  final int monthsToPayoff;
  final double interestPaid;

  const PayoffOrder({
    required this.debtName,
    required this.balance,
    required this.interestRate,
    required this.monthsToPayoff,
    required this.interestPaid,
  });
}

class DebtService {
  final _supabase = SupabaseConfig.client;

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<Debt>> getDebts({bool includeCompleted = false}) async {
    final List<Map<String, dynamic>> result;
    if (includeCompleted) {
      result = await _supabase
          .from('debts')
          .select()
          .eq('user_id', _userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);
    } else {
      result = await _supabase
          .from('debts')
          .select()
          .eq('user_id', _userId)
          .filter('deleted_at', 'is', null)
          .eq('is_paid_off', false)
          .order('created_at', ascending: false);
    }
    return result.map(Debt.fromJson).toList();
  }

  Future<Debt> createDebt({
    required String name,
    String? description,
    required DebtType debtType,
    required double totalAmount,
    required double currentBalance,
    required double interestRate,
    required double minimumPayment,
    int? paymentDueDay,
    String currency = 'USD',
    String? icon,
    String? color,
    String? notes,
  }) async {
    final data = {
      'user_id': _userId,
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
      'notes': notes,
    };
    final result = await _supabase.from('debts').insert(data).select().single();
    return Debt.fromJson(result);
  }

  Future<Debt> updateDebt({
    required String id,
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
    String? notes,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (debtType != null) data['debt_type'] = debtType.dbValue;
    if (totalAmount != null) data['total_amount'] = totalAmount;
    if (currentBalance != null) data['current_balance'] = currentBalance;
    if (interestRate != null) data['interest_rate'] = interestRate;
    if (minimumPayment != null) data['minimum_payment'] = minimumPayment;
    if (paymentDueDay != null) data['payment_due_day'] = paymentDueDay;
    if (currency != null) data['currency'] = currency;
    if (icon != null) data['icon'] = icon;
    if (color != null) data['color'] = color;
    if (notes != null) data['notes'] = notes;

    final result = await _supabase
        .from('debts')
        .update(data)
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    return Debt.fromJson(result);
  }

  Future<void> deleteDebt(String id) async {
    await _supabase
        .from('debts')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<DebtPayment> recordPayment({
    required String debtId,
    required double amount,
    String? notes,
    String? accountId,
    DateTime? paidAt,
  }) async {
    final data = <String, dynamic>{
      'debt_id': debtId,
      'user_id': _userId,
      'amount': amount,
      'notes': notes,
      'paid_at': (paidAt ?? DateTime.now()).toIso8601String(),
      if (accountId != null) 'account_id': accountId,
    };
    final result =
        await _supabase.from('debt_payments').insert(data).select().single();
    // Debit the source account for this payment
    if (accountId != null) {
      await _supabase.rpc('update_account_balance', params: {
        'account_id': accountId,
        'amount_change': amount,
        'operation': 'subtract',
      });
    }
    return DebtPayment.fromJson(result);
  }

  Future<List<DebtPayment>> getPayments(String debtId) async {
    final result = await _supabase
        .from('debt_payments')
        .select()
        .eq('debt_id', debtId)
        .eq('user_id', _userId)
        .order('paid_at', ascending: false)
        .limit(50);
    return result.map(DebtPayment.fromJson).toList();
  }

  Future<Debt?> refreshDebt(String id) async {
    final result = await _supabase
        .from('debts')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (result == null) return null;
    return Debt.fromJson(result);
  }

  // ── Snowball / Avalanche Simulation ───────────────────────────────────────

  /// Simulate payoff using extra monthly payment distributed across debts.
  ///
  /// Snowball: pay minimums on all, put extras toward smallest balance first.
  /// Avalanche: pay minimums on all, put extras toward highest interest first.
  PayoffSimulation simulate({
    required List<Debt> debts,
    required double extraMonthlyPayment,
    required String strategy, // 'snowball' | 'avalanche'
  }) {
    if (debts.isEmpty) {
      return PayoffSimulation(
          strategy: strategy,
          totalMonths: 0,
          totalInterestPaid: 0,
          totalPaid: 0,
          order: []);
    }

    // Deep-copy balances for simulation
    final balances = debts.map((d) => d.currentBalance).toList();
    final rates = debts.map((d) => d.interestRate / 100 / 12).toList();
    final mins = debts.map((d) => d.minimumPayment).toList();
    final names = debts.map((d) => d.name).toList();
    final paid = List<bool>.filled(debts.length, false);
    final monthsPaid = List<int>.filled(debts.length, 0);
    final interestPaid = List<double>.filled(debts.length, 0.0);
    double totalInterest = 0;
    double totalPaidAmt = 0;
    int totalMonths = 0;

    // Sort order for extra payment
    final indices = List.generate(debts.length, (i) => i);
    if (strategy == 'snowball') {
      indices.sort((a, b) => balances[a].compareTo(balances[b]));
    } else {
      indices.sort((a, b) => rates[b].compareTo(rates[a]));
    }

    for (int month = 0; month < 600; month++) {
      // Apply interest
      for (int i = 0; i < debts.length; i++) {
        if (!paid[i]) {
          final interest = balances[i] * rates[i];
          balances[i] += interest;
          interestPaid[i] += interest;
          totalInterest += interest;
        }
      }

      // Apply minimum payments
      double leftover = extraMonthlyPayment;
      for (int i = 0; i < debts.length; i++) {
        if (!paid[i]) {
          final payment = min(mins[i], balances[i]);
          balances[i] -= payment;
          totalPaidAmt += payment;
          if (balances[i] <= 0.01) {
            paid[i] = true;
            monthsPaid[i] = month + 1;
            balances[i] = 0;
          }
        }
      }

      // Apply extra to priority debt
      for (final idx in indices) {
        if (!paid[idx] && leftover > 0) {
          final payment = min(leftover, balances[idx]);
          balances[idx] -= payment;
          totalPaidAmt += payment;
          leftover -= payment;
          if (balances[idx] <= 0.01) {
            paid[idx] = true;
            monthsPaid[idx] = month + 1;
            balances[idx] = 0;
          }
        }
      }

      if (paid.every((p) => p)) {
        totalMonths = month + 1;
        break;
      }
    }

    final order = List.generate(
      debts.length,
      (i) => PayoffOrder(
        debtName: names[i],
        balance: debts[i].currentBalance,
        interestRate: debts[i].interestRate,
        monthsToPayoff: monthsPaid[i],
        interestPaid: interestPaid[i],
      ),
    );
    order.sort((a, b) => a.monthsToPayoff.compareTo(b.monthsToPayoff));

    return PayoffSimulation(
      strategy: strategy,
      totalMonths: totalMonths,
      totalInterestPaid: totalInterest,
      totalPaid: totalPaidAmt,
      order: order,
    );
  }
}
