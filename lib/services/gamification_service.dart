import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService(FirebaseFirestore.instance);
});

class GamificationService {
  final FirebaseFirestore _firestore;

  GamificationService(this._firestore);

  Future<void> awardPoints(String userId, int points, {String? reason}) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Use transaction to ensure atomic updates
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final currentPoints = snapshot.data()?['points'] as int? ?? 0;
      final newPoints = currentPoints + points;

      transaction.update(userRef, {'points': newPoints});

      // Check for level up or badges (simplified logic)
      _checkAndAwardBadges(
        transaction,
        userRef,
        newPoints,
        snapshot.data()?['badges'],
      );
    });
  }

  void _checkAndAwardBadges(
    Transaction transaction,
    DocumentReference userRef,
    int points,
    dynamic currentBadgesRaw,
  ) {
    List<String> currentBadges =
        (currentBadgesRaw as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    bool badgeAdded = false;

    if (points >= 100 && !currentBadges.contains('Novice')) {
      currentBadges.add('Novice');
      badgeAdded = true;
    }
    if (points >= 500 && !currentBadges.contains('Explorateur')) {
      currentBadges.add('Explorateur');
      badgeAdded = true;
    }
    if (points >= 1000 && !currentBadges.contains('Expert')) {
      currentBadges.add('Expert');
      badgeAdded = true;
    }
    if (points >= 5000 && !currentBadges.contains('Légende')) {
      currentBadges.add('Légende');
      badgeAdded = true;
    }

    if (badgeAdded) {
      transaction.update(userRef, {'badges': currentBadges});
    }
  }
}
