import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';

import 'logger_service.dart';
import 'notification_api_client.dart'; // We will create this

class OneSignalService {
  final LoggerService _logger;

  OneSignalService(this._logger);

  /// Initialize OneSignal SDK (v5+)
  Future<void> init(String appId) async {
    if (kIsWeb) {
      _logger.info('OneSignal bypassed on Web.');
      return;
    }
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(appId);
      
      // We will handle permission separately on login or feature request.
      
      _logger.info('OneSignal initialized successfully.');

      // Notification tap handler
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        if (data != null && data.containsKey('route')) {
          _handleDeepLink(data);
        }
      });
    } catch (e, st) {
      _logger.error('Failed to initialize OneSignal', e, st);
    }
  }

  /// Called upon user login to map Firebase UID to OneSignal External ID
  Future<void> login(String firebaseUid) async {
    if (kIsWeb) return;
    try {
      await OneSignal.login(firebaseUid);
      _logger.info('OneSignal mapped to external ID: $firebaseUid');
      
      // Request permission after successful login
      await _requestPermission();
    } catch (e, st) {
      _logger.error('Failed to login to OneSignal', e, st);
    }
  }

  /// Called upon user logout
  Future<void> logout() async {
    if (kIsWeb) return;
    try {
      await OneSignal.logout();
      _logger.info('OneSignal logged out.');
    } catch (e, st) {
      _logger.error('Failed to logout of OneSignal', e, st);
    }
  }

  Future<void> _requestPermission() async {
    try {
      final hasPermission = await OneSignal.Notifications.requestPermission(true);
      _logger.info('OneSignal permission granted: $hasPermission');
    } catch (e, st) {
      _logger.error('Failed to request OneSignal permission', e, st);
    }
  }

  void _handleDeepLink(Map<String, dynamic> data) {
    // In a real scenario, you'd use a GlobalKey<NavigatorState> 
    // or a routing package like go_router to navigate based on data['route'].
    final route = data['route'] as String?;
    final assignmentId = data['assignmentId'] as String?;
    
    _logger.info('Notification tapped. Route: $route, AssignmentId: $assignmentId');
    // TODO: Dispatch navigation event
  }
}
