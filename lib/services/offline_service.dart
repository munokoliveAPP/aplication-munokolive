import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'smart_cache_service.dart';

final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService(ref.read(smartCacheServiceProvider));
});

/// Service de gestion offline
class OfflineService {
  final SmartCacheService _cache;
  ConnectivityResult _currentStatus = ConnectivityResult.none;

  OfflineService(this._cache) {
    _init();
  }

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    _currentStatus = result.first;
  }

  /// Vérifier si on est en ligne
  bool get isOnline {
    return _currentStatus != ConnectivityResult.none;
  }

  /// Vérifier si on est offline
  bool get isOffline => !isOnline;

  /// Mettre à jour le statut de connexion
  void updateStatus(ConnectivityResult status) {
    _currentStatus = status;
  }

  /// Sauvegarder des données pour le mode offline
  Future<void> saveForOffline(String key, dynamic data) async {
    await _cache.save(
      'offline_$key',
      data,
      expiration: const Duration(days: 7),
    );
  }

  /// Récupérer des données du cache offline
  Future<T?> getOfflineData<T>(String key) async {
    return await _cache.get<T>('offline_$key');
  }

  /// Vider le cache offline
  Future<void> clearOfflineCache() async {
    await _cache.invalidatePrefix('offline_');
  }
}
