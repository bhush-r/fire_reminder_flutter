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
    // Use the latest data from state if available (prevents stale UI after recordPayment)
    final latestLoans = ref.watch(loanControllerProvider);
    final currentLoan = latestLoans.isEmpty
        ? loan
        : latestLoans.firstWhere((l) => l.id == loan.id, orElse: () => loan);

    final pending = currentLoan.remainingAmount;
    final daysRemaining = LoanCalculator.daysRemaining(currentLoan.dueDate);
    final status = currentLoan.calculatedStatus;

    Color statusColor() {
      switch (status) {
        case LoanStatus.paid: return AppColors.success;
        case LoanStatus.overdue: return AppColors.danger;
        case LoanStatus.partial: return AppColors.warning;
        default: return AppColors.primary;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddLoanScreen(existingLoan: currentLoan))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, ref, currentLoan),
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
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(currentLoan.customerName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(currentLoan.phone, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: statusColor().withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status.name.toUpperCase(), style: TextStyle(color: statusColor(), fontWeight: FontWeight.bold)),
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
                      _statItem("Principal", "₹${currentLoan.principal.toInt()}"),
                      _statItem("Interest", "${currentLoan.interestRate}%"),
                      _statItem("Total", "₹${currentLoan.totalAmount.toInt()}"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _actionBtn(icon: Icons.call, label: "Call", color: AppColors.info, onTap: () => WhatsAppUtil.call(currentLoan.phone))),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn(icon: Icons.chat_bubble_outline, label: "WhatsApp", color: AppColors.success, onTap: () => WhatsAppUtil.sendReminder(phone: currentLoan.phone, name: currentLoan.customerName, pending: pending, daysRemaining: daysRemaining))),
              ],
            ),
            const SizedBox(height: 24),

            if (currentLoan.history.isNotEmpty) ...[
              const Align(alignment: Alignment.centerLeft, child: Text("Payment History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentLoan.history.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = currentLoan.history.reversed.toList()[index];
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

            _infoTile(Icons.calendar_today_outlined, "Given Date", _fmt(currentLoan.givenDate)),
            _infoTile(Icons.event_note_outlined, "Due Date", _fmt(currentLoan.dueDate)),
            _infoTile(Icons.payment_outlined, "Payment Mode", currentLoan.paymentType),
            const SizedBox(height: 32),
            if (pending > 0)
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => _showPaymentDialog(context, ref, currentLoan, pending), child: const Text("Record Payment"))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => ExcelExportService.exportSingleLoan(context, currentLoan), icon: const Icon(Icons.table_view), label: const Text("Excel"))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(onPressed: () => PdfExportService.exportSingleLoan(context, currentLoan), icon: const Icon(Icons.picture_as_pdf), label: const Text("PDF"))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String val) => Column(children: [Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]);

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Icon(icon, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))])));

  Widget _infoTile(IconData icon, String label, String val) => ListTile(leading: Icon(icon, color: AppColors.textSecondary, size: 20), title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)), trailing: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)));

  String _fmt(DateTime d) => "${d.day}/${d.month}/${d.year}";

  void _confirmDelete(BuildContext context, WidgetRef ref, Loan currentLoan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Loan?"),
        content: const Text("Are you sure you want to delete this loan record?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () { ref.read(loanControllerProvider.notifier).deleteLoan(currentLoan.id); Navigator.pop(context); Navigator.pop(context); }, child: const Text("Delete")),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, Loan currentLoan, double pending) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Record Payment"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Amount (₹)",
            hintText: "Max: ₹${pending.toStringAsFixed(0)}",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(onPressed: () {
            final cleanedText = ctrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
            final amt = double.tryParse(cleanedText);
            if (amt != null && amt > 0 && amt <= (pending + 0.01)) {
              ref.read(loanControllerProvider.notifier).recordPayment(currentLoan.id, amt);
              Navigator.pop(context);
            }
          }, child: const Text("Confirm Payment")),
        ],
      ),
    );
  }
}