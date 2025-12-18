import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/loan_calculator.dart';
import '../../core/utils/whatsapp_util.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_status.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/pdf_export_service.dart';
import '../../core/theme/app_colors.dart';
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
        case LoanStatus.paid: return AppColors.success;
        case LoanStatus.overdue: return AppColors.danger;
        case LoanStatus.dueSoon: return AppColors.warning;
        default: return AppColors.primary;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddLoanScreen(existingLoan: loan))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(loan.customerName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(loan.phone, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: statusColor().withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(loan.status.name.toUpperCase(), style: TextStyle(color: statusColor(), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  const Text("Dues Remaining", style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text("₹${pending.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem("Principal", "₹${loan.principal.toInt()}"),
                      _statItem("Interest", "${loan.interestRate}%"),
                      _statItem("Total", "₹${loan.totalAmount.toInt()}"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _actionBtn(icon: Icons.call, label: "Call", color: AppColors.info, onTap: () => WhatsAppUtil.call(loan.phone))),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn(icon: Icons.chat_bubble_outline, label: "WhatsApp", color: AppColors.success, onTap: () => WhatsAppUtil.sendReminder(phone: loan.phone, name: loan.customerName, pending: pending, daysRemaining: daysRemaining))),
              ],
            ),
            const SizedBox(height: 24),

            // PAYMENT HISTORY SECTION
            if (loan.history.isNotEmpty) ...[
              const Align(alignment: Alignment.centerLeft, child: Text("Payment History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loan.history.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = loan.history.reversed.toList()[index];
                    return ListTile(
                      leading: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      title: Text("Received ₹${tx.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.date)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            _infoTile(Icons.calendar_today_outlined, "Given Date", _fmt(loan.givenDate)),
            _infoTile(Icons.event_note_outlined, "Due Date", _fmt(loan.dueDate)),
            const SizedBox(height: 32),
            if (pending > 0)
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => _showPaymentDialog(context, ref, pending), child: const Text("Record Payment"))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => ExcelExportService.exportSingleLoan(context, loan), icon: const Icon(Icons.table_view), label: const Text("Excel"))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(onPressed: () => PdfExportService.exportSingleLoan(context, loan), icon: const Icon(Icons.picture_as_pdf), label: const Text("PDF"))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String val) => Column(children: [Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]);

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(icon, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))])));

  Widget _infoTile(IconData icon, String label, String val) => ListTile(leading: Icon(icon, color: AppColors.textSecondary, size: 20), title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)), trailing: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)));

  String _fmt(DateTime d) => "${d.day}/${d.month}/${d.year}";

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Loan?"),
        content: const Text("Kya aap waqai is loan ko delete karna chahte hain?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () { ref.read(loanControllerProvider.notifier).deleteLoan(loan.id); Navigator.pop(context); Navigator.pop(context); }, child: const Text("Delete")),
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
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (₹)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(onPressed: () { final amt = double.tryParse(ctrl.text); if (amt != null && amt > 0 && amt <= pending) { ref.read(loanControllerProvider.notifier).recordPayment(loan.id, amt); Navigator.pop(context); } }, child: const Text("Confirm Payment")),
        ],
      ),
    );
  }
}