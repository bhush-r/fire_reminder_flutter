package com.example.fire_reminder_flutter.features.loan;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_status.dart';

final loanControllerProvider =
    StateNotifierProvider<LoanController, List<Loan>>(
        (ref) => LoanController());

class LoanController extends StateNotifier<List<Loan>> {
  LoanController() : super([]);

  void saveLoan({
    String? existingId,
    required String name,
    required String phone,
    required double principal,
    required double rate,
    required DateTime givenDate,
    required DateTime dueDate,
    required String paymentType,
  }) {
    final total = calculate(principal, rate, givenDate, dueDate);

    final loan = Loan(
      id: existingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: name,
      phone: phone,
      principal: principal,
      interestRate: rate,
      totalAmount: total,
      paidAmount: 0,
      givenDate: givenDate,
      dueDate: dueDate,
      status: LoanStatus.pending,
    );

    if (existingId == null) {
      state = [...state, loan];
    } else {
      state = [
        for (final l in state) if (l.id == existingId) loan else l
      ];
    }
  }

  double calculate(
      double principal, double rate, DateTime given, DateTime due) {
    final months =
        (due.year - given.year) * 12 + (due.month - given.month);
    return principal + (principal * rate / 100 * months);
  }

  void recordPayment(String loanId, double amount) {
  state = [
    for (final l in state)
      if (l.id == loanId)
        l.copyWith(
          paidAmount: l.paidAmount + amount,
          status: (l.paidAmount + amount) >= l.totalAmount
              ? LoanStatus.paid
              : LoanStatus.partial,
        )
      else
        l
  ];
}

void deleteLoan(String loanId) {
  state = state.where((l) => l.id != loanId).toList();
}

}
