/// Level Provider Abstraction.
///
/// Abstracts level loading from different sources:
/// - New procedural generator (GeneratedLevel)
/// - Legacy JSON format (via adapter)
///
/// All gameplay code uses Level through this provider.
library;

import 'dart:convert';

import 'models/models.dart';
import 'level_generator.dart';

/// Abstract interface for level providers.
abstract class LevelProvider {
  /// Get a level by episode and index.
  Future<GeneratedLevel?> getLevel(int episode, int index);

  /// Get total level count for an episode.
  int getLevelCount(int episode);

  /// Check if a level supports drag (sandbox mode only).
  bool supportsDrag(int episode, int index) => false;
}

/// Provider that generates levels procedurally.
class ProceduralLevelProvider implements LevelProvider {
  final LevelGenerator _generator = LevelGenerator();
  final Map<String, GeneratedLevel> _cache = {};

  @override
  Future<GeneratedLevel?> getLevel(int episode, int index) async {
    final key = 'E${episode}_L$index';

    // Check cache
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    // Generate deterministically
    final seed = episode * 10000 + index;
    final level = _generator.generate(episode, index, seed);

    if (level != null) {
      _cache[key] = level;
    }

    return level;
  }

  @override
  int getLevelCount(int episode) {
    // Each episode has 200 levels
    return 200;
  }

  @override
  bool supportsDrag(int episode, int index) => false; // Campaign = rotate only

  /// Pre-generate levels for an episode (optional background task).
  Future<void> preloadEpisode(int episode) async {
    for (int i = 1; i <= getLevelCount(episode); i++) {
      await getLevel(episode, i);
    }
  }

  /// Clear cache.
  void clearCache() {
    _cache.clear();
  }
}

/// Adapter for loading legacy JSON levels.
class LegacyLevelLoader {
  /// Convert legacy level JSON to new GeneratedLevel format.
  static GeneratedLevel fromLegacyJson(Map<String, dynamic> json) {
    final objects = json['objects'] as List<dynamic>? ?? [];

    Source? source;
    final targets = <Target>[];
    final walls = <Wall>{};
    final mirrors = <Mirror>[];
    final prisms = <Prism>[];

    for (final obj in objects) {
      final type = obj['type'] as String;
      final x = (obj['x'] as num).toDouble();
      final y = (obj['y'] as num).toDouble();

      switch (type) {
        case 'light_source':
          final direction = _parseDirection(obj['direction'] as num?);
          final color = _parseColor(obj['color'] as String?);
          source = Source(
            position: _pixelToGrid(x, y),
            direction: direction,
            color: color,
          );
          break;

        case 'target':
          final color = _parseColor(obj['color'] as String?);
          targets.add(Target(
            position: _pixelToGrid(x, y),
            requiredColor: color,
          ));
          break;

        case 'wall':
          walls.add(Wall(position: _pixelToGrid(x, y)));
          break;

        case 'mirror':
          final angle = (obj['angle'] as num?)?.toDouble() ?? 0;
          final locked = obj['locked'] as bool? ?? false;
          mirrors.add(Mirror(
            position: _pixelToGrid(x, y),
            orientation: _angleToMirrorOrientation(angle),
            rotatable: !locked,
          ));
          break;

        case 'prism':
          final angle = (obj['angle'] as num?)?.toDouble() ?? 0;
          final locked = obj['locked'] as bool? ?? false;
          prisms.add(Prism(
            position: _pixelToGrid(x, y),
            orientation: _angleToPrismOrientation(angle),
            rotatable: !locked,
            type: PrismType.splitter,
          ));
          break;
      }
    }

    // Use default source if not found
    source ??= const Source(
      position: GridPosition(0, 4),
      direction: Direction.east,
    );

    return GeneratedLevel(
      seed: json['id'] as int? ?? 0,
      episode: 0, // Legacy
      index: json['id'] as int? ?? 0,
      source: source,
      targets: targets,
      walls: walls,
      mirrors: mirrors,
      prisms: prisms,
      meta: LevelMeta(
        optimalMoves: json['par'] as int? ?? 0,
        difficultyBand: DifficultyBand.tutorial,
      ),
      solution: const [],
    );
  }

  /// Convert pixel position to grid position.
  static GridPosition _pixelToGrid(double x, double y) {
    const cellSize = GridPosition.cellSize;
    return GridPosition(
      (x / cellSize).round().clamp(0, GridPosition.gridWidth - 1),
      (y / cellSize).round().clamp(0, GridPosition.gridHeight - 1),
    );
  }

  /// Parse direction from legacy angle in degrees.
  static Direction _parseDirection(num? degrees) {
    if (degrees == null) return Direction.east;
    final normalized = (degrees % 360).toInt();
    if (normalized >= 315 || normalized < 45) return Direction.east;
    if (normalized >= 45 && normalized < 135) return Direction.south;
    if (normalized >= 135 && normalized < 225) return Direction.west;
    return Direction.north;
  }

  /// Parse color from legacy string.
  static LightColor _parseColor(String? color) {
    switch (color?.toLowerCase()) {
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
      case 'white':
      default:
        return LightColor.white;
    }
  }

  /// Convert legacy angle to discrete mirror orientation.
  static MirrorOrientation _angleToMirrorOrientation(double angleDegrees) {
    // Normalize to 0-360
    final normalized = (angleDegrees % 360 + 360) % 360;

    // Map to 4 states (45° increments centered)
    // 0° = horizontal, 45° = slash, 90° = vertical, 135° = backslash
    if (normalized >= 337.5 || normalized < 22.5) {
      return MirrorOrientation.horizontal;
    } else if (normalized >= 22.5 && normalized < 67.5) {
      return MirrorOrientation.slash;
    } else if (normalized >= 67.5 && normalized < 112.5) {
      return MirrorOrientation.vertical;
    } else if (normalized >= 112.5 && normalized < 157.5) {
      return MirrorOrientation.backslash;
    } else if (normalized >= 157.5 && normalized < 202.5) {
      return MirrorOrientation.horizontal;
    } else if (normalized >= 202.5 && normalized < 247.5) {
      return MirrorOrientation.slash;
    } else if (normalized >= 247.5 && normalized < 292.5) {
      return MirrorOrientation.vertical;
    } else {
      return MirrorOrientation.backslash;
    }
  }

  /// Convert legacy angle to discrete prism orientation (4 states).
  static int _angleToPrismOrientation(double angleDegrees) {
    final normalized = (angleDegrees % 360 + 360) % 360;
    return ((normalized + 45) ~/ 90) % 4;
  }
}

/// Provider that loads legacy JSON levels.
class LegacyLevelProvider implements LevelProvider {
  final Map<String, GeneratedLevel> _levels = {};
  final Future<String> Function(String path) _loadAsset;

  LegacyLevelProvider(this._loadAsset);

  /// Load all levels from JSON asset.
  Future<void> loadFromAsset(String path) async {
    final jsonStr = await _loadAsset(path);
    final List<dynamic> levelList = jsonDecode(jsonStr);

    for (final levelJson in levelList) {
      final level = LegacyLevelLoader.fromLegacyJson(
        levelJson as Map<String, dynamic>,
      );
      _levels['L${level.index}'] = level;
    }
  }

  @override
  Future<GeneratedLevel?> getLevel(int episode, int index) async {
    return _levels['L$index'];
  }

  @override
  int getLevelCount(int episode) => _levels.length;

  @override
  bool supportsDrag(int episode, int index) {
    // Legacy sandbox levels can support drag
    return true;
  }
}
