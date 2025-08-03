import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'mindfulness_timer_channel';
  static const String _channelName = 'Mindfulness Timer';
  static const String _channelDescription =
      'Notifications for mindfulness timer';
  static const int _ongoingNotificationId = 1;
  static const int _bellPlayingNotificationId = 2;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Create notification channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      showBadge: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Shows a notification with stop button when bell is playing
  Future<void> showBellPlayingNotification({
    required String title,
    required String body,
    required VoidCallback onStopPressed,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
          ongoing: true,
          autoCancel: false,
          actions: [const AndroidNotificationAction('stop_bell', 'Stop Bell')],
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      _bellPlayingNotificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: 'bell_playing',
    );
  }

  /// Shows a standard notification
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/
          1000, // Unique ID based on timestamp
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Shows an ongoing notification that can't be dismissed by the user
  Future<void> showOngoingNotification({
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          showWhen: false,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      _ongoingNotificationId, // Use a fixed ID for the ongoing notification
      title,
      body,
      platformChannelSpecifics,
    );
  }
  
  /// Cancels all active notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancels the bell playing notification
  Future<void> cancelBellPlayingNotification() async {
    await _notificationsPlugin.cancel(_bellPlayingNotificationId);
  }

  // For backward compatibility
  Future<void> showTimerNotification({
    required String title,
    required String body,
    bool isOngoing = false,
  }) async {
    if (isOngoing) {
      return showOngoingNotification(title: title, body: body);
    } else {
      return showNotification(title: title, body: body);
    }
  }
}
