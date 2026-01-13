import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/models/sos_model.dart';

final sosServiceProvider = Provider<SosService>((ref) {
  return SosService(FirebaseFirestore.instance);
});

class SosService {
  final FirebaseFirestore _firestore;

  SosService(this._firestore);

  // Trigger an SOS Alert
  Future<void> triggerSOS({
    required String requesterId,
    required String requesterName,
    required GeoPoint location,
    double radiusKm = 5.0,
    Map<String, dynamic> details = const {},
    String? locationDescription,
  }) async {
    final sosId = _firestore.collection('sos_alerts').doc().id;
    final timestamp = DateTime.now();

    // 1. Create SOS Document
    final sosAlert = SOSModel(
      id: sosId,
      requesterId: requesterId,
      requesterName: requesterName,
      location: location,
      radiusKm: radiusKm,
      timestamp: timestamp,
      status: 'active',
      notifiedUserIds: [],
      details: details,
      locationDescription: locationDescription,
    );

    await _firestore.collection('sos_alerts').doc(sosId).set(sosAlert.toJson());

    // 2. Find Available Musicians (Client-side simulation of Cloud Function)
    await _notifyNearbyMusicians(sosAlert);
  }

  Future<void> sendMusicianSOS({
    required String requesterId,
    required String requesterName,
    required String instrumentType,
    required String programType,
    required String time,
    required String location, // description
    required GeoPoint userLocation, // actual coords
  }) async {
    return triggerSOS(
      requesterId: requesterId,
      requesterName: requesterName,
      location: userLocation,
      locationDescription: location,
      radiusKm: 10.0, // Default for musicians (updated to 10km per UI text)
      details: {
        'type': 'musician',
        'instrumentType': instrumentType,
        'programType': programType,
        'time': time,
      },
    );
  }

  Future<void> sendPastorSOS({
    required String requesterId,
    required String requesterName,
    required String requesterPhone,
    required String needType,
    required String date,
    required String location, // description
    required GeoPoint userLocation, // actual coords
    required bool sendSMS,
  }) async {
    return triggerSOS(
      requesterId: requesterId,
      requesterName: requesterName,
      location: userLocation,
      locationDescription: location,
      radiusKm: 15.0, // Wider range for pastors
      details: {
        'type': 'pastor',
        'requesterPhone': requesterPhone,
        'needType': needType,
        'date': date,
        'sendSMS': sendSMS,
      },
    );
  }

  Future<void> _notifyNearbyMusicians(SOSModel sos) async {
    final collectionReference = _firestore.collection('locations');
    final geoRef = GeoCollectionReference(collectionReference);
    final center = GeoFirePoint(sos.location);

    // One-time fetch of nearby users
    // Note: In a real production app with Cloud Functions, this logic would be server-side.
    // Here we listen to the stream once to get current data.
    final stream = geoRef.subscribeWithin(
      center: center,
      radiusInKm: sos.radiusKm,
      field: 'geo',
      geopointFrom: (data) => (data['geo'] as Map)['geopoint'] as GeoPoint,
      strictMode: true,
    );

    final List<DocumentSnapshot> nearbyDocs = await stream.first;

    final List<String> notifiedIds = [];

    for (final doc in nearbyDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final uid = data['uid'] as String?;
      // final role = data['role'] as String?;

      // Filter: Don't notify self, and only notify Musicians (or specific roles)
      // Assuming 'Musicien' or similar in role/category.
      // Also check if 'Statut Vert' (we'll check 'status' field if available in locations doc)
      // For now, we notify everyone except requester.
      if (uid != null && uid != sos.requesterId) {
        // Send Notification (Write to user's notification collection)
        await _sendNotification(uid, sos);
        notifiedIds.add(uid);
      }
    }

    // Update SOS doc with notified users
    await _firestore.collection('sos_alerts').doc(sos.id).update({
      'notifiedUserIds': notifiedIds,
    });
  }

  Future<void> _sendNotification(String targetUid, SOSModel sos) async {
    await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .add({
          'type': 'sos',
          'title': 'URGENCE SOS',
          'body': '${sos.requesterName} a besoin d\'aide à proximité !',
          'sosId': sos.id,
          'location': sos.location,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
  }

  // Cancel/Resolve SOS
  Future<void> resolveSOS(String sosId) async {
    await _firestore.collection('sos_alerts').doc(sosId).update({
      'status': 'resolved',
    });
  }
}
