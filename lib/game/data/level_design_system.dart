import 'package:flutter/material.dart';
import 'package:flame/components.dart';

// --- GRID SYSTEM ---
class GridPos {
  final int x;
  final int y;
  const GridPos(this.x, this.y);
  
  @override
  String toString() => '($x, $y)';
}

class GridConverter {
  static const double cellSize = 85.0;
  static const int gridCols = 14;
  static const int gridRows = 7;
  
  // 720 - (7 * 85) = 125 -> Margin Y = 62.5
  static const double offsetX = 45.0; // (1280 - (14*85)) / 2 = 45.0
  static const double offsetY = 62.5;
  
  // Center grid 16x9 efficiently within 1280x720 viewport
  // We can override bounds for Campaign Levels or assume the "GameBounds" apply to UI overlay, 
  // but the grid is the play area.
  // Let's use 80, 45 to center the grid OF 16x9.
  
  static Vector2 gridToPixel(GridPos pos) {
    // Center of cell
    return Vector2(
      offsetX + (pos.x * cellSize) + (cellSize / 2),
      offsetY + (pos.y * cellSize) + (cellSize / 2),
    );
  }
  
  // For walls spanning multiple cells
  static Vector2 gridToPixelTopLeft(GridPos pos) {
    return Vector2(
      offsetX + (pos.x * cellSize),
      offsetY + (pos.y * cellSize),
    );
  }
}

// --- LEVEL DEFINITION MODELS ---

enum Direction { right, down, left, up }
enum LightColor { white, red, green, blue, cyan, magenta, yellow, orange }

class LevelDef {
  final int levelNumber;
  final String name;
  final int optimalMoves;
  
  final GridLightSource lightSource;
  final List<GridTarget> targets;
  final List<GridWall> walls;
  final List<GridMirror> mirrors;
  final List<GridPrism> prisms;
  
  // Hints / Solution
  final List<String> solutionSteps;

  const LevelDef({
    required this.levelNumber,
    required this.name,
    required this.optimalMoves,
    required this.lightSource,
    this.targets = const [],
    this.walls = const [],
    this.mirrors = const [],
    this.prisms = const [],
    this.solutionSteps = const [],
  });
}

// --- COMPONENT BLUEPRINTS ---

class GridLightSource {
  final GridPos pos;
  final Direction direction;
  final LightColor color;
  const GridLightSource({required this.pos, required this.direction, this.color = LightColor.white});
  
  double get angleRad {
    switch (direction) {
      case Direction.right: return 0;
      case Direction.down: return 1.5708; // 90 deg
      case Direction.left: return 3.14159; // 180 deg
      case Direction.up: return 4.71239; // 270 deg
    }
  }
}

class GridTarget {
  final GridPos pos;
  final LightColor color;
  const GridTarget({required this.pos, this.color = LightColor.white});
}

class GridMirror {
  final GridPos pos;
  final double angle; // Degrees (0, 45, etc.) -> Converted to Radians in loader
  final bool movable;
  final bool rotatable;
  const GridMirror({required this.pos, this.angle = 0, this.movable = true, this.rotatable = true});
}

class GridPrism {
  final GridPos pos;
  final double angle;
  final bool movable;
  final bool rotatable;
  const GridPrism({required this.pos, this.angle = 0, this.movable = true, this.rotatable = true});
}

class GridWall {
  final GridPos from;
  final GridPos to; // Inclusive range. If from=(8,0) to=(8,9), it's a vertical wall spanning rows 0-9 at col 8.
  // Actually, walls are usually THIN and placed BETWEEN cells or INSIDE cells?
  // LEVEL.md says: walls: [Wall( start: (x,y), end: (x,y) )]
  // In Grid system, maybe "Occupies cell"? Or "Thin wall between"?
  // Visuals in LEVEL.md imply Walls take up space or block paths.
  // "Wall(start: 560,100, end: 560,540, thickness: 8)" -> Pixel coordinates.
  // In Grid: Simplest is "Wall Block" that fills the cell (70x70) or specific Wall object.
  // Let's assume standard "Wall Block" logic for simplicity in 16x9 grid.
  // If we need thin walls, we can have "ThinWall" type.
  // User example: Wall(from: GridPos(8,0), to: GridPos(8,9)).
  // This implies filling the cells (8,0) through (8,9).
  
  const GridWall({required this.from, required this.to});
}

// Helper convert color
Color mapColor(LightColor c) {
  switch (c) {
    case LightColor.white: return Colors.white;
    case LightColor.red: return Colors.red;
    case LightColor.green: return Colors.green;
    case LightColor.blue: return Colors.blue;
    case LightColor.cyan: return Colors.cyanAccent;
    case LightColor.magenta: return Colors.purpleAccent;
    case LightColor.yellow: return Colors.yellow;
    case LightColor.orange: return Colors.orange;
  }
}

