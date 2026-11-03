import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../orders/order_detail_controller.dart';
import '../orders/order_detail_screen.dart';
import '../orders/orders_repository.dart';
import 'device_token_repository.dart';

/// This must be a top-level (or static) function: Firebase invokes it
/// in a separate background isolate when a data/notification message
/// arrives while the app is backgrounded or terminated, so it can't
/// close over any app state.
///
/// There's deliberately almost nothing here. Our plugin always sends
/// a `notification` block (not a bare data-only message — see
/// WCOM_FCM::send_to_token), and FCM's Android SDK displays the
/// system notification for that automatically while the app isn't in
/// the foreground. We only need this isolate to exist and initialize
/// Firebase, per the firebase_messaging plugin's own requirement.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: see the comment above.
}

/// Owns everything push-notification related: requesting permission,
/// registering/refreshing this device's FCM token with the store,
/// showing a notification ourselves when a message arrives while the
/// app is in the foreground (FCM does NOT do this for you), and
/// opening the right order when a notification is tapped.
class PushNotificationsService {
  PushNotificationsService({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _androidChannelId = 'new_orders';

  DeviceTokenRepository? _deviceTokenRepository;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _listenersAttached = false;

  /// Call once at app startup (Firebase.initializeApp() itself must
  /// already have run in main(), before runApp).
  Future<void> initialize() async {
    await _initLocalNotifications();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (_listenersAttached) return;
    _listenersAttached = true;

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  /// Call once a store is connected (login succeeded or a saved
  /// session was restored): sends this device's current FCM token to
  /// that store, and keeps sending it again whenever Firebase rotates
  /// the token for as long as the app stays open.
  void attachStore(DeviceTokenRepository repository) {
    _deviceTokenRepository = repository;

    _registerCurrentToken();

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
  }

  /// Call on logout, so a stale service no longer tries to register
  /// tokens against a store the user disconnected from.
  void detachStore() {
    _deviceTokenRepository = null;
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(token);
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _deviceTokenRepository?.register(token);
    } catch (_) {
      // Not fatal: onTokenRefresh will fire again eventually, and the
      // orders list's own polling fallback covers a missed push in
      // the meantime.
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final orderId = int.tryParse(response.payload ?? '');
        if (orderId != null) _openOrder(orderId);
      },
    );
  }

  /// FCM only auto-shows a system notification for background/
  /// terminated apps. While the app is open, we have to display it
  /// ourselves — otherwise a new order would arrive silently.
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          'سفارش‌های جدید',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['order_id']?.toString(),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final orderId = int.tryParse(message.data['order_id']?.toString() ?? '');
    if (orderId != null) _openOrder(orderId);
  }

  void _openOrder(int orderId) {
    final context = navigatorKey.currentState?.context;
    if (context == null) return;

    final repository = context.read<OrdersRepository>();

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<OrderDetailController>(
          create: (_) => OrderDetailController(repository, orderId)..load(),
          child: const OrderDetailScreen(),
        ),
      ),
    );
  }
}
