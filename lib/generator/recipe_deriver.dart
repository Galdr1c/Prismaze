import '../core/utils/deterministic_hash.dart';
import 'models/level_recipe.dart';
import 'selector/template_selector.dart';

/// Static utility to derive deterministic seeds and recipes for levels.
/// Implements the "Law of the Seed":
/// Version + LevelIndex = Unique Deterministic Seed
class RecipeDeriver {
  RecipeDeriver._();

  static const String _separator = ":";
  static final TemplateSelector _selector = TemplateSelector();

  /// Derives the unique seed for a specific level and generator version.
  /// 
  /// Formula: seed = Hash(version + ":" + levelIndex)
  static int deriveSeed(String version, int levelIndex) {
    final input = "$version$_separator$levelIndex";
    return DeterministicHash.hash(input);
  }

  /// Derives a full LevelRecipe for a given index and version.
  static LevelRecipe deriveRecipe(String version, int levelIndex) {
    final seed = deriveSeed(version, levelIndex);
    final family = _selector.selectFamily(version, levelIndex);
    
    return LevelRecipe(
      levelIndex: levelIndex, 
      templateId: family.name, // We use family name as ID for now (v0 assumed)
      seed: seed, 
      generatorVersion: version,
    );
  }
}
