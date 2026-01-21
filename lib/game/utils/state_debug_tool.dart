import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Debug utility for inspecting and managing saved game state
/// Access via Settings debug mode or developer console
class StateDebugTool {
  static Future<Map<String, dynamic>> exportAllState() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> export = {};
    
    for (final key in keys) {
      final value = prefs.get(key);
      export[key] = value;
    }
    
    return export;
  }
  
  static Future<String> exportAsJson() async {
    final state = await exportAllState();
    return const JsonEncoder.withIndent('  ').convert(state);
  }
  
  static Future<void> importState(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        await prefs.setStringList(key, value.cast<String>());
      }
    }
    
    print("[StateDebugTool] Imported ${data.length} keys");
  }
  
  static void printStateSnapshot() async {
    final state = await exportAllState();
    
    print("╔════════════════════════════════════════╗");
    print("║       SAVED STATE SNAPSHOT             ║");
    print("╠════════════════════════════════════════╣");
    
    // Group by prefix
    final groups = <String, Map<String, dynamic>>{};
    
    for (final entry in state.entries) {
      String prefix = 'other';
      if (entry.key.startsWith('level_')) prefix = 'progress';
      else if (entry.key.startsWith('stat_')) prefix = 'stats';
      else if (entry.key.startsWith('settings_')) prefix = 'settings';
      else if (entry.key.startsWith('hint_')) prefix = 'economy';
      else if (entry.key.startsWith('activity_')) prefix = 'activity';
      else if (entry.key.startsWith('ach_') || entry.key == 'achievements') prefix = 'achievements';
      
      groups.putIfAbsent(prefix, () => {});
      groups[prefix]![entry.key] = entry.value;
    }
    
    for (final group in groups.entries) {
      print("║ [${group.key.toUpperCase()}]");
      for (final item in group.value.entries) {
        final val = item.value.toString();
        final truncated = val.length > 30 ? '${val.substring(0, 30)}...' : val;
        print("║   ${item.key}: $truncated");
      }
    }
    
    print("╚════════════════════════════════════════╝");
    print("Total keys: ${state.length}");
  }
  
  /// Get progress summary for quick debug
  static Future<Map<String, dynamic>> getProgressSummary() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Count level stars
    int totalStars = 0;
    int completedLevels = 0;
    int threeStarLevels = 0;
    
    for (final key in prefs.getKeys()) {
      if (key.startsWith('level_stars_')) {
        final stars = prefs.getInt(key) ?? 0;
        if (stars > 0) {
          completedLevels++;
          totalStars += stars;
          if (stars == 3) threeStarLevels++;
        }
      }
    }
    
    final achievements = prefs.getStringList('achievements') ?? [];
    
    return {
      'completedLevels': completedLevels,
      'totalStars': totalStars,
      'threeStarLevels': threeStarLevels,
      'achievements': achievements.length,
      'tokens': prefs.getString('hint_tokens_enc') != null ? '(encrypted)' : 0,
      'playTime': prefs.getInt('stat_total_play_time') ?? 0,
    };
  }
  
  /// Clear all saved data (use with caution!)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("[StateDebugTool] All data cleared!");
  }
  
  /// Backup current state before modifications
  static Future<Map<String, dynamic>> createBackup() async {
    final state = await exportAllState();
    print("[StateDebugTool] Backup created with ${state.length} keys");
    return state;
  }
  
  /// Restore from backup
  static Future<void> restoreBackup(Map<String, dynamic> backup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await importState(backup);
    print("[StateDebugTool] Restored from backup");
  }
}
