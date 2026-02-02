/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_service.dart';

// Overridden in main.dart
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden');
});

class StorageService {
  final Future<SharedPreferences> _prefs;
  final SecurityService _security;

  StorageService(this._prefs, this._security);

  Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    final encrypted = _security.encryptData(value);
    await prefs.setString(key, encrypted);
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    final encrypted = prefs.getString(key);
    if (encrypted == null) return null;
    try {
      return _security.decryptData(encrypted);
    } catch (e) {
      return null;
    }
  }

  // --- SECURE STORAGE (For API Keys, Tokens) ---

  Future<void> setSecureString(String key, String value) async {
    await _security.writeSecure(key, value);
  }

  Future<String?> getSecureString(String key) async {
    return await _security.readSecure(key);
  }

  Future<void> deleteSecureString(String key) async {
    await _security.deleteSecure(key);
  }
}
