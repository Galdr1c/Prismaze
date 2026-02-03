import 'package:shared_preferences/shared_preferences.dart';

/// Manages progress specifically for the Global Endless mode.
/// Tracks the highest level index reached by the user.
/// Designed to be thread-safe (via SharedPreferences atomic writes where possible)
/// and distinct from the campaign ProgressManager.
class EndlessProgressManager {
  static const String _keyCurrentLevel = 'endless_current_level_index';
  
  final SharedPreferences _prefs;

  EndlessProgressManager(this._prefs);

  static Future<EndlessProgressManager> init() async {
    final prefs = await SharedPreferences.getInstance();
    return EndlessProgressManager(prefs);
  }

  /// Returns the current level index the user is on.
  /// Defaults to 1 if typically levels are 1-based.
  int getCurrentLevelIndex() {
    return _prefs.getInt(_keyCurrentLevel) ?? 1;
  }

  /// Updates the current level index.
  /// Only updates if the new index is greater than the current one (no regression),
  /// unless [force] is true.
  Future<void> setCurrentLevelIndex(int index, {bool force = false}) async {
    final current = getCurrentLevelIndex();
    if (force || index > current) {
      await _prefs.setInt(_keyCurrentLevel, index);
    }
  }
}
