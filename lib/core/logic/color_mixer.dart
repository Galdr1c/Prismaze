import '../models/light_color.dart';

/// Stateless logic for color mixing and validation.
class ColorMixer {
  
  /// Mixes two colors using bitwise additive logic.
  /// 
  /// Example: Red(1) + Blue(4) = Purple(5).
  static LightColor mix(LightColor a, LightColor b) {
    return a.mix(b);
  }

  /// Checks if the [current] color satisfies the [required] color.
  /// 
  /// For now, this is a strict equality check (all components match).
  /// If [required] is None, it's always satisfied.
  static bool satisfies(LightColor current, LightColor required) {
    if (required == LightColor.none) return true;
    return current.mask == required.mask;
  }
}
