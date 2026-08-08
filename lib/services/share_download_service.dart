import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Opens remote poster URLs or local files via the platform.
class ShareDownloadService {
  static Future<bool> openPoster(String? pathOrUrl) async {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return false;

    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      final uri = Uri.parse(pathOrUrl);
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    }

    final file = File(pathOrUrl);
    if (!await file.exists()) return false;
    final uri = Uri.file(pathOrUrl);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
