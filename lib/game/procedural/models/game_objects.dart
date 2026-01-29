/// Game object models for procedural level generation.
///
/// These are pure data classes used by the generator, solver, and ray tracer.
/// They are decoupled from the Flame game components.
library;

import 'direction.dart';
import 'light_color.dart';

/// Grid position in the 22x9 coordinate system.
class GridPosition {
  final int x; // 0-21 (22 columns)
  final int y; // 0-8 (9 rows)

  const GridPosition(this.x, this.y);

  /// Grid dimensions.
  static const int gridWidth = 14;
  static const int gridHeight = 7;

  /// Cell size in pixels for rendering (matches level_loader and grid_overlay).
  static const double cellSize = 85.0;

  /// Check if position is within grid bounds.
  bool get isValid => x >= 0 && x < gridWidth && y >= 0 && y < gridHeight;

  /// Check if position is on the grid edge.
  bool get isOnEdge =>
      x == 0 || x == gridWidth - 1 || y == 0 || y == gridHeight - 1;

  /// Get the adjacent position in a direction.
  GridPosition step(Direction dir) {
    return GridPosition(x + dir.dx, y + dir.dy);
  }

  /// Manhattan distance to another position.
  int distanceTo(GridPosition other) {
    return (x - other.x).abs() + (y - other.y).abs();
  }

  /// Convert to pixel position (center of cell).
  (double, double) toPixel() {
    return (x * cellSize + cellSize / 2, y * cellSize + cellSize / 2);
  }

  @override
  bool operator ==(Object other) =>
      other is GridPosition && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ (y.hashCode * 31);

  @override
  String toString() => 'GridPosition($x, $y)';

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory GridPosition.fromJson(Map<String, dynamic> json) {
    return GridPosition(json['x'] as int, json['y'] as int);
  }
}

/// Light source definition.
class Source {
  final GridPosition position;
  final Direction direction;
  final LightColor color;

  const Source({
    required this.position,
    required this.direction,
    this.color = LightColor.white,
  });

  Map<String, dynamic> toJson() => {
        'x': position.x,
        'y': position.y,
        'direction': direction.toJsonString(),
        'color': color.toJsonString(),
      };

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      position: GridPosition(json['x'] as int, json['y'] as int),
      direction: DirectionExtension.fromJsonString(json['direction'] as String),
      color: LightColorExtension.fromJsonString(
          json['color'] as String? ?? 'white'),
    );
  }
}

/// Target definition.
class Target {
  final GridPosition position;
  final LightColor requiredColor;

  const Target({
    required this.position,
    this.requiredColor = LightColor.white,
  });

  /// Create a copy with optional new properties.
  Target copyWith({
    GridPosition? position,
    LightColor? requiredColor,
  }) {
    return Target(
      position: position ?? this.position,
      requiredColor: requiredColor ?? this.requiredColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': position.x,
        'y': position.y,
        'color': requiredColor.toJsonString(),
      };

  factory Target.fromJson(Map<String, dynamic> json) {
    return Target(
      position: GridPosition(json['x'] as int, json['y'] as int),
      requiredColor: LightColorExtension.fromJsonString(
          json['color'] as String? ?? 'white'),
    );
  }
}

/// Wall definition (single cell blocker).
class Wall {
  final GridPosition position;

  const Wall({required this.position});

  Map<String, dynamic> toJson() => {
        'x': position.x,
        'y': position.y,
      };

  factory Wall.fromJson(Map<String, dynamic> json) {
    return Wall(
      position: GridPosition(json['x'] as int, json['y'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Wall && position == other.position;

  @override
  int get hashCode => position.hashCode;
}

/// Mirror orientation states.
///
/// Mirrors have exactly 4 discrete states:
/// - 0: "_" horizontal reflector
/// - 1: "/" slash reflector
/// - 2: "|" vertical reflector
/// - 3: "\" backslash reflector
enum MirrorOrientation {
  horizontal, // 0: "_"
  slash,      // 1: "/"
  vertical,   // 2: "|"
  backslash,  // 3: "\"
}

extension MirrorOrientationExtension on MirrorOrientation {
  /// Get the next orientation in cycle (tap rotates to next).
  MirrorOrientation get next {
    return MirrorOrientation.values[(index + 1) % 4];
  }

  /// Get orientation from int (0-3).
  static MirrorOrientation fromInt(int value) {
    return MirrorOrientation.values[value % 4];
  }

  /// Get the angle in radians for rendering.
  double get angleRad {
    switch (this) {
      case MirrorOrientation.horizontal:
        return 0;
      case MirrorOrientation.slash:
        return -0.7854; // -45° or π/4
      case MirrorOrientation.vertical:
        return 1.5708; // 90° or π/2
      case MirrorOrientation.backslash:
        return 0.7854; // 45° or π/4
    }
  }

  String toJsonString() => index.toString();

  static MirrorOrientation fromJsonString(String s) {
    return fromInt(int.parse(s));
  }
}

/// Mirror definition.
class Mirror {
  final GridPosition position;
  final MirrorOrientation orientation;
  final bool rotatable;

  const Mirror({
    required this.position,
    required this.orientation,
    this.rotatable = true,
  });

  /// Create a copy with a new orientation.
  Mirror withOrientation(MirrorOrientation newOrientation) {
    return Mirror(
      position: position,
      orientation: newOrientation,
      rotatable: rotatable,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': position.x,
        'y': position.y,
        'orientation': orientation.index,
        'rotatable': rotatable,
      };

  factory Mirror.fromJson(Map<String, dynamic> json) {
    return Mirror(
      position: GridPosition(json['x'] as int, json['y'] as int),
      orientation:
          MirrorOrientationExtension.fromInt(json['orientation'] as int? ?? 0),
      rotatable: json['rotatable'] as bool? ?? true,
    );
  }
}

/// Prism types.
enum PrismType {
  splitter,  // White → splits into R,B,Y
  deflector, // Deflects direction, preserves color
}

extension PrismTypeExtension on PrismType {
  String toJsonString() => name;

  static PrismType fromJsonString(String s) {
    switch (s.toLowerCase()) {
      case 'splitter':
        return PrismType.splitter;
      case 'deflector':
        return PrismType.deflector;
      default:
        return PrismType.splitter;
    }
  }
}

/// Prism definition.
///
/// Prisms have 4 discrete orientation states (0-3).
class Prism {
  final GridPosition position;
  final int orientation; // 0-3
  final bool rotatable;
  final PrismType type;

  const Prism({
    required this.position,
    this.orientation = 0,
    this.rotatable = true,
    this.type = PrismType.splitter,
  });

  /// Create a copy with a new orientation.
  Prism withOrientation(int newOrientation) {
    return Prism(
      position: position,
      orientation: newOrientation % 4,
      rotatable: rotatable,
      type: type,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': position.x,
        'y': position.y,
        'orientation': orientation,
        'rotatable': rotatable,
        'type': type.toJsonString(),
      };

  factory Prism.fromJson(Map<String, dynamic> json) {
    return Prism(
      position: GridPosition(json['x'] as int, json['y'] as int),
      orientation: json['orientation'] as int? ?? 0,
      rotatable: json['rotatable'] as bool? ?? true,
      type: PrismTypeExtension.fromJsonString(json['type'] as String? ?? 'splitter'),
    );
  }
}

