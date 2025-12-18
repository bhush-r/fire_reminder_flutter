import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import '../models/loan_status.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;

  // Updated to match your actual Firebase Project ID from firebase_options.dart
  static const String _appId = 'fireapp-94831';

  // Path strategy as per environment mandatory rules
  static CollectionReference _getLoanCollection(String uid) {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .collection('loans');
  }

  static Stream<List<Loan>> listenLoans(String uid) {
    // Ensuring we have a valid UID before listening
    return _getLoanCollection(uid)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map((doc) => _fromDoc(doc)).toList(),
    );
  }

  static Future<void> saveLoan(String uid, Loan loan) async {
    try {
      await _getLoanCollection(uid)
          .doc(loan.id)
          .set(_toMap(loan));
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteLoan(String uid, String loanId) async {
    try {
      await _getLoanCollection(uid)
          .doc(loanId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  static Loan _fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Loan(
      id: doc.id,
      customerName: d['name'] ?? 'Unknown',
      phone: d['phone'] ?? '',
      principal: (d['principal'] ?? 0.0).toDouble(),
      interestRate: (d['rate'] ?? 0.0).toDouble(),
      totalAmount: (d['total'] ?? 0.0).toDouble(),
      paidAmount: (d['paid'] ?? 0.0).toDouble(),
      givenDate: d['givenDate'] != null
          ? (d['givenDate'] as Timestamp).toDate()
          : DateTime.now(),
      dueDate: d['dueDate'] != null
          ? (d['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      status: LoanStatus.values.byName(d['status'] ?? 'pending'),
    );
  }

  static Map<String, dynamic> _toMap(Loan l) => {
    'name': l.customerName,
    'phone': l.phone,
    'principal': l.principal,
    'rate': l.interestRate,
    'total': l.totalAmount,
    'paid': l.paidAmount,
    'givenDate': Timestamp.fromDate(l.givenDate),
    'dueDate': Timestamp.fromDate(l.dueDate),
    'status': l.status.name,
  };
}