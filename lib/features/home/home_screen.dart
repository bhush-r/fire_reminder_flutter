import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/loan_status.dart';
import '../loan/add_loan_screen.dart';
import '../loan/loan_controller.dart';
import '../loan/widgets/loan_card.dart';

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

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => searchQuery = v);
    });
  }

  void _openAddLoan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLoanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loans = ref.watch(loanControllerProvider);

    final filteredLoans = loans.where((loan) {
      final q = searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          loan.customerName.toLowerCase().contains(q) ||
          loan.phone.contains(q);

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

    final totalPending = loans.fold<double>(
      0.0,
          (sum, l) => sum + (l.totalAmount - l.paidAmount),
    );

    final counts = {
      for (var s in LoanStatus.values)
        s: loans.where((l) => l.calculatedStatus == s).length
    };

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text("Fire Reminder"),
            actions: [
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort_rounded),
                onSelected: (val) => setState(() => _currentSort = val),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: SortOption.dueDateAsc,
                    child: Text("Due date: Soonest"),
                  ),
                  PopupMenuItem(
                    value: SortOption.dueDateDesc,
                    child: Text("Due date: Latest"),
                  ),
                  PopupMenuItem(
                    value: SortOption.amountAsc,
                    child: Text("Amount: Low → High"),
                  ),
                  PopupMenuItem(
                    value: SortOption.amountDesc,
                    child: Text("Amount: High → Low"),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Summary + Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _buildCompactSummary(theme, totalPending, loans.length),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search name or phone…",
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      isDense: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterChip(null, loans.length, "All"),
                  ...LoanStatus.values.map(
                        (s) => _filterChip(s, counts[s] ?? 0, s.name),
                  ),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(top: 12)),

          // List / Empty state
          if (filteredLoans.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                onAdd: _openAddLoan,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final loan = filteredLoans[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 250),
                    child: SlideAnimation(
                      verticalOffset: 18,
                      child: FadeInAnimation(
                        child: LoanCard(loan: loan),
                      ),
                    ),
                  );
                },
                childCount: filteredLoans.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddLoan,
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
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
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
                "Total pending",
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: Colors.white70),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(LoanStatus? status, int count, String label) {
    final theme = Theme.of(context);
    final isSelected = filterStatus == status;

    String prettyLabel;
    if (status == null) {
      prettyLabel = "All";
    } else {
      prettyLabel =
      label.isEmpty ? label : "${label[0].toUpperCase()}${label.substring(1)}";
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text("$prettyLabel • $count"),
        selected: isSelected,
        onSelected: (val) => setState(() => filterStatus = val ? status : null),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        showCheckmark: false,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 86,
              width: 86,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No loans found",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add your first loan to start tracking EMIs, due dates, and collections.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add loan"),
            ),
          ],
        ),
      ),
    );
  }
}