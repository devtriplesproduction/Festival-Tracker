import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'logger_service.dart';

/// Models the event types our backend knows how to process.
enum NotificationEventType {
  newAssignment,
  qcRejected,
  deadlineReminder,
  overdueReminder,
  qcUploaded,
  qcApproved,
  readyToSend,
  posterSent,
  uploadFailed,
  packageExpiry,
}

extension NotificationEventTypeExt on NotificationEventType {
  String get value {
    switch (this) {
      case NotificationEventType.newAssignment: return 'NEW_ASSIGNMENT';
      case NotificationEventType.qcRejected: return 'QC_REJECTED';
      case NotificationEventType.deadlineReminder: return 'DEADLINE_REMINDER';
      case NotificationEventType.overdueReminder: return 'OVERDUE_REMINDER';
      case NotificationEventType.qcUploaded: return 'QC_UPLOADED';
      case NotificationEventType.qcApproved: return 'QC_APPROVED';
      case NotificationEventType.readyToSend: return 'READY_TO_SEND';
      case NotificationEventType.posterSent: return 'POSTER_SENT';
      case NotificationEventType.uploadFailed: return 'UPLOAD_FAILED';
      case NotificationEventType.packageExpiry: return 'PACKAGE_EXPIRY';
    }
  }
}

class NotificationApiClient {
  final LoggerService _logger;
  final Dio _dio;
  
  // URL to the Node.js backend. In production, this would be an environment variable.
  static const String _baseUrl = 'https://notification-server-asep.onrender.com/api/notifications/';

  NotificationApiClient(this._logger) : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    
    // Add retry interceptor or basic error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          _logger.warning('Failed to attach Firebase token to notification request: $e');
        }
        return handler.next(options);
      },
    ));
  }

  /// Fire-and-forget notification dispatch.
  /// Never blocks the main UI or Firestore writes.
  Future<void> sendEvent({
    required NotificationEventType eventType,
    String? targetUid,
    String? targetRole,
    Map<String, dynamic>? data,
  }) async {
    // We intentionally don't await the HTTP call to avoid blocking.
    _sendInternal(eventType, targetUid, targetRole, data).catchError((e, st) {
      _logger.error('Failed to send push notification', e, st);
    });
  }

  Future<void> _sendInternal(
    NotificationEventType eventType,
    String? targetUid,
    String? targetRole,
    Map<String, dynamic>? data,
  ) async {
    print('DEBUG: _sendInternal called with eventType: $eventType, targetRole: $targetRole');
    try {
      final response = await _dio.post('send', data: {
        'eventType': eventType.value,
        if (targetUid != null) 'targetUid': targetUid,
        if (targetRole != null) 'targetRole': targetRole,
        if (data != null) 'data': data,
      });

      print('DEBUG: _sendInternal response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        _logger.info('Push notification dispatched successfully.');
      } else {
        _logger.warning('Push notification backend returned: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: _sendInternal caught exception: $e');
      _logger.warning('Failed to reach notification backend: $e');
    }
      rethrow; // Caught by outer catchError
    }
  }
}
