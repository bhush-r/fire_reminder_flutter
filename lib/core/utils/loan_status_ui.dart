import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/loan_status.dart';

Color loanStatusColor(LoanStatus status) {
  switch (status) {
    case LoanStatus.paid:
      return AppColors.success;
    case LoanStatus.overdue:
      return AppColors.danger;
    case LoanStatus.dueSoon:
      return AppColors.info; // blue = attention soon
    case LoanStatus.partial:
      return AppColors.warning;
    case LoanStatus.pending:
      return AppColors.primary;
  }
}

String loanStatusLabel(LoanStatus status) {
  switch (status) {
    case LoanStatus.paid:
      return "Paid";
    case LoanStatus.overdue:
      return "Overdue";
    case LoanStatus.dueSoon:
      return "Due soon";
    case LoanStatus.partial:
      return "Partial";
    case LoanStatus.pending:
      return "Pending";
  }
}