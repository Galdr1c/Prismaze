/// A Linear Congruential Generator (LCG) for deterministic, cross-platform random number generation.
///
/// Constants used (from Numerical Recipes):
/// m = 2^31 (2147483648)
/// a = 1103515245
/// c = 12345
class DeterministicRNG {
  // LCG Constants
  static const int _m = 2147483648; // 2^31
  static const int _a = 1103515245;
  static const int _c = 12345;

  int _currentSeed;
  final int initialSeed;

  DeterministicRNG(this.initialSeed) : _currentSeed = initialSeed;

  /// Returns the current internal seed state.
  int get state => _currentSeed;

  /// Resets the RNG to its initial seed.
  void reset() {
    _currentSeed = initialSeed;
  }

  /// Generates the next random integer.
  int _next() {
    _currentSeed = (_a * _currentSeed + _c) % _m;
    return _currentSeed;
  }

  /// Generates a random integer from 0 (inclusive) to max (exclusive).
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError("max must be positive");
    return _next().abs() % max;
  }

  /// Generates a random boolean.
  bool nextBool() {
    return _next() % 2 == 0;
  }

  /// Generates a random double in range [0.0, 1.0).
  double nextDouble() {
    return _next().abs() / _m;
  }
  
  /// Returns a random element from the list.
  T item<T>(List<T> items) {
    if (items.isEmpty) throw ArgumentError("List cannot be empty");
    return items[nextInt(items.length)];
  }
}
