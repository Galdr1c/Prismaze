import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureSaveManager {
  static final SecureSaveManager _instance = SecureSaveManager._internal();
  factory SecureSaveManager() => _instance;
  SecureSaveManager._internal();

  final _storage = const FlutterSecureStorage();
  late final encrypt.Key _encryptionKey;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Retrieve or generate key
    String? savedKey = await _storage.read(key: 'save_encryption_key');
    
    if (savedKey == null) {
      print("SecureSave: Generating new encryption key...");
      final key = encrypt.Key.fromSecureRandom(32);
      await _storage.write(key: 'save_encryption_key', value: key.base64);
      _encryptionKey = key;
    } else {
      _encryptionKey = encrypt.Key.fromBase64(savedKey);
    }
    
    _initialized = true;
    print("SecureSave: Initialized.");
  }

  /// Save data securely to SharedPreferences (Encrypted)
  Future<void> saveData(String key, String jsonData) async {
    if (!_initialized) await init();

    // 1. Calculate Checksum (Integrity)
    final checksum = _calculateChecksum(jsonData);
    
    // 2. Wrap payload
    final payload = jsonEncode({
      'data': jsonData,
      'checksum': checksum,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // 3. Encrypt
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encrypt(payload, iv: iv);

    // 4. Save to SharedPrefs (using a suffix to distinguish from plain text)
    // We store the IV + Encrypted Data combined, usually base64(iv) + ":" + base64(data)
    final combined = '${iv.base64}:${encrypted.base64}';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${key}_secure', combined);
    
    print("SecureSave: Saved encrypted data for $key");
  }

  /// Load secure data
  Future<String?> loadData(String key) async {
    if (!_initialized) await init();

    final prefs = await SharedPreferences.getInstance();
    final encryptedString = prefs.getString('${key}_secure');

    if (encryptedString == null) {
      // Fallback: Try loading legacy plain text to migrate
      final legacy = prefs.getString(key);
      if (legacy != null) {
        print("SecureSave: Migrating legacy data for $key...");
        await saveData(key, legacy); // Upgrade to secure
        await prefs.remove(key); // Remove legacy
        return legacy;
      }
      return null;
    }

    try {
      final parts = encryptedString.split(':');
      if (parts.length != 2) throw Exception("Invalid format");

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final decryptedPayload = encrypter.decrypt(encryptedData, iv: iv);
      
      final Map<String, dynamic> payload = jsonDecode(decryptedPayload);
      final String originalData = payload['data'];
      final String savedChecksum = payload['checksum'];
      
      // Verify Integrity
      if (_calculateChecksum(originalData) != savedChecksum) {
        print("SecureSave: CHECKSUM MISMATCH! Possible tampering.");
        // Policy: Fail query or return null?
        // For now, return null to force integrity.
        return null;
      }
      
      return originalData;

    } catch (e) {
      print("SecureSave: Load Failed / Corrupted: $e");
      return null;
    }
  }
  
  String _calculateChecksum(String input) {
    final salt = "Prismaze_Salt_v1";
    final bytes = utf8.encode(input + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Debug/Test only
  Future<void> clearSecureData(String key) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.remove('${key}_secure');
  }
}
