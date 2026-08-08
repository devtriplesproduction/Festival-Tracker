import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bootstrap/bootstrap_app.dart';
import 'core/services/logger_service.dart';

void main() {
  final logger = LoggerService();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Phones + tablets: allow landscape on larger devices via system;
      // all orientations supported for foldables/tablets.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      runApp(BootstrapApp(logger: logger));
    },
    (error, stackTrace) {
      logger.error('Global unhandled exception', error, stackTrace);
      // Future: Crashlytics integration would go here
    },
  );
}
