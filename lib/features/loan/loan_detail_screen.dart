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
    final latestLoans = ref.watch(loanControllerProvider);

    // Ensure we are working with the latest state of this loan from the provider
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
              "OUTSTANDING PRINCIPAL",
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)
          ),
          const SizedBox(height: 4),
          Text(
              "₹${loan.outstandingAmount.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Interest Rate", "${loan.interestRate}%"),
              _statItem("Total Paid", "₹${loan.paidAmount.toInt()}"),
              _statItem("Tenure", "${loan.emis.length} Mo"),
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
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildActionRow(ThemeData theme, Loan loan) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
              theme,
              Icons.phone_in_talk_rounded,
              "Call",
              AppColors.info,
                  () => WhatsAppUtil.call(loan.phone)
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionButton(
              theme,
              Icons.message_rounded,
              "Remind",
              AppColors.success,
                  () => WhatsAppUtil.sendReminder(
                  phone: loan.phone,
                  name: loan.customerName,
                  pending: loan.remainingTotal,
                  daysRemaining: loan.overdueDays
              )
          ),
        ),
      ],
    );
  }

  Widget _actionButton(ThemeData theme, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmiSchedule(ThemeData theme, WidgetRef ref, Loan loan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                "REPAYMENT SCHEDULE",
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
            Text(
                "${loan.emis.where((e) => e.isPaid).length}/${loan.emis.length} Paid",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: loan.emis.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final emi = loan.emis[index];
            final statusColor = _getEmiStatusColor(emi.status);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: emi.isPaid
                        ? AppColors.success.withOpacity(0.2)
                        : theme.colorScheme.outlineVariant.withOpacity(0.5)
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (emi.isPaid ? AppColors.success : AppColors.primary).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                          "${index + 1}",
                          style: TextStyle(
                              color: emi.isPaid ? AppColors.success : AppColors.primary,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            DateFormat('dd MMMM yyyy').format(emi.dueDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                        const SizedBox(height: 2),
                        _statusBadge(emi.status.name, statusColor),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          "₹${emi.emiAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: emi.isPaid ? AppColors.success : AppColors.textPrimary
                          )
                      ),
                      if (!emi.isPaid)
                        TextButton(
                          onPressed: () => _confirmEmiPayment(context, ref, loan.id, emi),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text("Mark Paid", style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
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
        Text(
            "RECENT TRANSACTIONS",
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)
        ),
        const SizedBox(height: 16),
        ...loan.history.reversed.take(5).map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.success,
              radius: 18,
              child: Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 18),
            ),
            title: const Text("Payment Received", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(DateFormat('dd MMM, hh:mm a').format(tx.date), style: const TextStyle(fontSize: 12)),
            trailing: Text(
                "+ ₹${tx.amount.toInt()}",
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context, Loan loan) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ExcelExportService.exportSingleLoan(context, loan),
            icon: const Icon(Icons.table_rows_rounded, size: 18),
            label: const Text("Excel"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => PdfExportService.exportSingleLoan(context, loan),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text("PDF"),
          ),
        ),
      ],
    );
  }

  void _confirmEmiPayment(BuildContext context, WidgetRef ref, String loanId, Emi emi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record EMI Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Confirm payment for installment due on ${DateFormat('dd MMM yyyy').format(emi.dueDate)}."),
            const SizedBox(height: 12),
            Text("Amount: ₹${emi.emiAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              ref.read(loanControllerProvider.notifier).payEmi(loanId, emi.id);
              Navigator.pop(ctx);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Loan?"),
        content: const Text("This will permanently remove this loan record and all associated payment history. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(loanControllerProvider.notifier).deleteLoan(loan.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Delete Record"),
          ),
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

  Color _getEmiStatusColor(EmiStatus s) {
    switch (s) {
      case EmiStatus.paid: return AppColors.success;
      case EmiStatus.overdue: return AppColors.danger;
      case EmiStatus.due: return AppColors.warning;
      default: return AppColors.info;
    }
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
          label.toUpperCase(),
          style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)
      ),
    );
  }
}