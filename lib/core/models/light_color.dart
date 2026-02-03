import 'dart:ui';

/// Represents light colors using additive mixing (RGB).
enum LightColor {
  none(0),
  red(1),
  green(2),
  blue(4),
  yellow(3), // red | green
  purple(5), // red | blue
  cyan(6),   // green | blue
  white(7);  // red | green | blue

  final int mask;

  const LightColor(this.mask);

  /// Mixes this color with another color using bitwise OR.
  LightColor mix(LightColor other) {
    return LightColor.fromMask(mask | other.mask);
  }

  /// Returns true if this color contains all components of the other color.
  bool contains(LightColor other) {
    return (mask & other.mask) == other.mask;
  }
  
  /// Returns a LightColor from a bitmask.
  static LightColor fromMask(int mask) {
    for (var color in LightColor.values) {
      if (color.mask == mask) return color;
    }
    return LightColor.none;
  }
  
  /// Returns a valid flutter Color (Standard material mapping for visualization)
  /// Note: This is a placeholder for model logic, UI color should be in theme.
  // Color get toUiColor => ... (omitted to keep model pure dart)
  
  // Helpers
  int get requiredMask => mask;
  bool get isMixed => mask != 1 && mask != 2 && mask != 4;
  
  static const LightColor orange = yellow; // Map orange to yellow for this simple model
}

/// Helper for bitmask operations
class ColorMask {
  static const int none = 0;
  static const int red = 1;
  static const int green = 2;
  static const int yellow = 3;
  static const int blue = 4;
  static const int purple = 5;
  static const int cyan = 6;
  static const int white = 7;
  
  static int fromColors(Set<LightColor> colors) {
    int mask = 0;
    for (var c in colors) {
      mask |= c.mask;
    }
    return mask;
  }
  
  static bool satisfies(int currentMask, int requiredMask) {
    if (requiredMask == 0) return true;
    return currentMask == requiredMask;
  }
}

// Extension to bridge Model -> Flutter Color
extension LightColorExtension on LightColor {
  static LightColor fromFlutterColor(Color color) {
     if (color.value == const Color(0xFFFF4444).value) return LightColor.red;
     if (color.value == const Color(0xFF4488FF).value) return LightColor.blue;
     if (color.value == const Color(0xFF44FF44).value) return LightColor.green;
     if (color.value == const Color(0xFFFFFF00).value) return LightColor.yellow;
     if (color.value == const Color(0xFFFF00FF).value) return LightColor.purple;
     if (color.value == const Color(0xFF00FFFF).value) return LightColor.cyan;
     if (color.value == const Color(0xFFFFFFFF).value) return LightColor.white;
     return LightColor.none;
  }
  
  Color toFlutterColor() {
    switch (this) {
      case LightColor.red: return const Color(0xFFFF4444);
      case LightColor.green: return const Color(0xFF44FF44);
      case LightColor.blue: return const Color(0xFF4488FF);
      case LightColor.yellow: return const Color(0xFFFFFF00);
      case LightColor.purple: return const Color(0xFFFF00FF);
      case LightColor.cyan: return const Color(0xFF00FFFF);
      case LightColor.white: return const Color(0xFFFFFFFF);
      default: return const Color(0x00000000);
    }
  }
}
