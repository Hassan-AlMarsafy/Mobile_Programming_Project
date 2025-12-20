import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> showAlertNotification({
    required String title,
    required String body,
    required String severity,
  }) async {
    if (!_isInitialized) await initialize();

    // Different notification styles based on severity
    final androidDetails = AndroidNotificationDetails(
      'hydroponic_alerts',
      'Sensor Alerts',
      channelDescription: 'Notifications for sensor threshold violations',
      importance: severity == 'critical' ? Importance.max : Importance.high,
      priority: severity == 'critical' ? Priority.max : Priority.high,
      icon: '@mipmap/ic_launcher',
      color: severity == 'critical'
          ? const Color.fromARGB(255, 220, 53, 69) // Red
          : const Color.fromARGB(255, 255, 193, 7), // Orange/Yellow
      enableVibration: true,
      playSound: true,
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

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
