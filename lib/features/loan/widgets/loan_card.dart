import 'package:flutter/material.dart';
import '../../../data/models/loan_model.dart';
import '../../../data/models/loan_status.dart';
import '../loan_detail_screen.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;

  const LoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final status = loan.calculatedStatus;

    Color statusColor() {
      switch (status) {
        case LoanStatus.paid:
          return Colors.green;
        case LoanStatus.overdue:
          return Colors.red;
        case LoanStatus.partial:
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
        title: Row(
          children: [
            Expanded(child: Text(loan.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (loan.overdueDays > 0)
              Text(
                "Overdue ${loan.overdueDays}d",
                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loan.phone, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _amountInfo("Total", loan.totalAmount),
                _amountInfo("Paid", loan.paidAmount),
                _amountInfo("Left", loan.remainingAmount, isBold: true),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: statusColor(),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountInfo(String label, double val, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          "₹${val.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}