double calculateTotalAmount({
  required double principal,
  required double ratePerMonth,
  required DateTime givenDate,
  required DateTime dueDate,
}) {
  final months =
      (dueDate.year - givenDate.year) * 12 + (dueDate.month - givenDate.month);

  return principal + (principal * ratePerMonth / 100 * months);
}
