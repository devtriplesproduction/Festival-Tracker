// Firebase options for Festival Tracker (TSP) → posterflow-6c0cb.
//
// Configured from the Firebase web app credentials for project posterflow-6c0cb.
// For production, prefer running `flutterfire configure` so Android/iOS each
// get their own appId and native config files (google-services.json /
// GoogleService-Info.plist).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  /// True once real Firebase project keys are wired in.
  static const bool isConfigured = true;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAhYw2e25QZ06DdAL4rFHm7kFeKZ_3F9L4',
    appId: '1:67998510522:web:c51cfd45c2a51aa94ac183',
    messagingSenderId: '67998510522',
    projectId: 'posterflow-6c0cb',
    authDomain: 'posterflow-6c0cb.firebaseapp.com',
    storageBucket: 'posterflow-6c0cb.firebasestorage.app',
    measurementId: 'G-FLSKT71FP6',
  );

  // Same project credentials used for mobile until platform-specific apps
  // are registered in the Firebase console.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhYw2e25QZ06DdAL4rFHm7kFeKZ_3F9L4',
    appId: '1:67998510522:web:c51cfd45c2a51aa94ac183',
    messagingSenderId: '67998510522',
    projectId: 'posterflow-6c0cb',
    storageBucket: 'posterflow-6c0cb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAhYw2e25QZ06DdAL4rFHm7kFeKZ_3F9L4',
    appId: '1:67998510522:web:c51cfd45c2a51aa94ac183',
    messagingSenderId: '67998510522',
    projectId: 'posterflow-6c0cb',
    storageBucket: 'posterflow-6c0cb.firebasestorage.app',
    iosBundleId: 'com.triples.festivalTracker',
  );
}
