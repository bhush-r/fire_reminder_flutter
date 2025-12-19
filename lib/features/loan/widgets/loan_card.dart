import 'package:flutter/material.dart';
import '../../../data/models/loan_model.dart';
import '../../../data/models/loan_status.dart';
import '../loan_detail_screen.dart';
import '../../../core/theme/app_colors.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;

  const LoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = loan.calculatedStatus;

    Color statusColor() {
      switch (status) {
        case LoanStatus.paid: return AppColors.success;
        case LoanStatus.overdue: return AppColors.danger;
        case LoanStatus.partial: return AppColors.warning;
        default: return AppColors.primary;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor().withValues(alpha: 0.1),
                    child: Text(
                      loan.customerName[0].toUpperCase(),
                      style: TextStyle(color: statusColor(), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.customerName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          loan.phone,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildBadge(status.name, statusColor()),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountDetail(theme, "Remaining", "₹${loan.remainingAmount.toStringAsFixed(0)}", statusColor(), isPrimary: true),
                  _amountDetail(theme, "Total", "₹${loan.totalAmount.toStringAsFixed(0)}", AppColors.textSecondary),
                  _amountDetail(theme, "Paid", "₹${loan.paidAmount.toStringAsFixed(0)}", AppColors.textSecondary),
                ],
              ),
              if (loan.overdueDays > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Text(
                        "Overdue by ${loan.overdueDays} days",
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _amountDetail(ThemeData theme, String label, String value, Color color, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isPrimary ? color : AppColors.textPrimary,
            fontWeight: isPrimary ? FontWeight.w900 : FontWeight.bold,
            fontSize: isPrimary ? 18 : 14,
          ),
        ),
      ],
    );
  }
}