// lib/data/services/notification_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Channel IDs
  static const String _postPublishedChannelId = 'post_published_channel';
  static const String _postPublishedChannelName = 'Post Published Notifications';
  static const String _postPublishedChannelDesc = 'Notifications for when your posts are published';

  // Singleton pattern
  static final NotificationService _singleton = NotificationService._internal();
  factory NotificationService() => _singleton;
  NotificationService._internal();

  // Stream for notification clicks when app is in background/terminated
  Stream<RemoteMessage> get onNotificationOpen => FirebaseMessaging.onMessageOpenedApp;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined notification permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Using existing launcher icon for simplicity

    // Updated iOS initialization settings without the deprecated parameter
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification clicked with payload: ${details.payload}');
        // Handle notification click here
        if (details.payload != null) {
          try {
            final payloadData = jsonDecode(details.payload!);
            // Handle payload based on notification type
            _handleNotificationTap(payloadData);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Create the notification channels for Android
    await _createNotificationChannels();

    // Handle background/terminated notifications
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state via notification');
        _handleRemoteMessage(message);
      }
    });

    // Configure FCM handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Handle token refresh
    _fcm.onTokenRefresh.listen((String token) {
      debugPrint('FCM token refreshed: $token');
      // You'll implement token saving in the repository
    });
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Create post published channel
      AndroidNotificationChannel postPublishedChannel = const AndroidNotificationChannel(
        _postPublishedChannelId,
        _postPublishedChannelName,
        description: _postPublishedChannelDesc,
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(postPublishedChannel);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message in foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');

      _showLocalNotification(
        title: message.notification!.title ?? 'Vouse',
        body: message.notification!.body ?? 'You have a new notification',
        payload: message.data,
      );
    }

    _handleRemoteMessage(message);
  }

  // Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _postPublishedChannelId,
      _postPublishedChannelName,
      channelDescription: _postPublishedChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6C56F9), // Using vPrimaryColor
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // unique notification id
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(payload),
    );
  }

  // Handle incoming message data/notification
  void _handleRemoteMessage(RemoteMessage message) {
    // Process based on notification type
    final data = message.data;
    final notificationType = data['type'];

    switch (notificationType) {
      case 'post_published':
        debugPrint('Post published notification: ${data['postIdLocal']}');
        // Handle post published notification
        break;
      default:
        debugPrint('Unknown notification type: $notificationType');
    }
  }

  // Handle when a user taps on a notification
  void _handleNotificationTap(Map<String, dynamic> payload) {
    final notificationType = payload['type'];

    switch (notificationType) {
      case 'post_published':
      // You can navigate to specific screens here if needed
        debugPrint('User tapped on post published notification: ${payload['postIdLocal']}');
        break;
      default:
        debugPrint('Tapped unknown notification type: $notificationType');
    }
  }

  // Get the current FCM token
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}