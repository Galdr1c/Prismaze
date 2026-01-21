import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Security utilities for PrisMaze
class SecurityUtils {
  // Simple XOR key for token obfuscation (not true encryption, but deterrent)
  static const int _xorKey = 0x5A;
  static const String _salt = 'PRZ_2024';
  
  /// Encode a value for storage (obfuscation)
  static String encodeValue(int value) {
    final data = '$_salt:$value';
    final bytes = utf8.encode(data);
    final xored = bytes.map((b) => b ^ _xorKey).toList();
    return base64Encode(xored);
  }
  
  /// Decode a stored value
  static int? decodeValue(String encoded) {
    try {
      final xored = base64Decode(encoded);
      final bytes = xored.map((b) => b ^ _xorKey).toList();
      final data = utf8.decode(bytes);
      
      if (!data.startsWith('$_salt:')) return null; // Tampered
      
      return int.tryParse(data.split(':')[1]);
    } catch (e) {
      return null; // Invalid/tampered
    }
  }
  
  /// Generate checksum for validation
  static String generateChecksum(int value, int timestamp) {
    final data = '$_salt:$value:$timestamp';
    // Simple hash via fold
    int hash = 0;
    for (int i = 0; i < data.length; i++) {
      hash = (hash * 31 + data.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16);
  }
}

/// Integrity checker for cheat detection
class IntegrityChecker {
  
  /// Validate star calculation
  static bool validateStars(int moves, int par, int stars) {
    if (moves <= par && stars != 3) return false;
    if (moves > par && moves <= (par * 1.5).ceil() && stars != 2) return false;
    if (moves > (par * 1.5).ceil() && stars != 1) return false;
    return true;
  }
  
  /// Validate move count is reasonable
  static bool validateMoves(int moves, int levelId) {
    // Minimum possible moves (rough heuristic)
    if (moves < 1) return false; // Must have at least 1 move
    if (moves > 999) return false; // Sanity cap
    return true;
  }
  
  /// Validate token amount is reasonable
  static bool validateTokenChange(int before, int after, int expectedDelta) {
    return (after - before) == expectedDelta;
  }
  
  /// Check APK integrity (Android only)
  static Future<bool> checkAppIntegrity() async {
    if (!Platform.isAndroid) return true; // iOS uses different mechanisms
    
    try {
      // Check if running in debug mode (acceptable for dev)
      if (kDebugMode) return true;
      
      // In production, would use:
      // 1. Package signature verification
      // 2. SafetyNet/Play Integrity API
      // 3. Root detection
      
      // Stub: Check for common modded indicators
      final suspicious = await _checkSuspiciousEnvironment();
      return !suspicious;
      
    } catch (e) {
      // Fail closed - assume tampered if check fails
      return false;
    }
  }
  
  static Future<bool> _checkSuspiciousEnvironment() async {
    // Stub implementation - in production would check:
    // - /system/app/Superuser.apk
    // - /system/xbin/su
    // - Frida/Xposed hooks
    // - Modified signature
    
    // For now, always return false (not suspicious)
    print("[Security] Integrity check passed (stub)");
    return false;
  }
}

/// Server-side validation stubs
class ServerValidator {
  static const String _stubEndpoint = 'https://api.prismaze.example/validate';
  
  /// Validate IAP receipt (stub - would call real server)
  static Future<bool> validatePurchase({
    required String productId,
    required String receipt,
    required String platform, // 'android' or 'ios'
  }) async {
    print("[Server] Validating purchase: $productId");
    
    // Stub: Simulate server call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In production, would:
    // 1. Send receipt to backend
    // 2. Backend verifies with Google/Apple
    // 3. Return true only if valid
    
    // Stub always returns true for development
    print("[Server] Purchase validated (stub)");
    return true;
  }
  
  /// Validate score submission (anti-cheat)
  static Future<bool> validateScore({
    required int levelId,
    required int stars,
    required int moves,
    required double duration,
    required String checksum,
  }) async {
    print("[Server] Validating score: Level $levelId, $stars stars");
    
    // Stub: Simulate server validation
    await Future.delayed(const Duration(milliseconds: 200));
    
    // In production, would:
    // 1. Verify checksum
    // 2. Check against expected ranges
    // 3. Flag suspicious patterns
    
    return true;
  }
}
