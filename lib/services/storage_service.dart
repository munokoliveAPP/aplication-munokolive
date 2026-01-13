import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  // We assume SecurityService is available via ref if needed,
  // but StorageService here is often overridden in main.
  // Ideally, we should pass the security service.
  final securityService = ref.read(securityServiceProvider);
  return StorageService(SharedPreferences.getInstance(), securityService);
});

class StorageService {
  final Future<SharedPreferences> _prefs;
  final SecurityService?
  _securityService; // Optional for backward compatibility/testing

  StorageService(this._prefs, [this._securityService]);

  static const String _latKey = 'last_camera_lat';
  static const String _lngKey = 'last_camera_lng';
  static const String _zoomKey = 'last_camera_zoom';

  Future<void> saveCameraPosition(CameraPosition position) async {
    final prefs = await _prefs;
    await prefs.setDouble(_latKey, position.target.latitude);
    await prefs.setDouble(_lngKey, position.target.longitude);
    await prefs.setDouble(_zoomKey, position.zoom);
  }

  Future<CameraPosition?> getLastCameraPosition() async {
    final prefs = await _prefs;
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    final zoom = prefs.getDouble(_zoomKey);

    if (lat != null && lng != null && zoom != null) {
      return CameraPosition(target: LatLng(lat, lng), zoom: zoom);
    }
    return null;
  }

  // Generic Secure Storage Methods
  Future<void> saveSecureData(String key, String value) async {
    final prefs = await _prefs;
    if (_securityService != null) {
      // Ensure initialized
      await _securityService.initialize();
      final encrypted = _securityService.encryptData(value);
      await prefs.setString(key, encrypted);
    } else {
      // Fallback or throw? For now fallback to plain text if no security service (shouldn't happen in prod)
      await prefs.setString(key, value);
    }
  }

  Future<String?> getSecureData(String key) async {
    final prefs = await _prefs;
    final value = prefs.getString(key);
    if (value == null) return null;

    if (_securityService != null) {
      await _securityService.initialize();
      try {
        return _securityService.decryptData(value);
      } catch (e) {
        // If decryption fails (key changed, data corrupted), return null or original
        return null;
      }
    }
    return value;
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
    if (_securityService != null) {
      await _securityService.secureWipe();
    }
  }
}
