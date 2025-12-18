package com.example.fire_reminder_flutter.features.loan;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    phoneCtrl = TextEditingController(
      text: widget.existingLoan?.phone.replaceFirst("+91", "") ?? "",
    );
    principalCtrl =
        TextEditingController(text: widget.existingLoan?.principal.toString() ?? "");
    rateCtrl =
        TextEditingController(text: widget.existingLoan?.interestRate.toString() ?? "");

    givenDate = widget.existingLoan?.givenDate ?? DateTime.now();
    dueDate = widget.existingLoan?.dueDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = calculateTotalAmount(
      principal: double.tryParse(principalCtrl.text) ?? 0,
      ratePerMonth: double.tryParse(rateCtrl.text) ?? 0,
      givenDate: givenDate,
      dueDate: dueDate,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLoan == null ? "Add Loan" : "Edit Loan"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _field(
                controller: nameCtrl,
                label: "Customer Name",
                validator: Validators.required,
              ),

              const SizedBox(height: 12),

              // 📞 PHONE (+91 FIXED)
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixText: "+91 ",
                ),
                validator: Validators.phone10,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: principalCtrl,
                      label: "Principal (₹)",
                      keyboard: TextInputType.number,
                      validator: Validators.amount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: rateCtrl,
                      label: "Interest % (Monthly)",
                      keyboard: TextInputType.number,
                      validator: Validators.rate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _dateTile("Given Date", givenDate, () async {
                final picked = await pickDate(context, givenDate);
                if (picked != null) setState(() => givenDate = picked);
              }),

              _dateTile("Due Date", dueDate, () async {
                final picked = await pickDate(context, dueDate);
                if (picked != null) setState(() => dueDate = picked);
              }),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: paymentType,
                items: const [
                  DropdownMenuItem(value: "Cash", child: Text("Cash")),
                  DropdownMenuItem(value: "Online", child: Text("Online")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (v) => paymentType = v!,
                decoration: const InputDecoration(labelText: "Payment Type"),
              ),

              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  title: const Text("Total Amount"),
                  subtitle: Text("₹${totalAmount.toStringAsFixed(2)}"),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saveLoan,
                  child: Text(widget.existingLoan == null ? "Save Loan" : "Update Loan"),
                ),
              ),
            ],
          ),
        ),
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

  TextFormField _field({
    required TextEditingController controller,
    required String label,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  Widget _dateTile(String title, DateTime date, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text("${date.day}-${date.month}-${date.year}"),
      trailing: const Icon(Icons.calendar_month),
      onTap: onTap,
    );
  }

  Future<DateTime?> pickDate(BuildContext context, DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }
}
