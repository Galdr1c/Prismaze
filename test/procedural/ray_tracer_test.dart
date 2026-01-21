import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/models/models.dart';
import 'package:prismaze/game/procedural/ray_tracer.dart';

void main() {
  group('RayTracer', () {
    late RayTracer rayTracer;

    setUp(() {
      rayTracer = RayTracer();
    });

    test('traces straight line when no obstacles', () {
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(10, 4))],
        walls: const {},
        mirrors: const [],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = rayTracer.trace(level, state);

      expect(result.segments.isNotEmpty, true);
      expect(result.allTargetsSatisfied, true);
      expect(result.targetArrivals[0]!.contains(LightColor.white), true);
    });

    test('ray stops at wall', () {
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(10, 4))],
        walls: {const Wall(position: GridPosition(5, 4))},
        mirrors: const [],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = rayTracer.trace(level, state);

      // Target should not be reached
      expect(result.allTargetsSatisfied, false);
    });

    test('ray reflects off slash mirror', () {
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(5, 0))],
        walls: const {},
        mirrors: const [
          Mirror(
            position: GridPosition(5, 4),
            orientation: MirrorOrientation.slash,
            rotatable: false,
          ),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = rayTracer.trace(level, state);

      // Ray should hit mirror at (5,4), reflect north, hit target at (5,0)
      expect(result.allTargetsSatisfied, true);
      expect(result.segments.length, greaterThan(1)); // At least 2 segments
    });

    test('ray reflects off backslash mirror', () {
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(5, 8))],
        walls: const {},
        mirrors: const [
          Mirror(
            position: GridPosition(5, 4),
            orientation: MirrorOrientation.backslash,
            rotatable: false,
          ),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = rayTracer.trace(level, state);

      // Ray should hit mirror at (5,4), reflect south, hit target at (5,8)
      expect(result.allTargetsSatisfied, true);
    });

    test('color is tracked correctly', () {
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
          color: LightColor.red,
        ),
        targets: const [Target(position: GridPosition(10, 4), requiredColor: LightColor.red)],
        walls: const {},
        mirrors: const [],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = rayTracer.trace(level, state);

      expect(result.allTargetsSatisfied, true);
      expect(result.targetArrivals[0]!.contains(LightColor.red), true);
    });

    test('wrong color does not satisfy target', () {
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
          color: LightColor.red,
        ),
        targets: const [Target(position: GridPosition(10, 4), requiredColor: LightColor.blue)],
        walls: const {},
        mirrors: const [],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = rayTracer.trace(level, state);

      expect(result.allTargetsSatisfied, false);
    });

    test('loop detection prevents infinite loops', () {
      // Create a level that could cause infinite loops without detection
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(5, 4),
          direction: Direction.east,
        ),
        targets: const [],
        walls: const {},
        mirrors: const [
          // Create a square loop: all corners have mirrors
          Mirror(position: GridPosition(8, 4), orientation: MirrorOrientation.backslash),
          Mirror(position: GridPosition(8, 7), orientation: MirrorOrientation.slash),
          Mirror(position: GridPosition(2, 7), orientation: MirrorOrientation.backslash),
          Mirror(position: GridPosition(2, 4), orientation: MirrorOrientation.slash),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      
      // Should complete without hanging
      final result = rayTracer.trace(level, state);
      
      // Should have segments but terminate due to loop detection
      expect(result.stepCount, lessThan(RayTracer.maxTotalSteps));
    });

    test('isSolved convenience method works', () {
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(10, 4))],
        walls: const {},
        mirrors: const [],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      expect(rayTracer.isSolved(level, state), true);
    });
  });
}
