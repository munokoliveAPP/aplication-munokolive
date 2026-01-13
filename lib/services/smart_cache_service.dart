import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final smartCacheServiceProvider = Provider<SmartCacheService>((ref) {
  return SmartCacheService();
});

/// Service de cache intelligent pour optimiser les performances
class SmartCacheService {
  static const String _cachePrefix = 'smart_cache_';
  static const Duration _defaultExpiration = Duration(hours: 1);

  /// Sauvegarder des données en cache
  Future<void> save<T>(String key, T data, {Duration? expiration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expirationTime = DateTime.now()
          .add(expiration ?? _defaultExpiration)
          .toIso8601String();

      final cacheData = {
        'data': data,
        'expiration': expirationTime,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
    } catch (e) {
      // Silently fail - cache is not critical
    }
  }

  /// Récupérer des données du cache
  Future<T?> get<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('$_cachePrefix$key');

      if (cachedString == null) return null;

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final expiration = DateTime.parse(cacheData['expiration'] as String);

      if (DateTime.now().isAfter(expiration)) {
        // Cache expired
        await prefs.remove('$_cachePrefix$key');
        return null;
      }

      return cacheData['data'] as T?;
    } catch (e) {
      return null;
    }
  }

  /// Vérifier si une clé existe et n'est pas expirée
  Future<bool> exists(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// Invalider une clé de cache
  Future<void> invalidate(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
    } catch (e) {
      // Silently fail
    }
  }

  /// Invalider toutes les clés avec un préfixe
  Future<void> invalidatePrefix(String prefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('$_cachePrefix$prefix')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Nettoyer le cache expiré
  Future<void> cleanExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

      for (final key in keys) {
        final cachedString = prefs.getString(key);
        if (cachedString != null) {
          try {
            final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
            final expiration = DateTime.parse(
              cacheData['expiration'] as String,
            );

            if (DateTime.now().isAfter(expiration)) {
              await prefs.remove(key);
            }
          } catch (e) {
            // Invalid cache entry, remove it
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Vider tout le cache
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Silently fail
    }
  }
}
