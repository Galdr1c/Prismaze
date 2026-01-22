/// Mirror reflection lookup tables.
///
/// Deterministic tables for discrete 4-state mirror reflection.
/// No floating-point math - pure table lookup.
library;

import '../models/direction.dart';
import '../models/game_objects.dart';

/// Mirror reflection lookup table.
///
/// MIRROR_REFLECT[incomingDirection.index][mirrorOrientation.index] = outgoing Direction
///
/// Mirror orientations:
/// - 0: "_" horizontal - reflects north↔south, east/west pass through
/// - 1: "/" slash - reflects east↔north, west↔south
/// - 2: "|" vertical - reflects east↔west, north/south pass through
/// - 3: "\" backslash - reflects east↔south, west↔north
///
/// null means the ray passes through (hits mirror edge, not reflective surface)
const List<List<Direction?>> _mirrorReflectTable = [
  // Mirror orientation:  0(_)              1(/)              2(|)              3(\)
  /* east (0) →  */ [null,             Direction.north,  Direction.west,   Direction.south],
  /* north (1) → */ [Direction.south,  Direction.east,   null,             Direction.west],
  /* west (2) →  */ [null,             Direction.south,  Direction.east,   Direction.north],
  /* south (3) → */ [Direction.north,  Direction.west,   null,             Direction.east],
];

/// Get the reflected direction when a ray hits a mirror.
///
/// Returns null if the ray passes through (doesn't hit reflective surface).
///
/// Example:
/// ```dart
/// final outDir = reflectRay(Direction.east, MirrorOrientation.slash);
/// // outDir == Direction.north (east hitting "/" reflects to north)
/// ```
Direction? reflectRay(Direction incoming, MirrorOrientation mirrorOrientation) {
  return _mirrorReflectTable[incoming.index][mirrorOrientation.index];
}

/// Check if a ray would be reflected by a mirror.
bool wouldReflect(Direction incoming, MirrorOrientation mirrorOrientation) {
  return _mirrorReflectTable[incoming.index][mirrorOrientation.index] != null;
}

/// Get all reflection cases for a mirror orientation.
///
/// Returns a map of incoming → outgoing directions for all reflecting cases.
Map<Direction, Direction> getReflectionCases(MirrorOrientation mirrorOrientation) {
  final cases = <Direction, Direction>{};
  for (final dir in Direction.values) {
    final reflected = reflectRay(dir, mirrorOrientation);
    if (reflected != null) {
      cases[dir] = reflected;
    }
  }
  return cases;
}

/// Visual representation of mirror orientations for debugging.
const Map<MirrorOrientation, String> mirrorSymbols = {
  MirrorOrientation.horizontal: '_',
  MirrorOrientation.slash: '/',
  MirrorOrientation.vertical: '|',
  MirrorOrientation.backslash: '\\',
};

/// Get the visual symbol for a mirror orientation.
String getMirrorSymbol(MirrorOrientation orientation) {
  return mirrorSymbols[orientation] ?? '?';
}

/// Reflection table documentation.
///
/// This table encodes the physics of ideal flat mirrors at discrete angles:
///
/// ```
/// Horizontal (_):
///   North → South (reflect down)
///   South → North (reflect up)
///   East/West → pass through
///
/// Slash (/):
///   East → North (reflect up-right)
///   North → East (reflect right-up)
///   West → South (reflect down-left)
///   South → West (reflect left-down)
///
/// Vertical (|):
///   East → West (reflect left)
///   West → East (reflect right)
///   North/South → pass through
///
/// Backslash (\):
///   East → South (reflect down-right)
///   South → East (reflect right-down)
///   West → North (reflect up-left)
///   North → West (reflect left-up)
/// ```
///
/// The table is symmetric in that if A reflects to B, then B reflects to A
/// for the same mirror orientation.
class ReflectionTableDoc {
  static const String documentation = '''
Mirror Reflection Table (4-direction × 4-orientation)

Incoming    Horizontal(_)  Slash(/)   Vertical(|)  Backslash(\\)
---------   ------------   --------   -----------  -------------
East  →     pass           North      West         South
North →     South          East       pass         West
West  →     pass           South      East         North
South →     North          West       pass         East

Legend:
- "pass" means ray continues without reflection
- Each cell shows the outgoing direction after reflection
''';
}

