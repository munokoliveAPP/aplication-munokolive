import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/event_model.dart';
import 'auth_service.dart';
import 'package:geolocator/geolocator.dart';

final carpoolServiceProvider = Provider<CarpoolService>((ref) {
  return CarpoolService(FirebaseFirestore.instance, ref);
});

// Stream of potential carpool matches for a given event
final carpoolMatchesProvider = StreamProvider.family<List<UserProfile>, String>(
  (ref, eventId) {
    final carpoolService = ref.watch(carpoolServiceProvider);
    return carpoolService.findCarpoolMatches(eventId);
  },
);

class CarpoolService {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  CarpoolService(this._firestore, this._ref);

  // 1. Find attendees of the event who live nearby (same neighborhood/commune or < 5km)
  Stream<List<UserProfile>> findCarpoolMatches(String eventId) async* {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) yield [];

    // Get current user profile for location
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(user!.uid)
        .get();
    if (!currentUserDoc.exists) yield [];
    final currentUserProfile = UserProfile.fromJson(currentUserDoc.data()!);

    // Get event to verify attendees
    // We listen to the event document to update matches in real-time
    yield* _firestore.collection('events').doc(eventId).snapshots().asyncMap((
      eventSnapshot,
    ) async {
      if (!eventSnapshot.exists) return [];

      final eventData = eventSnapshot.data()!;
      final attendees = List<String>.from(eventData['attendees'] ?? []);

      // Exclude self
      attendees.remove(user.uid);

      if (attendees.isEmpty) return [];

      // Fetch profiles of attendees
      // Note: In a large scale app, we would use Algolia or query by chunks.
      // Here, assuming < 100 attendees for MVP, whereIn is limited to 10.
      // So we fetch them one by one or filter client side if list is small.
      // Better approach: Query users collection where 'uid' in attendees (chunks of 10)

      List<UserProfile> matches = [];

      // For MVP simplicity: Fetch all attendees and filter in memory
      // Optimized: Only fetch those who have explicitly enabled "Carpool" (future improvement)
      // For now, match by location.

      for (var attendeeId in attendees) {
        final doc = await _firestore.collection('users').doc(attendeeId).get();
        if (doc.exists) {
          final profile = UserProfile.fromJson(doc.data()!);

          // Match Logic
          bool isMatch = false;

          // A. Same Neighborhood (Strong Match)
          if (currentUserProfile.neighborhood != null &&
              profile.neighborhood == currentUserProfile.neighborhood) {
            isMatch = true;
          }
          // B. Same Commune (Medium Match)
          else if (currentUserProfile.commune != null &&
              profile.commune == currentUserProfile.commune) {
            isMatch = true;
          }
          // C. Distance < 3km (Geo Match)
          else if (currentUserProfile.latitude != null &&
              profile.latitude != null) {
            final distance = Geolocator.distanceBetween(
              currentUserProfile.latitude!,
              currentUserProfile.longitude!,
              profile.latitude!,
              profile.longitude!,
            );
            if (distance < 3000) {
              // 3km radius
              isMatch = true;
            }
          }

          if (isMatch) {
            matches.add(profile);
          }
        }
      }
      return matches;
    });
  }

  // 2. Register Participation with Ecosystem Logic
  Future<void> participateInEvent(EventModel event) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    // A. Add to Event Attendees
    final eventRef = _firestore.collection('events').doc(event.id);
    batch.update(eventRef, {
      'attendees': FieldValue.arrayUnion([user.uid]),
    });

    // B. Update User Profile (Points & History)
    final userRef = _firestore.collection('users').doc(user.uid);
    // +10 Points for participation
    batch.update(userRef, {
      'points': FieldValue.increment(10),
      'participatingEvents': FieldValue.arrayUnion([
        event.id,
      ]), // Ensure this field exists or ignored if schema loose
    });

    // C. Notify Friends
    // Get user's friends
    final userDoc = await userRef.get();
    final userProfile = UserProfile.fromJson(userDoc.data()!);

    for (var friendId in userProfile.friends) {
      final friendRef = _firestore
          .collection('users')
          .doc(friendId)
          .collection('notifications')
          .doc();
      batch.set(friendRef, {
        'type': 'event_friend',
        'body':
            '${userProfile.firstName} participe à ${event.title}. Rejoins-le !',
        'eventId': event.id,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    await batch.commit();
  }
}
