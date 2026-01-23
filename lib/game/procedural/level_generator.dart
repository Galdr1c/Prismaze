/// Blueprint-based Level Generator.
///
/// For Episode 1-2: Simple random placement with solver validation
/// For Episode 3+: Deterministic blueprint with planned solution
library;

import 'dart:math';
import 'models/models.dart';
import 'episode_config.dart';
import 'solver.dart';
import 'ray_tracer.dart';
import 'occupancy_grid.dart';

/// Rejection reason for failed generation attempts.
enum RejectionReason {
  noValidSourcePosition,
  noValidTargetPositions,
  noValidMirrorPositions,
  noValidPrismPositions,
  unsolvable,
  tooEasy,
  tooHard,
  trivialWin,
  solverTimeout,
  validationFailed,
  shortcutFound,
  blueprintFailed,
  plannedSolutionFailed,
}

/// A planned move in the blueprint solution.
class PlannedMove {
  final MoveType type;
  final int objectIndex;
  final int taps; // Number of taps (rotations) to apply

  const PlannedMove({
    required this.type,
    required this.objectIndex,
    required this.taps,
  });

  /// Convert to solution moves (one per tap).
  List<SolutionMove> toSolutionMoves() {
    return List.generate(taps, (_) => SolutionMove(type: type, objectIndex: objectIndex));
  }
}

/// Blueprint for a level with planned solution.
class LevelBlueprint {
  final Source source;
  final List<Target> targets;
  final List<Mirror> mirrors;
  final List<Prism> prisms;
  final Set<Wall> walls;
  final List<PlannedMove> plannedMoves;
  final int totalPlannedMoves;

  const LevelBlueprint({
    required this.source,
    required this.targets,
    required this.mirrors,
    required this.prisms,
    required this.walls,
    required this.plannedMoves,
    required this.totalPlannedMoves,
  });
}

/// Result of a generation attempt.
class GenerationAttempt {
  final bool success;
  final GeneratedLevel? level;
  final RejectionReason? rejectionReason;
  final int attemptNumber;

  const GenerationAttempt({
    required this.success,
    this.level,
    this.rejectionReason,
    required this.attemptNumber,
  });
}

/// Level generator with blueprint support.
class LevelGenerator {
  final Solver _solver = Solver();
  final RayTracer _rayTracer = RayTracer();

  /// Generate a level for a given episode and index.
  /// 
  /// Robust: If the current episode's logic fails, it will try lower episodes 
  /// as fallbacks to ensure generate() never returns null.
  GeneratedLevel generate(int episode, int index, int seed) {
    var config = EpisodeConfig.forEpisode(episode);
    var rng = Random(seed);

    // Initial robust attempt: Try standard logic with original config
    for (int attempt = 0; attempt < config.generationAttempts * 2; attempt++) {
      final result = episode >= 3
          ? _generateBlueprint(config, episode, index, seed + attempt, rng, attempt)
          : _generateSimple(config, episode, index, seed + attempt, rng, attempt);

      if (result.success && result.level != null) {
        return result.level!;
      }
    }

    // FALLBACK PHASE: If original episode fails, try lower episodes as generators
    for (int fallbackEp = episode - 1; fallbackEp >= 1; fallbackEp--) {
      final fallbackConfig = EpisodeConfig.forEpisode(fallbackEp);
      // We still use current episode/index in metadata, but lower episode generation logic
      for (int attempt = 0; attempt < 50; attempt++) {
        final result = fallbackEp >= 3
            ? _generateBlueprint(fallbackConfig, episode, index, seed + 1000 + attempt, rng, attempt)
            : _generateSimple(fallbackConfig, episode, index, seed + 1000 + attempt, rng, attempt);
            
        if (result.success && result.level != null) {
          return result.level!;
        }
      }
    }

    // EMERGENCY FALLBACK: Episode 1 generator is extremely likely to succeed
    final e1Config = EpisodeConfig.forEpisode(1);
    for (int attempt = 0; attempt < 1000; attempt++) {
        final result = _generateSimple(e1Config, episode, index, seed + 5000 + attempt, rng, attempt);
        if (result.success && result.level != null) {
            return result.level!;
        }
    }

    // This part should technically never be reached given the simple generator's success rate
    throw Exception('CRITICAL: Level generator failed to produce a valid level for E$episode L$index after exhaustive search.');
  }

  /// Simple generation for E1-E2.
  GenerationAttempt _generateSimple(
    EpisodeConfig config, int episode, int index, int seed, Random rng, int attemptNumber,
  ) {
    final occupied = <String>{};

    final source = _placeSource(rng, occupied);
    occupied.add(_key(source.position));

    final targets = _placeTargetsSimple(rng, 1, occupied, source.position);
    if (targets.isEmpty) {
      return GenerationAttempt(success: false, rejectionReason: RejectionReason.noValidTargetPositions, attemptNumber: attemptNumber);
    }
    for (final t in targets) occupied.add(_key(t.position));

    final mirrorCount = config.getInRange(config.minCriticalMirrors, config.maxCriticalMirrors, rng.nextDouble());
    final mirrors = _placeMirrors(rng, mirrorCount, occupied);
    for (final m in mirrors) occupied.add(_key(m.position));

    final level = GeneratedLevel(
      seed: seed, episode: episode, index: index,
      source: source, targets: targets,
      walls: _placeDecorativeStructures(rng, occupied, config.minWalls), // Use decorative logic + min count
      mirrors: mirrors, prisms: [],
      meta: LevelMeta(optimalMoves: 0, difficultyBand: config.difficultyBand, generationAttempts: attemptNumber + 1),
      solution: [],
    );

    final initialState = GameState.fromLevel(level);
    final solution = _solver.solve(level, initialState, budget: config.validationBudget);

    if (!solution.solvable) {
      return GenerationAttempt(success: false, rejectionReason: RejectionReason.unsolvable, attemptNumber: attemptNumber);
    }

    if (solution.optimalMoves < config.minMoves || solution.optimalMoves > config.maxMoves) {
      return GenerationAttempt(success: false, rejectionReason: solution.optimalMoves < config.minMoves ? RejectionReason.tooEasy : RejectionReason.tooHard, attemptNumber: attemptNumber);
    }

    if (config.rejectTrivials && solution.optimalMoves <= 2) {
      return GenerationAttempt(success: false, rejectionReason: RejectionReason.trivialWin, attemptNumber: attemptNumber);
    }

    return GenerationAttempt(
      success: true,
      level: _updateMeta(level, solution.optimalMoves, solution.moves, config, attemptNumber),
      attemptNumber: attemptNumber,
    );
  }

  /// Blueprint-based generation for E3+.
  /// 
  /// Creates a deterministic planned solution without calling the full solver.
  GenerationAttempt _generateBlueprint(
    EpisodeConfig config, int episode, int index, int seed, Random rng, int attemptNumber,
  ) {
    // Build appropriate blueprint based on episode
    LevelBlueprint? blueprint;
    if (episode >= 5) {
      blueprint = _buildFourPhaseBlueprint(config, rng);  // E5: 4 targets, 2 prisms
    } else if (episode >= 4) {
      blueprint = _buildThreePhaseBlueprint(config, rng); // E4: 2 mixed targets
    } else {
      blueprint = _buildTwoPhaseBlueprint(config, rng);   // E3: 1 purple target
    }
    
    if (blueprint == null) {
      return GenerationAttempt(success: false, rejectionReason: RejectionReason.blueprintFailed, attemptNumber: attemptNumber);
    }

    // Create level from blueprint
    final level = GeneratedLevel(
      seed: seed, episode: episode, index: index,
      source: blueprint.source,
      targets: blueprint.targets,
      walls: blueprint.walls,
      mirrors: blueprint.mirrors,
      prisms: blueprint.prisms,
      meta: LevelMeta(
        optimalMoves: blueprint.totalPlannedMoves,
        difficultyBand: config.difficultyBand,
        generationAttempts: attemptNumber + 1,
      ),
      solution: blueprint.plannedMoves.expand((pm) => pm.toSolutionMoves()).toList(),
    );

    // VALIDATION PHASE 1: Simulate planned solution (fast)
    final validationResult = _validatePlannedSolution(level, blueprint.plannedMoves);
    if (!validationResult) {
      return GenerationAttempt(success: false, rejectionReason: RejectionReason.plannedSolutionFailed, attemptNumber: attemptNumber);
    }

    // VALIDATION PHASE 2: Bounded shortcut search (reject if solvable under minMoves)
    if (blueprint.totalPlannedMoves >= config.minMoves) {
      final initialState = GameState.fromLevel(level);
      final shortcutCheck = _solver.solveWithMaxDepth(
        level, initialState,
        maxDepth: config.minMoves - 1,
        budget: 5000,
      );
      if (shortcutCheck.solvable) {
        return GenerationAttempt(success: false, rejectionReason: RejectionReason.shortcutFound, attemptNumber: attemptNumber);
      }
    }

    return GenerationAttempt(success: true, level: level, attemptNumber: attemptNumber);
  }

  /// Build a two-phase mixing blueprint for purple target.
  /// 
  /// Phase A: Route Red to target (collect R)
  /// Phase B: Route Blue to target (collect B)
  LevelBlueprint? _buildTwoPhaseBlueprint(EpisodeConfig config, Random rng) {
    final occupied = <String>{};

    // 1. Place source (white light)
    final source = _placeSource(rng, occupied);
    occupied.add(_key(source.position));

    // 2. Place purple target
    final targetPos = _findValidPosition(rng, occupied, source.position, minDist: 5);
    if (targetPos == null) return null;
    final targets = [Target(position: targetPos, requiredColor: LightColor.purple)];
    occupied.add(_key(targetPos));

    // 3. Place splitter prism between source and target
    final prismPos = _findPositionBetween(source.position, targetPos, rng, occupied);
    if (prismPos == null) return null;
    
    // Prism needs orientation to split white into R/B/Y
    final prisms = [
      Prism(
        position: prismPos,
        orientation: 0, // Will be adjusted by planned moves
        rotatable: true,
        type: PrismType.splitter,
      ),
    ];
    occupied.add(_key(prismPos));

    // 4. Place two mirrors to route colors to target
    // Mirror 1: Routes Red path
    // Mirror 2: Routes Blue path
    final mirror1Pos = _findPositionNear(prismPos, rng, occupied, offset: 2);
    if (mirror1Pos == null) return null;
    occupied.add(_key(mirror1Pos));

    final mirror2Pos = _findPositionNear(prismPos, rng, occupied, offset: 3);
    if (mirror2Pos == null) return null;
    occupied.add(_key(mirror2Pos));

    // Calculate required taps for target move count
    final targetMoves = config.getInRange(config.minMoves, config.maxMoves, rng.nextDouble());
    
    // Distribute moves: prism rotation + mirror rotations
    // Each object can contribute 1-3 taps
    final prismTaps = (1 + rng.nextInt(3)).clamp(1, targetMoves ~/ 3);
    final remainingAfterPrism = targetMoves - prismTaps;
    final mirror1Taps = (1 + rng.nextInt(3)).clamp(1, remainingAfterPrism ~/ 2);
    final mirror2Taps = remainingAfterPrism - mirror1Taps;

    // Set initial orientations offset from "solved"
    // Solved orientation is 0 for simplicity
    final prismInitialOri = (4 - prismTaps) % 4;
    final mirror1InitialOri = (4 - mirror1Taps) % 4;
    final mirror2InitialOri = (4 - mirror2Taps) % 4;

    final mirrors = [
      Mirror(position: mirror1Pos, orientation: MirrorOrientationExtension.fromInt(mirror1InitialOri), rotatable: true),
      Mirror(position: mirror2Pos, orientation: MirrorOrientationExtension.fromInt(mirror2InitialOri), rotatable: true),
    ];

    // Update prisms with initial orientation
    final finalPrisms = [
      Prism(position: prismPos, orientation: prismInitialOri, rotatable: true, type: PrismType.splitter),
    ];

    // Build planned moves
    final plannedMoves = <PlannedMove>[
      if (prismTaps > 0) PlannedMove(type: MoveType.rotatePrism, objectIndex: 0, taps: prismTaps),
      if (mirror1Taps > 0) PlannedMove(type: MoveType.rotateMirror, objectIndex: 0, taps: mirror1Taps),
      if (mirror2Taps > 0) PlannedMove(type: MoveType.rotateMirror, objectIndex: 1, taps: mirror2Taps),
    ];

    final totalMoves = prismTaps + mirror1Taps + mirror2Taps;

    // Add walls specifically for E3 using config
    final walls = _placeWallsForProtection(rng, occupied, config.getInRange(config.minWalls, config.maxWalls, rng.nextDouble()));

    return LevelBlueprint(
      source: source,
      targets: targets,
      mirrors: mirrors,
      prisms: finalPrisms,
      walls: walls,
      plannedMoves: plannedMoves,
      totalPlannedMoves: totalMoves,
    );
  }

  /// Build a blueprint for Episode 4+.
  /// 
  /// Extends E3 pattern with two mixed targets (Purple + Green).
  /// Uses same random placement + validation approach but with more objects.
  LevelBlueprint? _buildThreePhaseBlueprint(EpisodeConfig config, Random rng) {
    final occupied = <String>{};

    // 1. Place source (white light)
    final source = _placeSource(rng, occupied);
    occupied.add(_key(source.position));

    // 2. Place splitter prism in front of source
    final prismPos = _findPositionInDirection(source.position, source.direction, rng, 3, 6);
    if (prismPos == null) return null;
    occupied.add(_key(prismPos));

    // 3. Place two mixed targets
    final target1Pos = _findValidPosition(rng, occupied, prismPos, minDist: 3);
    if (target1Pos == null) return null;
    occupied.add(_key(target1Pos));

    final target2Pos = _findValidPosition(rng, occupied, prismPos, minDist: 3);
    if (target2Pos == null) return null;
    occupied.add(_key(target2Pos));

    final targets = [
      Target(position: target1Pos, requiredColor: LightColor.purple), // R+B
      Target(position: target2Pos, requiredColor: LightColor.green),  // B+Y
    ];

    // 4. Place 4 mirrors for routing
    final mirrors = <Mirror>[];
    for (int i = 0; i < 4; i++) {
      final mirrorPos = _findValidPosition(rng, occupied, prismPos, minDist: 2);
      if (mirrorPos == null && mirrors.length < 2) return null;
      if (mirrorPos != null) {
        occupied.add(_key(mirrorPos));
        mirrors.add(Mirror(position: mirrorPos, orientation: MirrorOrientationExtension.fromInt(rng.nextInt(4)), rotatable: true));
      }
    }
    if (mirrors.length < 2) return null;

    // 5. Calculate taps for target move count (16-26)
    final targetMoves = config.getInRange(config.minMoves, config.maxMoves, rng.nextDouble());
    
    // Distribute across 1 splitter + mirrors
    final objectCount = 1 + mirrors.length;
    final splitterTaps = (targetMoves / objectCount).ceil().clamp(1, 4);
    var remaining = targetMoves - splitterTaps;
    
    final mirrorTaps = <int>[];
    for (int i = 0; i < mirrors.length; i++) {
      final taps = i == mirrors.length - 1 
          ? remaining 
          : (remaining / (mirrors.length - i)).ceil().clamp(1, 4);
      mirrorTaps.add(taps);
      remaining -= taps;
    }

    // Set initial orientations (offset from random starting point)
    final prisms = [
      Prism(position: prismPos, orientation: (4 - splitterTaps) % 4, rotatable: true, type: PrismType.splitter),
    ];

    final updatedMirrors = <Mirror>[];
    for (int i = 0; i < mirrors.length; i++) {
      final oriIndex = mirrors[i].orientation.index;
      updatedMirrors.add(mirrors[i].copyWith(
        orientation: MirrorOrientationExtension.fromInt((oriIndex - mirrorTaps[i] + 4) % 4),
      ));
    }

    // Build planned moves
    final plannedMoves = <PlannedMove>[
      if (splitterTaps > 0) PlannedMove(type: MoveType.rotatePrism, objectIndex: 0, taps: splitterTaps),
      for (int i = 0; i < mirrorTaps.length; i++)
        if (mirrorTaps[i] > 0) PlannedMove(type: MoveType.rotateMirror, objectIndex: i, taps: mirrorTaps[i]),
    ];

    final totalMoves = splitterTaps + mirrorTaps.fold<int>(0, (a, b) => a + b);

    return LevelBlueprint(
      source: source,
      targets: targets,
      mirrors: updatedMirrors,
      prisms: prisms,
      walls: _placeWallsForProtection(rng, occupied, config.getInRange(config.minWalls, config.maxWalls, rng.nextDouble())),
      plannedMoves: plannedMoves,
      totalPlannedMoves: totalMoves,
    );
  }

  /// Build a blueprint for Episode 5.
  /// 
  /// Simplified: 3 targets (1 mixed + 2 base), 1 splitter, 5-6 mirrors
  /// Higher acceptance by reducing complexity relative to E4
  LevelBlueprint? _buildFourPhaseBlueprint(EpisodeConfig config, Random rng) {
    final occupied = <String>{};

    // 1. Place source (white light)
    final source = _placeSource(rng, occupied);
    occupied.add(_key(source.position));

    // 2. Place splitter prism in front of source
    final splitterPos = _findPositionInDirection(source.position, source.direction, rng, 2, 5);
    if (splitterPos == null) return null;
    occupied.add(_key(splitterPos));

    // 3. Place 3 targets with relaxed constraints
    final targetPositions = <GridPosition>[];
    for (int i = 0; i < 3; i++) {
      final pos = _findValidPosition(rng, occupied, splitterPos, minDist: 2);
      if (pos == null) return null;
      occupied.add(_key(pos));
      targetPositions.add(pos);
    }

    // 1 mixed + 2 base targets
    final targets = [
      Target(position: targetPositions[0], requiredColor: LightColor.purple), // R+B
      Target(position: targetPositions[1], requiredColor: LightColor.red),    // R
      Target(position: targetPositions[2], requiredColor: LightColor.blue),   // B
    ];

    // 4. Place 5-6 mirrors for routing
    final mirrors = <Mirror>[];
    for (int i = 0; i < 6; i++) {
      final pos = _findValidPosition(rng, occupied, splitterPos, minDist: 1);
      if (pos != null) {
        occupied.add(_key(pos));
        mirrors.add(Mirror(position: pos, orientation: MirrorOrientationExtension.fromInt(rng.nextInt(4)), rotatable: true));
      }
    }
    if (mirrors.length < 4) return null;

    // 5. Place 2 decoys
    final decoys = <Mirror>[];
    for (int i = 0; i < 2; i++) {
      final pos = _findValidPosition(rng, occupied, splitterPos, minDist: 3);
      if (pos != null) {
        occupied.add(_key(pos));
        decoys.add(Mirror(position: pos, orientation: MirrorOrientationExtension.fromInt(rng.nextInt(4)), rotatable: true));
      }
    }

    // 6. Calculate taps for target move count (22-35)
    final targetMoves = config.getInRange(config.minMoves, config.maxMoves, rng.nextDouble());
    
    // Distribute across 1 prism + mirrors
    final objectCount = 1 + mirrors.length;
    final splitterTaps = (targetMoves / objectCount).ceil().clamp(1, 4);
    var remaining = targetMoves - splitterTaps;
    
    final mirrorTaps = <int>[];
    for (int i = 0; i < mirrors.length; i++) {
      final taps = i == mirrors.length - 1 
          ? remaining.clamp(1, 6)
          : (remaining / (mirrors.length - i)).ceil().clamp(1, 5);
      mirrorTaps.add(taps);
      remaining -= taps;
    }

    // Set initial orientations (offset from random starting point)
    final prisms = [
      Prism(position: splitterPos, orientation: (4 - splitterTaps) % 4, rotatable: true, type: PrismType.splitter),
    ];

    final updatedMirrors = <Mirror>[];
    for (int i = 0; i < mirrors.length; i++) {
      final oriIndex = mirrors[i].orientation.index;
      updatedMirrors.add(mirrors[i].copyWith(
        orientation: MirrorOrientationExtension.fromInt((oriIndex - mirrorTaps[i] + 4) % 4),
      ));
    }

    // Add decoys to mirror list
    updatedMirrors.addAll(decoys);

    // Build planned moves
    final plannedMoves = <PlannedMove>[
      if (splitterTaps > 0) PlannedMove(type: MoveType.rotatePrism, objectIndex: 0, taps: splitterTaps),
      for (int i = 0; i < mirrorTaps.length; i++)
        if (mirrorTaps[i] > 0) PlannedMove(type: MoveType.rotateMirror, objectIndex: i, taps: mirrorTaps[i]),
    ];

    final totalMoves = splitterTaps + mirrorTaps.fold<int>(0, (a, b) => a + b);

    // Add walls using full config range
    final walls = _placeWallsForProtection(rng, occupied, config.getInRange(config.minWalls, config.maxWalls, rng.nextDouble()));

    return LevelBlueprint(
      source: source,
      targets: targets,
      mirrors: updatedMirrors,
      prisms: prisms,
      walls: walls,
      plannedMoves: plannedMoves,
      totalPlannedMoves: totalMoves,
    );
  }

  /// Place walls to protect corridor and block 1-turn shortcuts.
  Set<Wall> _placeWallsForProtection(Random rng, Set<String> occupied, int count) {
    final walls = <Wall>{};
    
    for (int attempts = 0; attempts < count * 10 && walls.length < count; attempts++) {
      final x = 1 + rng.nextInt(GridPosition.gridWidth - 2);
      final y = 1 + rng.nextInt(GridPosition.gridHeight - 2);
      final key = '$x,$y';
      
      if (!occupied.contains(key)) {
        walls.add(Wall(position: GridPosition(x, y)));
        occupied.add(key);
      }
    }
    
    return walls;
  }

  /// Place decorative structures (L, T, Box shapes) to fill empty space.
  /// 
  /// This creates a more "constructed" feel rather than random noise.
  Set<Wall> _placeDecorativeStructures(Random rng, Set<String> occupied, int minCount) {
    final walls = <Wall>{};
    
    // Structure templates (relative coordinates)
    const shapes = [
      [Point(0,0), Point(1,0), Point(0,1)], // L-Shape small
      [Point(0,0), Point(1,0), Point(1,1), Point(0,1)], // Box 2x2
      [Point(0,0), Point(1,0), Point(2,0)], // Line 3
      [Point(1,0), Point(0,1), Point(1,1), Point(2,1)], // T-Shape
      [Point(0,0), Point(0,1), Point(0,2), Point(1,2)], // L-Shape long
    ];
    
    // Try to place shapes first
    for (int attempts = 0; attempts < 20; attempts++) {
      final shape = shapes[rng.nextInt(shapes.length)];
      final originX = 2 + rng.nextInt(GridPosition.gridWidth - 5);
      final originY = 2 + rng.nextInt(GridPosition.gridHeight - 5);
      
      bool canPlace = true;
      for (final p in shape) {
        final key = '${originX + p.x},${originY + p.y}';
        if (occupied.contains(key)) {
          canPlace = false;
          break;
        }
      }
      
      if (canPlace) {
        for (final p in shape) {
          final pos = GridPosition(originX + p.x, originY + p.y);
          if (!walls.any((w) => w.position == pos)) { // Avoid dupes
             walls.add(Wall(position: pos));
             occupied.add('${pos.x},${pos.y}');
          }
        }
      }
    }
    
    // Fill remaining quota with random/smart walls if needed
    if (walls.length < minCount) {
       walls.addAll(_placeWallsForProtection(rng, occupied, minCount - walls.length));
    }
    
    return walls;
  }

  /// Find a position in a given direction from start.
  GridPosition? _findPositionInDirection(GridPosition start, Direction dir, Random rng, int minDist, int maxDist) {
    for (int attempts = 0; attempts < 20; attempts++) {
      final dist = minDist + rng.nextInt(maxDist - minDist + 1);
      final x = start.x + dir.dx * dist;
      final y = start.y + dir.dy * dist;
      final pos = GridPosition(x, y);
      if (pos.isValid && !pos.isOnEdge) {
        return pos;
      }
    }
    return null;
  }

  /// Validate planned solution by simulation.
  bool _validatePlannedSolution(GeneratedLevel level, List<PlannedMove> plannedMoves) {
    return validatePlannedSolutionStatic(level, plannedMoves, _rayTracer);
  }
  
  /// Public static method for external validation of planned solution.
  /// 
  /// Applies the planned moves to the level state and checks if all targets
  /// are satisfied. This is the 100% solvability guarantee mechanism.
  static bool validatePlannedSolutionStatic(
    GeneratedLevel level, 
    List<PlannedMove> plannedMoves, 
    [RayTracer? tracer]
  ) {
    final rayTracer = tracer ?? RayTracer();
    var state = GameState.fromLevel(level);

    // Initial trace
    state = rayTracer.traceAndUpdateProgress(level, state);

    // Apply each planned move
    for (final pm in plannedMoves) {
      for (int i = 0; i < pm.taps; i++) {
        if (pm.type == MoveType.rotateMirror) {
          state = state.rotateMirror(pm.objectIndex);
        } else {
          state = state.rotatePrism(pm.objectIndex);
        }
        // Trace and update after each rotation
        state = rayTracer.traceAndUpdateProgress(level, state);
      }
    }

    // Check if solved
    return state.allTargetsSatisfied(level.targets);
  }
  
  /// Public method to validate a GeneratedLevel via its stored solution.
  /// 
  /// Converts stored SolutionMoves back to PlannedMoves and validates.
  static bool validateLevelSolution(GeneratedLevel level) {
    if (level.solution.isEmpty) return false;
    
    // Convert SolutionMoves to PlannedMoves (group by object)
    final plannedMoves = <PlannedMove>[];
    for (final move in level.solution) {
      plannedMoves.add(PlannedMove(
        type: move.type,
        objectIndex: move.objectIndex,
        taps: move.taps,
      ));
    }
    
    return validatePlannedSolutionStatic(level, plannedMoves);
  }
  
  /// Validate both occupancy and solvability for a level.
  /// 
  /// Returns true only if level passes both checks.
  static bool validateLevelComplete(GeneratedLevel level) {
    // Check occupancy
    final occupancyResult = OccupancyGrid.validateLevel(level);
    if (!occupancyResult.valid) {
      return false;
    }
    
    // Check solvability
    return validateLevelSolution(level);
  }

  GeneratedLevel _updateMeta(GeneratedLevel level, int moves, List<SolutionMove> solution, EpisodeConfig config, int attempt) {
    return GeneratedLevel(
      seed: level.seed, episode: level.episode, index: level.index,
      source: level.source, targets: level.targets, walls: level.walls,
      mirrors: level.mirrors, prisms: level.prisms,
      meta: LevelMeta(
        optimalMoves: moves,
        difficultyBand: config.difficultyBand,
        generationAttempts: attempt + 1,
      ),
      solution: solution,
    );
  }

  // Helper methods
  String _key(GridPosition pos) => '${pos.x},${pos.y}';

  Source _placeSource(Random rng, Set<String> occupied) {
    final edge = rng.nextInt(4);
    int x, y;
    Direction dir;
    switch (edge) {
      case 0: x = 2 + rng.nextInt(GridPosition.gridWidth - 4); y = 0; dir = Direction.south; break;
      case 1: x = GridPosition.gridWidth - 1; y = 2 + rng.nextInt(GridPosition.gridHeight - 4); dir = Direction.west; break;
      case 2: x = 2 + rng.nextInt(GridPosition.gridWidth - 4); y = GridPosition.gridHeight - 1; dir = Direction.north; break;
      default: x = 0; y = 2 + rng.nextInt(GridPosition.gridHeight - 4); dir = Direction.east;
    }
    return Source(position: GridPosition(x, y), direction: dir, color: LightColor.white);
  }

  List<Target> _placeTargetsSimple(Random rng, int count, Set<String> occupied, GridPosition sourcePos) {
    final targets = <Target>[];
    for (int attempts = 0; attempts < 50 && targets.length < count; attempts++) {
      final x = 2 + rng.nextInt(GridPosition.gridWidth - 4);
      final y = 2 + rng.nextInt(GridPosition.gridHeight - 4);
      final pos = GridPosition(x, y);
      if (occupied.contains(_key(pos)) || pos.distanceTo(sourcePos) < 4) continue;
      targets.add(Target(position: pos, requiredColor: LightColor.white));
      occupied.add(_key(pos));
    }
    return targets;
  }

  GridPosition? _findValidPosition(Random rng, Set<String> occupied, GridPosition sourcePos, {int minDist = 4}) {
    for (int attempts = 0; attempts < 50; attempts++) {
      final x = 2 + rng.nextInt(GridPosition.gridWidth - 4);
      final y = 2 + rng.nextInt(GridPosition.gridHeight - 4);
      final pos = GridPosition(x, y);
      if (!occupied.contains(_key(pos)) && pos.distanceTo(sourcePos) >= minDist) {
        return pos;
      }
    }
    return null;
  }

  GridPosition? _findPositionBetween(GridPosition a, GridPosition b, Random rng, Set<String> occupied) {
    // Find a position roughly between a and b
    final midX = (a.x + b.x) ~/ 2;
    final midY = (a.y + b.y) ~/ 2;
    
    for (int attempts = 0; attempts < 30; attempts++) {
      final x = (midX + rng.nextInt(5) - 2).clamp(1, GridPosition.gridWidth - 2);
      final y = (midY + rng.nextInt(5) - 2).clamp(1, GridPosition.gridHeight - 2);
      final pos = GridPosition(x, y);
      if (!occupied.contains(_key(pos))) {
        return pos;
      }
    }
    return null;
  }

  GridPosition? _findPositionNear(GridPosition center, Random rng, Set<String> occupied, {int offset = 2}) {
    for (int attempts = 0; attempts < 30; attempts++) {
      final dx = rng.nextInt(offset * 2 + 1) - offset;
      final dy = rng.nextInt(offset * 2 + 1) - offset;
      if (dx == 0 && dy == 0) continue;
      
      final x = (center.x + dx).clamp(1, GridPosition.gridWidth - 2);
      final y = (center.y + dy).clamp(1, GridPosition.gridHeight - 2);
      final pos = GridPosition(x, y);
      if (!occupied.contains(_key(pos))) {
        return pos;
      }
    }
    return null;
  }

  List<Mirror> _placeMirrors(Random rng, int count, Set<String> occupied) {
    final mirrors = <Mirror>[];
    for (int attempts = 0; attempts < 200 && mirrors.length < count; attempts++) {
      final x = 1 + rng.nextInt(GridPosition.gridWidth - 2);
      final y = 1 + rng.nextInt(GridPosition.gridHeight - 2);
      if (occupied.contains('$x,$y')) continue;
      mirrors.add(Mirror(
        position: GridPosition(x, y),
        orientation: MirrorOrientationExtension.fromInt(rng.nextInt(4)),
        rotatable: true,
      ));
      occupied.add('$x,$y');
    }
    return mirrors;
  }

  /// Generate a batch of levels.
  List<GeneratedLevel> generateBatch({required int episode, required int count, int startSeed = 0}) {
    final levels = <GeneratedLevel>[];
    for (int i = 0; i < count; i++) {
      final level = generate(episode, i + 1, startSeed + i);
      if (level != null) levels.add(level);
    }
    return levels;
  }
}

/// Extension for Mirror.copyWith
extension MirrorCopyWith on Mirror {
  Mirror copyWith({
    GridPosition? position,
    MirrorOrientation? orientation,
    bool? rotatable,
  }) {
    return Mirror(
      position: position ?? this.position,
      orientation: orientation ?? this.orientation,
      rotatable: rotatable ?? this.rotatable,
    );
  }
}

