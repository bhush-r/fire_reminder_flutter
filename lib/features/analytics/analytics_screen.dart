import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/loan_model.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/pdf_export_service.dart';
import '../../core/theme/app_colors.dart';
import '../loan/loan_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loanControllerProvider);

    final totalPrincipal = loans.fold<double>(0, (sum, l) => sum + l.principal);
    final totalExpected = loans.fold<double>(0, (sum, l) => sum + l.totalAmount);
    final totalPending = loans.fold<double>(0, (sum, l) => sum + (l.totalAmount - l.paidAmount));
    final totalPaid = totalExpected - totalPending;

    final monthlyData = _groupMonthlyPending(loans);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Insight Analytics"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 SUMMARY GRID
            Row(
              children: [
                Expanded(child: _summaryBox("Total Capital", totalPrincipal, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _summaryBox("Recovered", totalPaid, AppColors.success)),
              ],
            ),
            const SizedBox(height: 12),
            _summaryBox("Total Pending", totalPending, AppColors.danger, isWide: true),

            const SizedBox(height: 32),

            _sectionHeader("Recovery Trend", "Monthly collection forecast"),
            const SizedBox(height: 16),

            if (monthlyData.isEmpty)
              _emptyDataState()
            else
              Container(
                height: 250,
                padding: const EdgeInsets.only(top: 20, right: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(monthlyData) * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '₹${rod.toY.toInt()}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= monthlyData.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                monthlyData[value.toInt()].month.split('/')[0],
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: monthlyData.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.amount,
                            color: AppColors.primary,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: _getMaxY(monthlyData) * 1.2,
                              color: AppColors.primary.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            _sectionHeader("Reports", "Download your transaction data"),
            const SizedBox(height: 16),

            _exportTile(
              "Excel Spreadsheet",
              "Best for accounting & detailed records",
              Icons.table_chart_outlined,
              Colors.green,
                  () => ExcelExportService.exportAllLoans(context, loans),
            ),
            const SizedBox(height: 12),
            _exportTile(
              "PDF Document",
              "Best for sharing and printing reports",
              Icons.picture_as_pdf_outlined,
              Colors.red,
                  () => PdfExportService.exportAllLoans(context, loans),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI COMPONENTS ----------

  Widget _summaryBox(String label, double value, Color color, {bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: isWide ? 28 : 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _exportTile(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      tileColor: Colors.white,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  Widget _emptyDataState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: const Column(
        children: [
          Icon(Icons.bar_chart, size: 48, color: AppColors.border),
          SizedBox(height: 12),
          Text("No trend data available", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ---------- DATA HELPERS ----------

  double _getMaxY(List<_MonthlyPending> data) {
    if (data.isEmpty) return 100;
    return data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  List<_MonthlyPending> _groupMonthlyPending(List<Loan> loans) {
    final Map<String, double> map = {};
    for (final loan in loans) {
      final key = "${loan.dueDate.month}/${loan.dueDate.year}";
      final pending = loan.totalAmount - loan.paidAmount;
      if (pending > 0) map[key] = (map[key] ?? 0) + pending;
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => _MonthlyPending(month: e.key, amount: e.value)).toList();
  }
}

class _MonthlyPending {
  final String month;
  final double amount;
  _MonthlyPending({required this.month, required this.amount});
}