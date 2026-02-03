import '../core/utils/deterministic_hash.dart';

/// Static utility to derive deterministic seeds for levels.
/// Implements the "Law of the Seed":
/// Version + LevelIndex = Unique Deterministic Seed
class RecipeDeriver {
  RecipeDeriver._();

  static const String _separator = ":";

  /// Derives the unique seed for a specific level and generator version.
  /// 
  /// Formula: SHA256("$version:$levelIndex") -> int
  static int deriveSeed(String version, int levelIndex) {
    if (levelIndex < 1) {
       // Ideally throw, but soft fail to valid seed for now or handle as error upstream
       // Ensuring index is part of hash
    }
    final input = "$version$_separator$levelIndex";
    return DeterministicHash.hash(input);
  }
}
