import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mercurio_messenger/services/storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.handleBackgroundMessage(message);
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mercurio_messages', 'Mercurio Messages',
    description: 'New message notifications for Mercurio',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  Future<void> init() async {
    final settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    if (kDebugMode) print('Notification permission: ${settings.authorizationStatus}');

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'New Message',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: jsonEncode(message.data),
    );
    await _incrementUnreadCount(message.data);
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) print('Notification tapped: ${message.data}');
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _incrementUnreadCount(message.data);
  }

  static Future<void> _incrementUnreadCount(Map<String, dynamic> data) async {
    final conversationId = data['conversation_id'] as String?;
    if (conversationId == null) return;
    try {
      final conversations = await StorageService().getAllConversations();
      final conv = conversations.firstWhere((c) => c['id'] == conversationId, orElse: () => {});
      if (conv.isNotEmpty) {
        await StorageService().saveConversation({
          ...conv,
          'unreadCount': (conv['unreadCount'] as int? ?? 0) + 1,
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error updating unread count: $e');
    }
  }

  Future<String?> getFcmToken() => _fcm.getToken();
}
