import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/models/models.dart';
import 'package:prismaze/game/procedural/solver.dart';

void main() {
  group('Solver', () {
    late Solver solver;

    setUp(() {
      solver = Solver();
    });

    test('returns already solved for trivial levels', () {
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
      final result = solver.solve(level, state);

      expect(result.solvable, true);
      expect(result.optimalMoves, 0);
      expect(result.moves, isEmpty);
    });

    test('finds 1-move solution', () {
      // Source shoots east, target is at (5, 0)
      // Mirror at (5, 4) needs to be in slash orientation to reflect north
      // Start mirror in wrong orientation, should need 1 rotation
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
            orientation: MirrorOrientation.horizontal, // Wrong orientation
            rotatable: true,
          ),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 1, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = solver.solve(level, state);

      expect(result.solvable, true);
      expect(result.optimalMoves, 1);
      expect(result.moves.length, 1);
      expect(result.moves.first.type, MoveType.rotateMirror);
      expect(result.moves.first.objectIndex, 0);
    });

    test('finds multi-move solution', () {
      // Create a puzzle requiring 2 mirror rotations
      // Ray: East from (0,4) -> Mirror1 at (5,4) reflects North -> Mirror2 at (5,1) reflects East -> Target at (10,1)
      // Mirror1 needs slash orientation (1)
      // Mirror2 needs backslash orientation (3)
      // Starting with horizontal (0), we need 1 rotation for Mirror1 and 3 for Mirror2
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(10, 1))],
        walls: const {},
        mirrors: const [
          Mirror(
            position: GridPosition(5, 4),
            orientation: MirrorOrientation.horizontal, // Needs slash (1 rotation)
            rotatable: true,
          ),
          Mirror(
            position: GridPosition(5, 1),
            orientation: MirrorOrientation.horizontal, // Needs backslash (3 rotations)
            rotatable: true,
          ),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 4, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = solver.solve(level, state);

      expect(result.solvable, true);
      expect(result.optimalMoves, greaterThan(0));
    });

    test('returns unsolvable when no rotatable objects', () {
      final level = GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(5, 0))], // Need to go north
        walls: const {},
        mirrors: const [
          Mirror(
            position: GridPosition(5, 4),
            orientation: MirrorOrientation.horizontal, // Wrong orientation, but fixed
            rotatable: false,
          ),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 0, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = solver.solve(level, state);

      expect(result.solvable, false);
    });

    test('respects budget limit', () {
      // Create a complex level that would exceed a small budget
      final mirrors = <Mirror>[];
      for (int i = 0; i < 10; i++) {
        mirrors.add(Mirror(
          position: GridPosition(2 + i * 2, 4),
          orientation: MirrorOrientation.horizontal,
          rotatable: true,
        ));
      }

      final level = GeneratedLevel(
        seed: 0,
        episode: 5,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(21, 0))],
        walls: const {},
        mirrors: mirrors,
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 20, difficultyBand: DifficultyBand.expert),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      final result = solver.solve(level, state, budget: 100);

      // Should either find solution or hit budget
      if (!result.solvable) {
        expect(result.budgetExceeded, true);
      }
      expect(result.statesExplored, lessThanOrEqualTo(100));
    });

    test('A* finds same solution as BFS', () {
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
            orientation: MirrorOrientation.horizontal,
            rotatable: true,
          ),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 1, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      );

      final state = GameState.fromLevel(level);
      
      final bfsResult = solver.solve(level, state);
      final aStarResult = solver.solveAStar(level, state);

      expect(aStarResult.solvable, bfsResult.solvable);
      if (bfsResult.solvable && aStarResult.solvable) {
        expect(aStarResult.optimalMoves, bfsResult.optimalMoves);
      }
    });
  });

  group('Solution', () {
    test('unsolvable factory creates correct result', () {
      final solution = Solution.unsolvable(budgetExceeded: true, statesExplored: 1000);
      
      expect(solution.solvable, false);
      expect(solution.budgetExceeded, true);
      expect(solution.statesExplored, 1000);
    });

    test('alreadySolved factory creates correct result', () {
      final solution = Solution.alreadySolved();
      
      expect(solution.solvable, true);
      expect(solution.optimalMoves, 0);
      expect(solution.moves, isEmpty);
    });
  });
}
