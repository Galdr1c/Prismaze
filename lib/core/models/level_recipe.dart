import 'package:flutter/foundation.dart';

/// Represents the deterministic blueprint for a generated level.
/// This object contains everything needed to reconstruct a level exactly.
@immutable
class LevelRecipe {
  final int levelIndex;
  final String generatorVersion;
  final int seed;
  final String templateId;

  const LevelRecipe({
    required this.levelIndex,
    required this.generatorVersion,
    required this.seed,
    required this.templateId,
  });

  Map<String, dynamic> toJson() {
    return {
      'levelIndex': levelIndex,
      'generatorVersion': generatorVersion,
      'seed': seed,
      'templateId': templateId,
    };
  }

  factory LevelRecipe.fromJson(Map<String, dynamic> json) {
    return LevelRecipe(
      levelIndex: json['levelIndex'] as int,
      generatorVersion: json['generatorVersion'] as String,
      seed: json['seed'] as int,
      templateId: json['templateId'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelRecipe &&
        other.levelIndex == levelIndex &&
        other.generatorVersion == generatorVersion &&
        other.seed == seed &&
        other.templateId == templateId;
  }

  @override
  int get hashCode => Object.hash(levelIndex, generatorVersion, seed, templateId);

  @override
  String toString() {
    return 'LevelRecipe(idx: $levelIndex, ver: $generatorVersion, seed: $seed, tpl: $templateId)';
  }
}
