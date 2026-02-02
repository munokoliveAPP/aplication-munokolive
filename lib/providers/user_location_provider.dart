import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// User Location Provider (Live GPS)
final userLocationProvider = StreamProvider<Position>((ref) async* {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw 'Les services de localisation sont désactivés. Veuillez les activer.';
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw 'Les permissions de localisation sont refusées.';
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw 'Les permissions de localisation sont définitivement refusées. Veuillez les activer dans les paramètres.';
  }

  // 1. Emit current position immediately (Fast Fix)
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      ),
    );
    yield position;
  } catch (_) {
    // If getting current position fails (timeout), wait for stream
  }

  // 2. Stream position updates
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10m for better responsiveness
    ),
  );
});
