import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/loan_calculator.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_status.dart';
import '../../data/services/firebase_service.dart';
import '../auth/auth_controller.dart';

final loanControllerProvider =
StateNotifierProvider<LoanController, List<Loan>>(
      (ref) {
    final user = ref.watch(authControllerProvider);
    return LoanController(ref, user);
  },
);

class LoanController extends StateNotifier<List<Loan>> {
  final Ref ref;
  final User? user;
  StreamSubscription? _sub;

  LoanController(this.ref, this.user) : super([]) {
    if (user != null) {
      _listenToLoans();
    }
  }

  void _listenToLoans() {
    if (user == null) return;
    _sub?.cancel();
    _sub = FirebaseService.listenLoans(user!.uid).listen(
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
    if (user == null) return;

    final total = calculateTotalAmount(
      principal: principal,
      ratePerMonth: rate,
      givenDate: givenDate,
      dueDate: dueDate,
    );

    final loanId = existingId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final loan = Loan(
      id: loanId,
      customerName: name,
      phone: phone,
      principal: principal,
      interestRate: rate,
      totalAmount: total,
      paidAmount: 0,
      givenDate: givenDate,
      dueDate: dueDate,
      status: LoanStatus.pending,
      history: [],
    );

    await FirebaseService.saveLoan(user!.uid, loan);
  }

  Future<void> recordPayment(String loanId, double amount) async {
    if (user == null) return;

    final loan = state.firstWhere((l) => l.id == loanId);
    final newPaid = loan.paidAmount + amount;

    final log = TransactionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: DateTime.now(),
    );

    final updatedHistory = List<TransactionLog>.from(loan.history)..add(log);

    final updated = loan.copyWith(
      paidAmount: newPaid,
      history: updatedHistory,
      status: newPaid >= loan.totalAmount
          ? LoanStatus.paid
          : LoanStatus.partial,
    );

    await FirebaseService.saveLoan(user!.uid, updated);
  }

  Future<void> deleteLoan(String loanId) async {
    if (user == null) return;
    await FirebaseService.deleteLoan(user!.uid, loanId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}