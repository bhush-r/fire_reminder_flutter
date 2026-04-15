import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/whatsapp_util.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/loan_status.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/pdf_export_service.dart';
import 'add_loan_screen.dart';
import 'loan_controller.dart';

class LoanDetailScreen extends ConsumerWidget {
  final Loan loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Watch latest state
    final latestLoans = ref.watch(loanControllerProvider);
    final currentLoan = latestLoans.firstWhere(
          (l) => l.id == loan.id,
      orElse: () => loan,
    );

    final status = currentLoan.calculatedStatus;
    final accent = _getStatusColor(status);

    return Scaffold(
      // Bottom pay button
      bottomNavigationBar: currentLoan.status != LoanStatus.paid
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: FilledButton.icon(
            onPressed: () =>
                _showManualPaymentDialog(context, ref, currentLoan),
            icon: const Icon(Icons.payments_outlined),
            label: const Text(
              "Record Manual Payment",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      )
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            title: const Text("Loan Statement"),
            actions: [
              IconButton(
                tooltip: "Edit",
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddLoanScreen(existingLoan: currentLoan),
                  ),
                ),
              ),
              IconButton(
                tooltip: "Delete",
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
                onPressed: () => _confirmDelete(context, ref, currentLoan),
              ),
              const SizedBox(width: 6),
            ],
          ),

          // Header card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _HeaderCard(
                loan: currentLoan,
                status: status,
                accent: accent,
                currency: currency,
              ),
            ),
          ),

          // Actions row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.phone_in_talk_rounded,
                      label: "Call",
                      color: AppColors.info,
                      onTap: () => WhatsAppUtil.call(currentLoan.phone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.message_rounded,
                      label: "Remind",
                      color: AppColors.success,
                      onTap: () => WhatsAppUtil.sendReminder(
                        phone: currentLoan.phone,
                        name: currentLoan.customerName,
                        pending: currentLoan.remainingTotal,
                        daysRemaining: currentLoan.overdueDays,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // EMI schedule
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Text(
                "Repayment schedule",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.separated(
              itemCount: currentLoan.emis.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final emi = currentLoan.emis[index];
                return _EmiTile(
                  index: index,
                  emi: emi,
                  currency: currency,
                  accent: accent,
                );
              },
            ),
          ),

          // History (last 5)
          if (currentLoan.history.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Text(
                  "Recent transactions",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _TransactionList(
                  loan: currentLoan,
                  currency: currency,
                ),
              ),
            ),
          ],

          // Export
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ExcelExportService.exportSingleLoan(context, currentLoan),
                      icon: const Icon(Icons.table_rows_rounded),
                      label: const Text("Excel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          PdfExportService.exportSingleLoan(context, currentLoan),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text("PDF"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
        ],
      ),
    );
  }

  // Manual payment dialog (kept same logic, cleaner UI)
  void _showManualPaymentDialog(BuildContext context, WidgetRef ref, Loan loan) {
    final amountController = TextEditingController();
    final remarkController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record manual payment"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Amount will be allocated to overdue EMIs first, then principal.",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
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
                  if (value == null || value.isEmpty) {
                    return "Please enter an amount";
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return "Enter a valid positive amount";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final amount = double.parse(amountController.text);

              await ref.read(loanControllerProvider.notifier).recordManualPayment(
                loan: loan,
                amount: amount,
                remarks: remarkController.text.trim().isEmpty
                    ? null
                    : remarkController.text.trim(),
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
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete loan?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(loanControllerProvider.notifier).deleteLoan(loan.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
  Color _getStatusColor(LoanStatus s) {
    switch (s) {
      case LoanStatus.paid:
        return AppColors.success;
      case LoanStatus.overdue:
        return AppColors.danger;
      case LoanStatus.dueSoon:
        return AppColors.info;
      case LoanStatus.partial:
        return AppColors.warning;
      case LoanStatus.pending:
        return AppColors.primary;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.loan,
    required this.status,
    required this.accent,
    required this.currency,
  });

  final Loan loan;
  final LoanStatus status;
  final Color accent;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = loan.customerName.trim();
    final initial = name.isEmpty ? "?" : name.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.20),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "Unnamed" : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loan.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: status.name, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),

          // Outstanding
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Outstanding",
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              currency.format(loan.outstandingAmount),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: loan.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(
                label: "Paid",
                value: currency.format(loan.paidAmount),
              ),
              _MiniStat(
                label: "Remaining",
                value: currency.format(loan.remainingTotal),
              ),
              _MiniStat(
                label: "Overdue",
                value: loan.overdueDays.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    String pretty = label.isEmpty
        ? label
        : "${label[0].toUpperCase()}${label.substring(1)}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        pretty,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmiTile extends StatelessWidget {
  const _EmiTile({
    required this.index,
    required this.emi,
    required this.currency,
    required this.accent,
  });

  final int index;
  final Emi emi;
  final NumberFormat currency;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isPaid = emi.isPaid || emi.paidAmount >= (emi.emiAmount - 0.01);
    final tileAccent = isPaid ? AppColors.success : accent;

    final paidProgress =
    (emi.emiAmount <= 0) ? 0.0 : (emi.paidAmount / emi.emiAmount).clamp(0.0, 1.0);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: tileAccent.withValues(alpha: 0.12),
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  color: tileAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(emi.dueDate),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(emi.status.name),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: paidProgress,
                            minHeight: 6,
                            backgroundColor: theme
                                .colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            valueColor:
                            AlwaysStoppedAnimation<Color>(tileAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(emi.emiAmount),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  isPaid ? "Paid" : currency.format(emi.emiAmount - emi.paidAmount),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isPaid ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _chip(String s) {
    final pretty = s.isEmpty ? s : "${s[0].toUpperCase()}${s.substring(1)}";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        pretty,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.loan, required this.currency});

  final Loan loan;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = loan.history.reversed.take(5).toList();

    return Column(
      children: [
        for (final tx in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.payments_rounded, color: AppColors.primary),
            title: Text(
              "Received ${currency.format(tx.amount)}",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            subtitle: Text(DateFormat('dd MMM, hh:mm a').format(tx.date)),
            trailing: tx.remarks != null && tx.remarks!.trim().isNotEmpty
                ? Text(
              tx.remarks!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
                : null,
          ),
      ],
    );
  }
}