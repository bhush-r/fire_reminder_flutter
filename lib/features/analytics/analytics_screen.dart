import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/loan_model.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/pdf_export_service.dart';
import '../loan/loan_controller.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _exporting = false;

  Future<void> _runExport(Future<void> Function() task) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    // Simple blocking loader (smooth UX)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text("Preparing report…")),
          ],
        ),
      ),
    );

    try {
      await task();
      if (!mounted) return;
      Navigator.pop(context); // close loader
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Export failed: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loans = ref.watch(loanControllerProvider);

    final totalPrincipal =
    loans.fold<double>(0, (sum, l) => sum + l.principal);
    final totalExpected =
    loans.fold<double>(0, (sum, l) => sum + l.totalAmount);
    final totalPending = loans.fold<double>(
        0, (sum, l) => sum + (l.totalAmount - l.paidAmount));
    final totalPaid = totalExpected - totalPending;

    final monthlyData = _groupMonthlyPending(loans);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("Analytics"),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCard(theme, "Working Capital", totalPrincipal,
                      AppColors.primary, Icons.account_balance_rounded),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildMiniStat(theme, "Recovered", totalPaid,
                              AppColors.success)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildMiniStat(theme, "Balance", totalPending,
                              AppColors.danger)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "RECOVERY FORECAST",
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (monthlyData.isEmpty) _emptyDataState(theme) else _buildChart(theme, monthlyData),
                  const SizedBox(height: 40),
                  Text(
                    "REPORTS",
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _exportTile(
                    theme,
                    "Excel Sheet",
                    "Financial breakdown for accounting",
                    Icons.table_chart_rounded,
                    Colors.green,
                        () => _runExport(() => ExcelExportService.exportAllLoans(context, loans)),
                  ),
                  const SizedBox(height: 12),
                  _exportTile(
                    theme,
                    "PDF Summary",
                    "Printable collection reports",
                    Icons.picture_as_pdf_rounded,
                    Colors.red,
                        () => _runExport(() => PdfExportService.exportAllLoans(context, loans)),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, double value, Color color,
      IconData icon) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  "₹${value.toStringAsFixed(0)}",
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 40, color: color.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme, List<_MonthlyPending> data) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(data) * 1.3,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[v.toInt()].month.split('/')[0],
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.amount,
                color: theme.colorScheme.primary,
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }

  Widget _exportTile(ThemeData theme, String title, String sub, IconData icon,
      Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: _exporting
          ? const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }

  Widget _emptyDataState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Column(
        children: [
          Icon(Icons.query_stats_rounded, size: 48, color: AppColors.border),
          SizedBox(height: 12),
          Text("No data to display"),
        ],
      ),
    );
  }

  double _getMaxY(List<_MonthlyPending> data) =>
      data.isEmpty ? 100 : data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

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