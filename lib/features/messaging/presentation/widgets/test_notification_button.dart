import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/crashlytics_service.dart';

class TestNotificationButton extends StatelessWidget {
  const TestNotificationButton({super.key});

  Future<void> _testNotification(BuildContext context) async {
    try {
      // Log analytics event
      await AnalyticsService.logButtonClick(
        buttonName: 'test_notification',
        screenName: 'home_screen',
      );

      // Get FCM token
      final token = await FirebaseMessaging.instance.getToken();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📩 Notification de test',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Token FCM: ${token?.substring(0, 20)}...',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pour envoyer une notification, utilisez Firebase Console > Cloud Messaging',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.blue,
          ),
        );
      }

      await CrashlyticsService.log('Test notification button clicked');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _testNotification(context),
      icon: const Icon(Icons.notifications_active),
      label: const Text('📩 Tester une notification'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}


