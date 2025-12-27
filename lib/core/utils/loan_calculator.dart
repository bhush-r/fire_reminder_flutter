import 'dart:math';
import '../../data/models/loan_model.dart';

class LoanCalculator {
  /// Standard EMI calculation using Reducing Balance method
  /// P = Principal, r = monthly interest rate (annual/12/100), n = months
  static double calculateEmi(double principal, double annualRate, int months) {
    if (annualRate == 0) return principal / months;
    double r = annualRate / 12 / 100;
    num powFactor = pow(1 + r, months);
    return (principal * r * powFactor) / (powFactor - 1);
  }

  static List<Emi> generateAmortizationSchedule({
    required double principal,
    required double annualRate,
    required DateTime startDate,
    required int tenureMonths,
  }) {
    List<Emi> schedule = [];
    double monthlyRate = annualRate / 12 / 100;
    double emiAmount = calculateEmi(principal, annualRate, tenureMonths);
    double remainingPrincipal = principal;

    for (int i = 1; i <= tenureMonths; i++) {
      double interestPart = remainingPrincipal * monthlyRate;
      double principalPart = emiAmount - interestPart;

      // Handle last EMI rounding
      if (i == tenureMonths) {
        emiAmount = remainingPrincipal + interestPart;
        principalPart = remainingPrincipal;
      }

      schedule.add(Emi(
        id: "emi_$i",
        dueDate: DateTime(startDate.year, startDate.month + i, startDate.day),
        emiAmount: emiAmount,
        principalPart: principalPart,
        interestPart: interestPart,
      ));

      remainingPrincipal -= principalPart;
    }

    return schedule;
  }

  static int daysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }
}