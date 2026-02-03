import 'package:shared_preferences/shared_preferences.dart';

/// Manages the generator version for the Global Endless mode.
/// Ensures players stick to their assigned version to maintain level consistency
/// even if the app updates with a new default generator version.
class VersionManager {
  static const String _keyVersion = 'generator_version';
  static const String latestVersion = 'v1'; // Current latest version of the generator

  final SharedPreferences _prefs;

  VersionManager(this._prefs);

  static Future<VersionManager> init() async {
    final prefs = await SharedPreferences.getInstance();
    return VersionManager(prefs);
  }

  /// Returns the user's locked generator version.
  /// If no version is set (fresh install), it locks the user to the [latestVersion].
  String getCurrentVersion() {
    String? version = _prefs.getString(_keyVersion);
    
    if (version == null) {
      // New user, lock to current latest
      version = latestVersion;
      _prefs.setString(_keyVersion, version);
      // Note: We deliberately do not await here to return synchronously,
      // but SharedPreferences is async-write, sync-read for cache.
    }
    
    return version;
  }

  /// FOR DEBUGGING/MIGRATION ONLY: Force set a version.
  Future<void> setVersion(String version) async {
    await _prefs.setString(_keyVersion, version);
  }
}
