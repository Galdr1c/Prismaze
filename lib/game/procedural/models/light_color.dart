/// LightColor enum for deterministic color system.
///
/// Colors are discrete enums, not RGB values.
/// Mixing rules are strictly defined for puzzle determinism.
library;

import 'package:flutter/material.dart';

/// Light colors available in the game.
enum LightColor {
  white,  // Default source color, can be split by prisms
  red,    // Base color
  blue,   // Base color
  yellow, // Base color
  purple, // Mixed: Red + Blue
  orange, // Mixed: Red + Yellow
  green,  // Mixed: Blue + Yellow
}

/// Extension methods for LightColor operations.
extension LightColorExtension on LightColor {
  /// Check if this is a base color (can be combined).
  bool get isBase {
    return this == LightColor.red ||
        this == LightColor.blue ||
        this == LightColor.yellow;
  }

  /// Check if this is a mixed color.
  bool get isMixed {
    return this == LightColor.purple ||
        this == LightColor.orange ||
        this == LightColor.green;
  }

  /// Get the base color components of this color.
  /// Returns a set of base colors that make up this color.
  Set<LightColor> get baseComponents {
    switch (this) {
      case LightColor.white:
        return {}; // White is special, not made of bases
      case LightColor.red:
        return {LightColor.red};
      case LightColor.blue:
        return {LightColor.blue};
      case LightColor.yellow:
        return {LightColor.yellow};
      case LightColor.purple:
        return {LightColor.red, LightColor.blue};
      case LightColor.orange:
        return {LightColor.red, LightColor.yellow};
      case LightColor.green:
        return {LightColor.blue, LightColor.yellow};
    }
  }

  /// Get the Flutter Color for rendering.
  Color get renderColor {
    switch (this) {
      case LightColor.white:
        return const Color(0xFFFFFFFF);
      case LightColor.red:
        return const Color(0xFFFF4444);
      case LightColor.blue:
        return const Color(0xFF4488FF);
      case LightColor.yellow:
        return const Color(0xFFFFDD44);
      case LightColor.purple:
        return const Color(0xFFAA44FF);
      case LightColor.orange:
        return const Color(0xFFFF8844);
      case LightColor.green:
        return const Color(0xFF44DD44);
    }
  }

  /// Convert to string for JSON serialization.
  String toJsonString() => name;

  /// Parse from JSON string.
  static LightColor fromJsonString(String s) {
    switch (s.toLowerCase()) {
      case 'white':
        return LightColor.white;
      case 'red':
        return LightColor.red;
      case 'blue':
        return LightColor.blue;
      case 'yellow':
        return LightColor.yellow;
      case 'purple':
        return LightColor.purple;
      case 'orange':
        return LightColor.orange;
      case 'green':
        return LightColor.green;
      default:
        throw ArgumentError('Invalid light color string: $s');
    }
  }

  /// Convert Flutter Color to LightColor based on approximate values
  static LightColor fromFlutterColor(Color c) {
    // Exact matches first (from LightColorExtension.renderColor)
    if (c.red > 200 && c.green > 200 && c.blue > 200) return LightColor.white;
    if (c.red > 200 && c.green < 100 && c.blue < 100) return LightColor.red;
    if (c.blue > 200 && c.red < 150 && c.green < 200) return LightColor.blue;
    if (c.red > 200 && c.green > 200 && c.blue < 100) return LightColor.yellow;
    
    // Mixed Colors
    if (c.red > 150 && c.blue > 150 && c.green < 150) return LightColor.purple;
    if (c.red > 200 && c.green > 100 && c.green < 200 && c.blue < 100) return LightColor.orange;
    if (c.green > 200 && c.red < 150 && c.blue < 150) return LightColor.green;
    
    return LightColor.white; // Fallback
  }

  /// Bitmask for this color's base components.
  /// R=1 (bit 0), B=2 (bit 1), Y=4 (bit 2)
  int get componentMask {
    switch (this) {
      case LightColor.white:
        return 0; // White has no base components
      case LightColor.red:
        return ColorMask.red;
      case LightColor.blue:
        return ColorMask.blue;
      case LightColor.yellow:
        return ColorMask.yellow;
      case LightColor.purple:
        return ColorMask.red | ColorMask.blue; // 3
      case LightColor.orange:
        return ColorMask.red | ColorMask.yellow; // 5
      case LightColor.green:
        return ColorMask.blue | ColorMask.yellow; // 6
    }
  }

  /// Get required mask for this target color.
  /// For white, returns special value 8 (bit 3).
  int get requiredMask {
    if (this == LightColor.white) {
      return ColorMask.white;
    }
    return componentMask;
  }
}

/// Bitmask constants for color components.
class ColorMask {
  static const int red = 1;    // Bit 0
  static const int blue = 2;   // Bit 1
  static const int yellow = 4; // Bit 2
  static const int white = 8;  // Bit 3 (special for white targets)

  /// Convert a set of arriving colors to a component mask.
  static int fromColors(Set<LightColor> colors) {
    int mask = 0;
    for (final color in colors) {
      if (color == LightColor.white) {
        mask |= white;
      } else {
        // Use componentMask directly (handles both base and mixed colors)
        mask |= color.componentMask;
      }
    }
    return mask;
  }

  /// Check if collected mask satisfies required mask.
  static bool satisfies(int collected, int required) {
    return (collected & required) == required;
  }

  /// Get display string for a mask.
  static String display(int mask) {
    final parts = <String>[];
    if (mask & red != 0) parts.add('R');
    if (mask & blue != 0) parts.add('B');
    if (mask & yellow != 0) parts.add('Y');
    if (mask & white != 0) parts.add('W');
    return parts.isEmpty ? '-' : parts.join('+');
  }
}

/// Color mixing utility class.
///
/// Uses "Target-cell accumulation" mixing:
/// - Track which base colors arrive at a target cell
/// - Check if the required bases are present for the target's required color
class ColorMixer {
  /// Mix a set of arriving base colors into a result.
  ///
  /// Rules:
  /// - Empty set → no color (target not satisfied)
  /// - Single base → that base color
  /// - Two bases → mixed color (if valid combination)
  /// - Three or more bases → invalid (target not satisfied)
  /// - White arriving is tracked separately
  static LightColor? mixBases(Set<LightColor> bases) {
    // Expand mixed colors into their components
    final baseColors = bases.expand((c) => c.baseComponents).toSet();

    if (baseColors.isEmpty) {
      // Check if white was passed through
      if (bases.contains(LightColor.white)) {
        return LightColor.white;
      }
      return null;
    }

    if (baseColors.length == 1) {
      return baseColors.first;
    }

    if (baseColors.length == 2) {
      if (baseColors.contains(LightColor.red) &&
          baseColors.contains(LightColor.blue)) {
        return LightColor.purple;
      }
      if (baseColors.contains(LightColor.red) &&
          baseColors.contains(LightColor.yellow)) {
        return LightColor.orange;
      }
      if (baseColors.contains(LightColor.blue) &&
          baseColors.contains(LightColor.yellow)) {
        return LightColor.green;
      }
    }

    // More than 2 bases or invalid combination
    return null;
  }

  /// Check if arriving colors satisfy a target's required color.
  ///
  /// Rules:
  /// - White target: satisfied only by white arriving
  /// - Base target: satisfied if that base color arrives
  /// - Mixed target: satisfied only if exactly those two bases arrive
  static bool satisfiesTarget(
    Set<LightColor> arrivingColors,
    LightColor required,
  ) {
    // White is special: only satisfied by white
    if (required == LightColor.white) {
      return arrivingColors.contains(LightColor.white);
    }

    // For base and mixed colors, check base components
    final requiredBases = required.baseComponents;
    
    // Expand arriving mixed colors (e.g. Purple -> Red, Blue)
    final arrivingBases = arrivingColors.expand((c) => c.baseComponents).toSet();
    
    // Must have exactly the required bases
    return arrivingBases.length == requiredBases.length &&
        arrivingBases.containsAll(requiredBases);
  }
}

