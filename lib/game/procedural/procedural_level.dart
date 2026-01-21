/// Procedural Level Data Structure
/// Represents a generated level before conversion to game format

import 'dart:math';

/// Grid position in 22x9 coordinate system
class GridPos {
  final int x; // 0-21 (22 columns)
  final int y; // 0-8 (9 rows)
  
  const GridPos(this.x, this.y);
  
  /// Convert to pixel position (center of cell)
  Vector2 toPixel() {
    const cellSize = 55.0;
    return Vector2(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2);
  }
  
  /// Check if position is on edge (for light source placement)
  bool get isOnEdge => x == 0 || x == 21 || y == 0 || y == 8;
  
  /// Check if position is within bounds
  bool get isValid => x >= 0 && x <= 21 && y >= 0 && y <= 8;
  
  /// Manhattan distance to another position
  int distanceTo(GridPos other) => (x - other.x).abs() + (y - other.y).abs();
  
  @override
  bool operator ==(Object other) =>
      other is GridPos && x == other.x && y == other.y;
  
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
  
  @override
  String toString() => 'GridPos($x, $y)';
}

/// Simple Vector2 for pixel positions
class Vector2 {
  final double x, y;
  const Vector2(this.x, this.y);
  
  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  
  double get length => sqrt(x * x + y * y);
  Vector2 get normalized => this * (1 / length);
  
  @override
  String toString() => 'Vector2($x, $y)';
}

/// Direction for light sources
enum LightDirection {
  east,   // →
  west,   // ←
  north,  // ↑
  south,  // ↓
}

extension LightDirectionExt on LightDirection {
  /// Get angle in radians
  double get angleRad {
    switch (this) {
      case LightDirection.east: return 0;
      case LightDirection.south: return pi / 2;
      case LightDirection.west: return pi;
      case LightDirection.north: return -pi / 2;
    }
  }
  
  /// Get direction pointing inward from edge
  static LightDirection fromEdge(GridPos pos) {
    if (pos.x == 0) return LightDirection.east;
    if (pos.x == 21) return LightDirection.west;
    if (pos.y == 0) return LightDirection.south;
    if (pos.y == 8) return LightDirection.north;
    return LightDirection.east; // Default
  }
}

/// Light source definition
class LightSourceDef {
  final GridPos position;
  final LightDirection direction;
  final String color; // "white", "red", "blue", "yellow"
  
  const LightSourceDef({
    required this.position,
    required this.direction,
    this.color = 'white',
  });
  
  Map<String, dynamic> toJson() => {
    'x': position.x,
    'y': position.y,
    'direction': direction.name,
    'color': color,
  };
}

/// Target definition
class TargetDef {
  final GridPos position;
  final String requiredColor;
  
  const TargetDef({
    required this.position,
    this.requiredColor = 'white',
  });
  
  Map<String, dynamic> toJson() => {
    'x': position.x,
    'y': position.y,
    'color': requiredColor,
  };
}

/// Mirror definition
class MirrorDef {
  final GridPos position;
  final double angle; // degrees
  final bool movable;
  final bool rotatable;
  
  const MirrorDef({
    required this.position,
    this.angle = 45,
    this.movable = true,
    this.rotatable = true,
  });
  
  Map<String, dynamic> toJson() => {
    'x': position.x,
    'y': position.y,
    'angle': angle,
    'movable': movable,
    'rotatable': rotatable,
  };
}

/// Prism definition
class PrismDef {
  final GridPos position;
  final double angle;
  final bool movable;
  
  const PrismDef({
    required this.position,
    this.angle = 0,
    this.movable = true,
  });
  
  Map<String, dynamic> toJson() => {
    'x': position.x,
    'y': position.y,
    'angle': angle,
    'movable': movable,
  };
}

/// Wall definition (line segment between two cells)
class WallDef {
  final GridPos start;
  final GridPos end;
  
  const WallDef(this.start, this.end);
  
  /// Check if wall blocks a specific cell
  bool blocksCell(GridPos cell) {
    final minX = min(start.x, end.x);
    final maxX = max(start.x, end.x);
    final minY = min(start.y, end.y);
    final maxY = max(start.y, end.y);
    
    return cell.x >= minX && cell.x <= maxX &&
           cell.y >= minY && cell.y <= maxY;
  }
  
  Map<String, dynamic> toJson() => {
    'from': {'x': start.x, 'y': start.y},
    'to': {'x': end.x, 'y': end.y},
  };
}

/// Solution step
class SolutionStep {
  final int objectIndex;
  final String action; // "move", "rotate"
  final GridPos? targetPos;
  final double? targetAngle;
  
  const SolutionStep({
    required this.objectIndex,
    required this.action,
    this.targetPos,
    this.targetAngle,
  });
  
  Map<String, dynamic> toJson() => {
    'object': 'object_$objectIndex',
    'action': action,
    if (targetPos != null) 'to': {'x': targetPos!.x, 'y': targetPos!.y},
    if (targetAngle != null) 'angle': targetAngle,
  };
}

/// Complete procedural level
class ProceduralLevel {
  final int levelId;
  final int chapter;
  final int optimalMoves;
  final LightSourceDef lightSource;
  final List<TargetDef> targets;
  final List<MirrorDef> mirrors;
  final List<PrismDef> prisms;
  final List<WallDef> walls;
  final List<SolutionStep> solution;
  
  const ProceduralLevel({
    required this.levelId,
    required this.chapter,
    required this.optimalMoves,
    required this.lightSource,
    required this.targets,
    required this.mirrors,
    required this.prisms,
    required this.walls,
    required this.solution,
  });
  
  /// Star thresholds based on optimal moves
  Map<String, int> get starThresholds => {
    '3_star': optimalMoves,
    '2_star': (optimalMoves * 1.5).ceil(),
    '1_star': 999,
  };
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'level_id': levelId,
    'chapter': chapter,
    'optimal_moves': optimalMoves,
    'star_thresholds': starThresholds,
    'play_area': {
      'width': 22,
      'height': 9,
      'cell_size': 55,
    },
    'light_sources': [lightSource.toJson()],
    'targets': targets.map((t) => t.toJson()).toList(),
    'mirrors': mirrors.map((m) => m.toJson()).toList(),
    'prisms': prisms.map((p) => p.toJson()).toList(),
    'walls': walls.map((w) => w.toJson()).toList(),
    'solution': solution.map((s) => s.toJson()).toList(),
  };
}
