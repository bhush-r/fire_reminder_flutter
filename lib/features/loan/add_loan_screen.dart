import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/loan_calculator.dart';
import '../../core/utils/validators.dart';
import '../../data/models/loan_model.dart';
import 'loan_controller.dart';
import '../../core/theme/app_colors.dart';

class AddLoanScreen extends ConsumerStatefulWidget {
  final Loan? existingLoan;

  const AddLoanScreen({super.key, this.existingLoan});

  @override
  ConsumerState<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends ConsumerState<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController principalCtrl;
  late TextEditingController rateCtrl;
  late TextEditingController tenureCtrl;

  late DateTime givenDate;
  String paymentType = "Cash";

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.existingLoan?.customerName ?? "");
    phoneCtrl = TextEditingController(text: widget.existingLoan?.phone.replaceFirst("+91", "") ?? "");
    principalCtrl = TextEditingController(text: widget.existingLoan?.principal.toString() ?? "");
    rateCtrl = TextEditingController(text: widget.existingLoan?.interestRate.toString() ?? "");
    tenureCtrl = TextEditingController(text: widget.existingLoan?.emis.length.toString() ?? "12");
    givenDate = widget.existingLoan?.givenDate ?? DateTime.now();
    paymentType = widget.existingLoan?.paymentType ?? "Cash";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final principal = double.tryParse(principalCtrl.text) ?? 0;
    final rate = double.tryParse(rateCtrl.text) ?? 0;
    final tenure = int.tryParse(tenureCtrl.text) ?? 0;

    final emiAmount = LoanCalculator.calculateEmi(principal, rate, tenure > 0 ? tenure : 1);
    final totalPayable = emiAmount * tenure;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLoan == null ? "New Loan Account" : "Edit Loan Terms"),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: _saveLoan,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              widget.existingLoan == null ? "Disburse Loan" : "Update Agreement",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(theme, "Borrower Information"),
              const SizedBox(height: 16),
              _field(
                controller: nameCtrl,
                label: "Full Name",
                icon: Icons.person_outline_rounded,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "Mobile Number",
                  prefixText: "+91 ",
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: "",
                ),
                validator: Validators.phone10,
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, "Loan Parameters"),
              const SizedBox(height: 16),
              _field(
                controller: principalCtrl,
                label: "Principal Amount (₹)",
                keyboard: TextInputType.number,
                icon: Icons.account_balance_wallet_outlined,
                validator: Validators.amount,
                onChanged: (v) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: rateCtrl,
                      label: "Annual Interest %",
                      keyboard: TextInputType.number,
                      icon: Icons.percent_rounded,
                      validator: Validators.rate,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _field(
                      controller: tenureCtrl,
                      label: "Tenure (Months)",
                      keyboard: TextInputType.number,
                      icon: Icons.calendar_today_rounded,
                      validator: (v) => (int.tryParse(v ?? "") ?? 0) <= 0 ? "Invalid tenure" : null,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _dateTile(theme, "Disbursement Date", givenDate, () async {
                final picked = await _pickDate(context, givenDate);
                if (picked != null) setState(() => givenDate = picked);
              }),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: paymentType,
                items: const [
                  DropdownMenuItem(value: "Cash", child: Text("Cash Basis")),
                  DropdownMenuItem(value: "Online", child: Text("Digital Transfer")),
                  DropdownMenuItem(value: "Bank", child: Text("Bank Check")),
                ],
                onChanged: (v) => setState(() => paymentType = v!),
                decoration: const InputDecoration(
                  labelText: "Collection Mode",
                  prefixIcon: Icon(Icons.payment_rounded),
                ),
              ),
              const SizedBox(height: 32),
              _buildEmiPreview(theme, emiAmount, totalPayable),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmiPreview(ThemeData theme, double emi, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Monthly EMI", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    "₹${emi.toStringAsFixed(2)}",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
              const Icon(Icons.calculate_outlined, color: AppColors.primary),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Payable", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                "₹${total.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  void _saveLoan() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(loanControllerProvider.notifier).saveLoan(
      existingId: widget.existingLoan?.id,
      name: nameCtrl.text.trim(),
      phone: "+91${phoneCtrl.text}",
      principal: double.parse(principalCtrl.text),
      rate: double.parse(rateCtrl.text),
      givenDate: givenDate,
      tenureMonths: int.parse(tenureCtrl.text),
      paymentType: paymentType,
    );
    Navigator.pop(context);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _dateTile(ThemeData theme, String title, DateTime date, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: theme.textTheme.labelLarge),
        subtitle: Text(
          DateFormat('dd MMMM yyyy').format(date),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.calendar_today_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }
}