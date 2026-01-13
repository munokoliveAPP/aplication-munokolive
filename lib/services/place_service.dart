import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/models/place_model.dart';
import 'offline_service.dart';

final placeServiceProvider = Provider<PlaceService>((ref) {
  return PlaceService(FirebaseFirestore.instance);
});

final approvedPlacesProvider = StreamProvider<List<PlaceModel>>((ref) async* {
  final service = ref.watch(placeServiceProvider);
  final offlineService = ref.watch(offlineServiceProvider);

  // 1. Yield cached data first (Offline First)
  try {
    final cachedJson = await offlineService.getOfflineData<List<dynamic>>(
      'approved_places',
    );
    if (cachedJson != null) {
      final cachedPlaces = cachedJson
          .map((json) => PlaceModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      if (cachedPlaces.isNotEmpty) {
        yield cachedPlaces;
      }
    }
  } catch (e) {
    // Silent error for cache
  }

  // 2. Yield fresh data from Firestore and cache it
  await for (final places in service.getApprovedPlaces()) {
    // Cache the new data
    try {
      final jsonList = places.map((p) => p.toJson()).toList();
      offlineService.saveForOffline('approved_places', jsonList);
    } catch (e) {
      // Silent error for save
    }
    yield places;
  }
});

class PlaceService {
  final FirebaseFirestore _firestore;

  PlaceService(this._firestore);

  // Collection Reference
  CollectionReference get _placesCollection => _firestore.collection('places');

  // Add a new place (Crowdsourcing)
  Future<void> addPlace(PlaceModel place) async {
    await _placesCollection.add(place.toMap());
  }

  // Get Approved Places (For Users)
  Stream<List<PlaceModel>> getApprovedPlaces() {
    return _placesCollection
        .where('status', isEqualTo: PlaceStatus.approved.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlaceModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get Pending Places (For Admin)
  Stream<List<PlaceModel>> getPendingPlaces() {
    return _placesCollection
        .where('status', isEqualTo: PlaceStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlaceModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get My Places (For Ecosystem Integration)
  Stream<List<PlaceModel>> getMyPlaces(String userId) {
    return _placesCollection
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlaceModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Admin Actions
  Future<void> approvePlace(String placeId) async {
    await _placesCollection.doc(placeId).update({
      'status': PlaceStatus.approved.name,
      'isVerified':
          true, // Auto-verify if approved by admin? Or separate step. Let's say yes for now.
    });
  }

  Future<void> rejectPlace(String placeId) async {
    await _placesCollection.doc(placeId).update({
      'status': PlaceStatus.rejected.name,
    });
  }

  // Advanced Search / Filtering
  Future<List<PlaceModel>> searchPlaces({
    String? category,
    String? city,
    String? query,
  }) async {
    Query q = _placesCollection.where(
      'status',
      isEqualTo: PlaceStatus.approved.name,
    );

    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }

    if (city != null && city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }

    // Note: Firestore doesn't support full-text search natively.
    // We can do client-side filtering for 'query' (name contains) or use Algolia/ElasticSearch.
    // For now, we fetch and filter in Dart if query is present.

    final snapshot = await q.get();
    var places = snapshot.docs
        .map((doc) => PlaceModel.fromFirestore(doc))
        .toList();

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      places = places
          .where(
            (p) =>
                p.name.toLowerCase().contains(lowerQuery) ||
                p.description.toLowerCase().contains(lowerQuery) ||
                p.city.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }

    return places;
  }

  // Get Nearby Places (Client-side filtering)
  Future<List<PlaceModel>> getPlacesNearby(
    GeoPoint center,
    double radiusKm, {
    PlaceCategory? category,
  }) async {
    final snapshot = await _placesCollection
        .where('status', isEqualTo: PlaceStatus.approved.name)
        .get();

    final allPlaces = snapshot.docs
        .map((doc) => PlaceModel.fromFirestore(doc))
        .toList();

    return allPlaces.where((place) {
      if (place.coordinates == null) return false;
      if (category != null && place.category != category) return false;

      final double distance = _calculateDistance(
        center.latitude,
        center.longitude,
        place.coordinates!.latitude,
        place.coordinates!.longitude,
      );

      return distance <= radiusKm;
    }).toList();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }
}
