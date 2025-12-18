import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/loan_calculator.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_status.dart';
import '../../data/services/firebase_service.dart';

final loanControllerProvider =
StateNotifierProvider<LoanController, List<Loan>>(
      (ref) => LoanController(ref),
);

class LoanController extends StateNotifier<List<Loan>> {
  final Ref ref;
  StreamSubscription? _sub;

  LoanController(this.ref) : super([]) {
    _listenToLoans();
  }

  void _listenToLoans() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sub?.cancel();
    _sub = FirebaseService.listenLoans(user.uid).listen(
          (loans) => state = loans,
    );
  }

  Future<void> saveLoan({
    String? existingId,
    required String name,
    required String phone,
    required double principal,
    required double rate,
    required DateTime givenDate,
    required DateTime dueDate,
    required String paymentType,
  }) async {
    // Removed unused 'months' variable

    final total =
    calculateTotalAmount(
      principal: principal,
      ratePerMonth: rate,
      givenDate: givenDate,
      dueDate: dueDate,
    );

    final loan = Loan(
      id: existingId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseService.saveLoan(user.uid, loan);
  }

  Future<void> recordPayment(String loanId, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final loan = state.firstWhere((l) => l.id == loanId);
    final newPaid = loan.paidAmount + amount;

    final updated = loan.copyWith(
      paidAmount: newPaid,
      status: newPaid >= loan.totalAmount
          ? LoanStatus.paid
          : LoanStatus.partial,
    );

    await FirebaseService.saveLoan(user.uid, updated);
  }

  Future<void> deleteLoan(String loanId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseService.deleteLoan(user.uid, loanId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}