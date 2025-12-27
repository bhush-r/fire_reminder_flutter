import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final nextEmi = loan.nextEmi;

    Color statusColor() {
      switch (status) {
        case LoanStatus.paid: return AppColors.success;
        case LoanStatus.overdue: return AppColors.danger;
        case LoanStatus.partial: return AppColors.warning;
        default: return AppColors.primary;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: statusColor().withOpacity(0.1),
                    child: Text(
                      loan.customerName[0].toUpperCase(),
                      style: TextStyle(color: statusColor(), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountDetail(theme, "Principal", "₹${loan.principal.toInt()}", AppColors.textPrimary),
                  _amountDetail(theme, "Outstanding", "₹${loan.outstandingAmount.toInt()}", statusColor(), isPrimary: true),
                ],
              ),
              if (nextEmi != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_repeat_rounded, size: 16, color: AppColors.primary.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        "Next EMI: ₹${nextEmi.emiAmount.toInt()}",
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM').format(nextEmi.dueDate),
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _amountDetail(ThemeData theme, String label, String value, Color color, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: isPrimary ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
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