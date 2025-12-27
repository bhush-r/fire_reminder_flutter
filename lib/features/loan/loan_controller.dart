import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/loan_calculator.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_status.dart';
import '../../data/services/firebase_service.dart';
import '../auth/auth_controller.dart';

final loanControllerProvider = StateNotifierProvider<LoanController, List<Loan>>((ref) {
  final user = ref.watch(authControllerProvider);
  return LoanController(ref, user);
});

class LoanController extends StateNotifier<List<Loan>> {
  final Ref ref;
  final User? user;
  StreamSubscription? _sub;

  LoanController(this.ref, this.user) : super([]) {
    if (user != null) _listenToLoans();
  }

  void _listenToLoans() {
    if (user == null) return;
    _sub?.cancel();
    _sub = FirebaseService.listenLoans(user!.uid).listen((loans) => state = loans);
  }

  Future<void> saveLoan({
    String? existingId,
    required String name,
    required String phone,
    required double principal,
    required double rate,
    required DateTime givenDate,
    required int tenureMonths,
    required String paymentType,
  }) async {
    if (user == null) return;

    final emis = LoanCalculator.generateAmortizationSchedule(
      principal: principal,
      annualRate: rate,
      startDate: givenDate,
      tenureMonths: tenureMonths,
    );

    final totalAmount = emis.fold<double>(0, (sum, e) => sum + e.emiAmount);
    final finalDueDate = emis.last.dueDate;

    final loanId = existingId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final loan = Loan(
      id: loanId,
      customerName: name,
      phone: phone,
      principal: principal,
      interestRate: rate,
      totalAmount: totalAmount,
      paidAmount: 0,
      outstandingAmount: principal,
      givenDate: givenDate,
      dueDate: finalDueDate,
      status: LoanStatus.pending,
      paymentType: paymentType,
      emis: emis,
    );

    await FirebaseService.saveLoan(user!.uid, loan);
  }

  Future<void> payEmi(String loanId, String emiId) async {
    if (user == null) return;
    final loan = state.firstWhere((l) => l.id == loanId);

    final updatedEmis = loan.emis.map((e) {
      if (e.id == emiId && !e.isPaid) {
        return e.copyWith(isPaid: true, paidOn: DateTime.now());
      }
      return e;
    }).toList();

    final paidEmi = loan.emis.firstWhere((e) => e.id == emiId);
    final newPaidAmount = loan.paidAmount + paidEmi.emiAmount;
    final newOutstanding = loan.outstandingAmount - paidEmi.principalPart;

    final log = TransactionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: paidEmi.emiAmount,
      date: DateTime.now(),
      emiId: emiId,
    );

    final updated = loan.copyWith(
      paidAmount: newPaidAmount,
      outstandingAmount: newOutstanding,
      emis: updatedEmis,
      history: [...loan.history, log],
      status: newPaidAmount >= (loan.totalAmount - 0.1) ? LoanStatus.paid : LoanStatus.partial,
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