import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find nearby musicians by instrument type
  /// Improved: Query from users collection first, then filter by location
  Future<List<String>> findNearbyMusicians({
    required GeoPoint userLocation,
    required String instrumentType, // 'Pianiste', 'Batteur', 'Chantre', etc.
    double radiusKm = 10.0, // 10km radius
  }) async {
    try {
      // Step 1: Get all validated Talent users (musicians)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('category', isEqualTo: 'Talent')
          .where('isValidated', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      final nearbyMusicianIds = <String>[];
      final instrumentLower = instrumentType.toLowerCase();

      // Step 2: For each user, check if they match the instrument and are nearby
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        // Check subCategory or instruments list
        final subCategory = (userData['subCategory'] as String? ?? '')
            .toLowerCase();
        final instruments = (userData['instruments'] as List<dynamic>? ?? [])
            .map((e) => e.toString().toLowerCase())
            .toList();

        // Match instrument type
        final isMatch =
            subCategory.contains(instrumentLower) ||
            instruments.any((inst) => inst.contains(instrumentLower)) ||
            _matchesInstrumentType(subCategory, instrumentLower) ||
            instruments.any(
              (inst) => _matchesInstrumentType(inst, instrumentLower),
            );

        if (!isMatch) continue;

        // Step 3: Check location from locations collection
        final locationDoc = await _firestore
            .collection('locations')
            .doc(userId)
            .get();
        if (!locationDoc.exists) continue;

        final locationData = locationDoc.data();
        final geo = locationData?['geo'] as Map<String, dynamic>?;
        final gp = geo?['geopoint'] as GeoPoint?;
        if (gp == null) continue;

        // Step 4: Calculate distance
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          gp.latitude,
          gp.longitude,
        );

        if (distance <= radiusKm * 1000) {
          nearbyMusicianIds.add(userId);
        }
      }

      return nearbyMusicianIds;
    } catch (e) {
      debugPrint('Error finding nearby musicians: $e');
      return [];
    }
  }

  bool _matchesInstrumentType(String roleOrInstrument, String instrumentType) {
    final roleLower = roleOrInstrument.toLowerCase();
    return (instrumentType == 'pianiste' &&
            (roleLower.contains('piano') || roleLower.contains('pian'))) ||
        (instrumentType == 'batteur' &&
            (roleLower.contains('batterie') || roleLower.contains('drum'))) ||
        (instrumentType == 'chantre' &&
            (roleLower.contains('chant') || roleLower.contains('vocal'))) ||
        (instrumentType == 'guitariste' && roleLower.contains('guitar')) ||
        (instrumentType == 'bassiste' && roleLower.contains('bass')) ||
        (instrumentType == 'saxophoniste' && roleLower.contains('sax')) ||
        (instrumentType == 'trompettiste' && roleLower.contains('tromp')) ||
        (instrumentType == 'violoniste' && roleLower.contains('violon'));
  }

  /// Find nearby pastors/leaders
  /// Improved: Query from users collection first (category='Leader'), then filter by location
  Future<List<String>> findNearbyPastors({
    required GeoPoint userLocation,
    double radiusKm = 10.0, // 10km radius
  }) async {
    try {
      // Step 1: Get all validated Leader users
      final usersSnapshot = await _firestore
          .collection('users')
          .where('category', isEqualTo: 'Leader')
          .where('isValidated', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      final nearbyPastorIds = <String>[];

      // Step 2: For each leader, check if they are nearby
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        // Check subCategory for pastor/leader types
        final subCategory = (userData['subCategory'] as String? ?? '')
            .toLowerCase();
        final role = (userData['role'] as String? ?? '').toLowerCase();

        final isPastor =
            subCategory.contains('pasteur') ||
            subCategory.contains('prêtre') ||
            subCategory.contains('leader') ||
            subCategory.contains('ministre') ||
            subCategory.contains('évêque') ||
            subCategory.contains('apôtre') ||
            subCategory.contains('prophète') ||
            role.contains('pasteur') ||
            role.contains('prêtre') ||
            role.contains('leader');

        if (!isPastor) continue;

        // Step 3: Check location from locations collection
        final locationDoc = await _firestore
            .collection('locations')
            .doc(userId)
            .get();
        if (!locationDoc.exists) continue;

        final locationData = locationDoc.data();
        final geo = locationData?['geo'] as Map<String, dynamic>?;
        final gp = geo?['geopoint'] as GeoPoint?;
        if (gp == null) continue;

        // Step 4: Calculate distance
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          gp.latitude,
          gp.longitude,
        );

        if (distance <= radiusKm * 1000) {
          nearbyPastorIds.add(userId);
        }
      }

      return nearbyPastorIds;
    } catch (e) {
      debugPrint('Error finding nearby pastors: $e');
      return [];
    }
  }

  /// Get address from coordinates using geocoding
  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }
        return parts.isNotEmpty ? parts.join(', ') : 'Adresse non disponible';
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return 'Adresse non disponible';
  }

  /// Send SOS Alert for Musician
  Future<void> sendMusicianSOS({
    required String requesterId,
    required String requesterName,
    required String instrumentType,
    required String programType,
    required String time,
    required String location,
    required GeoPoint userLocation,
    String? requesterPhone,
    bool sendSMS = false,
  }) async {
    try {
      // Find nearby musicians
      final musicianIds = await findNearbyMusicians(
        userLocation: userLocation,
        instrumentType: instrumentType,
      );

      if (musicianIds.isEmpty) {
        throw Exception('Aucun $instrumentType trouvé à proximité (10km)');
      }

      // Obtenir l'adresse complète via geocoding si location est vide ou incomplète
      String finalLocation = location;
      if (location.isEmpty || location == 'Adresse non disponible') {
        finalLocation = await _getAddressFromCoordinates(
          userLocation.latitude,
          userLocation.longitude,
        );
      }

      // Create alert payload
      final message =
          'SOS MUSICIEN : $requesterName recherche un $instrumentType pour $programType à $time - $finalLocation.';

      // Create SOS document for tracking
      final sosDocRef = await _firestore.collection('sos_alerts').add({
        'type': 'musician',
        'requesterId': requesterId,
        'requesterName': requesterName,
        'requesterPhone': requesterPhone,
        'instrumentType': instrumentType,
        'programType': programType,
        'time': time,
        'location': finalLocation,
        'latitude': userLocation.latitude,
        'longitude': userLocation.longitude,
        'targetIds': musicianIds,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      });

      // Send alert for FCM notifications
      await _firestore.collection('alerts').add({
        'targetIds': musicianIds,
        'payload': {
          'title': 'SOS MUSICIEN',
          'body': message,
          'type': 'sos_musician',
          'sosId': sosDocRef.id,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'requesterPhone': requesterPhone,
          'instrumentType': instrumentType,
          'programType': programType,
          'time': time,
          'location': location,
          'latitude': userLocation.latitude,
          'longitude': userLocation.longitude,
          'sendSMS': sendSMS,
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending musician SOS: $e');
      rethrow;
    }
  }

  /// Send SOS Alert for Pastor/Man of God
  Future<void> sendPastorSOS({
    required String requesterId,
    required String requesterName,
    required String
    needType, // 'Consécration d\'enfant', 'Accompagnement', 'Délivrance', etc.
    required String date,
    required String location,
    required GeoPoint userLocation,
    String? requesterPhone,
    bool sendSMS = false,
  }) async {
    try {
      // Find nearby pastors
      final pastorIds = await findNearbyPastors(userLocation: userLocation);

      if (pastorIds.isEmpty) {
        throw Exception('Aucun Homme de Dieu trouvé à proximité (10km)');
      }

      // Obtenir l'adresse complète via geocoding si location est vide ou incomplète
      String finalLocation = location;
      if (location.isEmpty || location == 'Adresse non disponible') {
        finalLocation = await _getAddressFromCoordinates(
          userLocation.latitude,
          userLocation.longitude,
        );
      }

      // Create alert payload
      final message =
          'SOS MINISTÈRE : Besoin d\'un Homme de Dieu pour $needType le $date à $finalLocation.';

      // Create SOS document for tracking
      final sosDocRef = await _firestore.collection('sos_alerts').add({
        'type': 'pastor',
        'requesterId': requesterId,
        'requesterName': requesterName,
        'requesterPhone': requesterPhone,
        'needType': needType,
        'date': date,
        'location': finalLocation,
        'latitude': userLocation.latitude,
        'longitude': userLocation.longitude,
        'targetIds': pastorIds,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      });

      // Send alert for FCM notifications
      await _firestore.collection('alerts').add({
        'targetIds': pastorIds,
        'payload': {
          'title': 'SOS MINISTÈRE',
          'body': message,
          'type': 'sos_pastor',
          'sosId': sosDocRef.id,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'requesterPhone': requesterPhone,
          'needType': needType,
          'date': date,
          'location': location,
          'latitude': userLocation.latitude,
          'longitude': userLocation.longitude,
          'sendSMS': sendSMS,
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending pastor SOS: $e');
      rethrow;
    }
  }
}
