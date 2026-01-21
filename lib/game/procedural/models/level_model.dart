/// Level model for procedural level generation.
///
/// Complete level representation with all objects and metadata.
library;

import 'dart:convert';
import 'game_objects.dart';
import 'light_color.dart';

/// Difficulty band classification.
enum DifficultyBand {
  tutorial,   // Episode 1: 1-6 moves
  easy,       // Episode 2: 4-10 moves
  medium,     // Episode 3: 10-18 moves
  hard,       // Episode 4: 16-26 moves
  expert,     // Episode 5: 22-35 moves
}

/// Level metadata.
class LevelMeta {
  final int optimalMoves;
  final DifficultyBand difficultyBand;
  final int generationAttempts;
  final Duration solveTime;

  const LevelMeta({
    required this.optimalMoves,
    required this.difficultyBand,
    this.generationAttempts = 1,
    this.solveTime = Duration.zero,
  });

  /// Star thresholds based on optimal moves.
  int get threeStarMax => optimalMoves;
  int get twoStarMax => (optimalMoves * 1.5).ceil();
  // 1 star: any completion

  /// Get stars for a given move count.
  int getStars(int moveCount) {
    if (moveCount <= threeStarMax) return 3;
    if (moveCount <= twoStarMax) return 2;
    return 1;
  }

  Map<String, dynamic> toJson() => {
        'optimalMoves': optimalMoves,
        'difficultyBand': difficultyBand.name,
        'generationAttempts': generationAttempts,
        'solveTimeMs': solveTime.inMilliseconds,
        'starThresholds': {
          '3_star': threeStarMax,
          '2_star': twoStarMax,
          '1_star': 999,
        },
      };

  factory LevelMeta.fromJson(Map<String, dynamic> json) {
    return LevelMeta(
      optimalMoves: json['optimalMoves'] as int,
      difficultyBand: DifficultyBand.values
          .firstWhere((e) => e.name == json['difficultyBand']),
      generationAttempts: json['generationAttempts'] as int? ?? 1,
      solveTime:
          Duration(milliseconds: json['solveTimeMs'] as int? ?? 0),
    );
  }
}

/// A single move in a solution.
class SolutionMove {
  final MoveType type;
  final int objectIndex;
  final int taps; // Always 1 for rotation, but included for future flexibility

  const SolutionMove({
    required this.type,
    required this.objectIndex,
    this.taps = 1,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'objectIndex': objectIndex,
        'taps': taps,
      };

  factory SolutionMove.fromJson(Map<String, dynamic> json) {
    return SolutionMove(
      type: MoveType.values.firstWhere((e) => e.name == json['type']),
      objectIndex: json['objectIndex'] as int,
      taps: json['taps'] as int? ?? 1,
    );
  }
}

enum MoveType {
  rotateMirror,
  rotatePrism,
}

/// Complete generated level.
class GeneratedLevel {
  final int seed;
  final int episode;
  final int index;
  final Source source;
  final List<Target> targets;
  final Set<Wall> walls;
  final List<Mirror> mirrors;
  final List<Prism> prisms;
  final LevelMeta meta;
  final List<SolutionMove> solution;

  const GeneratedLevel({
    required this.seed,
    required this.episode,
    required this.index,
    required this.source,
    required this.targets,
    required this.walls,
    required this.mirrors,
    required this.prisms,
    required this.meta,
    required this.solution,
  });

  /// Generate a unique level ID.
  String get levelId => 'E${episode}_L${index}_S$seed';

  /// Get the total number of rotatable objects.
  int get rotatableCount {
    return mirrors.where((m) => m.rotatable).length +
        prisms.where((p) => p.rotatable).length;
  }

  /// Convert to JSON for storage.
  Map<String, dynamic> toJson() => {
        'seed': seed,
        'episode': episode,
        'index': index,
        'levelId': levelId,
        'playArea': {
          'width': GridPosition.gridWidth,
          'height': GridPosition.gridHeight,
          'cellSize': GridPosition.cellSize,
        },
        'source': source.toJson(),
        'targets': targets.map((t) => t.toJson()).toList(),
        'walls': walls.map((w) => w.toJson()).toList(),
        'mirrors': mirrors.map((m) => m.toJson()).toList(),
        'prisms': prisms.map((p) => p.toJson()).toList(),
        'meta': meta.toJson(),
        'solution': solution.map((s) => s.toJson()).toList(),
      };

  /// Convert to JSON string.
  String toJsonString() => jsonEncode(toJson());

  factory GeneratedLevel.fromJson(Map<String, dynamic> json) {
    return GeneratedLevel(
      seed: json['seed'] as int,
      episode: json['episode'] as int,
      index: json['index'] as int,
      source: Source.fromJson(json['source'] as Map<String, dynamic>),
      targets: (json['targets'] as List)
          .map((e) => Target.fromJson(e as Map<String, dynamic>))
          .toList(),
      walls: (json['walls'] as List)
          .map((e) => Wall.fromJson(e as Map<String, dynamic>))
          .toSet(),
      mirrors: (json['mirrors'] as List)
          .map((e) => Mirror.fromJson(e as Map<String, dynamic>))
          .toList(),
      prisms: (json['prisms'] as List)
          .map((e) => Prism.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: LevelMeta.fromJson(json['meta'] as Map<String, dynamic>),
      solution: (json['solution'] as List?)
              ?.map((e) => SolutionMove.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory GeneratedLevel.fromJsonString(String jsonString) {
    return GeneratedLevel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
