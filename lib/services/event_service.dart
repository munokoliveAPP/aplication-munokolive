import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(FirebaseFirestore.instance);
});

class EventService {
  final FirebaseFirestore _firestore;

  EventService(this._firestore);

  Future<void> createEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.id).set(event.toJson());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<void> validateEvent(String eventId, bool isValid) async {
    await _firestore.collection('events').doc(eventId).update({
      'status': isValid ? 'approved' : 'rejected',
    });
  }

  Future<void> toggleAttendance(String eventId, String userId) async {
    final docRef = _firestore.collection('events').doc(eventId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final List<String> attendees = List<String>.from(
      doc.data()?['attendees'] ?? [],
    );
    if (attendees.contains(userId)) {
      attendees.remove(userId);
    } else {
      attendees.add(userId);
    }

    await docRef.update({'attendees': attendees});
  }

  Stream<List<EventModel>> getEvents() {
    return _firestore.collection('events').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return EventModel.fromJson(data);
      }).toList();
    });
  }
}
