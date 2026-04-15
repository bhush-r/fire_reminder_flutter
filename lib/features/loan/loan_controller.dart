import 'dart:async';
import 'dart:math' as math;
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

  /// SMART MANUAL PAYMENT ENGINE
  /// Implements FIFO (First In First Out) allocation logic
  /// Sequence: Overdue -> Due -> Upcoming -> Principal Reduction
  Future<void> recordManualPayment({
    required Loan loan,
    required double amount,
    String? remarks,
  }) async {
    if (user == null || amount <= 0 || loan.isPaid) return;

    double remainingToAllocate = amount;
    List<Emi> updatedEmis = List.from(loan.emis);

    // 1. Allocate to existing EMIs based on chronological order (FIFO)
    for (int i = 0; i < updatedEmis.length; i++) {
      if (remainingToAllocate <= 0) break;

      Emi emi = updatedEmis[i];
      if (emi.isPaid) continue;

      // Calculate how much this specific EMI still needs
      double emiRemainingBalance = emi.emiAmount - emi.paidAmount;
      double allocationToThisEmi = math.min(remainingToAllocate, emiRemainingBalance);

      double newPaidAmountForEmi = emi.paidAmount + allocationToThisEmi;

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
    double principalReduction = remainingToAllocate;
    double newOutstanding = math.max(0, loan.outstandingAmount - principalReduction);

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
    final isFullySettled = newTotalPaid >= (loan.totalAmount - 0.01) || newOutstanding <= 0.01;

    final updatedLoan = loan.copyWith(
      paidAmount: newTotalPaid,
      outstandingAmount: newOutstanding,
      emis: updatedEmis,
      history: [...loan.history, log],
      status: isFullySettled ? LoanStatus.paid : LoanStatus.partial,
    );

    await FirebaseService.saveLoan(user!.uid, updatedLoan);
  }

  /// Keeps compatibility with "Mark Paid" button on specific EMIs
  Future<void> payEmi(String loanId, String emiId) async {
    if (user == null) return;
    final loan = state.firstWhere((l) => l.id == loanId);
    final emi = loan.emis.firstWhere((e) => e.id == emiId);

    if (emi.isPaid) return;

    // We use the smart engine to pay exactly what's needed for this EMI
    await recordManualPayment(
        loan: loan,
        amount: emi.emiAmount - emi.paidAmount,
        remarks: "Direct EMI payment: ${emi.id}"
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