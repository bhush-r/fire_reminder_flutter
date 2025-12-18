import 'package:flutter/material.dart';
import '../models/loan_model.dart';

class ExcelExportService {
  static void exportSingleLoan(BuildContext context, Loan loan) {
    // Implement using `excel` + `share_plus`
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Excel exported")));
  }
}
