/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

class SyncService {
  void startMonitoring() {
    // Start background sync
  }
  
  void stopMonitoring() {
    // Stop background sync
  }
}
