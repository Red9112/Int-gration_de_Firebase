import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../services/crashlytics_service.dart';
import '../../services/analytics_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Get FCM token
  static String? get fcmToken => _fcmToken;

  /// Initialize FCM service
  static Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint('User granted permission: ${settings.authorizationStatus}');
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (kDebugMode) {
        debugPrint('FCM Token: $_fcmToken');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          debugPrint('FCM Token refreshed: $newToken');
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage =
          await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('Message notification: ${message.notification?.title}');
      }
    }

    // Log analytics event
    AnalyticsService.logEvent(
      name: 'notification_received',
      parameters: {
        'message_id': message.messageId ?? '',
        'notification_title': message.notification?.title ?? '',
      },
    );
  }

  /// Handle background messages
  static void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Got a message whilst in the background!');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('Message notification: ${message.notification?.title}');
      }
    }

    // Log analytics event
    AnalyticsService.logEvent(
      name: 'notification_opened',
      parameters: {
        'message_id': message.messageId ?? '',
        'notification_title': message.notification?.title ?? '',
      },
    );

    // Handle navigation based on message data
    // Example: Navigate to a specific screen based on message.data['route']
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      await CrashlyticsService.log('Subscribed to topic: $topic');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      await CrashlyticsService.log('Unsubscribed from topic: $topic');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
    }
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      await CrashlyticsService.log('FCM token deleted');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
    }
  }
}

/// Top-level function for handling background messages
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Handling a background message: ${message.messageId}');
  }
  // You can perform background tasks here
}

