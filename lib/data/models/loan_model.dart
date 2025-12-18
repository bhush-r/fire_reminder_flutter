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
  final String paymentType;
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
    this.paymentType = "Cash",
    this.history = const [],
  });

  double get remainingAmount => totalAmount - paidAmount;

  /// Returns the payment progress as a value between 0.0 and 1.0
  double get progress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  bool get isPaid => paidAmount >= totalAmount;

  int get overdueDays {
    if (isPaid) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (today.isAfter(due)) {
      return today.difference(due).inDays;
    }
    return 0;
  }

  LoanStatus get calculatedStatus {
    if (isPaid) return LoanStatus.paid;
    if (overdueDays > 0) return LoanStatus.overdue;
    if (paidAmount > 0) return LoanStatus.partial;
    return LoanStatus.pending;
  }

  Loan copyWith({
    String? customerName,
    String? phone,
    double? principal,
    double? interestRate,
    double? totalAmount,
    double? paidAmount,
    DateTime? givenDate,
    DateTime? dueDate,
    LoanStatus? status,
    String? paymentType,
    List<TransactionLog>? history,
  }) {
    return Loan(
      id: id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      givenDate: givenDate ?? this.givenDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentType: paymentType ?? this.paymentType,
      history: history ?? this.history,
    );
  }
}