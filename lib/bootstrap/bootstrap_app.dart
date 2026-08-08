import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/logger_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_state.dart';
import '../screens/auth/login_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash/splash_screen.dart';
import 'app_initializer.dart';
import 'bootstrap_result.dart';
import '../core/services/onesignal_service.dart';
import '../core/services/notification_api_client.dart';

class BootstrapApp extends StatefulWidget {
  final LoggerService logger;

  const BootstrapApp({super.key, required this.logger});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  BootstrapResult? _result;
  String _initializationMessage = 'Starting up...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  Future<void> _startBootstrap() async {
    // Add artificial delay for smooth splash animation if desired
    final startTime = DateTime.now();

    try {
      final result = await AppInitializer.init(
        onProgress: (msg) {
          if (mounted) {
            setState(() => _initializationMessage = msg);
          }
        },
        logger: widget.logger,
      );

      final elapsed = DateTime.now().difference(startTime);
      final minDuration = const Duration(milliseconds: 2000);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }

      if (mounted) {
        setState(() {
          _result = result;
        });
      }
    } catch (e, stackTrace) {
      widget.logger.error('Bootstrap failed completely', e, stackTrace);
      if (mounted) {
        setState(() {
          _hasError = true;
          _initializationMessage = 'Initialization failed.\nPlease restart.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertino,
        home: CupertinoPageScaffold(
          child: Center(
            child: Text(
              _initializationMessage,
              textAlign: TextAlign.center,
              style: AppFonts.montserrat(color: AppColors.overdue),
            ),
          ),
        ),
      );
    }

    if (_result == null) {
      return CupertinoApp(
        title: 'Festival Tracker Initialization',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertino,
        home: SplashScreen(
          message: _initializationMessage,
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _result!.appState),
        ChangeNotifierProvider.value(value: _result!.authState),
        Provider.value(value: _result!.appRepository),
        Provider.value(value: _result!.authRepository),
        Provider.value(value: _result!.uploadService),
        Provider.value(value: widget.logger),
        if (_result!.oneSignalService != null)
          Provider.value(value: _result!.oneSignalService),
        if (_result!.notificationApiClient != null)
          Provider.value(value: _result!.notificationApiClient),
        if (_result!.googleDriveService != null)
          Provider.value(value: _result!.googleDriveService),
      ],
      child: const FestivalTrackerApp(),
    );
  }
}

class FestivalTrackerApp extends StatelessWidget {
  const FestivalTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Festival Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.material,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Clamp system text scale so layouts stay stable on all devices
        // while still respecting moderate accessibility scaling.
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.90,
          maxScaleFactor: 1.25,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: CupertinoTheme(
            data: AppTheme.cupertino,
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: Consumer<AuthState>(
        builder: (context, authState, _) {
          if (!authState.ready) {
            return const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          if (!authState.isLoggedIn) return const LoginScreen();
          return const MainShell();
        },
      ),
    );
  }
}
