import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  late DateTime givenDate;
  late DateTime dueDate;

  String paymentType = "Cash";

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.existingLoan?.customerName ?? "");
    phoneCtrl = TextEditingController(text: widget.existingLoan?.phone.replaceFirst("+91", "") ?? "");
    principalCtrl = TextEditingController(text: widget.existingLoan?.principal.toString() ?? "");
    rateCtrl = TextEditingController(text: widget.existingLoan?.interestRate.toString() ?? "");
    givenDate = widget.existingLoan?.givenDate ?? DateTime.now();
    dueDate = widget.existingLoan?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    paymentType = widget.existingLoan?.paymentType ?? "Cash";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAmount = calculateTotalAmount(
      principal: double.tryParse(principalCtrl.text) ?? 0,
      ratePerMonth: double.tryParse(rateCtrl.text) ?? 0,
      givenDate: givenDate,
      dueDate: dueDate,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLoan == null ? "Create New Loan" : "Edit Loan Details"),
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
              widget.existingLoan == null ? "Create Loan" : "Update Records",
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
              _buildSectionHeader(theme, "Borrower Details"),
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
                  labelText: "Phone Number",
                  prefixText: "+91 ",
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: "",
                ),
                validator: Validators.phone10,
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, "Loan Terms"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: principalCtrl,
                      label: "Principal (₹)",
                      keyboard: TextInputType.number,
                      icon: Icons.account_balance_wallet_outlined,
                      validator: Validators.amount,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _field(
                      controller: rateCtrl,
                      label: "Interest %",
                      keyboard: TextInputType.number,
                      icon: Icons.percent_rounded,
                      validator: Validators.rate,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _dateTile(theme, "Agreement Date", givenDate, () async {
                final picked = await _pickDate(context, givenDate);
                if (picked != null) setState(() => givenDate = picked);
              }),
              const SizedBox(height: 12),
              _dateTile(theme, "Repayment Due Date", dueDate, () async {
                final picked = await _pickDate(context, dueDate);
                if (picked != null) setState(() => dueDate = picked);
              }),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: paymentType,
                items: const [
                  DropdownMenuItem(value: "Cash", child: Text("Cash Payment")),
                  DropdownMenuItem(value: "Online", child: Text("Digital Transfer")),
                  DropdownMenuItem(value: "Other", child: Text("Other Modes")),
                ],
                onChanged: (v) => setState(() => paymentType = v!),
                decoration: const InputDecoration(
                  labelText: "Preferred Mode",
                  prefixIcon: Icon(Icons.payment_rounded),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.primaryContainer),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Expected Total", style: theme.textTheme.labelMedium),
                        Text(
                          "₹${totalAmount.toStringAsFixed(2)}",
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
      dueDate: dueDate,
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
          "${date.day}/${date.month}/${date.year}",
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
  }
}