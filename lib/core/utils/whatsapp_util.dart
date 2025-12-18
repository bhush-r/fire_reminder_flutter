import 'package:url_launcher/url_launcher.dart';

class WhatsAppUtil {
  static Future<void> call(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> sendReminder({
    required String phone,
    required String name,
    required double pending,
    required int daysRemaining,
  }) async {
    final msg = Uri.encodeComponent(
      "Hi $name, your pending amount is ₹${pending.toStringAsFixed(2)}. "
      "${daysRemaining < 0 ? "Overdue" : "Due in $daysRemaining days"}.",
    );
    final uri = Uri.parse("https://wa.me/$phone?text=$msg");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
