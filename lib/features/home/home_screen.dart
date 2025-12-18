import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed unused import: '../../data/models/loan_model.dart'
import '../../data/models/loan_status.dart';
import '../loan/add_loan_screen.dart';
import '../loan/loan_controller.dart';
import '../loan/widgets/loan_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String searchQuery = "";
  LoanStatus? filterStatus;

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(loanControllerProvider);

    final filteredLoans = loans.where((loan) {
      final matchesSearch =
          loan.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
              loan.phone.contains(searchQuery);

      final matchesStatus =
          filterStatus == null || loan.status == filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    final totalPending = filteredLoans.fold<double>(
      0,
          (sum, l) => sum + (l.totalAmount - l.paidAmount),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Dashboard"),
        actions: [
          PopupMenuButton<LoanStatus?>(
            onSelected: (value) {
              setState(() => filterStatus = value);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text("All")),
              const PopupMenuItem(
                  value: LoanStatus.pending, child: Text("Pending")),
              const PopupMenuItem(
                  value: LoanStatus.paid, child: Text("Paid")),
              const PopupMenuItem(
                  value: LoanStatus.overdue, child: Text("Overdue")),
            ],
            icon: const Icon(Icons.filter_list),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLoanScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search name or phone",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                title: const Text("Total Pending"),
                subtitle: Text("₹${totalPending.toStringAsFixed(2)}"),
                trailing: const Icon(Icons.trending_up),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredLoans.isEmpty
                ? const Center(child: Text("No loans found"))
                : ListView.builder(
              itemCount: filteredLoans.length,
              itemBuilder: (context, index) {
                final loan = filteredLoans[index];
                return LoanCard(loan: loan);
              },
            ),
          ),
        ],
      ),
    );
  }
}