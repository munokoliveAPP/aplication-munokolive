/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_service.dart';

final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.connectivityStream;
});

final isOfflineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStatusProvider);
  return connectivityAsync.when(
    data: (isConnected) => !isConnected,
    loading: () => false, // Assume online while loading
    error: (error, stack) => false, // Assume online on error
  );
});
