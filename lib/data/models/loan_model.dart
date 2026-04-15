import 'loan_status.dart';

/// Added partiallyPaid to support bank-grade partial recovery
enum EmiStatus { upcoming, due, overdue, partiallyPaid, paid }

class Emi {
  final String id;
  final DateTime dueDate;
  final double emiAmount;
  final double principalPart;
  final double interestPart;
  final bool isPaid;
  final double paidAmount; // Added: Track exactly how much of this EMI is recovered
  final DateTime? paidOn;
  final double penalty;

  Emi({
    required this.id,
    required this.dueDate,
    required this.emiAmount,
    required this.principalPart,
    required this.interestPart,
    this.isPaid = false,
    this.paidAmount = 0.0, // Default to zero
    this.paidOn,
    this.penalty = 0.0,
  });

  /// Smart status getter: Priority is given to payment status, then date-based status
  EmiStatus get status {
    if (isPaid || paidAmount >= (emiAmount - 0.01)) return EmiStatus.paid;
    if (paidAmount > 0) return EmiStatus.partiallyPaid;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (today.isAfter(due)) return EmiStatus.overdue;
    if (today.isAtSameMomentAs(due)) return EmiStatus.due;
    return EmiStatus.upcoming;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'dueDate': dueDate.toIso8601String(),
    'emiAmount': emiAmount,
    'principalPart': principalPart,
    'interestPart': interestPart,
    'isPaid': isPaid,
    'paidAmount': paidAmount, // Persist paid amount
    'paidOn': paidOn?.toIso8601String(),
    'penalty': penalty,
  };

  factory Emi.fromMap(Map<String, dynamic> map) => Emi(
    id: map['id'],
    dueDate: DateTime.parse(map['dueDate']),
    emiAmount: (map['emiAmount'] as num).toDouble(),
    principalPart: (map['principalPart'] as num).toDouble(),
    interestPart: (map['interestPart'] as num).toDouble(),
    isPaid: map['isPaid'] ?? false,
    paidAmount: (map['paidAmount'] as num? ?? 0.0).toDouble(),
    paidOn: map['paidOn'] != null ? DateTime.parse(map['paidOn']) : null,
    penalty: (map['penalty'] as num? ?? 0.0).toDouble(),
  );

  Emi copyWith({bool? isPaid, double? paidAmount, DateTime? paidOn, double? penalty}) {
    return Emi(
      id: id,
      dueDate: dueDate,
      emiAmount: emiAmount,
      principalPart: principalPart,
      interestPart: interestPart,
      isPaid: isPaid ?? this.isPaid,
      paidAmount: paidAmount ?? this.paidAmount,
      paidOn: paidOn ?? this.paidOn,
      penalty: penalty ?? this.penalty,
    );
  }
}

class TransactionLog {
  final String id;
  final double amount;
  final DateTime date;
  final String? emiId;
  final String type; // Added: 'emiPayment' or 'manualPayment'
  final String? remarks; // Added: For custom payment notes

  TransactionLog({
    required this.id,
    required this.amount,
    required this.date,
    this.emiId,
    this.type = 'emiPayment',
    this.remarks,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'emiId': emiId,
    'type': type,
    'remarks': remarks,
  };

  factory TransactionLog.fromMap(Map<String, dynamic> map) => TransactionLog(
    id: map['id'],
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date']),
    emiId: map['emiId'],
    type: map['type'] ?? 'emiPayment',
    remarks: map['remarks'],
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
  final double outstandingAmount;
  final DateTime givenDate;
  final DateTime dueDate;
  final LoanStatus status;
  final String paymentType;
  final List<TransactionLog> history;
  final List<Emi> emis;

  Loan({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.principal,
    required this.interestRate,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.givenDate,
    required this.dueDate,
    required this.status,
    this.paymentType = "Cash",
    this.history = const [],
    this.emis = const [],
  });

  double get remainingTotal => totalAmount - paidAmount;

  Emi? get nextEmi {
    try {
      return emis.firstWhere((e) => !e.isPaid);
    } catch (_) {
      return null;
    }
  }

  double get progress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  bool get isPaid => paidAmount >= (totalAmount - 0.01);

  int get overdueDays {
    if (isPaid) return 0;
    final overdueEmis = emis.where((e) => e.status == EmiStatus.overdue);
    if (overdueEmis.isEmpty) return 0;

    final oldestDue = overdueEmis.map((e) => e.dueDate).reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(oldestDue).inDays;
  }

  LoanStatus get calculatedStatus {
    if (isPaid) return LoanStatus.paid;
    if (emis.any((e) => e.status == EmiStatus.overdue)) return LoanStatus.overdue;
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
    double? outstandingAmount,
    DateTime? givenDate,
    DateTime? dueDate,
    LoanStatus? status,
    String? paymentType,
    List<TransactionLog>? history,
    List<Emi>? emis,
  }) {
    return Loan(
      id: id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      givenDate: givenDate ?? this.givenDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentType: paymentType ?? this.paymentType,
      history: history ?? this.history,
      emis: emis ?? this.emis,
    );
  }
}