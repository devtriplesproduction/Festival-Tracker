import 'package:url_launcher/url_launcher.dart';

/// Builds and opens WhatsApp deep links (wa.me) for client poster delivery.
class WhatsAppService {
  static String generateLink({
    required String phoneNumber,
    required String clientName,
    required String festivalName,
    String? driveUrl,
  }) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final buffer = StringBuffer()
      ..writeln('Hello $clientName! 👋')
      ..writeln()
      ..writeln(
        'Here is your custom festival poster for *$festivalName* from Triple S Production 🎨✨.',
      )
      ..writeln();
    if (driveUrl != null && driveUrl.isNotEmpty) {
      buffer
        ..writeln('📁 Download High-Res Poster: $driveUrl')
        ..writeln();
    }
    buffer
      ..writeln('Wishing you and your team a wonderful celebration! 🎉')
      ..write('— Triple S Production');

    final text = Uri.encodeComponent(buffer.toString());
    return 'https://wa.me/$cleanPhone?text=$text';
  }

  static Future<bool> openChat({
    required String phoneNumber,
    required String clientName,
    required String festivalName,
    String? driveUrl,
  }) async {
    final link = generateLink(
      phoneNumber: phoneNumber,
      clientName: clientName,
      festivalName: festivalName,
      driveUrl: driveUrl,
    );
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
