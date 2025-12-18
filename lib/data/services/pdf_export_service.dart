import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/loan_model.dart';

class PdfExportService {
  static Future<void> exportAllLoans(
      BuildContext context, List<Loan> loans) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("All Loans Report",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            for (final l in loans)
              pw.Text(
                  "${l.customerName} | ₹${l.totalAmount} | Paid ₹${l.paidAmount}"),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/all_loans.pdf")
      ..writeAsBytesSync(await pdf.save());

    await Share.shareXFiles([XFile(file.path)]);
  }

  static Future<void> exportSingleLoan(BuildContext context, Loan loan) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Loan Detail: ${loan.customerName}",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Text("Phone: ${loan.phone}"),
            pw.Text("Principal: ₹${loan.principal}"),
            pw.Text("Total Amount: ₹${loan.totalAmount}"),
            pw.Text("Paid Amount: ₹${loan.paidAmount}"),
            pw.Text("Status: ${loan.status.name.toUpperCase()}"),
            pw.Text("Due Date: ${loan.dueDate.day}-${loan.dueDate.month}-${loan.dueDate.year}"),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/loan_${loan.id}.pdf")
      ..writeAsBytesSync(await pdf.save());

    await Share.shareXFiles([XFile(file.path)]);
  }
}