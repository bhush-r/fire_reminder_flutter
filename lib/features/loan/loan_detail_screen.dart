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
        title: const Text("Statement"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddLoanScreen(existingLoan: currentLoan))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, ref, currentLoan),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileSection(theme, currentLoan, status, statusColor()),
            const SizedBox(height: 32),
            _buildBalanceCard(theme, pending, currentLoan),
            const SizedBox(height: 32),
            _buildActionRow(theme, currentLoan, pending, daysRemaining),
            const SizedBox(height: 32),
            _buildTimelineSection(theme, currentLoan),
            if (currentLoan.history.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildHistorySection(theme, currentLoan),
            ],
            const SizedBox(height: 40),
            _buildExportSection(context, currentLoan),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: pending > 0
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: () => _showPaymentDialog(context, ref, currentLoan, pending),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Record Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildProfileSection(ThemeData theme, Loan loan, LoanStatus status, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 4),
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              loan.customerName[0].toUpperCase(),
              style: theme.textTheme.headlineLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(loan.customerName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(loan.phone, style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            status.name.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(ThemeData theme, double pending, Loan loan) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 40, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text("OUTSTANDING BALANCE", style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text("₹${pending.toStringAsFixed(2)}", style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          Row(
            children: [
              _miniStat(theme, "Principal", "₹${loan.principal.toInt()}"),
              _verticalDivider(theme),
              _miniStat(theme, "Int. Rate", "${loan.interestRate}%"),
              _verticalDivider(theme),
              _miniStat(theme, "Payable", "₹${loan.totalAmount.toInt()}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(ThemeData theme, String label, String val) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(val, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _verticalDivider(ThemeData theme) => Container(height: 24, width: 1, color: theme.colorScheme.outlineVariant);

  Widget _buildActionRow(ThemeData theme, Loan loan, double pending, int days) {
    return Row(
      children: [
        _circleAction(theme, Icons.phone_rounded, "Call", AppColors.info, () => WhatsAppUtil.call(loan.phone)),
        const SizedBox(width: 16),
        _circleAction(theme, Icons.chat_bubble_rounded, "Notify", AppColors.success, () => WhatsAppUtil.sendReminder(phone: loan.phone, name: loan.customerName, pending: pending, daysRemaining: days)),
      ],
    );
  }

  Widget _circleAction(ThemeData theme, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme, Loan loan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _timelineRow(theme, Icons.calendar_month_rounded, "Agreement Date", DateFormat('dd MMM yyyy').format(loan.givenDate)),
          const Divider(height: 32),
          _timelineRow(theme, Icons.event_available_rounded, "Expiry Date", DateFormat('dd MMM yyyy').format(loan.dueDate)),
          const Divider(height: 32),
          _timelineRow(theme, Icons.payments_rounded, "Collection Mode", loan.paymentType),
        ],
      ),
    );
  }

  Widget _timelineRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHistorySection(ThemeData theme, Loan loan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("TRANSACTION LOG", style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: loan.history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = loan.history.reversed.toList()[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 16),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Installment Received", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd MMM, yyyy • hh:mm a').format(tx.date), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text("₹${tx.amount.toInt()}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.success)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context, Loan loan) {
    return Row(
      children: [
        Expanded(child: _exportBtn(context, Icons.description_rounded, "XLSX", () => ExcelExportService.exportSingleLoan(context, loan))),
        const SizedBox(width: 16),
        Expanded(child: _exportBtn(context, Icons.picture_as_pdf_rounded, "PDF", () => PdfExportService.exportSingleLoan(context, loan))),
      ],
    );
  }

  Widget _exportBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Record?"),
        content: const Text("This action will permanently delete all data related to this loan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(loanControllerProvider.notifier).deleteLoan(loan.id);
              Navigator.pop(ctx); Navigator.pop(context);
            },
            child: const Text("Delete Forever"),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, Loan loan, double pending) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Record Payment", style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("Outstanding: ₹${pending.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: "₹ ",
                hintText: "0.00",
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final amt = double.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9.]'), ''));
                  if (amt != null && amt > 0 && amt <= (pending + 0.01)) {
                    ref.read(loanControllerProvider.notifier).recordPayment(loan.id, amt);
                    Navigator.pop(ctx);
                  }
                },
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                child: const Text("Confirm & Log", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}