/// Direction enum for discrete 4-direction ray system.
///
/// This is the fundamental building block for deterministic ray tracing.
/// All directions are discrete - no continuous angles allowed.
library;

import 'dart:math';

/// The four cardinal directions for ray propagation.
enum Direction {
  east,  // →  (positive X)
  north, // ↑  (negative Y, screen coordinates)
  west,  // ←  (negative X)
  south, // ↓  (positive Y, screen coordinates)
}

/// Extension methods for Direction operations.
extension DirectionExtension on Direction {
  /// Get the opposite direction.
  Direction get opposite {
    switch (this) {
      case Direction.east:
        return Direction.west;
      case Direction.north:
        return Direction.south;
      case Direction.west:
        return Direction.east;
      case Direction.south:
        return Direction.north;
    }
  }

  /// Rotate 90° counter-clockwise.
  Direction get rotateLeft {
    switch (this) {
      case Direction.east:
        return Direction.north;
      case Direction.north:
        return Direction.west;
      case Direction.west:
        return Direction.south;
      case Direction.south:
        return Direction.east;
    }
  }

  /// Rotate 90° clockwise.
  Direction get rotateRight {
    switch (this) {
      case Direction.east:
        return Direction.south;
      case Direction.north:
        return Direction.east;
      case Direction.west:
        return Direction.north;
      case Direction.south:
        return Direction.west;
    }
  }

  /// Get the delta X for stepping in this direction.
  int get dx {
    switch (this) {
      case Direction.east:
        return 1;
      case Direction.west:
        return -1;
      case Direction.north:
      case Direction.south:
        return 0;
    }
  }

  /// Get the delta Y for stepping in this direction.
  int get dy {
    switch (this) {
      case Direction.south:
        return 1;
      case Direction.north:
        return -1;
      case Direction.east:
      case Direction.west:
        return 0;
    }
  }

  /// Get the direction index (0-3) for table lookups.
  int get index {
    switch (this) {
      case Direction.east:
        return 0;
      case Direction.north:
        return 1;
      case Direction.west:
        return 2;
      case Direction.south:
        return 3;
    }
  }

  /// Get direction from index (0-3).
  static Direction fromIndex(int index) {
    switch (index % 4) {
      case 0:
        return Direction.east;
      case 1:
        return Direction.north;
      case 2:
        return Direction.west;
      case 3:
        return Direction.south;
      default:
        return Direction.east;
    }
  }

  /// Get the angle in radians for rendering purposes.
  double get angleRad {
    switch (this) {
      case Direction.east:
        return 0;
      case Direction.south:
        return pi / 2;
      case Direction.west:
        return pi;
      case Direction.north:
        return -pi / 2;
    }
  }

  /// Get direction pointing inward from an edge position.
  static Direction inwardFromEdge(int x, int y, int gridWidth, int gridHeight) {
    if (x == 0) return Direction.east;
    if (x == gridWidth - 1) return Direction.west;
    if (y == 0) return Direction.south;
    if (y == gridHeight - 1) return Direction.north;
    return Direction.east; // Default for non-edge positions
  }

  /// Convert to string for JSON serialization.
  String toJsonString() => name;

  /// Parse from JSON string.
  static Direction fromJsonString(String s) {
    switch (s.toLowerCase()) {
      case 'east':
        return Direction.east;
      case 'north':
        return Direction.north;
      case 'west':
        return Direction.west;
      case 'south':
        return Direction.south;
      default:
        throw ArgumentError('Invalid direction string: $s');
    }
  }
}

