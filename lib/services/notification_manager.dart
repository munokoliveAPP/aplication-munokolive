import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import 'watchdog_service.dart';

final notificationManagerProvider = Provider<NotificationManager>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return NotificationManager(notificationService);
});

class NotificationManager {
  final NotificationService _notificationService;

  // Stacking Buffer: key = channel/type, value = list of {body, payload}
  final Map<String, List<Map<String, String?>>> _notificationBuffer = {};
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(
    seconds: 2,
  ); // Wait 2s before showing

  NotificationManager(this._notificationService);

  void handleIncomingNotification(String type, String body, {String? payload}) {
    // Add to buffer
    if (!_notificationBuffer.containsKey(type)) {
      _notificationBuffer[type] = [];
    }
    _notificationBuffer[type]!.add({'body': body, 'payload': payload});

    // Restart timer
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _flushNotifications);
  }

  void _flushNotifications() {
    _notificationBuffer.forEach((type, items) {
      if (items.isEmpty) return;

      if (items.length == 1) {
        // Show single notification
        final item = items.first;
        _notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: _getTitleForType(type),
          body: item['body'] ?? '',
          payload: item['payload'],
        );
      } else {
        // Smart Stacking
        // For stacked notifications, payload could be just the type to navigate to a list
        _notificationService.showNotification(
          id: type.hashCode, // Consistent ID updates the existing notification
          title: _getTitleForType(type),
          body: 'Vous avez ${items.length} nouveaux messages.',
          payload: type, // Payload is just the type
        );
      }

      WatchdogService.logInfo(
        "Stacked ${items.length} notifications for type $type",
      );
    });

    // Clear buffer
    _notificationBuffer.clear();
  }

  String _getTitleForType(String type) {
    switch (type) {
      case 'message':
        return 'Nouveau Message';
      case 'post':
        return 'Nouvelle Publication';
      case 'alert':
        return 'Alerte';
      case 'sos':
        return 'URGENCE SOS';
      default:
        return 'Notification';
    }
  }
}
