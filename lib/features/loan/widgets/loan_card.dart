import 'package:flutter/material.dart';
import '../../../data/models/loan_model.dart';
import '../../../data/models/loan_status.dart';
import '../loan_detail_screen.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;

  const LoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final pending = loan.totalAmount - loan.paidAmount;

    Color statusColor() {
      switch (loan.status) {
        case LoanStatus.paid:
          return Colors.green;
        case LoanStatus.overdue:
          return Colors.red;
        case LoanStatus.dueSoon:
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoanDetailScreen(loan: loan),
            ),
          );
        },
        title: Text(loan.customerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loan.phone),
            Text("Pending: ₹${pending.toStringAsFixed(2)}"),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            loan.status.name.toUpperCase(),
            style: TextStyle(
              color: statusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}