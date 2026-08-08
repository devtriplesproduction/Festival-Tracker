import 'package:flutter/foundation.dart';

class LoggerService {
  void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO]: $message');
    }
  }

  void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARNING]: $message');
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR]: $message');
      if (error != null) {
        debugPrint('Details: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }
}
