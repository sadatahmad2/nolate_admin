import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _ordersChannel;

  // In-app notification stream for UI banners
  final StreamController<Map<String, dynamic>> _inAppNotifController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get inAppNotifications => _inAppNotifController.stream;

  Future<void> initialize() async {
    // Init local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);

    // Request permission on iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Start listening to real-time order updates
    _startRealtimeListener();
  }

  void _startRealtimeListener() {
    _ordersChannel = _supabase
        .channel('orders-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final newOrder = payload.newRecord;
            _handleNewOrder(newOrder);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final updatedOrder = payload.newRecord;
            final status = updatedOrder['status'] as String?;
            if (status == 'ready') {
              _handleOrderReady(updatedOrder);
            }
          },
        )
        .subscribe();
  }

  void _handleNewOrder(Map<String, dynamic> order) {
    final orderId = (order['id'] as String?)?.substring(0, 8).toUpperCase() ?? 'NEW';
    _showLocalNotification(
      id: order['id'].hashCode,
      title: '🛒 New Order Received!',
      body: 'Order #$orderId has been placed. Review it now.',
    );
    _inAppNotifController.add({
      'type': 'new_order',
      'title': 'New Order!',
      'body': 'Order #$orderId has been placed.',
      'orderId': order['id'],
      'color': 'blue',
    });
  }

  void _handleOrderReady(Map<String, dynamic> order) {
    final orderId = (order['id'] as String?)?.substring(0, 8).toUpperCase() ?? '---';
    _showLocalNotification(
      id: order['id'].hashCode + 1,
      title: '✅ Order Ready for Pickup!',
      body: 'Order #$orderId is ready. Assign a delivery rider now.',
    );
    _inAppNotifController.add({
      'type': 'order_ready',
      'title': '✅ Order Ready!',
      'body': 'Order #$orderId is ready — assign a rider!',
      'orderId': order['id'],
      'color': 'green',
    });
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'nolate_admin_channel',
      'Nolate Admin Alerts',
      channelDescription: 'Notifications for new and ready orders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details);
  }

  void dispose() {
    _ordersChannel?.unsubscribe();
    _inAppNotifController.close();
  }
}
