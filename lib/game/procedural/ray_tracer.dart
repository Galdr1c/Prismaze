/// Deterministic cell-based ray tracer.
///
/// This ray tracer operates on discrete grid cells and directions.
/// No floating-point geometry - pure table lookups and cell stepping.
library;

import 'models/models.dart';
import 'tables/tables.dart';

/// A single ray being traced.
class Ray {
  final int x;
  final int y;
  final Direction direction;
  final LightColor color;
  final bool isSecondary;

  const Ray(this.x, this.y, this.direction, this.color, {this.isSecondary = false});

  /// Unique key for loop detection.
  String get key => '$x,$y,${direction.index},${color.index},$isSecondary';

  /// Step to the next cell.
  Ray step() {
    return Ray(
      x + direction.dx,
      y + direction.dy,
      direction,
      color,
      isSecondary: isSecondary,
    );
  }

  /// Create a ray with a new direction.
  Ray withDirection(Direction newDir) {
    return Ray(x, y, newDir, color, isSecondary: isSecondary);
  }

  /// Create a ray with a new color.
  Ray withColor(LightColor newColor) {
    return Ray(x, y, direction, newColor, isSecondary: isSecondary);
  }

  @override
  String toString() => 'Ray($x,$y,$direction,$color,sec=$isSecondary)';
}

/// A segment of a ray path for rendering.
class RaySegment {
  final int startX, startY;
  final int endX, endY;
  final LightColor color;
  final bool isSecondary;

  const RaySegment({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    this.isSecondary = false,
  });

  @override
  String toString() =>
      'RaySegment(($startX,$startY)->($endX,$endY), $color, sec=$isSecondary)';
}

/// Result of tracing rays through a level.
class TraceResult {
  /// All ray segments for rendering.
  final List<RaySegment> segments;

  /// Colors arriving at each target (by target index).
  /// Used for target satisfaction checking.
  final Map<int, Set<LightColor>> targetArrivals;

  /// Per-target arrival masks (bitmask of color components).
  /// Used for stateful color mixing.
  final Map<int, int> arrivalMasks;

  /// Whether all targets are satisfied (instant check, not stateful).
  final bool allTargetsSatisfied;

  /// Number of rays traced.
  final int rayCount;

  /// Number of steps taken.
  final int stepCount;

  const TraceResult({
    required this.segments,
    required this.targetArrivals,
    required this.arrivalMasks,
    required this.allTargetsSatisfied,
    required this.rayCount,
    required this.stepCount,
  });
}

/// Deterministic ray tracer for procedural levels.
class RayTracer {
  /// Maximum steps per ray (prevents infinite loops).
  static const int maxStepsPerRay = 500;

  /// Maximum total rays (prevents explosion from prism splits).
  static const int maxTotalRays = 32;

  /// Maximum total steps across all rays.
  static const int maxTotalSteps = 2000;

  /// Trace rays through a level with the given state.
  TraceResult trace(GeneratedLevel level, GameState state) {
    final segments = <RaySegment>[];
    final targetArrivals = <int, Set<LightColor>>{};

    // Initialize target arrivals
    for (int i = 0; i < level.targets.length; i++) {
      targetArrivals[i] = {};
    }

    // Build lookup maps for fast access
    final wallSet = <String>{};
    for (final wall in level.walls) {
      wallSet.add('${wall.position.x},${wall.position.y}');
    }

    final mirrorMap = <String, int>{};
    for (int i = 0; i < level.mirrors.length; i++) {
      final pos = level.mirrors[i].position;
      mirrorMap['${pos.x},${pos.y}'] = i;
    }

    final prismMap = <String, int>{};
    for (int i = 0; i < level.prisms.length; i++) {
      final pos = level.prisms[i].position;
      prismMap['${pos.x},${pos.y}'] = i;
    }

    final targetMap = <String, int>{};
    for (int i = 0; i < level.targets.length; i++) {
      final pos = level.targets[i].position;
      targetMap['${pos.x},${pos.y}'] = i;
    }

    // Ray queue for BFS-style tracing
    final rayQueue = <Ray>[];
    final visited = <String>{};
    int totalRays = 0;
    int totalSteps = 0;

    // Start with source ray
    rayQueue.add(Ray(
      level.source.position.x,
      level.source.position.y,
      level.source.direction,
      level.source.color,
      isSecondary: false,
    ));

    while (rayQueue.isNotEmpty && totalRays < maxTotalRays) {
      final ray = rayQueue.removeAt(0);
      totalRays++;

      // Trace this ray
      var currentRay = ray;
      int raySteps = 0;
      int segmentStartX = currentRay.x;
      int segmentStartY = currentRay.y;

      while (raySteps < maxStepsPerRay && totalSteps < maxTotalSteps) {
        // Step to next cell
        currentRay = currentRay.step();
        raySteps++;
        totalSteps++;

        final cellKey = '${currentRay.x},${currentRay.y}';

        // Check bounds
        if (!_isInBounds(currentRay.x, currentRay.y)) {
          // Ray exits grid - add final segment
          segments.add(RaySegment(
            startX: segmentStartX,
            startY: segmentStartY,
            endX: currentRay.x,
            endY: currentRay.y,
            color: currentRay.color,
            isSecondary: currentRay.isSecondary,
          ));
          break;
        }

        // Check wall collision
        if (wallSet.contains(cellKey)) {
          // Ray stops at wall - add segment up to wall
          segments.add(RaySegment(
            startX: segmentStartX,
            startY: segmentStartY,
            endX: currentRay.x,
            endY: currentRay.y,
            color: currentRay.color,
            isSecondary: currentRay.isSecondary,
          ));
          break;
        }

        // Check loop detection
        if (visited.contains(currentRay.key)) {
          // Loop detected - terminate this ray
          segments.add(RaySegment(
            startX: segmentStartX,
            startY: segmentStartY,
            endX: currentRay.x,
            endY: currentRay.y,
            color: currentRay.color,
            isSecondary: currentRay.isSecondary,
          ));
          break;
        }
        visited.add(currentRay.key);

        // Check target hit (ray continues through)
        if (targetMap.containsKey(cellKey)) {
          final targetIdx = targetMap[cellKey]!;
          targetArrivals[targetIdx]!.add(currentRay.color);
          // Ray continues through target
        }

        // Check mirror interaction
        if (mirrorMap.containsKey(cellKey)) {
          final mirrorIdx = mirrorMap[cellKey]!;
          final mirrorOri = state.getMirrorOrientation(mirrorIdx);
          final reflected = reflectRay(currentRay.direction, mirrorOri);

          if (reflected != null) {
            // Ray reflects - add segment and start new one
            segments.add(RaySegment(
              startX: segmentStartX,
              startY: segmentStartY,
              endX: currentRay.x,
              endY: currentRay.y,
              color: currentRay.color,
              isSecondary: currentRay.isSecondary,
            ));
            segmentStartX = currentRay.x;
            segmentStartY = currentRay.y;
            currentRay = currentRay.withDirection(reflected);
          }
          // If reflected is null, ray passes through
          continue;
        }

        // Check prism interaction
        if (prismMap.containsKey(cellKey)) {
          final prismIdx = prismMap[cellKey]!;
          final prism = level.prisms[prismIdx];
          final prismOri = state.getPrismOrientation(prismIdx);

          final outputs = applyPrism(
            currentRay.direction,
            currentRay.color,
            prismOri,
            prism.type,
          );

          // Add segment up to prism
          segments.add(RaySegment(
            startX: segmentStartX,
            startY: segmentStartY,
            endX: currentRay.x,
            endY: currentRay.y,
            color: currentRay.color,
            isSecondary: currentRay.isSecondary,
          ));

          // Determine if outputs should be secondary (Splitter logic)
          // If 3 outputs (white split), mark them secondary.
          // If 1 output (deflector or pass-through), inherit.
          // ALSO: If input was already secondary, outputs stay secondary.
          final bool makeSecondary = currentRay.isSecondary || (outputs.length > 1);

          // Queue output rays (skip first, continue with it)
          bool first = true;
          for (final output in outputs) {
            final newRay = Ray(
              currentRay.x,
              currentRay.y,
              output.direction,
              output.color,
              isSecondary: makeSecondary,
            );
            if (first) {
              // Continue current trace with first output
              currentRay = newRay;
              segmentStartX = currentRay.x;
              segmentStartY = currentRay.y;
              first = false;
            } else {
              // Queue additional rays
              rayQueue.add(newRay);
            }
          }
          continue;
        }
      }
    }

    // Check target satisfaction (instant, not stateful)
    final allSatisfied = _checkAllTargets(level, targetArrivals);

    // Compute arrival masks from arrival colors
    final arrivalMasks = <int, int>{};
    for (final entry in targetArrivals.entries) {
      arrivalMasks[entry.key] = ColorMask.fromColors(entry.value);
    }

    return TraceResult(
      segments: segments,
      targetArrivals: targetArrivals,
      arrivalMasks: arrivalMasks,
      allTargetsSatisfied: allSatisfied,
      rayCount: totalRays,
      stepCount: totalSteps,
    );
  }

  /// Check if a position is within grid bounds.
  bool _isInBounds(int x, int y) {
    return x >= 0 &&
        x < GridPosition.gridWidth &&
        y >= 0 &&
        y < GridPosition.gridHeight;
  }

  /// Check if all targets are satisfied.
  bool _checkAllTargets(
    GeneratedLevel level,
    Map<int, Set<LightColor>> arrivals,
  ) {
    for (int i = 0; i < level.targets.length; i++) {
      final target = level.targets[i];
      final arriving = arrivals[i] ?? {};

      if (!ColorMixer.satisfiesTarget(arriving, target.requiredColor)) {
        return false;
      }
    }
    return true;
  }

  /// Quick check if a level is solved with the given state (instant check).
  bool isSolved(GeneratedLevel level, GameState state) {
    return trace(level, state).allTargetsSatisfied;
  }

  /// Check if level is solved using stateful progress in GameState.
  /// This is the proper check for games with color accumulation.
  bool isSolvedStateful(GeneratedLevel level, GameState state) {
    return state.allTargetsSatisfied(level.targets);
  }

  /// Trace and update state with new arrivals (stateful mixing).
  /// Returns the new state with updated targetCollected.
  GameState traceAndUpdateProgress(
    GeneratedLevel level,
    GameState state,
  ) {
    final result = trace(level, state);
    return state.withTargetProgress(level.targets, result.arrivalMasks);
  }
}

