import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/firebase/firebase_service.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseService.analytics;

  /// Log a custom event
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  /// Log screen view
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Set user ID
  static Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Set user property
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Log login event
  static Future<void> logLogin({String? loginMethod}) async {
    await logEvent(
      name: 'login',
      parameters: {
        if (loginMethod != null) 'method': loginMethod,
      },
    );
  }

  /// Log sign up event
  static Future<void> logSignUp({String? signUpMethod}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {
        if (signUpMethod != null) 'method': signUpMethod,
      },
    );
  }

  /// Log button click
  static Future<void> logButtonClick({
    required String buttonName,
    String? screenName,
  }) async {
    await logEvent(
      name: 'button_click',
      parameters: {
        'button_name': buttonName,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }
}



