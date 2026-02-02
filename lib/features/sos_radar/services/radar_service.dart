import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final radarServiceProvider = Provider((ref) => RadarService());

class RadarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Les services de localisation sont désactivés.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Les permissions de localisation sont refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Les permissions de localisation sont définitivement refusées.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<List<Map<String, dynamic>>> getNearbyMembers(
      double lat, double lng, double radiusKm) async {
    try {
      final response = await _supabase.rpc('get_nearby_members', params: {
        'lat': lat,
        'long': lng,
        'radius_km': radiusKm,
      });
      
      // Filter out busy users immediately if possible, though Realtime handles updates
      // Assuming the RPC returns a list of users with their status
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des membres: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamNearbyMembers(double lat, double lng, double radiusKm) {
    // This is a simplified stream. In a real scenario, you'd combine 
    // the initial fetch with Supabase Realtime updates.
    // For now, we'll just return the future as a stream and rely on manual refresh or
    // a separate realtime subscription in the UI to update the list.
    return Stream.fromFuture(getNearbyMembers(lat, lng, radiusKm));
  }
}
