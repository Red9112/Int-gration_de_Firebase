import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../core/firebase/firebase_service.dart';

class CrashlyticsService {
  static FirebaseCrashlytics? get _crashlytics => FirebaseService.crashlytics;

  /// Record an error
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      // Silently fail if Crashlytics is not ready
      if (kDebugMode) {
        debugPrint('Crashlytics recordError failed: $e');
      }
    }
  }

  /// Log a message
  static Future<void> log(String message) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.log(message);
    } catch (e) {
      // Silently fail if Crashlytics is not ready
      if (kDebugMode) {
        debugPrint('Crashlytics log failed: $e');
      }
    }
  }

  /// Set user identifier
  static Future<void> setUserIdentifier(String identifier) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.setUserIdentifier(identifier);
    } catch (e) {
      // Silently fail if Crashlytics is not ready
      if (kDebugMode) {
        debugPrint('Crashlytics setUserIdentifier failed: $e');
      }
    }
  }

  /// Set custom key
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      // Silently fail if Crashlytics is not ready
      if (kDebugMode) {
        debugPrint('Crashlytics setCustomKey failed: $e');
      }
    }
  }

  /// Set custom keys (multiple)
  static void setCustomKeys(Map<String, dynamic> keys) {
    for (final entry in keys.entries) {
      setCustomKey(entry.key, entry.value);
    }
  }

  /// Check if crashlytics collection is enabled
  static bool get isCrashlyticsCollectionEnabled {
    if (_crashlytics == null) return false;
    try {
      return _crashlytics!.isCrashlyticsCollectionEnabled;
    } catch (e) {
      // Return false if Crashlytics is not ready
      return false;
    }
  }

  /// Enable or disable crashlytics collection
  static Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Crashlytics setCrashlyticsCollectionEnabled failed: $e');
      }
    }
  }

  /// Force a crash (for testing - use only in debug mode)
  static void crash() {
    if (kDebugMode && _crashlytics != null) {
      _crashlytics!.crash();
    }
  }
}

