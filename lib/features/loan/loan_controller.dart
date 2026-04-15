import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/loan_calculator.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_status.dart';
import '../../data/services/firebase_service.dart';
import '../auth/auth_controller.dart';

final loanControllerProvider =
StateNotifierProvider<LoanController, List<Loan>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final user = auth.valueOrNull; // User? (null during loading/error)
  return LoanController(ref: ref, user: user);
});

class LoanController extends StateNotifier<List<Loan>> {
  LoanController({
    required this.ref,
    required User? user,
  })  : _user = user,
        super(const []) {
    _syncSubscription();
  }

  final Ref ref;
  User? _user;

  StreamSubscription<List<Loan>>? _sub;

  void _syncSubscription() {
    _sub?.cancel();
    _sub = null;
    state = const [];

    final user = _user;
    if (user == null) return;

    _sub = FirebaseService.listenLoans(user.uid).listen((loans) {
      state = loans;
    });
  }

  /// If your UI rebuilds providers when auth changes, this controller will be recreated.
  /// But if you later convert this to keepAlive, this method is still useful.
  void updateUser(User? user) {
    if (_user?.uid == user?.uid) return;
    _user = user;
    _syncSubscription();
  }

  /// SMART MANUAL PAYMENT ENGINE
  /// Implements FIFO (First In First Out) allocation logic
  /// Sequence: Overdue -> Due -> Upcoming -> Principal Reduction
  Future<void> recordManualPayment({
    required Loan loan,
    required double amount,
    String? remarks,
  }) async {
    final user = _user;
    if (user == null || amount <= 0 || loan.isPaid) return;

    double remainingToAllocate = amount;
    final updatedEmis = List<Emi>.from(loan.emis);

    // 1. Allocate to existing EMIs based on chronological order (FIFO)
    for (int i = 0; i < updatedEmis.length; i++) {
      if (remainingToAllocate <= 0) break;

      final emi = updatedEmis[i];
      if (emi.isPaid) continue;

      // Calculate how much this specific EMI still needs
      final emiRemainingBalance = emi.emiAmount - emi.paidAmount;

      // NOTE: math.min returns num => convert to double to avoid type issues
      final allocationToThisEmi =
      math.min(remainingToAllocate, emiRemainingBalance).toDouble();

      final newPaidAmountForEmi = emi.paidAmount + allocationToThisEmi;

      updatedEmis[i] = emi.copyWith(
        paidAmount: newPaidAmountForEmi,
        // EMI is fully paid if the balance hits zero
        isPaid: newPaidAmountForEmi >= (emi.emiAmount - 0.01),
        paidOn: DateTime.now(),
      );

      remainingToAllocate -= allocationToThisEmi;
    }

    // 2. Principal Reduction Logic
    // If money remains after all EMIs are cleared, it goes straight to Principal
    final principalReduction = remainingToAllocate;

    // NOTE: math.max returns num => convert to double to avoid type issues
    final newOutstanding =
    math.max(0, loan.outstandingAmount - principalReduction).toDouble();

    // 3. Create Audit Trail
    final log = TransactionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: DateTime.now(),
      type: 'manualPayment',
      remarks: remarks ?? "Manual payment received",
    );

    final newTotalPaid = loan.paidAmount + amount;

    // 4. Lifecycle Management
    // A loan is closed if Total Paid matches Total Amount OR Principal is zero
    final isFullySettled =
        newTotalPaid >= (loan.totalAmount - 0.01) || newOutstanding <= 0.01;

    final updatedLoan = loan.copyWith(
      paidAmount: newTotalPaid,
      outstandingAmount: newOutstanding,
      emis: updatedEmis,
      history: [...loan.history, log],
      status: isFullySettled ? LoanStatus.paid : LoanStatus.partial,
    );

    await FirebaseService.saveLoan(user.uid, updatedLoan);
  }

  /// Keeps compatibility with "Mark Paid" button on specific EMIs
  Future<void> payEmi(String loanId, String emiId) async {
    final user = _user;
    if (user == null) return;

    final loan = state.firstWhere((l) => l.id == loanId);
    final emi = loan.emis.firstWhere((e) => e.id == emiId);

    if (emi.isPaid) return;

    // We use the smart engine to pay exactly what's needed for this EMI
    await recordManualPayment(
      loan: loan,
      amount: (emi.emiAmount - emi.paidAmount).toDouble(),
      remarks: "Direct EMI payment: ${emi.id}",
    );
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
    final user = _user;
    if (user == null) return;

    final principalD = principal.toDouble();
    final rateD = rate.toDouble();

    final emis = LoanCalculator.generateAmortizationSchedule(
      principal: principalD,
      annualRate: rateD,
      startDate: givenDate,
      tenureMonths: tenureMonths,
    );

    final totalAmount = emis.fold<double>(
      0.0,
          (sum, e) => sum + e.emiAmount.toDouble(),
    );
    final finalDueDate = emis.last.dueDate;

    final loanId =
        existingId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final loan = Loan(
      id: loanId,
      customerName: name,
      phone: phone,
      principal: principalD,
      interestRate: rateD,
      totalAmount: totalAmount,
      paidAmount: 0.0,
      outstandingAmount: principalD,
      givenDate: givenDate,
      dueDate: finalDueDate,
      status: LoanStatus.pending,
      paymentType: paymentType,
      emis: emis,
    );

    await FirebaseService.saveLoan(user.uid, loan);
  }

  Future<void> deleteLoan(String loanId) async {
    final user = _user;
    if (user == null) return;
    await FirebaseService.deleteLoan(user.uid, loanId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}