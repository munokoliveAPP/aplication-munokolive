import 'dart:io';
import 'package:app_device_integrity/app_device_integrity.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class IntegrityService {
  final AppDeviceIntegrity _integrityPlugin = AppDeviceIntegrity();
  final Uuid _uuid = const Uuid();

  // Replace with your actual GCP Project ID (Android)
  // Found in Google Play Console > Release > App Integrity
  static const int _gcpProjectNumber =
      0; // Set to 0 to disable or replace with real ID

  Future<String?> getIntegrityToken(String? challenge) async {
    if (kIsWeb) return null; // Web not supported by this plugin yet

    try {
      final String sessionId = challenge ?? _uuid.v4();
      String? token;

      if (Platform.isAndroid) {
        if (_gcpProjectNumber == 0) {
          debugPrint('GCP Project Number not set. Skipping Integrity Check.');
          return "dummy_token_dev";
        }
        // Android: Play Integrity
        token = await _integrityPlugin.getAttestationServiceSupport(
          challengeString: sessionId,
          gcp: _gcpProjectNumber,
        );
      } else if (Platform.isIOS) {
        // iOS: App Attest
        token = await _integrityPlugin.getAttestationServiceSupport(
          challengeString: sessionId,
        );
      }

      return token;
    } catch (e) {
      debugPrint('Integrity Check Error: $e');
      // On emulator or failed check, this might throw or return null/error string
      return null;
    }
  }
}
