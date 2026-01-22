/// Placement Engine
/// Handles valid placement of all game objects

import 'dart:math';
import 'procedural_level.dart';

class PlacementEngine {
  final Random _rng;
  
  /// Grid constants
  static const int gridWidth = 22;
  static const int gridHeight = 9;
  
  PlacementEngine([int? seed]) : _rng = Random(seed);
  
  /// Generate a random seed for reproducible levels
  static int generateSeed(int chapter, int levelNumber) {
    return chapter * 1000 + levelNumber;
  }
  
  /// Place light source on edge of play area
  /// Returns position and direction pointing inward
  LightSourceDef placeLightSource({String color = 'white'}) {
    // Choose random edge (0=top, 1=right, 2=bottom, 3=left)
    final edge = _rng.nextInt(4);
    
    GridPos pos;
    LightDirection direction;
    
    switch (edge) {
      case 0: // Top edge
        pos = GridPos(_rng.nextInt(gridWidth - 2) + 1, 0);
        direction = LightDirection.south;
        break;
      case 1: // Right edge
        pos = GridPos(gridWidth - 1, _rng.nextInt(gridHeight - 2) + 1);
        direction = LightDirection.west;
        break;
      case 2: // Bottom edge
        pos = GridPos(_rng.nextInt(gridWidth - 2) + 1, gridHeight - 1);
        direction = LightDirection.north;
        break;
      case 3: // Left edge
      default:
        pos = GridPos(0, _rng.nextInt(gridHeight - 2) + 1);
        direction = LightDirection.east;
        break;
    }
    
    return LightSourceDef(position: pos, direction: direction, color: color);
  }
  
  /// Place targets avoiding walls and other objects
  List<TargetDef> placeTargets({
    required int count,
    required List<WallDef> walls,
    required LightSourceDef lightSource,
    required List<GridPos> occupied,
    String color = 'white',
  }) {
    final targets = <TargetDef>[];
    final usedPositions = Set<GridPos>.from(occupied);
    usedPositions.add(lightSource.position);
    
    // Add wall-blocked cells to occupied
    for (final wall in walls) {
      _addWallCells(wall, usedPositions);
    }
    
    int attempts = 0;
    while (targets.length < count && attempts < 200) {
      attempts++;
      
      // Generate position away from edges (min 2 cells from edge)
      final x = _rng.nextInt(gridWidth - 4) + 2;
      final y = _rng.nextInt(gridHeight - 4) + 2;
      final pos = GridPos(x, y);
      
      // Check if position is valid
      if (usedPositions.contains(pos)) continue;
      if (!_hasWallClearance(pos, walls, 1)) continue;
      
      // Ensure target is reachable (not completely blocked by walls)
      if (_isIsolated(pos, walls)) continue;
      
      targets.add(TargetDef(position: pos, requiredColor: color));
      usedPositions.add(pos);
      
      // Add buffer zone around target
      _addBufferZone(pos, usedPositions, 1);
    }
    
    return targets;
  }
  
  /// Place mirrors in valid positions
  List<MirrorDef> placeMirrors({
    required int count,
    required List<WallDef> walls,
    required List<GridPos> occupied,
    bool someFixed = false,
  }) {
    final mirrors = <MirrorDef>[];
    final usedPositions = Set<GridPos>.from(occupied);
    
    // Add wall cells to occupied
    for (final wall in walls) {
      _addWallCells(wall, usedPositions);
    }
    
    int attempts = 0;
    while (mirrors.length < count && attempts < 300) {
      attempts++;
      
      // Generate position (1 cell away from edges)
      final x = _rng.nextInt(gridWidth - 2) + 1;
      final y = _rng.nextInt(gridHeight - 2) + 1;
      final pos = GridPos(x, y);
      
      // Check if position is valid
      if (usedPositions.contains(pos)) continue;
      if (!_hasWallClearance(pos, walls, 1)) continue;
      
      // Random angle (0, 45, 90, 135 degrees)
      final angleIndex = _rng.nextInt(4);
      final angle = angleIndex * 45.0;
      
      // Determine if fixed (first few mirrors in harder levels)
      final isFixed = someFixed && mirrors.length < count ~/ 3;
      
      mirrors.add(MirrorDef(
        position: pos,
        angle: angle,
        movable: !isFixed,
        rotatable: !isFixed,
      ));
      usedPositions.add(pos);
    }
    
    return mirrors;
  }
  
  /// Place prisms in valid positions
  List<PrismDef> placePrisms({
    required int count,
    required List<WallDef> walls,
    required List<GridPos> occupied,
  }) {
    final prisms = <PrismDef>[];
    final usedPositions = Set<GridPos>.from(occupied);
    
    // Add wall cells to occupied
    for (final wall in walls) {
      _addWallCells(wall, usedPositions);
    }
    
    int attempts = 0;
    while (prisms.length < count && attempts < 200) {
      attempts++;
      
      // Generate position (2 cells away from edges for prisms)
      final x = _rng.nextInt(gridWidth - 4) + 2;
      final y = _rng.nextInt(gridHeight - 4) + 2;
      final pos = GridPos(x, y);
      
      // Check if position is valid
      if (usedPositions.contains(pos)) continue;
      if (!_hasWallClearance(pos, walls, 1)) continue;
      
      // Random angle
      final angle = _rng.nextDouble() * 360;
      
      prisms.add(PrismDef(position: pos, angle: angle, movable: true));
      usedPositions.add(pos);
      
      // Prisms need more space around them
      _addBufferZone(pos, usedPositions, 1);
    }
    
    return prisms;
  }
  
  /// Generate wall pattern without creating isolated regions
  List<WallDef> generateWallPattern(int count) {
    final walls = <WallDef>[];
    
    int attempts = 0;
    while (walls.length < count && attempts < 100) {
      attempts++;
      
      // Random wall type: horizontal or vertical
      final isHorizontal = _rng.nextBool();
      
      // Random length (2-5 cells)
      final length = _rng.nextInt(4) + 2;
      
      // Random starting position (away from edges)
      final startX = _rng.nextInt(gridWidth - length - 2) + 1;
      final startY = _rng.nextInt(gridHeight - (isHorizontal ? 2 : length) - 1) + 1;
      
      final start = GridPos(startX, startY);
      final end = isHorizontal 
          ? GridPos(startX + length, startY)
          : GridPos(startX, startY + length);
      
      final newWall = WallDef(start, end);
      
      // Check if this wall creates isolated regions
      final testWalls = [...walls, newWall];
      if (!_hasUnreachableRegions(testWalls)) {
        walls.add(newWall);
      }
    }
    
    return walls;
  }
  
  // ===== Helper Methods =====
  
  void _addWallCells(WallDef wall, Set<GridPos> cells) {
    final minX = min(wall.start.x, wall.end.x);
    final maxX = max(wall.start.x, wall.end.x);
    final minY = min(wall.start.y, wall.end.y);
    final maxY = max(wall.start.y, wall.end.y);
    
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add(GridPos(x, y));
      }
    }
  }
  
  void _addBufferZone(GridPos center, Set<GridPos> cells, int radius) {
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        final newX = center.x + dx;
        final newY = center.y + dy;
        if (newX >= 0 && newX < gridWidth && newY >= 0 && newY < gridHeight) {
          cells.add(GridPos(newX, newY));
        }
      }
    }
  }
  
  bool _hasWallClearance(GridPos pos, List<WallDef> walls, int minDistance) {
    for (final wall in walls) {
      // Check nearby cells
      for (int dx = -minDistance; dx <= minDistance; dx++) {
        for (int dy = -minDistance; dy <= minDistance; dy++) {
          if (wall.blocksCell(GridPos(pos.x + dx, pos.y + dy))) {
            return false;
          }
        }
      }
    }
    return true;
  }
  
  bool _isIsolated(GridPos pos, List<WallDef> walls) {
    // Simple check: if all 4 neighbors are blocked, it's isolated
    int blockedNeighbors = 0;
    final neighbors = [
      GridPos(pos.x - 1, pos.y),
      GridPos(pos.x + 1, pos.y),
      GridPos(pos.x, pos.y - 1),
      GridPos(pos.x, pos.y + 1),
    ];
    
    for (final neighbor in neighbors) {
      if (!neighbor.isValid) {
        blockedNeighbors++;
        continue;
      }
      for (final wall in walls) {
        if (wall.blocksCell(neighbor)) {
          blockedNeighbors++;
          break;
        }
      }
    }
    
    return blockedNeighbors >= 4;
  }
  
  /// Check if walls create unreachable regions using flood fill
  bool _hasUnreachableRegions(List<WallDef> walls) {
    // Create grid of blocked cells
    final blocked = <GridPos>{};
    for (final wall in walls) {
      _addWallCells(wall, blocked);
    }
    
    // Find first non-blocked cell
    GridPos? start;
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        final pos = GridPos(x, y);
        if (!blocked.contains(pos)) {
          start = pos;
          break;
        }
      }
      if (start != null) break;
    }
    
    if (start == null) return true; // All blocked!
    
    // Flood fill from start
    final visited = <GridPos>{};
    final queue = <GridPos>[start];
    
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (visited.contains(current)) continue;
      if (blocked.contains(current)) continue;
      if (!current.isValid) continue;
      
      visited.add(current);
      
      queue.add(GridPos(current.x - 1, current.y));
      queue.add(GridPos(current.x + 1, current.y));
      queue.add(GridPos(current.x, current.y - 1));
      queue.add(GridPos(current.x, current.y + 1));
    }
    
    // Count non-blocked cells
    int nonBlockedCount = 0;
    for (int x = 0; x < gridWidth; x++) {
      for (int y = 0; y < gridHeight; y++) {
        if (!blocked.contains(GridPos(x, y))) {
          nonBlockedCount++;
        }
      }
    }
    
    // If visited count != non-blocked count, there are isolated regions
    return visited.length != nonBlockedCount;
  }
}

