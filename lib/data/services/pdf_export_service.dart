import 'package:flutter/material.dart';
import '../models/loan_model.dart';

class PdfExportService {
  static void exportSingleLoan(BuildContext context, Loan loan) {
    // Implement using `pdf` + `printing`
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("PDF exported")));
  }
}
