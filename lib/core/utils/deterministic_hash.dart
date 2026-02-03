import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Provides a cross-platform deterministic hashing mechanism.
/// Ensures consistent hash codes across Android, iOS, and Web.
class DeterministicHash {
  DeterministicHash._(); // Private constructor

  /// Generates a deterministic 32-bit signed integer hash from the input string.
  /// 
  /// Uses SHA-256 and takes the last 4 bytes to form the integer.
  /// This guarantees that the same string always produces the same integer
  /// on any platform, unlike Dart's native [String.hashCode].
  static int hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    
    // Get last 4 bytes of the digest
    final digestBytes = digest.bytes;
    final length = digestBytes.length;
    
    // We take the last 4 bytes (indices length-4 to length-1)
    // to build a 32-bit integer.
    // Big-endian construction for consistency
    int result = (digestBytes[length - 4] << 24) | 
                 (digestBytes[length - 3] << 16) | 
                 (digestBytes[length - 2] << 8) | 
                 (digestBytes[length - 1]);
                 
    return result.toSigned(32);
  }
  
  /// Combines multiple hash codes deterministically
  static int combine(List<int> hashes) {
    int result = 0;
    for (int hash in hashes) {
      result = (result * 31 + hash) & 0xFFFFFFFF; // Standard 31 multiplier
    }
    return result;
  }
}
