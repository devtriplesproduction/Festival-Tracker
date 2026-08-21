import 'package:url_launcher/url_launcher.dart';

/// Builds and opens WhatsApp deep links (wa.me) for client poster delivery.
class WhatsAppService {
  static String generateLink({
    required String phoneNumber,
    required String clientName,
    required String festivalName,
    String? posterUrl,
    String? driveUrl,
    String? designerNotes,
  }) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final effectiveDesignUrl = (posterUrl != null && posterUrl.isNotEmpty)
        ? posterUrl
        : (driveUrl != null && driveUrl.isNotEmpty ? driveUrl : null);

    final buffer = StringBuffer()
      ..writeln('Hello $clientName! 👋')
      ..writeln()
      ..writeln(
        'Here is your custom festival poster for *$festivalName* from *Triple S Production* 🎨✨',
      )
      ..writeln();

    if (effectiveDesignUrl != null && effectiveDesignUrl.isNotEmpty) {
      buffer
        ..writeln('🖼️ *Attached Design:*')
        ..writeln(effectiveDesignUrl)
        ..writeln();
    }

    if (designerNotes != null && designerNotes.trim().isNotEmpty) {
      buffer
        ..writeln('📝 *Note:* ${designerNotes.trim()}')
        ..writeln();
    }

    buffer
      ..writeln('Wishing you and your team a wonderful celebration! 🎉')
      ..write('— *Triple S Production*');

    final text = Uri.encodeComponent(buffer.toString());
    return 'https://wa.me/$cleanPhone?text=$text';
  }

  static Future<bool> openChat({
    required String phoneNumber,
    required String clientName,
    required String festivalName,
    String? posterUrl,
    String? driveUrl,
    String? designerNotes,
  }) async {
    final link = generateLink(
      phoneNumber: phoneNumber,
      clientName: clientName,
      festivalName: festivalName,
      posterUrl: posterUrl,
      driveUrl: driveUrl,
      designerNotes: designerNotes,
    );
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static String generateBillingLink({
    required String phoneNumber,
    required String clientName,
    required bool isExpired,
    required double price,
  }) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final status = isExpired ? 'has expired' : 'is expiring soon';
    final action = isExpired ? 'continue our services' : 'avoid service interruption';
    
    final buffer = StringBuffer()
      ..writeln('Hello $clientName! 👋')
      ..writeln()
      ..writeln('This is a gentle reminder from *Triple S Production* that your yearly festival poster package $status.')
      ..writeln()
      ..writeln('Renewal Price: *₹${price.toStringAsFixed(0)}*')
      ..writeln()
      ..writeln('Please renew your package to $action.')
      ..writeln()
      ..write('Thank you for being with us! ✨');

    final text = Uri.encodeComponent(buffer.toString());
    return 'https://wa.me/$cleanPhone?text=$text';
  }

  static Future<bool> openBillingChat({
    required String phoneNumber,
    required String clientName,
    required bool isExpired,
    required double price,
  }) async {
    final link = generateBillingLink(
      phoneNumber: phoneNumber,
      clientName: clientName,
      isExpired: isExpired,
      price: price,
    );
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
