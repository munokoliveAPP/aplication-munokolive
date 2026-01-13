import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/services/auth_service.dart';
import 'package:munokolive_music/services/notification_manager.dart';

final notificationListenerProvider = Provider<NotificationListenerService>((
  ref,
) {
  final authService = ref.read(authServiceProvider);
  final notificationManager = ref.read(notificationManagerProvider);
  return NotificationListenerService(authService, notificationManager);
});

class NotificationListenerService {
  final AuthService _authService;
  final NotificationManager _notificationManager;
  StreamSubscription<QuerySnapshot>? _subscription;

  NotificationListenerService(this._authService, this._notificationManager);

  void startListening() {
    final user = _authService.currentUser;
    if (user == null) return;

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;
              _handleNotification(change.doc.id, data);
            }
          }
        });
  }

  void stopListening() {
    _subscription?.cancel();
  }

  Future<void> _handleNotification(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final type = data['type'] as String? ?? 'general';
    final body = data['body'] as String? ?? '';
    final sosId = data['sosId'] as String?;

    // Construct payload
    String? payload;
    if (type == 'sos' && sosId != null) {
      payload = 'sos:$sosId';
    } else {
      payload = type;
    }

    // Pass to manager to display/stack
    _notificationManager.handleIncomingNotification(
      type,
      body,
      payload: payload,
    );

    // Mark as read immediately to avoid re-processing
    try {
      if (_authService.currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_authService.currentUser!.uid)
            .collection('notifications')
            .doc(docId)
            .update({'read': true});
      }
    } catch (e) {
      // Ignore update errors (maybe offline)
    }
  }
}
