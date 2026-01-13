import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/access_request.dart';

final privacyServiceProvider = Provider<PrivacyService>((ref) {
  return PrivacyService(FirebaseFirestore.instance);
});

class PrivacyService {
  final FirebaseFirestore _firestore;

  PrivacyService(this._firestore);

  // 1. Ghost Mode (Panic Button)
  Future<void> toggleGhostMode(String uid, bool isEnabled) async {
    await _firestore.collection('users').doc(uid).update({
      'isGhostMode': isEnabled,
    });
  }

  // 2. Fuzzy Location (Zone 500m)
  Future<void> toggleFuzzyLocation(String uid, bool isEnabled) async {
    await _firestore.collection('users').doc(uid).update({
      'isDiscretMode': isEnabled,
    });
  }

  // 3. Request Access
  Future<void> requestVisibilityAccess({
    required String requesterId,
    required String targetUserId,
    required int durationMinutes,
  }) async {
    await _firestore.collection('visibility_requests').add({
      'requesterId': requesterId,
      'targetId': targetUserId,
      'status': AccessRequestStatus.pending.name,
      'durationMinutes': durationMinutes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 4. Accept Access
  Future<void> acceptVisibilityRequest(String requestId) async {
    await _firestore.collection('visibility_requests').doc(requestId).update({
      'status': AccessRequestStatus.accepted.name,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // 5. Revoke/Reject Access
  Future<void> rejectVisibilityRequest(String requestId) async {
    await _firestore.collection('visibility_requests').doc(requestId).update({
      'status': AccessRequestStatus.rejected.name,
    });
  }

  // 6. Listen to Incoming Requests
  Stream<List<AccessRequest>> getIncomingRequests(String userId) {
    return _firestore
        .collection('visibility_requests')
        .where('targetId', isEqualTo: userId)
        .where('status', isEqualTo: AccessRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          // Map documents to model then filter out expired requests (request validity: 10 minutes).
          return snapshot.docs
              .map((doc) => AccessRequest.fromFirestore(doc))
              .where((request) {
                if (request.durationMinutes == -1) return true;
                final expirationTime = request.createdAt.add(
                  const Duration(minutes: 10),
                );
                return now.isBefore(expirationTime);
              })
              .toList();
        });
  }

  // 7. Check if user has access to another user (helper for map)
  // This would need to query accepted requests that are still valid.
  // For now, we handle this on the client side or rely on a separate stream if needed.
}
