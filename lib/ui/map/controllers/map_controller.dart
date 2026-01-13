import 'dart:async';
import 'dart:math' as math; // Pour Haversine pure Dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Pour compute
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

import 'package:munokolive_music/services/auth_service.dart';
import '../../../models/user_profile.dart';
import '../../../services/georadar_service.dart';
import '../../../services/notification_service.dart';
import '../widgets/user_marker_widget.dart';
import '../widgets/cluster_marker_widget.dart';

// État du contrôleur de la carte
class MapState {
  final Set<Marker> markers;
  final bool hasPermission;
  final UserProfile? selectedUser;
  final LatLng? myLocation;
  final Map<String, int> zoneStats; // "20 Pianistes", etc.
  final List<UserProfile> nearbyUsers;

  MapState({
    this.markers = const {},
    this.hasPermission = false,
    this.selectedUser,
    this.myLocation,
    this.zoneStats = const {},
    this.nearbyUsers = const [],
  });

  MapState copyWith({
    Set<Marker>? markers,
    bool? hasPermission,
    UserProfile? selectedUser,
    bool clearSelectedUser = false,
    LatLng? myLocation,
    Map<String, int>? zoneStats,
    List<UserProfile>? nearbyUsers,
  }) {
    return MapState(
      markers: markers ?? this.markers,
      hasPermission: hasPermission ?? this.hasPermission,
      selectedUser: clearSelectedUser
          ? null
          : (selectedUser ?? this.selectedUser),
      myLocation: myLocation ?? this.myLocation,
      zoneStats: zoneStats ?? this.zoneStats,
      nearbyUsers: nearbyUsers ?? this.nearbyUsers,
    );
  }
}

// Contrôleur (Logic Layer)
class MapController extends StateNotifier<MapState> {
  final GeoRadarService _geoRadarService;
  final NotificationService _notificationService;
  final String? _currentUserId;

  // Caches & Throttling
  final Map<String, BitmapDescriptor> _markerCache = {};
  final Map<String, DateTime> _lastNotificationTime = {};
  DateTime _lastMarkerUpdate = DateTime.now();
  StreamSubscription<Position>? _positionStream;

  Set<Marker> _userMarkers = {};
  Set<Marker> _eventMarkers = {};

  // Constantes
  static const double _proximityAlertThreshold = 10.0; // mètres
  static const Duration _notificationCooldown = Duration(minutes: 10);
  static const Duration _markerUpdateThrottle = Duration(
    milliseconds: 500,
  ); // Max 2 updates/sec
  static const double _clusterThreshold = 30.0; // mètres pour regrouper

  MapController(
    this._geoRadarService,
    this._notificationService,
    this._currentUserId,
  ) : super(MapState());

  @override
  void dispose() {
    _positionStream?.cancel();
    _geoRadarService.stopScan();
    super.dispose();
  }

  // Initialisation
  Future<void> initialize() async {
    await checkPermission();
    _listenToEvents();
  }

  // Vérifier la permission
  Future<void> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      state = state.copyWith(hasPermission: true);
      _startLocationUpdates();
    }
  }

  // Demander la permission
  Future<void> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      state = state.copyWith(hasPermission: true);
      _startLocationUpdates();
    }
  }

  // Throttling GPS Updates (Battery Saver)
  void _startLocationUpdates() {
    _positionStream?.cancel();

    // Configuration optimisée pour la batterie
    // Mises à jour tous les 10 mètres ou 10 secondes minimum
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: Duration(seconds: 10),
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position pos) {
            state = state.copyWith(
              myLocation: LatLng(pos.latitude, pos.longitude),
            );
          },
          onError: (e) {
            debugPrint('Error getting location stream: $e');
          },
        );
  }

  // Démarrer le scan radar
  void startRealtimeScan(LatLng center) {
    _geoRadarService.startScan(
      initialRadiusMeters:
          50000, // Large radius to catch many, filtering done locally
      center: GeoPoint(center.latitude, center.longitude),
      onFound: (docs) => _processUsers(docs),
    );
  }

  // Écouter les événements Firestore
  void _listenToEvents() {
    FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .listen(
          (snapshot) {
            _updateEventMarkers(snapshot.docs);
          },
          onError: (e) {
            debugPrint('Error listening to events: $e');
          },
        );
  }

  Future<void> _updateEventMarkers(List<DocumentSnapshot> docs) async {
    final Set<Marker> newMarkers = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      final geo = data['geo'] as Map<String, dynamic>?;
      if (geo == null) continue;

      double lat, lng;
      if (geo['geopoint'] is GeoPoint) {
        lat = (geo['geopoint'] as GeoPoint).latitude;
        lng = (geo['geopoint'] as GeoPoint).longitude;
      } else {
        continue;
      }

      // Simple Star Marker for Events
      final icon = await const Icon(
        Icons.star,
        color: Color(0xFFDF00FF),
        size: 40,
      ).toBitmapDescriptor();

      newMarkers.add(
        Marker(
          markerId: MarkerId('event_${doc.id}'),
          position: LatLng(lat, lng),
          icon: icon,
          infoWindow: InfoWindow(title: data['title'] ?? 'Événement'),
        ),
      );
    }
    _eventMarkers = newMarkers;
    _mergeMarkers();
  }

  void _mergeMarkers() {
    state = state.copyWith(markers: {..._userMarkers, ..._eventMarkers});
  }

  // Core Logic: Process Users (Clustering, Notifications, Stats, Markers)
  Future<void> _processUsers(List<DocumentSnapshot> docs) async {
    // Throttling: Ne pas mettre à jour trop souvent les marqueurs
    if (DateTime.now().difference(_lastMarkerUpdate) < _markerUpdateThrottle) {
      return;
    }
    _lastMarkerUpdate = DateTime.now();

    final myLoc = state.myLocation;

    // Préparation des données pour l'Isolate
    // On extrait les Map JSON car DocumentSnapshot ne passe pas dans l'isolate
    final List<Map<String, dynamic>> usersData = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        usersData.add(data);
      }
    }

    // Paramètres pour l'isolate
    final params = _ClusterParams(
      usersData: usersData,
      myLat: myLoc?.latitude,
      myLng: myLoc?.longitude,
      currentUserId: _currentUserId,
      clusterThreshold: _clusterThreshold,
      proximityThreshold: _proximityAlertThreshold,
    );

    // EXÉCUTION DANS UN ISOLATE (Thread séparé)
    // Cela garantit que le calcul ne bloque JAMAIS l'UI, même avec 1000 users.
    final result = await compute(_isolateClusterComputation, params);

    // Traitement des résultats sur le Thread Principal (UI)

    // 1. Stats & Notifications (Rapide)
    final Map<String, int> stats = result.stats;
    if (result.usersToNotify.isNotEmpty) {
      // Haptic Feedback for nearby users
      HapticFeedback.heavyImpact();
    }
    for (var notifUser in result.usersToNotify) {
      _triggerProximityNotification(notifUser.user, notifUser.distance);
    }

    // 2. Génération des Marqueurs (Nécessite Flutter Engine)
    final Set<Marker> newMarkers = {};

    // A. Single Users
    for (var user in result.singleUsers) {
      final icon = await _getMarkerIcon(user);
      newMarkers.add(
        Marker(
          markerId: MarkerId(user.uid),
          position: LatLng(user.latitude!, user.longitude!),
          icon: icon,
          onTap: () {
            state = state.copyWith(selectedUser: user);
          },
        ),
      );
      if (newMarkers.length >= 200) break;
    }

    // B. Clusters
    for (var cluster in result.clusters) {
      if (newMarkers.length >= 200) break;
      final icon = await _getClusterIcon(cluster.count);
      newMarkers.add(
        Marker(
          markerId: MarkerId('cluster_${cluster.centerUser.uid}'),
          position: LatLng(
            cluster.centerUser.latitude!,
            cluster.centerUser.longitude!,
          ),
          icon: icon,
          onTap: () {
            // Optionnel : Zoom sur le cluster
          },
        ),
      );
    }

    _userMarkers = newMarkers;

    // Update State
    state = state.copyWith(
      markers: {..._userMarkers, ..._eventMarkers},
      zoneStats: stats,
      nearbyUsers: result.allUsers,
    );
  }

  // Helper: Marker Icon Generator with Cache
  Future<BitmapDescriptor> _getMarkerIcon(UserProfile user) async {
    final cacheKey =
        '${user.uid}_${user.photoUrl ?? "no_photo"}_${user.isOnline}';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    // Generate Custom Marker
    try {
      final icon =
          await UserMarkerWidget(
            photoUrl: user.photoUrl,
            isOnline: user.isOnline,
          ).toBitmapDescriptor(
            logicalSize: const Size(60, 70),
            imageSize: const Size(120, 140),
            waitToRender: const Duration(
              milliseconds: 100,
            ), // Give time for image load
          );

      _markerCache[cacheKey] = icon;
      return icon;
    } catch (e) {
      debugPrint('Error generating marker for ${user.uid}: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  // Helper: Cluster Icon Generator with Cache
  Future<BitmapDescriptor> _getClusterIcon(int count) async {
    final cacheKey = 'cluster_$count';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    try {
      final icon = await ClusterMarkerWidget(count: count).toBitmapDescriptor(
        logicalSize: const Size(50, 50),
        imageSize: const Size(100, 100),
      );
      _markerCache[cacheKey] = icon;
      return icon;
    } catch (e) {
      debugPrint('Error generating cluster marker: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  // Helper: Notification Trigger
  void _triggerProximityNotification(UserProfile user, double distance) {
    final now = DateTime.now();
    final lastTime = _lastNotificationTime[user.uid];

    if (lastTime == null || now.difference(lastTime) > _notificationCooldown) {
      _lastNotificationTime[user.uid] = now;

      // Format demandé : "Un Pianiste vient de se connecter à 5m de vous !"
      final category = user.category;
      final distStr = distance.toStringAsFixed(0); // 0 decimals (ex: 5m)

      _notificationService.showNotification(
        id: user.uid.hashCode,
        title: 'Proximité détectée !',
        body: 'Un $category vient de se connecter à ${distStr}m de vous !',
        payload: 'user:${user.uid}',
      );
    }
  }

  void clearSelection() {
    state = state.copyWith(clearSelectedUser: true);
  }
}

// Provider
final mapControllerProvider = StateNotifierProvider<MapController, MapState>((
  ref,
) {
  final geoService = ref.read(geoRadarServiceProvider);
  final notifService = ref.read(notificationServiceProvider);
  final authService = ref.read(authServiceProvider);
  final userId = authService.currentUser?.uid;
  return MapController(geoService, notifService, userId);
});

// --- ISOLATE HELPERS & LOGIC ---

class _ClusterParams {
  final List<Map<String, dynamic>> usersData;
  final double? myLat;
  final double? myLng;
  final String? currentUserId;
  final double clusterThreshold;
  final double proximityThreshold;

  _ClusterParams({
    required this.usersData,
    this.myLat,
    this.myLng,
    this.currentUserId,
    required this.clusterThreshold,
    required this.proximityThreshold,
  });
}

class _ClusterResult {
  final List<UserProfile> singleUsers;
  final List<_ClusterInfo> clusters;
  final List<_NotificationUser> usersToNotify;
  final Map<String, int> stats;
  final List<UserProfile> allUsers;

  _ClusterResult({
    required this.singleUsers,
    required this.clusters,
    required this.usersToNotify,
    required this.stats,
    required this.allUsers,
  });
}

class _ClusterInfo {
  final UserProfile centerUser;
  final int count;

  _ClusterInfo({required this.centerUser, required this.count});
}

class _NotificationUser {
  final UserProfile user;
  final double distance;

  _NotificationUser({required this.user, required this.distance});
}

// Pure Dart Haversine Implementation (Optimized for Isolate)
double _calculateHaversine(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a =
      0.5 -
      math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) *
          math.cos(lat2 * p) *
          (1 - math.cos((lon2 - lon1) * p)) /
          2;
  return 12742 * math.asin(math.sqrt(a)) * 1000; // Result in meters
}

// ISOLATE ENTRY POINT
// This runs in a separate thread to keep the UI fluid.
Future<_ClusterResult> _isolateClusterComputation(_ClusterParams params) async {
  final List<UserProfile> allUsers = [];
  final Map<String, int> stats = {};
  final List<_NotificationUser> usersToNotify = [];

  // 1. Parse Users & Calculate Stats/Notifications
  for (var data in params.usersData) {
    try {
      final user = UserProfile.fromJson(data);

      // Filter invalid coordinates
      if (user.latitude == null || user.longitude == null) continue;
      if (user.latitude == 0 && user.longitude == 0) continue;

      // Filter current user
      if (user.uid == params.currentUserId) continue;

      // Stats aggregation
      if (user.isOnline) {
        // Use category or subCategory for stats
        final category = user.subCategory ?? user.category;
        stats[category] = (stats[category] ?? 0) + 1;
      }

      // Proximity Check
      if (params.myLat != null && params.myLng != null) {
        final distance = _calculateHaversine(
          params.myLat!,
          params.myLng!,
          user.latitude!,
          user.longitude!,
        );

        if (distance <= params.proximityThreshold && user.isOnline) {
          usersToNotify.add(_NotificationUser(user: user, distance: distance));
        }
      }

      allUsers.add(user);
    } catch (e) {
      // Skip malformed data
      continue;
    }
  }

  // 2. Clustering Logic
  final List<UserProfile> singleUsers = [];
  final List<_ClusterInfo> clusters = [];
  final Set<String> clusteredUserIds = {};

  for (int i = 0; i < allUsers.length; i++) {
    if (clusteredUserIds.contains(allUsers[i].uid)) continue;

    final userA = allUsers[i];
    int clusterCount = 1;

    // Check neighbors
    for (int j = i + 1; j < allUsers.length; j++) {
      if (clusteredUserIds.contains(allUsers[j].uid)) continue;

      final userB = allUsers[j];
      final distance = _calculateHaversine(
        userA.latitude!,
        userA.longitude!,
        userB.latitude!,
        userB.longitude!,
      );

      if (distance <= params.clusterThreshold) {
        clusterCount++;
        clusteredUserIds.add(userB.uid);
      }
    }

    if (clusterCount > 1) {
      clusters.add(_ClusterInfo(centerUser: userA, count: clusterCount));
    } else {
      singleUsers.add(userA);
    }
    clusteredUserIds.add(userA.uid);
  }

  return _ClusterResult(
    singleUsers: singleUsers,
    clusters: clusters,
    usersToNotify: usersToNotify,
    stats: stats,
    allUsers: allUsers,
  );
}
