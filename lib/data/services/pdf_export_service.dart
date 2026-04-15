import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/loan_model.dart';

class PdfExportService {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _currency = "Rs."; // Using Rs. as a safe fallback for PDF fonts

  static Future<void> exportAllLoans(BuildContext context, List<Loan> loans) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),

        header: (ctx) => _buildHeader("All Loans Report"),

        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Fire Reminder - Loan Management App",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                "Page ${ctx.pageNumber}",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),

        build: (ctx) => [
          pw.SizedBox(height: 14),
          _buildAllLoansTable(loans),
        ],
      ),
    );

    await _saveAndShare(pdf, "all_loans_report.pdf");
  }

  static Future<void> exportSingleLoan(BuildContext context, Loan loan) async {
    final pdf = pw.Document();
    final remaining = loan.totalAmount - loan.paidAmount;
    final status = loan.calculatedStatus;
    final overdueDays = loan.overdueDays;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader("Loan Statement"),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 30),
          child: pw.Text("Generated via Fire", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        ),
        build: (context) => [
          pw.SizedBox(height: 20),

          // Borrower & Status Section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: _buildInfoBlock("Borrower Details", [
                  "Name: ${loan.customerName}",
                  "Phone: ${loan.phone}",
                ]),
              ),
              pw.Expanded(
                flex: 1,
                child: _buildInfoBlock("Status", [
                  "Current: ${status.name.toUpperCase()}",
                  if (overdueDays > 0) "Overdue: $overdueDays Days" else "Due Date: ${_dateFormat.format(loan.dueDate)}",
                ], color: overdueDays > 0 ? PdfColors.red : PdfColors.blue),
              ),
            ],
          ),

          pw.Divider(height: 30, thickness: 1, color: PdfColors.grey300),

          // Loan Summary Block
          pw.Text("Financial Summary", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildSummaryGrid(loan, remaining),

          pw.SizedBox(height: 30),

          // Payment History Section
          pw.Text("Payment History", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildHistoryTable(loan.history),

          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text("Thank you for using our service.", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
          ),
        ],
      ),
    );

    await _saveAndShare(pdf, "loan_statement_${loan.customerName.replaceAll(' ', '_')}.pdf");
  }

  // UI Helper methods
  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("FIRE REMINDER", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
                pw.Text("Secure Loan Management", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text("Date: ${_dateFormat.format(DateTime.now())}", style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2, color: PdfColors.indigo700),
      ],
    );
  }

  static pw.Widget _buildInfoBlock(String title, List<String> details, {PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        for (var detail in details)
          pw.Text(detail, style: pw.TextStyle(fontSize: 10, color: color ?? PdfColors.black, fontWeight: color != null ? pw.FontWeight.bold : null)),
      ],
    );
  }

  static pw.Widget _buildSummaryGrid(Loan loan, double remaining) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _summaryRow("Principal Amount", "$_currency ${loan.principal.toStringAsFixed(2)}"),
          _summaryRow("Interest Rate", "${loan.interestRate}% Monthly"),
          _summaryRow("Total Payable", "$_currency ${loan.totalAmount.toStringAsFixed(2)}", isBold: true),
          pw.Divider(color: PdfColors.white),
          _summaryRow("Total Paid", "$_currency ${loan.paidAmount.toStringAsFixed(2)}", color: PdfColors.green),
          _summaryRow("Remaining Balance", "$_currency ${remaining.toStringAsFixed(2)}", color: PdfColors.red, isBold: true),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    final style = pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static pw.Widget _buildHistoryTable(List<TransactionLog> history) {
    if (history.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        child: pw.Text("No payments recorded yet.", style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(150), // Date
        1: const pw.FlexColumnWidth(), // Description/Note
        2: const pw.FixedColumnWidth(120), // Amount
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell("Payment Date", isHeader: true),
            _tableCell("Transaction Note", isHeader: true),
            _tableCell("Amount", isHeader: true, align: pw.Alignment.centerRight),
          ],
        ),
        ...history.map(
              (tx) => pw.TableRow(
            children: [
              _tableCell(_dateTimeFormat.format(tx.date)),
              _tableCell("Installment Payment"),
              _tableCell("$_currency ${tx.amount.toStringAsFixed(2)}",
                  align: pw.Alignment.centerRight),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAllLoansTable(List<Loan> loans) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo),
          children: [
            _tableCell("Borrower", isHeader: true, color: PdfColors.white),
            _tableCell("Phone", isHeader: true, color: PdfColors.white),
            _tableCell("Total",
                isHeader: true,
                color: PdfColors.white,
                align: pw.Alignment.centerRight),
            _tableCell("Paid",
                isHeader: true,
                color: PdfColors.white,
                align: pw.Alignment.centerRight),
            _tableCell("Due Date", isHeader: true, color: PdfColors.white),
          ],
        ),
        ...loans.map(
              (l) => pw.TableRow(
            children: [
              _tableCell(l.customerName),
              _tableCell(l.phone),
              _tableCell(l.totalAmount.toStringAsFixed(2),
                  align: pw.Alignment.centerRight),
              _tableCell(l.paidAmount.toStringAsFixed(2),
                  align: pw.Alignment.centerRight),
              _tableCell(_dateFormat.format(l.dueDate)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
      String text, {
        bool isHeader = false,
        pw.Alignment align = pw.Alignment.centerLeft,
        PdfColor? color,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Container(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
          softWrap: true,
        ),
      ),
    );
  }

  static Future<void> _saveAndShare(pw.Document pdf, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$fileName")
      ..writeAsBytesSync(await pdf.save());

    await Share.shareXFiles([XFile(file.path)]);
  }
}