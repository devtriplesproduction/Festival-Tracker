import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/logger_service.dart';
import '../data/repositories/app_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/firebase_auth_repository.dart';
import '../data/repositories/firestore_app_repository.dart';
import '../data/repositories/local_auth_repository.dart';
import '../firebase_options.dart';
import '../providers/auth_state.dart';
import '../providers/app_state.dart';
import '../services/upload_service.dart';
import '../core/services/onesignal_service.dart';
import '../core/services/notification_api_client.dart';
import 'bootstrap_result.dart';

class AppInitializer {
  static Future<BootstrapResult> init({
    required Function(String) onProgress,
    required LoggerService logger,
  }) async {
    bool isLocalMode = false;
    AppRepository appRepo;
    AuthRepository authRepo;

    try {
      // 1. Initialize SharedPreferences
      onProgress('Loading Settings...');
      final prefs = await SharedPreferences.getInstance();

      // 2. Initialize Firebase
      onProgress('Initializing Firebase...');
      const useLocal = !DefaultFirebaseOptions.isConfigured;

      if (!useLocal) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          logger.info('Firebase initialized successfully.');
          
          onProgress('Connecting Database...');
          appRepo = FirestoreAppRepository();
          authRepo = FirebaseAuthRepository(prefs);
        } catch (e, stackTrace) {
          logger.error('Firebase initialization failed, falling back to local mode', e, stackTrace);
          isLocalMode = true;
          appRepo = LocalAppRepository(prefs);
          authRepo = LocalAuthRepository(prefs);
        }
      } else {
        logger.info('No Firebase configuration found, using local mode.');
        isLocalMode = true;
        appRepo = LocalAppRepository(prefs);
        authRepo = LocalAuthRepository(prefs);
      }

      if (isLocalMode) {
        onProgress('Initializing Local Database...');
        await (appRepo as LocalAppRepository).init();
      }

      // 3. Initialize Services
      onProgress('Preparing Services...');
      final uploadService = UploadService();
      
      OneSignalService? oneSignalService;
      NotificationApiClient? notificationApiClient;
      
      if (!isLocalMode) {
        // You would inject the OneSignal APP ID here (e.g. from environment variables)
        oneSignalService = OneSignalService(logger);
        await oneSignalService.init('193c6c80-e626-44b2-a90e-d4bf3fb821c8'); 
        
        notificationApiClient = NotificationApiClient(logger);
      }
      
      // Future ready stubs
      final dynamic googleDriveService = null;

      // 4. Initialize State
      onProgress('Loading User...');
      final appState = AppState(appRepo, notificationApiClient: notificationApiClient);
      await appState.init(localStore: isLocalMode);

      final authState = AuthState(authRepo);
      await authState.init();

      onProgress('Ready');

      return BootstrapResult(
        appState: appState,
        authState: authState,
        appRepository: appRepo,
        authRepository: authRepo,
        uploadService: uploadService,
        oneSignalService: oneSignalService,
        notificationApiClient: notificationApiClient,
        googleDriveService: googleDriveService,
        isLocalMode: isLocalMode,
      );
    } catch (e, stackTrace) {
      logger.error('Critical initialization failure', e, stackTrace);
      // In a real critical failure, we should probably throw or return a failed state.
      // We will rethrow here to be caught by the runZonedGuarded or UI if necessary,
      // but as per requirements, we try to recover gracefully.
      rethrow;
    }
  }
}
