import 'package:url_launcher/url_launcher.dart';

class WhatsAppUtil {
  static Future<void> call(String phone) async {
    // tel: scheme works with +, but we should remove spaces or dashes
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri.parse("tel:$cleanPhone");

    try {
      // On some modern Android versions, canLaunchUrl returns false even if it can launch.
      // We attempt to launch directly to be more robust.
      await launchUrl(uri);
    } catch (e) {
      // Handle the error silently or log it
    }
  }

  static Future<void> sendReminder({
    required String phone,
    required String name,
    required double pending,
    required int daysRemaining,
  }) async {
    // WhatsApp wa.me links require the number starting with country code
    // but WITHOUT the '+' sign or any other characters.
    // Example: +919876543210 must become 919876543210
    final whatsappPhone = phone.replaceAll(RegExp(r'\D'), '');

    final statusMsg = daysRemaining < 0
        ? "Your payment is ${-daysRemaining} days overdue."
        : "Your payment is due in $daysRemaining days.";

    final msg = Uri.encodeComponent(
        "Hi $name, this is a reminder regarding your loan. "
            "Your pending amount is ₹${pending.toStringAsFixed(2)}. "
            "$statusMsg Please clear it at the earliest."
    );

    final uri = Uri.parse("https://wa.me/$whatsappPhone?text=$msg");

    try {
      // Use externalApplication mode to force it to open the WhatsApp app
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Handle the error if WhatsApp is not installed
    }
  }
}