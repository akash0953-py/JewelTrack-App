// lib/utils/communication_service.dart
import 'package:url_launcher/url_launcher.dart';

class CommunicationService {
  static Future<void> callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final number = cleaned.startsWith('91') ? cleaned : '91$cleaned';
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$number?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static String buildReminderMessage({
    required String shopName,
    required String karigarName,
    required String itemName,
    required double issuedWeight,
    required DateTime expectedDate,
  }) {
    final dateStr =
        '${expectedDate.day}/${expectedDate.month}/${expectedDate.year}';
    return 'Jai Shree Krishna 🙏\n\n'
        'Dear $karigarName,\n\n'
        'This is a reminder from *$shopName*.\n\n'
        'The ornament *$itemName* (${issuedWeight.toStringAsFixed(2)} grams of gold issued) '
        'was expected to be delivered by *$dateStr*.\n\n'
        'Kindly arrange to submit the work at the earliest.\n\n'
        'Thank you 🙏';
  }
}
