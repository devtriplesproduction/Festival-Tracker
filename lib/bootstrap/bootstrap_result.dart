import '../data/repositories/app_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../providers/app_state.dart';
import '../providers/auth_state.dart';
import '../services/upload_service.dart';
import '../core/services/onesignal_service.dart';
import '../core/services/notification_api_client.dart';

class BootstrapResult {
  final AppState appState;
  final AuthState authState;
  final AppRepository appRepository;
  final AuthRepository authRepository;
  final UploadService uploadService;
  final OneSignalService? oneSignalService;
  final NotificationApiClient? notificationApiClient;
  final dynamic googleDriveService;
  final bool isLocalMode;

  BootstrapResult({
    required this.appState,
    required this.authState,
    required this.appRepository,
    required this.authRepository,
    required this.uploadService,
    required this.oneSignalService,
    required this.notificationApiClient,
    required this.googleDriveService,
    required this.isLocalMode,
  });
}
