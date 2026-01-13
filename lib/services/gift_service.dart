import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final giftServiceProvider = Provider<GiftService>((ref) {
  return GiftService(FirebaseFirestore.instance);
});

class GiftService {
  final FirebaseFirestore _firestore;

  GiftService(this._firestore);

  Future<void> sendGift({
    required String fromUserId,
    required String toUserId,
    required String giftType,
    String? message,
  }) async {
    try {
      await _firestore.collection('gifts').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'giftType': giftType,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent', // sent, received, opened
      });

      // Optionally update user reputation or points here
      // This would typically be done via a Cloud Function triggering on the 'gifts' collection
    } catch (e) {
      throw Exception('Failed to send gift: $e');
    }
  }
}
