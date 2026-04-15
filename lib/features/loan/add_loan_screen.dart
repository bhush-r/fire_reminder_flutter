import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/loan_calculator.dart';
import '../../core/utils/validators.dart';
import '../../data/models/loan_model.dart';
import 'loan_controller.dart';

class AddLoanScreen extends ConsumerStatefulWidget {
  final Loan? existingLoan;

  const AddLoanScreen({super.key, this.existingLoan});

  @override
  ConsumerState<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends ConsumerState<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController principalCtrl;
  late TextEditingController rateCtrl;
  late TextEditingController tenureCtrl;

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _principalFocus = FocusNode();
  final _rateFocus = FocusNode();
  final _tenureFocus = FocusNode();

  late DateTime givenDate;
  String paymentType = "Cash";

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    nameCtrl =
        TextEditingController(text: widget.existingLoan?.customerName ?? "");
    phoneCtrl = TextEditingController(
      text: widget.existingLoan?.phone.replaceFirst("+91", "") ?? "",
    );
    principalCtrl = TextEditingController(
      text: widget.existingLoan?.principal.toString() ?? "",
    );
    rateCtrl = TextEditingController(
      text: widget.existingLoan?.interestRate.toString() ?? "",
    );
    tenureCtrl = TextEditingController(
      text: widget.existingLoan?.emis.length.toString() ?? "12",
    );
    givenDate = widget.existingLoan?.givenDate ?? DateTime.now();
    paymentType = widget.existingLoan?.paymentType ?? "Cash";
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    principalCtrl.dispose();
    rateCtrl.dispose();
    tenureCtrl.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _principalFocus.dispose();
    _rateFocus.dispose();
    _tenureFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final principal = double.tryParse(principalCtrl.text) ?? 0;
    final rate = double.tryParse(rateCtrl.text) ?? 0;
    final tenure = int.tryParse(tenureCtrl.text) ?? 0;

    final emiAmount =
    LoanCalculator.calculateEmi(principal, rate, tenure > 0 ? tenure : 1);
    final totalPayable = emiAmount * tenure;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingLoan == null ? "New Loan Account" : "Edit Loan Terms",
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: _saveLoan,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
        autovalidateMode:
        _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_phoneFocus),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "Mobile Number",
                  prefixText: "+91 ",
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: "",
                ),
                validator: Validators.phone10,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_principalFocus),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, "Loan Parameters"),
              const SizedBox(height: 16),
              _field(
                controller: principalCtrl,
                label: "Principal Amount (₹)",
                keyboard:
                const TextInputType.numberWithOptions(decimal: true, signed: false),
                icon: Icons.account_balance_wallet_outlined,
                validator: Validators.amount,
                focusNode: _principalFocus,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_rateFocus),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: rateCtrl,
                      label: "Annual Interest %",
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      icon: Icons.percent_rounded,
                      validator: Validators.rate,
                      focusNode: _rateFocus,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_tenureFocus),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _field(
                      controller: tenureCtrl,
                      label: "Tenure (Months)",
                      keyboard: TextInputType.number,
                      icon: Icons.calendar_today_rounded,
                      validator: (v) =>
                      (int.tryParse(v ?? "") ?? 0) <= 0 ? "Invalid tenure" : null,
                      focusNode: _tenureFocus,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _saveLoan(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _dateTile(
                theme,
                "Disbursement Date",
                givenDate,
                    () async {
                  final picked = await _pickDate(context, givenDate);
                  if (picked != null) setState(() => givenDate = picked);
                },
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: paymentType,
                items: const [
                  DropdownMenuItem(value: "Cash", child: Text("Cash Basis")),
                  DropdownMenuItem(value: "Online", child: Text("Digital Transfer")),
                  DropdownMenuItem(value: "Bank", child: Text("Bank Check")),
                ],
                onChanged: (v) => setState(() => paymentType = v ?? "Cash"),
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
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                "Preview",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Monthly EMI",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                _currency.format(emi),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Payable",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                _currency.format(total),
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
    setState(() => _submitted = true);
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
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  Widget _dateTile(
      ThemeData theme,
      String title,
      DateTime date,
      VoidCallback onTap,
      ) {
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
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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