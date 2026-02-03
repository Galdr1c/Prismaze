/// Cardinal directions for the game grid.
enum Direction {
  north(0, -1),
  east(1, 0),
  south(0, 1),
  west(-1, 0);

  final int dx;
  final int dy;

  const Direction(this.dx, this.dy);

  /// Rotates 90 degrees clockwise (Right)
  Direction get rotateRight {
    switch (this) {
      case Direction.north: return Direction.east;
      case Direction.east: return Direction.south;
      case Direction.south: return Direction.west;
      case Direction.west: return Direction.north;
    }
  }

  /// Rotates 90 degrees counter-clockwise (Left)
  Direction get rotateLeft {
    switch (this) {
      case Direction.north: return Direction.west;
      case Direction.east: return Direction.north;
      case Direction.south: return Direction.east;
      case Direction.west: return Direction.south;
    }
  }

  /// Returns the opposite direction
  Direction get opposite {
    switch (this) {
      case Direction.north: return Direction.south;
      case Direction.east: return Direction.west;
      case Direction.south: return Direction.north;
      case Direction.west: return Direction.east;
    }
  }

  /// Returns a Direction from an integer index (0=North, 1=East, 2=South, 3=West)
  static Direction fromInt(int value) {
    return Direction.values[value % 4];
  }

  /// Returns the integer index of this direction
  int get toInt => index;
}
