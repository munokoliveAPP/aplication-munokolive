import 'dart:async';
import 'dart:ui'; // For Color
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:munokolive_music/models/user_profile.dart'; // Import UserProfile

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String?> _onNotificationTap =
      StreamController.broadcast();

  Stream<String?> get onNotificationTap => _onNotificationTap.stream;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'wish') {
          _onNotificationTap.add('${response.payload}?action=wish');
        } else {
          _onNotificationTap.add(response.payload);
        }
      },
    );
    tz.initializeTimeZones();
  }

  Future<void> scheduleBirthdayNotifications(List<UserProfile> users) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check next 7 days
    for (int i = 0; i < 7; i++) {
      final targetDate = today.add(Duration(days: i));
      final targetBirthdays = users.where((u) {
        if (u.dateOfBirth == null) return false;
        return u.dateOfBirth!.month == targetDate.month &&
            u.dateOfBirth!.day == targetDate.day;
      }).toList();

      if (targetBirthdays.isNotEmpty) {
        await _scheduleDailyBirthdayNotification(targetDate, targetBirthdays);
      }
    }
  }

  Future<void> _scheduleDailyBirthdayNotification(
    DateTime date,
    List<UserProfile> users,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      8, // 08:00 AM
      0,
    );

    // If the time has passed, don't schedule (or schedule for next year if we were doing recurring, but here we just want upcoming)
    if (scheduledDate.isBefore(now)) {
      return;
    }

    final mainUser = users.first;
    final otherCount = users.length - 1;

    String title = "Anniversaires du Jour";
    String body = "Aujourd'hui, c'est l'anniversaire de ${mainUser.firstName}";
    if (otherCount > 0) {
      body += " et $otherCount autres membres.";
    } else {
      body += " !";
    }
    body += " Renforcez votre réseau en leur souhaitant le meilleur !";

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'munokolive_birthdays',
          'Anniversaires',
          channelDescription: 'Notifications des anniversaires des membres',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFFFD700), // Gold
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'wish',
              'Souhaiter',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      ('birthday-${date.day}-${date.month}').hashCode,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: androidPlatformChannelSpecifics),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'birthday_wish',
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'munokolive_channel',
          'MunoKoLive Notifications',
          channelDescription: 'Notifications for MunoKoLive Music',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleEventReminders(
    String eventId,
    String title,
    DateTime eventDate,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    final eventTZDate = tz.TZDateTime.from(eventDate, tz.local);

    // D-3 Notification
    final dMinus3 = eventTZDate.subtract(const Duration(days: 3));
    if (dMinus3.isAfter(now)) {
      await _scheduleNotification(
        id: ('$eventId-d3').hashCode,
        title: "J-3 : $title",
        body: "L'événement approche ! Êtes-vous prêt ?",
        scheduledDate: dMinus3,
        payload: 'event:$eventId',
      );
    }

    // D-1 Notification
    final dMinus1 = eventTZDate.subtract(const Duration(days: 1));
    if (dMinus1.isAfter(now)) {
      await _scheduleNotification(
        id: ('$eventId-d1').hashCode,
        title: "J-1 : $title",
        body: "C'est demain ! Préparez-vous pour une expérience inoubliable.",
        scheduledDate: dMinus1,
        payload: 'event:$eventId',
      );
    }

    // H-2 Notification (Live Activity Style)
    final hMinus2 = eventTZDate.subtract(const Duration(hours: 2));
    if (hMinus2.isAfter(now)) {
      await _scheduleNotification(
        id: ('$eventId-h2').hashCode,
        title: "H-2 : Ça commence bientôt !",
        body:
            "L'événement commence dans 2 heures. Cliquez pour voir le covoiturage.",
        scheduledDate: hMinus2,
        payload: 'event:$eventId',
        isLiveActivity: true, // New parameter for ongoing/sticky notification
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    bool isLiveActivity = false,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'munokolive_reminders',
          'Rappels Événements',
          channelDescription:
              'Rappels automatiques pour vos événements favoris',
          importance: Importance.max,
          priority: Priority.max,
          ongoing: isLiveActivity, // Sticky notification for H-2
          autoCancel: !isLiveActivity,
          color: const Color(0xFFFF5252), // Brand color
          visibility: NotificationVisibility.public, // Show on lock screen
          category: AndroidNotificationCategory.event,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
