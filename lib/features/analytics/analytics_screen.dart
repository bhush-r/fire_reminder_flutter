import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/loan_model.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/pdf_export_service.dart';
import '../loan/loan_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loanControllerProvider);

    final totalPrincipal =
        loans.fold<double>(0, (sum, l) => sum + l.principal);
    final totalExpected =
        loans.fold<double>(0, (sum, l) => sum + l.totalAmount);
    final totalPending =
        loans.fold<double>(0, (sum, l) => sum + (l.totalAmount - l.paidAmount));

    final monthlyData = _groupMonthlyPending(loans);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Business Overview"),

            _metricCard("Total Principal", totalPrincipal, Icons.account_balance),
            _metricCard("Expected Return", totalExpected, Icons.trending_up),
            _metricCard("Total Pending", totalPending, Icons.money),

            const SizedBox(height: 24),

            _sectionTitle("Monthly Pending Trend"),

            if (monthlyData.isEmpty)
              const Text("No data available")
            else
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(monthlyData[value.toInt()].month);
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < monthlyData.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: monthlyData[i].amount,
                              width: 18,
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            )
                          ],
                        )
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            _sectionTitle("Export Reports"),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ExcelExportService.exportAllLoans(context, loans);
                },
                child: const Text("Export All Loans (Excel)"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  PdfExportService.exportAllLoans(context, loans);
                },
                child: const Text("Export All Loans (PDF)"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- HELPERS ----------

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _metricCard(String title, double value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          "₹${value.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<_MonthlyPending> _groupMonthlyPending(List<Loan> loans) {
    final Map<String, double> map = {};

    for (final loan in loans) {
      final key = "${loan.dueDate.month}/${loan.dueDate.year}";
      final pending = loan.totalAmount - loan.paidAmount;
      map[key] = (map[key] ?? 0) + pending;
    }

    return map.entries
        .map((e) => _MonthlyPending(month: e.key, amount: e.value))
        .toList();
  }
}

class _MonthlyPending {
  final String month;
  final double amount;

  _MonthlyPending({required this.month, required this.amount});
}
