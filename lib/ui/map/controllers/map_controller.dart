/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/providers/user_location_provider.dart';

final mapControllerProvider =
    StateNotifierProvider.autoDispose<MapController, AsyncValue<LatLng>>((ref) {
      final controller = MapController();

      // 1. Set Visibility ON when MapScreen is active (provider initialized)
      controller.updateVisibility(true);

      // 2. Watch Shared Location Provider
      final locationAsync = ref.watch(userLocationProvider);

      locationAsync.when(
        data: (position) {
          // Update local state and backend
          controller.updatePosition(position);
        },
        error: (e, st) {
          controller.setError(e, st);
        },
        loading: () {
          // Keep previous state or loading
        },
      );

      // 3. Cleanup: Set Visibility OFF when MapScreen is closed (provider disposed)
      ref.onDispose(() {
        controller.updateVisibility(false);
      });

      return controller;
    });

final nearbyUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .map(
        (event) => event
            .where(
              (user) =>
                  user['latitude'] != null &&
                  user['longitude'] != null &&
                  user['id'] != Supabase.instance.client.auth.currentUser?.id,
            )
            .toList(),
      );
});

final nearbyLocationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return Supabase.instance.client
      .from('locations')
      .stream(primaryKey: ['id'])
      .eq('is_validated', true)
      .map(
        (event) => event
            .where((loc) => loc['latitude'] != null && loc['longitude'] != null)
            .toList(),
      );
});

class MapController extends StateNotifier<AsyncValue<LatLng>> {
  MapController() : super(const AsyncValue.loading());

  Future<void> updateVisibility(bool isVisible) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_visible_on_map': isVisible})
          .eq('id', userId);
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> updatePosition(Position position) async {
    // 1. Update Local State (UI)
    state = AsyncValue.data(LatLng(position.latitude, position.longitude));

    // 2. Update Supabase (Realtime Sync)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client
            .from('users')
            .update({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'last_location_update': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      } catch (e) {
        // Silent fail
      }
    }
  }

  void setError(Object error, StackTrace stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
}
