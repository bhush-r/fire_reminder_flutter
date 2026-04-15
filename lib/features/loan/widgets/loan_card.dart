import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/loan_model.dart';
import '../../../data/models/loan_status.dart';
import '../loan_detail_screen.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;

  const LoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = loan.calculatedStatus;
    final nextEmi = loan.nextEmi;

    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    Color statusColor() {
      switch (status) {
        case LoanStatus.paid:
          return AppColors.success;
        case LoanStatus.overdue:
          return AppColors.danger;
        case LoanStatus.partial:
          return AppColors.warning;
        case LoanStatus.pending:
          return AppColors.primary;
        case LoanStatus.dueSoon:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    }

    String titleCase(String s) {
      if (s.isEmpty) return s;
      return "${s[0].toUpperCase()}${s.substring(1)}";
    }

    final accent = statusColor();
    final progress = loan.progress;

    final name = loan.customerName.trim();
    final initial = name.isEmpty ? "?" : name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accent.withOpacity(0.12),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loan.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildBadge(titleCase(status.name), accent),
                  ],
                ),

                const SizedBox(height: 14),

                // Progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 10),

                // Paid / total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Paid ${currency.format(loan.paidAmount)}",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      "Total ${currency.format(loan.totalAmount)}",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // Amount details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _amountDetail(
                      theme,
                      "Principal",
                      currency.format(loan.principal),
                      AppColors.textPrimary,
                    ),
                    _amountDetail(
                      theme,
                      "Outstanding",
                      currency.format(loan.outstandingAmount),
                      accent,
                      isPrimary: true,
                    ),
                  ],
                ),

                // Overdue hint
                if (status == LoanStatus.overdue && loan.overdueDays > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Overdue by ${loan.overdueDays} day${loan.overdueDays == 1 ? "" : "s"}",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],

                // Next EMI
                if (nextEmi != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_repeat_rounded,
                          size: 16,
                          color: accent.withOpacity(0.85),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Next EMI: ${currency.format(nextEmi.emiAmount)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd MMM').format(nextEmi.dueDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _amountDetail(
      ThemeData theme,
      String label,
      String value,
      Color color, {
        bool isPrimary = false,
      }) {
    return Column(
      crossAxisAlignment:
      isPrimary ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isPrimary ? color : AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: isPrimary ? 18 : 14,
          ),
        ),
      ],
    );
  }
}