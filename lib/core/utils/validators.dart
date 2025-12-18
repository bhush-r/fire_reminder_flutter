class Validators {
  static String? required(String? v) =>
      v == null || v.trim().isEmpty ? "Required" : null;

  static String? phone10(String? v) =>
      v == null || v.length != 10 ? "Enter 10 digit number" : null;

  static String? amount(String? v) =>
      v == null || double.tryParse(v) == null || double.parse(v) <= 0
          ? "Invalid amount"
          : null;

  static String? rate(String? v) =>
      v == null || double.tryParse(v) == null ? "Invalid rate" : null;
}
