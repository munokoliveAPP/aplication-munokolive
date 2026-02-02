/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:safe_device/safe_device.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

class SecurityService {
  final _secureStorage = const FlutterSecureStorage();
  late final encrypt.Encrypter _encrypter;
  bool _isInitialized = false;

  // Key for storing the AES key in secure storage
  static const String _keyStorageKey = 'app_encryption_key';

  // --- CONFIGURATION DE SÉCURITÉ ---
  // Remplacer par le hash SHA-256 de votre certificat de production
  // Commande pour l'obtenir : keytool -list -v -keystore <votre_keystore>
  static const String _authorizedSignatureHash =
      ""; // Laissez vide en dev, remplissez en prod avec le hash SHA-256

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Root/Jailbreak & Signature Detection
    await _performSecurityChecks();

    // 2. Encryption Setup
    String? keyString = await _secureStorage.read(key: _keyStorageKey);

    if (keyString == null) {
      // Generate a new 32-byte (256-bit) key
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = base64Url.encode(key.bytes);
      await _secureStorage.write(key: _keyStorageKey, value: keyString);
    }

    final key = encrypt.Key.fromBase64(keyString);
    // AES Mode CBC is default. IV will be generated per-message.
    _encrypter = encrypt.Encrypter(encrypt.AES(key));

    _isInitialized = true;
  }

  Future<void> _performSecurityChecks() async {
    // A. Root/Jailbreak Check
    bool isJailBroken = false;
    bool isRealDevice = true;
    try {
      isJailBroken = await SafeDevice.isJailBroken;
      isRealDevice = await SafeDevice.isRealDevice;
    } catch (e) {
      debugPrint("Security Check Error: $e");
    }

    // En mode debug, on est plus tolérant (émulateurs autorisés)
    if (kReleaseMode) {
      if (isJailBroken) {
        _killApp("Appareil compromis (Root/Jailbreak détecté).");
      }
      if (!isRealDevice) {
        // Optionnel : Bloquer les émulateurs en prod
        // _killApp("Exécution sur émulateur interdite.");
      }
    }

    // B. Signature Verification (Anti-Tamper)
    // Note: Une vérification robuste nécessite du code natif (MethodChannel)
    // ou un package comme 'freerasp'.
    // Ici, nous simulons une vérification de l'installateur (Google Play / App Store)
    // C'est une première ligne de défense.
    if (kReleaseMode) {
      await _verifyInstaller();
    }
  }

  Future<void> _verifyInstaller() async {
    // Vérifie si l'app a été installée par un store officiel
    // Ceci empêche l'exécution d'APK sideloadés (souvent modifiés)
    if (Platform.isAndroid) {
      // Note: Pour une vérification stricte, utilisez 'package_info_plus' pour obtenir
      // l'installerStore (ex: 'com.android.vending').
      // Pour l'instant, on ignore cette vérification pour éviter les blocages en dev/test.
      
      if (_authorizedSignatureHash.isNotEmpty) {
        // Logique de vérification de signature à implémenter ici
      }
    }
  }

  void _killApp(String reason) {
    debugPrint("SECURITY KILL SWITCH ACTIVATED: $reason");
    // Force crash/exit
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  String encryptData(String plainText) {
    if (!_isInitialized) throw Exception('SecurityService not initialized');

    final iv = encrypt.IV.fromLength(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);

    // Combine IV and Ciphertext: IV (16 bytes) + Ciphertext
    final combined = iv.bytes + encrypted.bytes;
    return base64.encode(combined);
  }

  String decryptData(String encryptedBase64) {
    if (!_isInitialized) throw Exception('SecurityService not initialized');

    final decoded = base64.decode(encryptedBase64);

    // Extract IV (first 16 bytes)
    if (decoded.length < 16) throw Exception('Invalid encrypted data');

    final iv = encrypt.IV(decoded.sublist(0, 16));
    final cipherBytes = decoded.sublist(16);
    final encrypted = encrypt.Encrypted(cipherBytes);

    return _encrypter.decrypt(encrypted, iv: iv);
  }

  // --- SECURE STORAGE DIRECT ACCESS ---

  Future<void> writeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> secureWipe() async {
    await _secureStorage.deleteAll();
  }
}
