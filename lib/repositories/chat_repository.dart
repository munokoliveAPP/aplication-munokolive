import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';

// Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.read(localDatabaseServiceProvider),
    ref.read(syncServiceProvider),
  );
});

class ChatRepository {
  final LocalDatabaseService _localDb;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatRepository(
    this._localDb,
    SyncService _,
  ); // Keep signature compatible for now or update provider

  // 1. Get Messages (Cache-First Strategy)
  // Returns a Stream that emits local data immediately, then updates when new data arrives.
  // This ensures "Instant Start" without network latency.
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) async* {
    // A. Emit Local Cache immediately
    final cached = await _localDb.getConversationMessages(conversationId);
    if (cached.isNotEmpty) {
      yield cached;
    }

    // B. Fetch from API in background (Silent Sync)
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        // Normalize timestamp for SQLite (int)
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
        }
        await _localDb.cacheMessage(data);
      }

      // C. Emit updated cache
      final updated = await _localDb.getConversationMessages(conversationId);
      yield updated;
    } catch (e) {
      // If offline, we just rely on cache emitted in step A.
      // This ensures "Offline Access" to history.
      debugPrint('Chat sync error (Offline?): $e');
    }
  }

  // 2. Send Message (Optimistic UI + Offline Queue)
  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String content,
  ) async {
    final tempId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final message = {
      'id': tempId,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'isRead': false,
      'status': 'sending', // Local status to show "clock" icon or similar
    };

    // A. Save to Local DB immediately (Instant Feedback)
    await _localDb.cacheMessage(message);

    // B. Queue for background sync (Robustness)
    // We use the tempId as the doc ID so we can track it.
    // Ideally use UUID.
    final payload = {
      'id': tempId,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(
        timestamp,
      ), // Server expects Timestamp
      'isRead': false,
    };

    // Queue it
    await _localDb.queueAction(tempId, 'message', payload);

    // Note: SyncService will pick this up automatically if online
  }
}
