import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import 'notification_service.dart';
import '../providers/events_provider.dart';

final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return GeofenceService(notificationService, ref);
});

class GeofenceService {
  final NotificationService _notificationService;
  final Ref _ref;
  StreamSubscription<Position>? _positionStreamSubscription;
  ProviderSubscription<AsyncValue<List<EventModel>>>? _eventsSubscription;
  List<EventModel> _cachedEvents = [];

  // Cache triggered events to avoid spamming
  // Key: eventId, Value: timestamp of last trigger
  static const String _prefsKeyPrefix = 'geofence_triggered_';

  GeofenceService(this._notificationService, this._ref);

  void startMonitoring() {
    // Request permission if needed (Assuming permission handled by main app flow)

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // Check every 20 meters
    );

    // Keep events fresh even if UI is not watching them
    _eventsSubscription = _ref.listen(eventsStreamProvider, (previous, next) {
      next.whenData((events) => _cachedEvents = events);
    });

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _checkGeofences(position);
          },
        );
  }

  void stopMonitoring() {
    _positionStreamSubscription?.cancel();
    _eventsSubscription?.close();
  }

  Future<void> _checkGeofences(Position userPosition) async {
    final prefs = await SharedPreferences.getInstance();

    // Use cached events
    final events = _cachedEvents;
    if (events.isEmpty) return;

    final now = DateTime.now();

    for (final event in events) {
      if (event.coordinates == null) continue;

      // 1. Check if event is TODAY (or active now)
      final isToday =
          event.date.year == now.year &&
          event.date.month == now.month &&
          event.date.day == now.day;

      // Only trigger for events happening today
      if (!isToday) continue;

      // 2. Calculate Distance
      final distanceInMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        event.coordinates!.latitude,
        event.coordinates!.longitude,
      );

      // 3. Trigger if < 100m
      if (distanceInMeters <= 100) {
        _triggerWelcomeNotification(event, prefs);
      }
    }
  }

  Future<void> _triggerWelcomeNotification(
    EventModel event,
    SharedPreferences prefs,
  ) async {
    final key = '$_prefsKeyPrefix${event.id}';
    final hasTriggered = prefs.getBool(key) ?? false;

    if (!hasTriggered) {
      // Send Notification
      await _notificationService.showNotification(
        id: ('geofence-${event.id}').hashCode,
        title: "👋 Bienvenue à ${event.title} !",
        body:
            "Vous êtes arrivé ! Voici votre Pass VIP Digital. Profitez de l'événement.",
        payload: 'event:${event.id}',
      );

      // Mark as triggered
      await prefs.setBool(key, true);
    }
  }
}
