import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/loan_model.dart';

class ExcelExportService {
  static Future<void> exportAllLoans(
      BuildContext context, List<Loan> loans) async {
    final excel = Excel.createExcel();
    final sheet = excel['Loans'];

    sheet.appendRow([
      TextCellValue("Name"),
      TextCellValue("Phone"),
      DoubleCellValue(0.0), // Placeholder for header logic if needed, but strings are preferred
      TextCellValue("Principal"),
      TextCellValue("Interest"),
      TextCellValue("Total"),
      TextCellValue("Paid"),
      TextCellValue("Due Date")
    ]);

    for (final l in loans) {
      sheet.appendRow([
        TextCellValue(l.customerName),
        TextCellValue(l.phone),
        DoubleCellValue(l.principal),
        DoubleCellValue(l.interestRate),
        DoubleCellValue(l.totalAmount),
        DoubleCellValue(l.paidAmount),
        TextCellValue("${l.dueDate.day}-${l.dueDate.month}-${l.dueDate.year}"),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/all_loans.xlsx")
      ..writeAsBytesSync(excel.encode()!);

    await Share.shareXFiles([XFile(file.path)]);
  }

  static Future<void> exportSingleLoan(BuildContext context, Loan loan) async {
    final excel = Excel.createExcel();
    final sheet = excel['LoanDetail'];

    sheet.appendRow([TextCellValue("Field"), TextCellValue("Value")]);
    sheet.appendRow([TextCellValue("Name"), TextCellValue(loan.customerName)]);
    sheet.appendRow([TextCellValue("Phone"), TextCellValue(loan.phone)]);
    sheet.appendRow([TextCellValue("Principal"), DoubleCellValue(loan.principal)]);
    sheet.appendRow([TextCellValue("Total Amount"), DoubleCellValue(loan.totalAmount)]);
    sheet.appendRow([TextCellValue("Paid"), DoubleCellValue(loan.paidAmount)]);
    sheet.appendRow([TextCellValue("Due Date"), TextCellValue("${loan.dueDate.day}-${loan.dueDate.month}-${loan.dueDate.year}")]);

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/loan_${loan.id}.xlsx")
      ..writeAsBytesSync(excel.encode()!);

    await Share.shareXFiles([XFile(file.path)]);
  }
}