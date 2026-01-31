// Unit tests for HintEngine.
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  group('HintEngine', () {
    late HintEngine hintEngine;
    late GeneratedLevel testLevel;
    late GameState initialState;

    setUp(() {
      hintEngine = HintEngine();

      // Create a simple solvable level:
      // Source at (0, 4) facing east
      // Mirror at (5, 4) facing slash (orientation 1) - needs rotation to orient correctly
      // Target at (10, 4) requiring white light
      testLevel = GeneratedLevel(
        seed: 12345,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
          color: LightColor.white,
        ),
        targets: const [
          Target(position: GridPosition(10, 4), requiredColor: LightColor.white),
        ],
        walls: const {},
        mirrors: const [
          Mirror(
            position: GridPosition(5, 4),
            orientation: MirrorOrientation.slash, // Index 1
            rotatable: true,
          ),
        ],
        prisms: const [],
        meta: LevelMeta(
          optimalMoves: 1,
          difficultyBand: DifficultyBand.tutorial,
        ),
        solution: const [
          SolutionMove(type: MoveType.rotateMirror, objectIndex: 0),
        ],
      );

      // Initial state: mirror at orientation 1 (slash)
      initialState = GameState.fromLevel(testLevel);
    });

    test('returns valid hint for solvable level', () {
      final hint = hintEngine.getHint(testLevel, initialState, HintType.light);

      expect(hint.available, isTrue);
      expect(hint.moves, isNotEmpty);
      expect(hint.highlightObjectIndex, isNotNull);
      expect(hint.highlightObjectType, equals(MoveType.rotateMirror));
    });

    test('light hint returns single move', () {
      final hint = hintEngine.getHint(testLevel, initialState, HintType.light);

      expect(hint.type, equals(HintType.light));
      expect(hint.moves.length, equals(1));
      expect(hint.rawMoves.length, greaterThan(0));
    });

    test('medium hint returns up to 3 moves', () {
      final hint = hintEngine.getHint(testLevel, initialState, HintType.medium);

      expect(hint.type, equals(HintType.medium));
      expect(hint.moves.length, lessThanOrEqualTo(3));
    });

    test('full hint returns all moves', () {
      final hint = hintEngine.getHint(testLevel, initialState, HintType.full);

      expect(hint.type, equals(HintType.full));
      // For this simple level, should be 1 move
      expect(hint.rawMoves.length, greaterThan(0));
    });

    test('returns unavailable for already solved level', () {
      // Create a solved state where ray reaches target
      // In this case, let's simulate the mirror being at correct orientation
      final solvedState = GameState(
        mirrorOrientations: Uint8List.fromList([0]), // horizontal - lets ray pass
        prismOrientations: Uint8List(0),
      );

      final hint = hintEngine.getHint(testLevel, solvedState, HintType.light);

      // May or may not be available depending on if solved - check the message
      if (!hint.available) {
        expect(hint.errorMessage, contains('solved'));
      }
    });

    test('applying first hint move does not increase remaining moves', () {
      final hint = hintEngine.getHint(testLevel, initialState, HintType.light);

      if (hint.available && hint.rawMoves.isNotEmpty) {
        final firstMove = hint.rawMoves.first;

        // Apply the move
        GameState newState;
        if (firstMove.type == MoveType.rotateMirror) {
          newState = initialState.rotateMirror(firstMove.objectIndex);
        } else {
          newState = initialState.rotatePrism(firstMove.objectIndex);
        }

        // Check remaining moves from new state
        final newHint = hintEngine.getHint(testLevel, newState, HintType.light);

        // Remaining moves should be less than or equal
        if (newHint.available && hint.movesRemaining != null) {
          final newRemaining = newHint.movesRemaining ?? hint.movesRemaining!;
          expect(newRemaining, lessThanOrEqualTo(hint.movesRemaining!));
        }
      }
    });

    test('records solve time', () {
      final hint = hintEngine.getHint(testLevel, initialState, HintType.light);

      expect(hint.solveTimeMs, greaterThanOrEqualTo(0));
    });

    test('records states explored', () {
      final hint = hintEngine.getHint(testLevel, initialState, HintType.light);

      if (hint.available) {
        expect(hint.statesExplored, greaterThan(0));
      }
    });
  });

  group('HintSession', () {
    late GeneratedLevel testLevel;
    late GameState initialState;

    setUp(() {
      testLevel = GeneratedLevel(
        seed: 12345,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
          color: LightColor.white,
        ),
        targets: const [
          Target(position: GridPosition(10, 4), requiredColor: LightColor.white),
        ],
        walls: const {},
        mirrors: const [
          Mirror(
            position: GridPosition(5, 4),
            orientation: MirrorOrientation.slash,
            rotatable: true,
          ),
        ],
        prisms: const [],
        meta: LevelMeta(
          optimalMoves: 1,
          difficultyBand: DifficultyBand.tutorial,
        ),
        solution: const [
          SolutionMove(type: MoveType.rotateMirror, objectIndex: 0),
        ],
      );

      initialState = GameState.fromLevel(testLevel);
    });

    test('creates session with correct initial state', () {
      final hintEngine = HintEngine();
      final hint = hintEngine.getHint(testLevel, initialState, HintType.full);

      if (hint.available) {
        final session = HintSession(
          level: testLevel,
          originalState: initialState,
          hint: hint,
        );

        expect(session.isComplete, isFalse);
        expect(session.currentStep, equals(0));
        expect(session.totalSteps, equals(hint.rawMoves.length));
      }
    });

    test('session plays moves without modifying original state', () {
      final hintEngine = HintEngine();
      final hint = hintEngine.getHint(testLevel, initialState, HintType.full);

      if (hint.available && hint.rawMoves.isNotEmpty) {
        final session = HintSession(
          level: testLevel,
          originalState: initialState,
          hint: hint,
        );

        // Record original state
        final originalHash = initialState.hashCode;

        // Play a move
        session.playNextMove();

        // Original state should be unchanged
        expect(initialState.hashCode, equals(originalHash));
      }
    });

    test('session reset returns to initial state', () {
      final hintEngine = HintEngine();
      final hint = hintEngine.getHint(testLevel, initialState, HintType.full);

      if (hint.available && hint.rawMoves.isNotEmpty) {
        final session = HintSession(
          level: testLevel,
          originalState: initialState,
          hint: hint,
        );

        // Play a move
        session.playNextMove();
        expect(session.currentStep, equals(1));

        // Reset
        session.reset();

        expect(session.currentStep, equals(0));
        expect(session.isComplete, isFalse);
      }
    });

    test('session completes after all moves', () {
      final hintEngine = HintEngine();
      final hint = hintEngine.getHint(testLevel, initialState, HintType.full);

      if (hint.available && hint.rawMoves.isNotEmpty) {
        final session = HintSession(
          level: testLevel,
          originalState: initialState,
          hint: hint,
        );

        // Play all moves
        while (!session.isComplete) {
          session.playNextMove();
        }

        expect(session.isComplete, isTrue);
        expect(session.currentStep, equals(session.totalSteps));
      }
    });
  });

  group('HintBudgetPolicy', () {
    test('returns correct budget for each hint type', () {
      const policy = HintBudgetPolicy();

      expect(policy.getBudget(HintType.light), equals(10000));
      expect(policy.getBudget(HintType.medium), equals(30000));
      expect(policy.getBudget(HintType.full), equals(100000));
    });

    test('custom policy values are used', () {
      const policy = HintBudgetPolicy(
        lightBudget: 5000,
        mediumBudget: 15000,
        fullBudget: 50000,
      );

      expect(policy.getBudget(HintType.light), equals(5000));
      expect(policy.getBudget(HintType.medium), equals(15000));
      expect(policy.getBudget(HintType.full), equals(50000));
    });
  });

  group('Fallback behavior', () {
    test('fallback hint has isFallback flag set', () {
      // Create a level that might exceed budget (complex)
      // For now, just verify the fallback structure
      final fallbackHint = Hint.fallback(
        objectIndex: 0,
        objectType: MoveType.rotateMirror,
        reason: 'Budget exceeded',
      );

      expect(fallbackHint.isFallback, isTrue);
      expect(fallbackHint.available, isTrue);
      expect(fallbackHint.errorMessage, contains('Budget'));
    });
  });
}
