import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/crashlytics_service.dart';
import '../../services/analytics_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _localNotificationsInitialized = false;

  /// Get FCM token
  static String? get fcmToken => _fcmToken;

  /// Initialize FCM service
  static Future<void> initialize() async {
    try {
      // Initialize local notifications for foreground messages (not needed on web)
      if (!kIsWeb) {
        await _initializeLocalNotifications();
      }

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

  /// Initialize local notifications (Android/iOS only, not for web)
  static Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        if (kDebugMode) {
          debugPrint('Notification tapped: ${details.payload}');
        }
      },
    );

    // Create Android notification channel (required for Android 8.0+)
    await _createAndroidNotificationChannel();

    _localNotificationsInitialized = true;
  }

  /// Create Android notification channel (required for Android 8.0+)
  /// Configured for heads-up (popup) notifications
  static Future<void> _createAndroidNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications from Firebase Cloud Messaging. Notifications will appear as popups.',
      importance: Importance.max, // MAX importance = heads-up (popup) notifications
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    if (kDebugMode) {
      debugPrint('✅ Android notification channel created: high_importance_channel (heads-up enabled)');
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('🔔 [Foreground] Got a message whilst in the foreground!');
      debugPrint('🔔 [Foreground] Message ID: ${message.messageId}');
      debugPrint('🔔 [Foreground] Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('🔔 [Foreground] Notification title: ${message.notification?.title}');
        debugPrint('🔔 [Foreground] Notification body: ${message.notification?.body}');
      } else {
        debugPrint('⚠️ [Foreground] Message has no notification field (only data)');
        debugPrint('⚠️ [Foreground] On Android, notifications need the "notification" field to display automatically');
      }
    }

    // Show local notification for foreground messages (Android/iOS only)
    // On web, notifications are handled by the browser's notification API
    if (!kIsWeb && message.notification != null && _localNotificationsInitialized) {
      final notification = message.notification!;
      // Configure for heads-up (popup) notifications
      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications from Firebase Cloud Messaging.',
        importance: Importance.max, // MAX importance = heads-up (popup) notifications
        priority: Priority.max, // MAX priority = popup notification
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          notification.body ?? '',
          htmlFormatBigText: false,
          contentTitle: notification.title ?? 'Nouvelle notification',
          htmlFormatContentTitle: false,
        ), // Allows long text with title
        fullScreenIntent: false, // Set to true if you want full-screen popup
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        ongoing: false,
        autoCancel: true,
        channelShowBadge: true,
        ticker: notification.title ?? 'Nouvelle notification', // Text shown in status bar
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFF6750A4), // Material 3 primary color
        colorized: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Nouvelle notification',
        notification.body ?? '',
        details,
        payload: message.data.toString(),
      );
      
      if (kDebugMode) {
        debugPrint('✅ [Foreground] Local notification displayed');
      }
    } else if (kIsWeb && message.notification != null) {
      // On web, use browser's Notification API for foreground messages
      if (kDebugMode) {
        debugPrint('Web: Notification will be shown by browser: ${message.notification?.title}');
      }
      // The browser will automatically show the notification if permission is granted
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

  /// Handle background messages (when app is opened from notification)
  static void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('🔔 [Background] App opened from notification!');
      debugPrint('🔔 [Background] Message ID: ${message.messageId}');
      debugPrint('🔔 [Background] Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('🔔 [Background] Notification title: ${message.notification?.title}');
        debugPrint('🔔 [Background] Notification body: ${message.notification?.body}');
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
/// This handler is called when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  try {
    // Note: Firebase should already be initialized, but we ensure it here
    if (kDebugMode) {
      debugPrint('🔔 [Background Handler] Received message: ${message.messageId}');
      debugPrint('🔔 [Background Handler] Title: ${message.notification?.title}');
      debugPrint('🔔 [Background Handler] Body: ${message.notification?.body}');
      debugPrint('🔔 [Background Handler] Data: ${message.data}');
    }

    // On Android, notifications are automatically displayed by the system
    // when the app is in background or terminated
    // We just log here for debugging purposes
    
    // You can perform background tasks here, such as:
    // - Updating local database
    // - Scheduling tasks
    // - Logging to analytics
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ [Background Handler] Error: $e');
    }
  }
}

