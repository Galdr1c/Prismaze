/// Grid Occupancy Manager
///
/// Enforces the invariant: each cell can contain at most ONE occupying object
/// (Wall, Target, Mirror, Prism, or Source).
library;

import 'models/models.dart';

/// Types of objects that occupy a cell.
enum OccupantType {
  source,
  target,
  mirror,
  prism,
  wall,
}

/// Result of occupancy validation.
class OccupancyValidationResult {
  final bool valid;
  final List<String> collisions;

  const OccupancyValidationResult({
    required this.valid,
    this.collisions = const [],
  });

  @override
  String toString() => valid
      ? 'OccupancyValidationResult(valid)'
      : 'OccupancyValidationResult(invalid: ${collisions.join(", ")})';
}

/// Tracks occupied cells and prevents collisions during level generation.
class OccupancyGrid {
  /// Map of cell key -> occupant type
  final Map<int, OccupantType> _occupied = {};

  /// Grid dimensions
  static const int gridWidth = 14;
  static const int gridHeight = 7;

  /// Generate a unique key for a position (x < 32, y < 32).
  /// x: 0-13 (4 bits), y: 0-6 (3 bits)
  static int _key(GridPosition pos) {
    // assert(pos.x >= 0 && pos.x < 32, 'X out of range');
    // assert(pos.y >= 0 && pos.y < 32, 'Y out of range');
    return (pos.x << 5) | pos.y;
  }
  
  static GridPosition _fromKey(int key) {
    return GridPosition(key >> 5, key & 0x1F);
  }

  /// Check if a cell is occupied.
  bool isOccupied(GridPosition pos) => _occupied.containsKey(_key(pos));

  /// Get the occupant type at a position.
  OccupantType? getOccupant(GridPosition pos) => _occupied[_key(pos)];

  /// Attempt to place an object. Returns false if cell is already occupied.
  bool tryPlace(GridPosition pos, OccupantType type) {
    final key = _key(pos);
    if (_occupied.containsKey(key)) {
      return false;
    }
    _occupied[key] = type;
    return true;
  }

  /// Reserve a cell (used during generation when we know it's safe).
  /// Throws assertion error in debug mode if cell is already occupied.
  void reserve(GridPosition pos, OccupantType type) {
    final key = _key(pos);
    assert(!_occupied.containsKey(key),
        'OccupancyGrid: Attempted to reserve occupied cell $pos (existing: ${_occupied[key]}, new: $type)');
    _occupied[key] = type;
  }

  /// Remove an occupant from a cell.
  void remove(GridPosition pos) {
    _occupied.remove(_key(pos));
  }

  /// Clear all occupants.
  void clear() {
    _occupied.clear();
  }

  /// Get all occupied positions.
  Set<GridPosition> getOccupiedPositions() {
    return _occupied.keys.map(_fromKey).toSet();
  }

  /// Validate a GeneratedLevel has no cell collisions.
  ///
  /// Checks that no two objects occupy the same cell.
  static OccupancyValidationResult validateLevel(GeneratedLevel level) {
    final grid = OccupancyGrid();
    final collisions = <String>[];

    // Check source
    final sourceKey = _key(level.source.position);
    if (!grid.tryPlace(level.source.position, OccupantType.source)) {
      collisions.add('Source at ${level.source.position} collides with ${grid.getOccupant(level.source.position)}');
    }

    // Check targets
    for (int i = 0; i < level.targets.length; i++) {
      final target = level.targets[i];
      if (!grid.tryPlace(target.position, OccupantType.target)) {
        collisions.add('Target[$i] at ${target.position} collides with ${grid.getOccupant(target.position)}');
      }
    }

    // Check mirrors
    for (int i = 0; i < level.mirrors.length; i++) {
      final mirror = level.mirrors[i];
      if (!grid.tryPlace(mirror.position, OccupantType.mirror)) {
        collisions.add('Mirror[$i] at ${mirror.position} collides with ${grid.getOccupant(mirror.position)}');
      }
    }

    // Check prisms
    for (int i = 0; i < level.prisms.length; i++) {
      final prism = level.prisms[i];
      if (!grid.tryPlace(prism.position, OccupantType.prism)) {
        collisions.add('Prism[$i] at ${prism.position} collides with ${grid.getOccupant(prism.position)}');
      }
    }

    // Check walls (each wall occupies a single cell)
    for (final wall in level.walls) {
      if (!grid.tryPlace(wall.position, OccupantType.wall)) {
        collisions.add('Wall at ${wall.position} collides with ${grid.getOccupant(wall.position)}');
      }
    }

    return OccupancyValidationResult(
      valid: collisions.isEmpty,
      collisions: collisions,
    );
  }

  /// Validate that no collisions exist, throwing an assertion error if invalid.
  /// Use this during level generation in debug builds.
  static void assertValidLevel(GeneratedLevel level) {
    final result = validateLevel(level);
    assert(result.valid, 'OccupancyGrid validation failed: ${result.collisions.join(", ")}');
  }
}
