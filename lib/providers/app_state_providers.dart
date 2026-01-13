import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_profile.dart';
import '../ui/map/controllers/map_controller.dart';
import 'user_provider.dart';
import 'events_provider.dart'; // Import for real events data

// --- Navigation ---
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// --- Shared Data ---

// 1. User Location (Single Source of Truth)
final userLocationProvider = StateProvider<Position?>((ref) => null);

// 2. Nearby Users (From Radar/Map)
// This is populated by the MapController when it scans.
final nearbyUsersProvider = Provider<List<UserProfile>>((ref) {
  return ref.watch(mapControllerProvider).nearbyUsers;
});

// 3. Focus Location (For "Lieu -> Radar" interaction)
final mapFocusLocationProvider = StateProvider<LatLng?>((ref) => null);

// 4. Badges State
class BadgeState {
  final int contactsOnline;
  final int eventsNearby;

  BadgeState({this.contactsOnline = 0, this.eventsNearby = 0});
}

final badgeStateProvider = Provider<BadgeState>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final eventsAsync = ref.watch(eventsStreamProvider);
  final myLoc = ref.watch(userLocationProvider);

  int onlineCount = 0;
  usersAsync.whenData((users) {
    onlineCount = users.where((u) => u.isOnline).length;
  });

  int nearbyEventsCount = 0;
  if (myLoc != null) {
    eventsAsync.whenData((events) {
      for (var event in events) {
        if (event.coordinates != null) {
          final dist = Geolocator.distanceBetween(
            myLoc.latitude,
            myLoc.longitude,
            event.coordinates!.latitude,
            event.coordinates!.longitude,
          );
          if (dist <= 1000) {
            // 1km radius
            nearbyEventsCount++;
          }
        }
      }
    });
  }

  return BadgeState(
    contactsOnline: onlineCount,
    eventsNearby: nearbyEventsCount,
  );
});

// --- Computed Logic ---

// Sort Contacts by Proximity (Logic for "Contact" tab)
final sortedContactsProvider = Provider<AsyncValue<List<UserProfile>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final myLoc = ref.watch(userLocationProvider);

  return usersAsync.whenData((users) {
    if (myLoc == null) return users;

    // Clone to avoid modifying source
    final sorted = List<UserProfile>.from(users);

    // Sort: Online & < 50m first, then by distance
    sorted.sort((a, b) {
      // Priority 1: Online & Close (< 50m)
      final distA = Geolocator.distanceBetween(
        myLoc.latitude,
        myLoc.longitude,
        a.latitude ?? 0,
        a.longitude ?? 0,
      );
      final distB = Geolocator.distanceBetween(
        myLoc.latitude,
        myLoc.longitude,
        b.latitude ?? 0,
        b.longitude ?? 0,
      );

      final isCloseA = distA < 50 && a.isOnline;
      final isCloseB = distB < 50 && b.isOnline;

      if (isCloseA && !isCloseB) return -1;
      if (!isCloseA && isCloseB) return 1;

      // Priority 2: Distance
      return distA.compareTo(distB);
    });

    return sorted;
  });
});
