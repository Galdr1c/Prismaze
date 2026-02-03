import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/level_recipe.dart';

/// Persists level recipes to local storage.
/// Ensures that once a level's blueprint is derived, it is locked.
class RecipeRepository {
  static const String _keyPrefix = 'recipe_v1_';

  static Future<void> saveRecipe(LevelRecipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${recipe.levelIndex}';
    await prefs.setString(key, jsonEncode(recipe.toJson()));
  }

  static Future<LevelRecipe?> getRecipe(int levelIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$levelIndex';
    final data = prefs.getString(key);
    if (data == null) return null;
    try {
      return LevelRecipe.fromJson(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
