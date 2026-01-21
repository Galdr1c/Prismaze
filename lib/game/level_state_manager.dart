import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/components.dart';
import 'dart:convert';

class LevelStateManager {
  static final LevelStateManager _instance = LevelStateManager._internal();
  factory LevelStateManager() => _instance;
  LevelStateManager._internal();
  
  late SharedPreferences _prefs;
  
  Future<void> init() async {
      _prefs = await SharedPreferences.getInstance();
  }
  
  Future<void> saveLevelState(int levelId, List<Map<String, dynamic>> objects) async {
      // objects list: [{ 'id': 1, 'x': 100, 'y': 200, 'angle': 1.5 }, ...]
      // We don't have unique IDs for components easily unless we assigned them.
      // But prisms are usually unique enough by index?
      // Actually, LevelLoader creates components pure. 
      // If we save state, we need to map it back.
      // Easiest is to save index-based config if array order is deterministic.
      // Assuming LevelLoader loads same order.
      
      final jsonStr = jsonEncode(objects);
      await _prefs.setString('level_state_$levelId', jsonStr);
      print("Auto-Saved Level $levelId State: ${objects.length} items");
  }
  
  List<Map<String, dynamic>>? loadLevelState(int levelId) {
      final str = _prefs.getString('level_state_$levelId');
      if (str == null) return null;
      try {
          final List<dynamic> list = jsonDecode(str);
          return list.cast<Map<String, dynamic>>();
      } catch (e) {
          return null;
      }
  }
  
  Future<void> clearLevelState(int levelId) async {
      await _prefs.remove('level_state_$levelId');
  }
}
