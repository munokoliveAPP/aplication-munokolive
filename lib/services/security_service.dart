import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:safe_device/safe_device.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

class SecurityService {
  final _secureStorage = const FlutterSecureStorage();
  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;
  bool _isInitialized = false;

  // Key for storing the AES key in secure storage
  static const String _keyStorageKey = 'app_encryption_key';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Root/Jailbreak Detection
    final isSafe = await _checkDeviceIntegrity();
    if (!isSafe) {
      // In a real app, you might crash or limit functionality here.
      // For now, we just log it or set a flag.
      debugPrint(
        'SECURITY WARNING: Device might be compromised (Rooted/Emulator).',
      );
    }

    // 2. Encryption Setup
    String? keyString = await _secureStorage.read(key: _keyStorageKey);

    if (keyString == null) {
      // Generate a new 32-byte (256-bit) key
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = base64Url.encode(key.bytes);
      await _secureStorage.write(key: _keyStorageKey, value: keyString);
    }

    final key = encrypt.Key.fromBase64(keyString);
    // Use a fixed IV or generate per message.
    // For simplicity in this local db context, we use a fixed IV or derived.
    // Ideally, IV should be stored alongside data.
    // Here we use a fixed 16-byte IV for simplicity of implementation in this demo,
    // but in production, unique IV per record is better.
    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));

    _isInitialized = true;
  }

  Future<bool> _checkDeviceIntegrity() async {
    try {
      bool isJailBroken = await SafeDevice.isJailBroken;
      // bool isRealDevice = await SafeDevice.isRealDevice;

      // Allow emulators for development but warn
      // return !isJailBroken && isRealDevice;

      if (isJailBroken) return false;
      return true;
    } catch (e) {
      return true; // Default to safe if check fails to avoid lockout on errors
    }
  }

  String encryptData(String plainText) {
    if (!_isInitialized) throw Exception('SecurityService not initialized');
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedBase64) {
    if (!_isInitialized) throw Exception('SecurityService not initialized');
    final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  Future<void> secureWipe() async {
    // Destroy keys and data
    await _secureStorage.deleteAll();
    // In a real app, also delete local files, databases, etc.
  }
}
