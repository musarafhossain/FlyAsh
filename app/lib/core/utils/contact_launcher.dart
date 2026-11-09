import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer / WhatsApp for an Indian 10-digit number
/// (customers, labours). Returns false when nothing could open it, so the
/// screen can show a message.
abstract final class ContactLauncher {
  /// Replaced in tests to record what would open.
  static Future<bool> Function(Uri uri) launch = (uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<bool> call(String phone) =>
      _safe(Uri(scheme: 'tel', path: '+91${_digits(phone)}'));

  /// WhatsApp chat with the number (app on phones, web elsewhere).
  static Future<bool> whatsApp(String phone) =>
      _safe(Uri.https('wa.me', '/91${_digits(phone)}'));

  static String _digits(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    return d.length > 10 ? d.substring(d.length - 10) : d;
  }

  static Future<bool> _safe(Uri uri) async {
    try {
      return await launch(uri);
    } catch (_) {
      return false;
    }
  }
}
