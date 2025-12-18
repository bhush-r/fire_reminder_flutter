import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed unused import: '../../data/models/loan_model.dart'
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
    final loans = ref.watch(loanControllerProvider);

    final filteredLoans = loans.where((loan) {
      final matchesSearch =
          loan.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              loan.phone.contains(searchQuery);
      final matchesStatus =
          filterStatus == null || loan.calculatedStatus == filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();

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

    final counts = {
      for (var s in LoanStatus.values)
        s: loans.where((l) => l.calculatedStatus == s).length
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Dashboard"),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (val) => setState(() => _currentSort = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: SortOption.dueDateAsc, child: Text("Due Date (Soonest)")),
              const PopupMenuItem(value: SortOption.dueDateDesc, child: Text("Due Date (Latest)")),
              const PopupMenuItem(value: SortOption.amountAsc, child: Text("Amount (Low to High)")),
              const PopupMenuItem(value: SortOption.amountDesc, child: Text("Amount (High to Low)")),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLoanScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search name or phone",
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip(null, loans.length, "All"),
                ...LoanStatus.values.map((s) => _filterChip(s, counts[s] ?? 0, s.name)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredLoans.isEmpty
                ? const Center(child: Text("No loans found"))
                : ListView.builder(
              itemCount: filteredLoans.length,
              itemBuilder: (context, index) => LoanCard(loan: filteredLoans[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(LoanStatus? status, int count, String label) {
    final isSelected = filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text("${label.toUpperCase()} ($count)"),
        selected: isSelected,
        onSelected: (val) => setState(() => filterStatus = val ? status : null),
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }
}