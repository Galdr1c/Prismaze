import '../../core/models/models.dart';

/// Represents the deterministic "recipe" for a level.
/// This data is enough to recreate the exact same [GeneratedLevel] 
/// across any device or platform.
class LevelRecipe {
  final int levelIndex;
  final String templateId; // family_variantId
  final int seed;
  final String generatorVersion;

  const LevelRecipe({
    required this.levelIndex,
    required this.templateId,
    required this.seed,
    required this.generatorVersion,
  });

  Map<String, dynamic> toJson() => {
    'levelIndex': levelIndex,
    'templateId': templateId,
    'seed': seed,
    'generatorVersion': generatorVersion,
  };

  factory LevelRecipe.fromJson(Map<String, dynamic> json) => LevelRecipe(
    levelIndex: json['levelIndex'] as int,
    templateId: json['templateId'] as String,
    seed: json['seed'] as int,
    generatorVersion: json['generatorVersion'] as String,
  );

  @override
  String toString() => 'LevelRecipe(index: $levelIndex, template: $templateId, seed: $seed, v: $generatorVersion)';
}
