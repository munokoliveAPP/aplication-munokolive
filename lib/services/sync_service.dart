import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_database_service.dart';
import 'watchdog_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final localDb = ref.read(localDatabaseServiceProvider);
  return SyncService(localDb);
});

class SyncService {
  final LocalDatabaseService _localDb;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._localDb);

  void startMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      // connectivity_plus returns a List<ConnectivityResult> in newer versions
      if (results.any((r) => r != ConnectivityResult.none)) {
        _processQueue();
      }
    });
  }

  void stopMonitoring() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingActions = await _localDb.getPendingActions();

      for (final action in pendingActions) {
        final id = action['id'] as String;
        final type = action['type'] as String;
        final payload =
            jsonDecode(action['payload'] as String) as Map<String, dynamic>;

        try {
          await _executeAction(type, payload);
          await _localDb.removePendingAction(
            id,
          ); // Remove from queue on success
        } catch (e) {
          // Keep in queue if temporary error, remove if fatal?
          // For now, simple retry logic: keep it there.
          WatchdogService.logWarning('Sync failed for action $id: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _executeAction(String type, Map<String, dynamic> payload) async {
    switch (type) {
      case 'post':
        await _firestore.collection('posts').doc(payload['id']).set(payload);
        break;
      case 'message':
        await _firestore.collection('messages').doc(payload['id']).set(payload);
        break;
      // Add more cases as needed
      default:
        WatchdogService.logWarning('Unknown action type: $type');
    }
  }

  // --- Background Sync (Silent Update) ---

  // Example: Sync latest posts silently
  Future<void> syncPosts() async {
    // 1. Fetch latest from API
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    // 2. Update Local DB
    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      // Convert Timestamp to int for SQLite
      if (data['timestamp'] is Timestamp) {
        data['timestamp'] =
            (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
      }
      await _localDb.cachePost(data);
    }
  }
}
