/// Prism behavior lookup tables.
///
/// Deterministic tables for discrete prism effects.
/// Handles both splitter and deflector prism types.
library;

import '../models/direction.dart';
import '../models/game_objects.dart';
import '../models/light_color.dart';

/// Result of a ray passing through a prism.
class PrismOutput {
  final Direction direction;
  final LightColor color;

  const PrismOutput(this.direction, this.color);

  @override
  String toString() => 'PrismOutput($direction, $color)';
}

/// Apply splitter prism behavior.
///
/// Splitter prism rules:
/// - White light → splits into 3 rays: Red, Blue, Yellow
///   - Directions: straight, left, right based on orientation
/// - Non-white light → passes through unchanged
///
/// Returns list of output rays (1 for non-white, 3 for white).
List<PrismOutput> applySplitter(
  Direction incoming,
  LightColor color,
  int prismOrientation,
) {
  // Non-white: pass through unchanged
  // Non-white: pass through unchanged (Straight)
  if (color != LightColor.white) {
    return [PrismOutput(incoming, color)];
  }

  // White: split into RGB
  // Orientation determines the spread pattern
  final baseDir = incoming;
  final leftDir = incoming.rotateLeft;
  final rightDir = incoming.rotateRight;

  // Apply orientation rotation to the spread
  Direction red, blue, yellow;
  switch (prismOrientation) {
    case 0:
      red = leftDir;
      blue = baseDir;
      yellow = rightDir;
      break;
    case 1:
      red = baseDir;
      blue = rightDir;
      yellow = leftDir;
      break;
    case 2:
      red = rightDir;
      blue = leftDir;
      yellow = baseDir;
      break;
    case 3:
      red = leftDir;
      blue = rightDir;
      yellow = baseDir;
      break;
    default:
      red = leftDir;
      blue = baseDir;
      yellow = rightDir;
  }

  return [
    PrismOutput(red, LightColor.red),
    PrismOutput(blue, LightColor.blue),
    PrismOutput(yellow, LightColor.yellow),
  ];
}

/// Apply deflector prism behavior.
///
/// Deflector prism rules:
/// - Any color → direction rotates by ±1 step based on orientation
/// - Color is preserved
///
/// Orientation 0,2: rotate left (counter-clockwise)
/// Orientation 1,3: rotate right (clockwise)
List<PrismOutput> applyDeflector(
  Direction incoming,
  LightColor color,
  int prismOrientation,
) {
  Direction outDir;
  
  switch (prismOrientation % 4) {
    case 0:
      outDir = incoming.rotateLeft;
      break;
    case 1:
      outDir = incoming.rotateRight;
      break;
    case 2:
      outDir = incoming.rotateLeft;
      break;
    case 3:
      outDir = incoming.rotateRight;
      break;
    default:
      outDir = incoming;
  }

  return [PrismOutput(outDir, color)];
}

/// Apply prism behavior based on type.
List<PrismOutput> applyPrism(
  Direction incoming,
  LightColor color,
  int prismOrientation,
  PrismType prismType,
) {
  switch (prismType) {
    case PrismType.splitter:
      return applySplitter(incoming, color, prismOrientation);
    case PrismType.deflector:
      return applyDeflector(incoming, color, prismOrientation);
  }
}

/// Helper for splitter non-white deflection.
Direction _deflectForSplitter(Direction incoming, int orientation) {
  // Simple pass-through with slight deflection based on orientation
  switch (orientation % 4) {
    case 0:
      return incoming;
    case 1:
      return incoming.rotateRight;
    case 2:
      return incoming;
    case 3:
      return incoming.rotateLeft;
    default:
      return incoming;
  }
}

/// Prism behavior documentation.
class PrismTableDoc {
  static const String documentation = '''
Prism Behavior Tables

SPLITTER PRISM (White → RGB split):
- White light entering splits into 3 rays: Red, Blue, Yellow
- Each ray exits in a different direction based on prism orientation
- Non-white light passes through with slight deflection

Orientation effects on split:
  Ori 0: Left=Red, Straight=Blue, Right=Yellow
  Ori 1: Straight=Red, Right=Blue, Left=Yellow
  Ori 2: Right=Red, Left=Blue, Straight=Yellow
  Ori 3: Left=Red, Right=Blue, Straight=Yellow

DEFLECTOR PRISM (Direction change, color preserved):
- Rotates ray direction by 90° based on orientation
- Color is unchanged

Orientation effects:
  Ori 0: Rotate left (counter-clockwise)
  Ori 1: Rotate right (clockwise)
  Ori 2: Rotate left (counter-clockwise)
  Ori 3: Rotate right (clockwise)
''';
}

/// Maximum number of output rays from a single prism interaction.
const int maxPrismOutputRays = 3;

