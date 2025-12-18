import 'loan_status.dart';

class Loan {
  final String id;
  final String customerName;
  final String phone;
  final double principal;
  final double interestRate;
  final double totalAmount;
  final double paidAmount;
  final DateTime givenDate;
  final DateTime dueDate;
  final LoanStatus status;

  Loan({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.principal,
    required this.interestRate,
    required this.totalAmount,
    required this.paidAmount,
    required this.givenDate,
    required this.dueDate,
    required this.status,
  });

  Loan copyWith({
    double? paidAmount,
    LoanStatus? status,
  }) {
    return Loan(
      id: id,
      customerName: customerName,
      phone: phone,
      principal: principal,
      interestRate: interestRate,
      totalAmount: totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      givenDate: givenDate,
      dueDate: dueDate,
      status: status ?? this.status,
    );
  }
}
