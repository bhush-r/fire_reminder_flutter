double calculateTotalAmount({
  required double principal,
  required double ratePerMonth,
  required DateTime givenDate,
  required DateTime dueDate,
}) {
  final months =
      (dueDate.year - givenDate.year) * 12 + (dueDate.month - givenDate.month);

  return principal + (principal * ratePerMonth / 100 * (months > 0 ? months : 0));
}

class LoanCalculator {
  static int daysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }
}