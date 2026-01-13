import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../models/user_profile.dart';

final geoRadarServiceProvider = Provider<GeoRadarService>((ref) {
  return GeoRadarService();
});

class GeoRadarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<DocumentSnapshot>>? _streamSubscription;

  Future<void> updateUserLocation(UserProfile user, GeoPoint location) async {
    final collectionReference = _firestore.collection('locations');
    final geoFirePoint = GeoFirePoint(location);

    await collectionReference.doc(user.uid).set({
      'uid': user.uid,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'photoUrl': user.photoUrl,
      'category': user.category,
      'role': user.category, // Legacy support
      'geo': {'geopoint': location, 'geohash': geoFirePoint.geohash},
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void startScan({
    required double initialRadiusMeters,
    required GeoPoint center,
    required Function(List<DocumentSnapshot>) onFound,
  }) {
    final collectionReference = _firestore.collection('locations');
    // Using simple GeoFirestore query logic or geoflutterfire_plus
    // Note: geoflutterfire_plus uses GeoCollectionReference

    final geoRef = GeoCollectionReference(collectionReference);

    _streamSubscription?.cancel();
    _streamSubscription = geoRef
        .subscribeWithin(
          center: GeoFirePoint(center),
          radiusInKm: initialRadiusMeters / 1000.0,
          field: 'geo',
          geopointFrom: (data) => (data['geo'] as Map)['geopoint'] as GeoPoint,
          strictMode: true,
        )
        .listen(
          (docs) {
            onFound(docs);
          },
          onError: (e) {
            debugPrint('Error in GeoRadar scan: $e');
            // Silently fail or retry, but don't crash UI
          },
        );
  }

  void stopScan() {
    _streamSubscription?.cancel();
  }
}
