import 'loan_status.dart';

class TransactionLog {
  final String id;
  final double amount;
  final DateTime date;

  TransactionLog({
    required this.id,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory TransactionLog.fromMap(Map<String, dynamic> map) => TransactionLog(
    id: map['id'],
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date']),
  );
}

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
  final List<TransactionLog> history;

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
    this.history = const [],
  });

  Loan copyWith({
    double? paidAmount,
    LoanStatus? status,
    List<TransactionLog>? history,
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
      history: history ?? this.history,
    );
  }
}