import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;

  static FirebaseAnalytics get analytics {
    if (_analytics == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _analytics!;
  }

  static FirebaseCrashlytics? get crashlytics {
    return _crashlytics;
  }

  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;

      // Initialize Crashlytics only if not in debug mode or if explicitly needed
      // Do this asynchronously to avoid blocking the main thread
      _initializeCrashlyticsAsync();
    } catch (e, stackTrace) {
      // If Firebase initialization fails, log it
      if (kDebugMode) {
        debugPrint('Error initializing Firebase: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  // Initialize Crashlytics asynchronously to avoid blocking
  static void _initializeCrashlyticsAsync() {
    // Run in background to avoid blocking UI
    Future.microtask(() async {
      try {
        _crashlytics = FirebaseCrashlytics.instance;
        
        // Only enable Crashlytics in release mode
        // In debug mode, Crashlytics can cause issues
        if (!kDebugMode) {
          await _crashlytics!.setCrashlyticsCollectionEnabled(true);
          
          // Set up Flutter error handler for Crashlytics
          FlutterError.onError = (errorDetails) {
            _crashlytics?.recordFlutterFatalError(errorDetails);
          };

          // Set up async error handler for Crashlytics
          PlatformDispatcher.instance.onError = (error, stack) {
            _crashlytics?.recordError(error, stack, fatal: true);
            return true;
          };
        } else {
          // In debug mode, disable Crashlytics collection to avoid errors
          await _crashlytics!.setCrashlyticsCollectionEnabled(false);
        }
      } catch (e) {
        // If Crashlytics fails to initialize, continue without it
        if (kDebugMode) {
          debugPrint('Crashlytics initialization skipped: $e');
        }
        _crashlytics = null;
      }
    });
  }
}

