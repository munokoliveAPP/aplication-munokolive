import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings: settings);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'munokolive_channel',
      'Munokolive Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}

// Service to listen for Smart Triggers (New Topics)
class SmartTriggerService {
  final SupabaseClient _client = Supabase.instance.client;

  StreamSubscription<List<Map<String, dynamic>>> startListening() {
    return _client
        .from('salon_topics')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(1)
        .listen((data) {
          if (data.isNotEmpty) {
            final topic = data.first;
            if (topic['is_active'] == true) {
              // Check if we should notify (simple debounce could be added here)
              final topicId = topic['id'];
              // Ideally, check local storage if we already notified for this ID
              // For now, we just show it.
              NotificationService().showNotification(
                id: topicId.hashCode,
                title: "🔥 Sujet Brûlant !",
                body: "Rejoignez le débat : ${topic['topic']}",
              );
            }
          }
        });
  }
}
