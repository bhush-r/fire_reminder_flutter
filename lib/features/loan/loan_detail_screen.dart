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
    final theme = Theme.of(context);

    // Watch the latest state of this specific loan from the controller
    final latestLoans = ref.watch(loanControllerProvider);
    final currentLoan = latestLoans.firstWhere(
            (l) => l.id == loan.id,
        orElse: () => loan
    );

    final status = currentLoan.calculatedStatus;
    final color = _getStatusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Statement"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddLoanScreen(existingLoan: currentLoan))
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, ref, currentLoan),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // 1️⃣ FIXED BOTTOM BUTTON
      // Hidden automatically if the loan is CLOSED (PAID)
      bottomNavigationBar: currentLoan.status != LoanStatus.paid
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: FilledButton.icon(
            onPressed: () => _showManualPaymentDialog(context, ref, currentLoan),
            icon: const Icon(Icons.payments_outlined),
            label: const Text("Record Manual Payment", style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(theme, currentLoan, status, color),
            const SizedBox(height: 24),
            _buildBalanceCard(theme, currentLoan),
            const SizedBox(height: 24),
            _buildActionRow(theme, currentLoan),
            const SizedBox(height: 32),
            _buildEmiSchedule(theme, ref, currentLoan),

            // Show transaction history if any payments exist
            if (currentLoan.history.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildTransactionHistory(theme, currentLoan),
            ],

            const SizedBox(height: 40),
            _buildExportSection(context, currentLoan),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 2️⃣ PAYMENT DIALOG & 3️⃣ VALIDATION
  void _showManualPaymentDialog(BuildContext context, WidgetRef ref, Loan loan) {
    final amountController = TextEditingController();
    final remarkController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Manual Payment"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Amount will be allocated to overdue EMIs first, then principal.",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Payment Amount (₹)",
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                  hintText: "Enter amount",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter an amount";
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return "Enter a valid positive amount";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remarkController,
                decoration: const InputDecoration(
                  labelText: "Remark (Optional)",
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  hintText: "Cash / UPI / Agent Name",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          // 4️⃣ ACTION ON SAVE
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);

                // Call the Smart Allocation Logic from Controller
                await ref.read(loanControllerProvider.notifier).recordManualPayment(
                  loan: loan,
                  amount: amount,
                  remarks: remarkController.text.trim().isEmpty ? null : remarkController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Payment recorded and allocated successfully"),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text("Save Payment"),
          ),
        ],
      ),
    );
  }

  // --- REUSED UI COMPONENTS (UNCHANGED LOGIC) ---

  Widget _buildProfileHeader(ThemeData theme, Loan loan, LoanStatus status, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            loan.customerName[0].toUpperCase(),
            style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Text(loan.customerName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(loan.phone, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(ThemeData theme, Loan loan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text("OUTSTANDING PRINCIPAL", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text("₹${loan.outstandingAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white24, height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Total Paid", "₹${loan.paidAmount.toInt()}"),
              _statItem("Remaining", "₹${loan.remainingTotal.toInt()}"),
              _statItem("Status", loan.status.name.toUpperCase()),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildActionRow(ThemeData theme, Loan loan) {
    return Row(
      children: [
        Expanded(child: _actionBtn(Icons.phone_in_talk_rounded, "Call", AppColors.info, () => WhatsAppUtil.call(loan.phone))),
        const SizedBox(width: 16),
        Expanded(child: _actionBtn(Icons.message_rounded, "Remind", AppColors.success, () => WhatsAppUtil.sendReminder(phone: loan.phone, name: loan.customerName, pending: loan.remainingTotal, daysRemaining: loan.overdueDays))),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(children: [Icon(icon, color: color), const SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))]),
      ),
    );
  }

  Widget _buildEmiSchedule(ThemeData theme, WidgetRef ref, Loan loan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("REPAYMENT SCHEDULE", style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: loan.emis.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final emi = loan.emis[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: emi.isPaid ? AppColors.success.withOpacity(0.2) : theme.dividerColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: (emi.isPaid ? AppColors.success : AppColors.primary).withOpacity(0.1), child: Text("${index + 1}", style: TextStyle(color: emi.isPaid ? AppColors.success : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(emi.dueDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(emi.status.name.toUpperCase(), style: TextStyle(fontSize: 10, color: _getStatusColor(loan.status), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text("₹${emi.emiAmount.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionHistory(ThemeData theme, Loan loan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("TRANSACTION HISTORY", style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...loan.history.reversed.take(5).map((tx) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_edu_rounded, color: AppColors.primary),
          title: Text("Received ₹${tx.amount.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(DateFormat('dd MMM, hh:mm a').format(tx.date)),
          trailing: tx.remarks != null ? Text(tx.remarks!, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)) : null,
        )),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context, Loan loan) {
    return Row(
      children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => ExcelExportService.exportSingleLoan(context, loan), icon: const Icon(Icons.table_rows_rounded), label: const Text("Excel"))),
        const SizedBox(width: 12),
        Expanded(child: OutlinedButton.icon(onPressed: () => PdfExportService.exportSingleLoan(context, loan), icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text("PDF"))),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Loan?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () { ref.read(loanControllerProvider.notifier).deleteLoan(loan.id); Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("Delete")),
        ],
      ),
    );
  }

  Color _getStatusColor(LoanStatus s) {
    switch (s) {
      case LoanStatus.paid: return AppColors.success;
      case LoanStatus.overdue: return AppColors.danger;
      case LoanStatus.partial: return AppColors.warning;
      default: return AppColors.primary;
    }
  }
}