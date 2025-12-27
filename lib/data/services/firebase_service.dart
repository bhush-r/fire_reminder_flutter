import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import '../models/loan_status.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;
  static const String _appId = 'fireapp-94831';

  static CollectionReference _getLoanCollection(String uid) {
    return _db.collection('artifacts').doc(_appId).collection('users').doc(uid).collection('loans');
  }

  static Stream<List<Loan>> listenLoans(String uid) {
    return _getLoanCollection(uid).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => _fromDoc(doc)).toList(),
    );
  }

  static Future<void> saveLoan(String uid, Loan loan) async {
    await _getLoanCollection(uid).doc(loan.id).set(_toMap(loan));
  }

  static Future<void> deleteLoan(String uid, String loanId) async {
    await _getLoanCollection(uid).doc(loanId).delete();
  }

  static Loan _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final history = (d['history'] as List? ?? [])
        .map((h) => TransactionLog.fromMap(h as Map<String, dynamic>))
        .toList();

    final emis = (d['emis'] as List? ?? [])
        .map((e) => Emi.fromMap(e as Map<String, dynamic>))
        .toList();

    return Loan(
      id: doc.id,
      customerName: d['name'] ?? 'Unknown',
      phone: d['phone'] ?? '',
      principal: (d['principal'] ?? 0.0).toDouble(),
      interestRate: (d['rate'] ?? 0.0).toDouble(),
      totalAmount: (d['total'] ?? 0.0).toDouble(),
      paidAmount: (d['paid'] ?? 0.0).toDouble(),
      outstandingAmount: (d['outstanding'] ?? d['total'] ?? 0.0).toDouble(), // Fallback for old data
      givenDate: (d['givenDate'] as Timestamp).toDate(),
      dueDate: (d['dueDate'] as Timestamp).toDate(),
      status: LoanStatus.values.byName(d['status'] ?? 'pending'),
      paymentType: d['paymentType'] ?? 'Cash',
      history: history,
      emis: emis,
    );
  }

  static Map<String, dynamic> _toMap(Loan l) => {
    'name': l.customerName,
    'phone': l.phone,
    'principal': l.principal,
    'rate': l.interestRate,
    'total': l.totalAmount,
    'paid': l.paidAmount,
    'outstanding': l.outstandingAmount,
    'givenDate': Timestamp.fromDate(l.givenDate),
    'dueDate': Timestamp.fromDate(l.dueDate),
    'status': l.status.name,
    'paymentType': l.paymentType,
    'history': l.history.map((h) => h.toMap()).toList(),
    'emis': l.emis.map((e) => e.toMap()).toList(),
  };
}