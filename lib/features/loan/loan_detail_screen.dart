package com.example.fire_reminder_flutter.features.loan;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/loan_calculator.dart';
import '../../core/utils/whatsapp_util.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_status.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/pdf_export_service.dart';
import 'loan_controller.dart';
import 'add_loan_screen.dart';

class LoanDetailScreen extends ConsumerWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = loan.totalAmount - loan.paidAmount;
    final daysRemaining = LoanCalculator.daysRemaining(loan.dueDate);

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

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddLoanScreen(existingLoan: loan),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 SUMMARY
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Pending ₹${pending.toStringAsFixed(2)}",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(loan.status.name.toUpperCase()),
                      backgroundColor: statusColor().withOpacity(0.15),
                      labelStyle:
                          TextStyle(color: statusColor(), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysRemaining < 0
                          ? "${-daysRemaining} days overdue"
                          : "Due in $daysRemaining days",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 📞 ACTIONS
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text("Call"),
                    onPressed: () => WhatsAppUtil.call(loan.phone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text("WhatsApp"),
                    onPressed: () => WhatsAppUtil.sendReminder(
                      phone: loan.phone,
                      name: loan.customerName,
                      pending: pending,
                      daysRemaining: daysRemaining,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 📤 EXPORT
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ExcelExportService.exportSingleLoan(context, loan);
                    },
                    child: const Text("Export Excel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      PdfExportService.exportSingleLoan(context, loan);
                    },
                    child: const Text("Export PDF"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 📋 DETAILS
            _detail("Phone", loan.phone),
            _detail("Principal", "₹${loan.principal}"),
            _detail("Interest", "${loan.interestRate}% / month"),
            _detail("Total Amount", "₹${loan.totalAmount}"),
            _detail("Paid", "₹${loan.paidAmount}"),
            _detail("Given Date", _fmt(loan.givenDate)),
            _detail("Due Date", _fmt(loan.dueDate)),

            const SizedBox(height: 24),

            // 💰 RECORD PAYMENT
            if (pending > 0)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _showPaymentDialog(context, ref, pending),
                  child: const Text("Record Payment"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => "${d.day}-${d.month}-${d.year}";

  Widget _detail(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Loan"),
        content: const Text("Are you sure you want to delete this loan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              ref.read(loanControllerProvider.notifier).deleteLoan(loan.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, double pending) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Record Payment"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text);
              if (amt != null && amt > 0 && amt <= pending) {
                ref
                    .read(loanControllerProvider.notifier)
                    .recordPayment(loan.id, amt);
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
