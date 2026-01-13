import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sos_service.dart';

final sosServiceProvider = Provider<SosService>((ref) {
  return SosService(FirebaseFirestore.instance);
});

// Provider for active SOS alerts nearby (for receiving)
// This is a simplified stream for demonstration
final activeSOSProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('sos_alerts')
      .where('status', isEqualTo: 'active')
      .orderBy('timestamp', descending: true)
      .limit(1) // Just get the latest one for now
      .snapshots();
});
