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
  static final _currency = "Rs.";

  static Future<void> exportAllLoans(BuildContext context, List<Loan> loans) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader("All Loans Report"),
          pw.SizedBox(height: 20),
          _buildAllLoansTable(loans),
          pw.Footer(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
            leading: pw.Text("Fire Reminder - Loan Management App", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            trailing: pw.Text("Page ${context.pageNumber} of ${context.pagesCount}", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ),
        ],
      ),
    );

    await _saveAndShare(pdf, "all_loans_report.pdf");
  }

  static Future<void> exportSingleLoan(BuildContext context, Loan loan) async {
    final pdf = pw.Document();
    final remainingLiability = loan.totalAmount - loan.paidAmount;
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
          child: pw.Text("Generated via Fire • Secure FinTech Solutions", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
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
                  "Loan ID: ${loan.id}",
                ]),
              ),
              pw.Expanded(
                flex: 1,
                child: _buildInfoBlock("Summary Status", [
                  "Status: ${status.name.toUpperCase()}",
                  if (overdueDays > 0) "Overdue: $overdueDays Days" else "Maturity: ${_dateFormat.format(loan.dueDate)}",
                ], color: overdueDays > 0 ? PdfColors.red : PdfColors.indigo700),
              ),
            ],
          ),

          pw.Divider(height: 30, thickness: 1, color: PdfColors.grey300),

          // Financial Summary Block
          pw.Text("Account Summary", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildSummaryGrid(loan, remainingLiability),

          pw.SizedBox(height: 30),

          // Detailed Repayment Schedule
          pw.Text("Repayment Progress", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildEmiTable(loan.emis),

          pw.SizedBox(height: 30),

          // Payment History Section (Ledger)
          pw.Text("Transaction Ledger", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildHistoryTable(loan.history),

          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text("This is a computer-generated statement and does not require a signature.",
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
          ),
        ],
      ),
    );

    await _saveAndShare(pdf, "loan_statement_${loan.customerName.replaceAll(' ', '_')}.pdf");
  }

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
                pw.Text("Professional FinTech Solutions", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
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
        ...details.map((detail) => pw.Text(detail, style: pw.TextStyle(fontSize: 10, color: color ?? PdfColors.black, fontWeight: color != null ? pw.FontWeight.bold : null))),
      ],
    );
  }

  static pw.Widget _buildSummaryGrid(Loan loan, double remaining) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _summaryRow("Agreement Principal", "$_currency ${loan.principal.toStringAsFixed(2)}"),
          _summaryRow("Total Payable (with Interest)", "$_currency ${loan.totalAmount.toStringAsFixed(2)}", isBold: true),
          pw.Divider(color: PdfColors.white, thickness: 2),
          _summaryRow("Cumulative Recovered", "$_currency ${loan.paidAmount.toStringAsFixed(2)}", color: PdfColors.green700),
          _summaryRow("Net Outstanding Liability", "$_currency ${remaining.toStringAsFixed(2)}", color: PdfColors.red700, isBold: true),
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

  static pw.Widget _buildAllLoansTable(List<Loan> loans) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo700),
          children: [
            _tableCell("Customer", isHeader: true, color: PdfColors.white),
            _tableCell("Total", isHeader: true, color: PdfColors.white, align: pw.Alignment.centerRight),
            _tableCell("Paid", isHeader: true, color: PdfColors.white, align: pw.Alignment.centerRight),
            _tableCell("Outstanding", isHeader: true, color: PdfColors.white, align: pw.Alignment.centerRight),
            _tableCell("Status", isHeader: true, color: PdfColors.white, align: pw.Alignment.center),
          ],
        ),
        ...loans.map((l) => pw.TableRow(
          children: [
            _tableCell(l.customerName),
            _tableCell("$_currency ${l.totalAmount.toStringAsFixed(0)}", align: pw.Alignment.centerRight),
            _tableCell("$_currency ${l.paidAmount.toStringAsFixed(0)}", align: pw.Alignment.centerRight),
            _tableCell("$_currency ${(l.totalAmount - l.paidAmount).toStringAsFixed(0)}", align: pw.Alignment.centerRight),
            _tableCell(l.calculatedStatus.name.toUpperCase(), align: pw.Alignment.center),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildEmiTable(List<Emi> emis) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(70),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell("#", isHeader: true),
            _tableCell("Due Date", isHeader: true),
            _tableCell("EMI Amount", isHeader: true, align: pw.Alignment.centerRight),
            _tableCell("Paid", isHeader: true, align: pw.Alignment.centerRight),
            _tableCell("Status", isHeader: true, align: pw.Alignment.center),
          ],
        ),
        ...emis.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return pw.TableRow(
            children: [
              _tableCell("${i + 1}"),
              _tableCell(_dateFormat.format(e.dueDate)),
              _tableCell("$_currency ${e.emiAmount.toStringAsFixed(0)}", align: pw.Alignment.centerRight),
              _tableCell("$_currency ${e.paidAmount.toStringAsFixed(0)}", align: pw.Alignment.centerRight),
              _tableCell(e.status.name.toUpperCase(), align: pw.Alignment.center, color: _getEmiStatusColor(e.status)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildHistoryTable(List<TransactionLog> history) {
    if (history.isEmpty) {
      return pw.Text("No transactions recorded yet.", style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(110),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(70),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell("Date & Time", isHeader: true),
            _tableCell("Description / Remarks", isHeader: true),
            _tableCell("Amount", isHeader: true, align: pw.Alignment.centerRight),
          ],
        ),
        ...history.reversed.map((tx) => pw.TableRow(
          children: [
            _tableCell(_dateTimeFormat.format(tx.date)),
            _tableCell(
                "${tx.type == 'manualPayment' ? 'Manual Collection' : 'EMI Settlement'}${tx.remarks != null ? '\n[Note: ' + tx.remarks! + ']' : ''}",
                fontSize: 9
            ),
            _tableCell("$_currency ${tx.amount.toStringAsFixed(0)}", align: pw.Alignment.centerRight, color: PdfColors.green700),
          ],
        )),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false, pw.Alignment? align, PdfColor? color, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Container(
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ),
    );
  }

  static PdfColor _getEmiStatusColor(EmiStatus s) {
    switch (s) {
      case EmiStatus.paid: return PdfColors.green700;
      case EmiStatus.overdue: return PdfColors.red700;
      case EmiStatus.partiallyPaid: return PdfColors.orange700;
      case EmiStatus.due: return PdfColors.blueGrey700;
      default: return PdfColors.grey700;
    }
  }

  static Future<void> _saveAndShare(pw.Document pdf, String fileName) async {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Loan Statement attached.');
  }
}