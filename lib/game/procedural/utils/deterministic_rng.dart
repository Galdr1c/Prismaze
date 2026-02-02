/// Deterministic RNG and Seed Mixing utilities for Prismaze V4.
///
/// Ensures cross-platform byte-for-byte consistency using a standard LCG algorithm
/// instead of platform-dependent Random implementation.
library;

/// A Linear Congruential Generator (LCG) for deterministic random number generation.
/// Uses parameters: m = 2^31-1, a = 48271 (minstd_rand).
class DeterministicRNG {
  static const int _a = 48271;
  static const int _m = 2147483647; // 2^31 - 1

  int _seed;

  DeterministicRNG(int seed) : _seed = (seed == 0) ? 1 : seed;

  /// Returns a random integer in range [0, max).
  int nextInt(int max) {
    _seed = (_a * _seed) % _m;
    return _seed % max;
  }

  /// Returns a random integer without a max limit (raw LCG value).
  int next() {
    _seed = (_a * _seed) % _m;
    return _seed;
  }

  /// Returns a random double in range [0.0, 1.0).
  double nextDouble() {
    return nextInt(1000000) / 1000000.0;
  }

  /// Returns a random boolean.
  bool nextBool() {
    return nextInt(2) == 0;
  }
  
  /// Shuffles a list deterministically.
  List<T> shuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }
}

/// Robust seed mixing function (Avalanche effect).
/// Combines multiple inputs into a single high-entropy seed.
int mixSeed(int baseSeed, int episode, int levelIndex, [int salt = 0]) {
  int x = baseSeed ^ (episode * 0x9E3779B9) ^ (levelIndex * 0x85EBCA6B) ^ (salt * 0xC2B2AE35);
  x ^= (x >> 16);
  x *= 0x7feb352d;
  x ^= (x >> 15);
  x *= 0x846ca68b;
  x ^= (x >> 16);
  return x & 0x7fffffff;
}
