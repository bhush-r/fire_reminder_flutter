import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/loan_status.dart';
import '../loan/add_loan_screen.dart';
import '../loan/loan_controller.dart';
import '../loan/widgets/loan_card.dart';
import '../../core/theme/app_colors.dart';

enum SortOption { dueDateAsc, dueDateDesc, amountAsc, amountDesc }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String searchQuery = "";
  LoanStatus? filterStatus;
  SortOption _currentSort = SortOption.dueDateAsc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loans = ref.watch(loanControllerProvider);

    final filteredLoans = loans.where((loan) {
      final matchesSearch =
          loan.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              loan.phone.contains(searchQuery);
      final matchesStatus =
          filterStatus == null || loan.calculatedStatus == filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    // Sorting logic
    filteredLoans.sort((a, b) {
      switch (_currentSort) {
        case SortOption.dueDateAsc:
          return a.dueDate.compareTo(b.dueDate);
        case SortOption.dueDateDesc:
          return b.dueDate.compareTo(a.dueDate);
        case SortOption.amountAsc:
          return a.totalAmount.compareTo(b.totalAmount);
        case SortOption.amountDesc:
          return b.totalAmount.compareTo(a.totalAmount);
      }
    });

    final totalPending = loans.fold<double>(0, (sum, l) => sum + (l.totalAmount - l.paidAmount));

    final counts = {
      for (var s in LoanStatus.values)
        s: loans.where((l) => l.calculatedStatus == s).length
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text("Fire Reminder"),
            actions: [
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort_rounded),
                onSelected: (val) => setState(() => _currentSort = val),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: SortOption.dueDateAsc, child: Text("Due Date (Soonest)")),
                  const PopupMenuItem(value: SortOption.dueDateDesc, child: Text("Due Date (Latest)")),
                  const PopupMenuItem(value: SortOption.amountAsc, child: Text("Amount (Low to High)")),
                  const PopupMenuItem(value: SortOption.amountDesc, child: Text("Amount (High to Low)")),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Compact Summary Banner
                  _buildCompactSummary(theme, totalPending, loans.length),
                  const SizedBox(height: 16),
                  // Sleek Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search name or phone...",
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      isDense: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                ],
              ),
            ),
          ),
          // Compact Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterChip(null, loans.length, "All"),
                  ...LoanStatus.values.map((s) => _filterChip(s, counts[s] ?? 0, s.name)),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 12)),
          filteredLoans.isEmpty
              ? const SliverFillRemaining(
            child: Center(child: Text("Records not found", style: TextStyle(color: AppColors.textSecondary))),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => LoanCard(loan: filteredLoans[index]),
              childCount: filteredLoans.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLoanScreen())),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildCompactSummary(ThemeData theme, double pending, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Pending",
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
              Text(
                "₹${pending.toStringAsFixed(0)}",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$total Active",
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(LoanStatus? status, int count, String label) {
    final theme = Theme.of(context);
    final isSelected = filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text("${label.toUpperCase()} $count"),
        selected: isSelected,
        onSelected: (val) => setState(() => filterStatus = val ? status : null),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        showCheckmark: false,
      ),
    );
  }
}