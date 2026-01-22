/// Hint Engine for providing player assistance.
///
/// Re-solves puzzles from the current state to provide accurate hints.
/// Supports multiple hint levels with budget policies and graceful degradation.
library;

import 'package:flutter/foundation.dart';
import 'models/models.dart';
import 'solver.dart';
import 'ray_tracer.dart';

/// Types of hints available.
enum HintType {
  light,  // Highlight first object to change
  medium, // Show next 3 moves
  full,   // Show complete solution
}

/// Budget policy for different hint types.
class HintBudgetPolicy {
  final int lightBudget;
  final int mediumBudget;
  final int fullBudget;

  const HintBudgetPolicy({
    this.lightBudget = 10000,   // Fast, responsive
    this.mediumBudget = 30000,  // Moderate
    this.fullBudget = 100000,   // Largest, still bounded
  });

  int getBudget(HintType type) {
    switch (type) {
      case HintType.light:
        return lightBudget;
      case HintType.medium:
        return mediumBudget;
      case HintType.full:
        return fullBudget;
    }
  }

  static const HintBudgetPolicy standard = HintBudgetPolicy();
}

/// A single hint suggestion.
class HintMove {
  final MoveType type;
  final int objectIndex;
  final int tapsRequired;

  const HintMove({
    required this.type,
    required this.objectIndex,
    this.tapsRequired = 1,
  });

  @override
  String toString() => 'HintMove(${type.name}[$objectIndex] x$tapsRequired)';
}

/// Result of requesting a hint.
class Hint {
  /// Whether a hint could be generated.
  final bool available;

  /// The type of hint that was generated.
  final HintType type;

  /// Moves to suggest to the player (consolidated).
  final List<HintMove> moves;

  /// Raw solution moves (for animation).
  final List<SolutionMove> rawMoves;

  /// Index of object to highlight (for light hints).
  final int? highlightObjectIndex;

  /// Type of highlighted object.
  final MoveType? highlightObjectType;

  /// Minimum moves remaining from current state.
  final int? movesRemaining;

  /// Error message if hint unavailable.
  final String? errorMessage;

  /// Whether this is a fallback hint (solver exceeded budget).
  final bool isFallback;

  /// Solve time in milliseconds.
  final int solveTimeMs;

  /// Number of states explored.
  final int statesExplored;

  const Hint({
    required this.available,
    required this.type,
    this.moves = const [],
    this.rawMoves = const [],
    this.highlightObjectIndex,
    this.highlightObjectType,
    this.movesRemaining,
    this.errorMessage,
    this.isFallback = false,
    this.solveTimeMs = 0,
    this.statesExplored = 0,
  });

  /// Create a light hint (highlight only).
  factory Hint.highlight({
    required int objectIndex,
    required MoveType objectType,
    required int movesRemaining,
    required List<SolutionMove> rawMoves,
    int solveTimeMs = 0,
    int statesExplored = 0,
  }) {
    return Hint(
      available: true,
      type: HintType.light,
      highlightObjectIndex: objectIndex,
      highlightObjectType: objectType,
      movesRemaining: movesRemaining,
      moves: [HintMove(type: objectType, objectIndex: objectIndex)],
      rawMoves: rawMoves,
      solveTimeMs: solveTimeMs,
      statesExplored: statesExplored,
    );
  }

  /// Create a medium hint (next 3 moves).
  factory Hint.medium({
    required List<HintMove> moves,
    required List<SolutionMove> rawMoves,
    required int movesRemaining,
    int solveTimeMs = 0,
    int statesExplored = 0,
  }) {
    return Hint(
      available: true,
      type: HintType.medium,
      moves: moves,
      rawMoves: rawMoves,
      movesRemaining: movesRemaining,
      solveTimeMs: solveTimeMs,
      statesExplored: statesExplored,
    );
  }

  /// Create a full hint (all moves).
  factory Hint.full({
    required List<HintMove> moves,
    required List<SolutionMove> rawMoves,
    int solveTimeMs = 0,
    int statesExplored = 0,
  }) {
    return Hint(
      available: true,
      type: HintType.full,
      moves: moves,
      rawMoves: rawMoves,
      movesRemaining: rawMoves.length,
      solveTimeMs: solveTimeMs,
      statesExplored: statesExplored,
    );
  }

  /// Create an unavailable hint.
  factory Hint.unavailable(String reason) {
    return Hint(
      available: false,
      type: HintType.light,
      errorMessage: reason,
    );
  }

  /// Create a fallback hint when solver fails.
  factory Hint.fallback({
    required int objectIndex,
    required MoveType objectType,
    required String reason,
    int solveTimeMs = 0,
    int statesExplored = 0,
  }) {
    return Hint(
      available: true,
      type: HintType.light,
      highlightObjectIndex: objectIndex,
      highlightObjectType: objectType,
      moves: [HintMove(type: objectType, objectIndex: objectIndex)],
      rawMoves: [SolutionMove(type: objectType, objectIndex: objectIndex)],
      errorMessage: reason,
      isFallback: true,
      solveTimeMs: solveTimeMs,
      statesExplored: statesExplored,
    );
  }

  @override
  String toString() => available
      ? 'Hint($type, ${moves.length} moves, remaining: $movesRemaining, fallback: $isFallback)'
      : 'Hint(unavailable: $errorMessage)';
}

/// Hint engine for generating player assistance.
///
/// Re-solves from CURRENT state with budget limits.
class HintEngine {
  final Solver _solver = Solver();
  final HintBudgetPolicy budgetPolicy;

  HintEngine({this.budgetPolicy = HintBudgetPolicy.standard});

  /// Get a hint for the current game state.
  ///
  /// Always attempts to solve from the current state, not the initial state.
  /// This ensures hints are accurate even if the player has made mistakes.
  Hint getHint(
    GeneratedLevel level,
    GameState currentState,
    HintType type,
  ) {
    final budget = budgetPolicy.getBudget(type);
    final stopwatch = Stopwatch()..start();

    // Solve from current state with appropriate budget
    var solution = _solver.solve(level, currentState, budget: budget);
    stopwatch.stop();

    final solveTimeMs = stopwatch.elapsedMilliseconds;

    // Check if already solved
    if (solution.solvable && solution.optimalMoves == 0) {
      return Hint.unavailable('Level already solved!');
    }

    // Check if solvable within budget
    if (!solution.solvable) {
      // Log budget failure
      _logBudgetFailure(level, type, solution, solveTimeMs);

      // Try A* with same budget
      stopwatch.reset();
      stopwatch.start();
      final aStarSolution = _solver.solveAStar(level, currentState, budget: budget);
      stopwatch.stop();

      if (!aStarSolution.solvable) {
        // Log A* failure too
        _logBudgetFailure(level, type, aStarSolution, stopwatch.elapsedMilliseconds, isAStar: true);
        return _createFallbackHint(level, currentState, solveTimeMs, solution.statesExplored);
      }

      solution = aStarSolution;
    }

    return _createHint(solution, type, solveTimeMs);
  }

  /// Log budget failure for debugging.
  void _logBudgetFailure(
    GeneratedLevel level,
    HintType type,
    Solution solution,
    int solveTimeMs, {
    bool isAStar = false,
  }) {
    if (kDebugMode) {
      final method = isAStar ? 'A*' : 'BFS';
      debugPrint('=== HINT BUDGET FAILURE ===');
      debugPrint('Episode: ${level.episode}, Seed: ${level.seed}');
      debugPrint('Hint type: ${type.name}');
      debugPrint('Method: $method');
      debugPrint('Budget: ${budgetPolicy.getBudget(type)}');
      debugPrint('States explored: ${solution.statesExplored}');
      debugPrint('Time: ${solveTimeMs}ms');
      debugPrint('Budget exceeded: ${solution.budgetExceeded}');
    }
  }

  /// Create hint from solution.
  Hint _createHint(Solution solution, HintType type, int solveTimeMs) {
    if (solution.moves.isEmpty) {
      return Hint.unavailable('No moves needed');
    }

    switch (type) {
      case HintType.light:
        final firstMove = solution.moves.first;
        return Hint.highlight(
          objectIndex: firstMove.objectIndex,
          objectType: firstMove.type,
          movesRemaining: solution.optimalMoves,
          rawMoves: solution.moves,
          solveTimeMs: solveTimeMs,
          statesExplored: solution.statesExplored,
        );

      case HintType.medium:
        final movesToShow = solution.moves.take(3).toList();
        return Hint.medium(
          moves: _consolidateMoves(movesToShow),
          rawMoves: movesToShow,
          movesRemaining: solution.optimalMoves,
          solveTimeMs: solveTimeMs,
          statesExplored: solution.statesExplored,
        );

      case HintType.full:
        return Hint.full(
          moves: _consolidateMoves(solution.moves),
          rawMoves: solution.moves,
          solveTimeMs: solveTimeMs,
          statesExplored: solution.statesExplored,
        );
    }
  }

  /// Consolidate consecutive moves on the same object.
  List<HintMove> _consolidateMoves(List<SolutionMove> moves) {
    if (moves.isEmpty) return [];

    final result = <HintMove>[];
    int currentIndex = moves.first.objectIndex;
    MoveType currentType = moves.first.type;
    int count = 0;

    for (final move in moves) {
      if (move.objectIndex == currentIndex && move.type == currentType) {
        count++;
      } else {
        result.add(HintMove(
          type: currentType,
          objectIndex: currentIndex,
          tapsRequired: count,
        ));
        currentIndex = move.objectIndex;
        currentType = move.type;
        count = 1;
      }
    }

    result.add(HintMove(
      type: currentType,
      objectIndex: currentIndex,
      tapsRequired: count,
    ));

    return result;
  }

  /// Create a fallback hint when solver fails.
  ///
  /// Uses critical path heuristics to suggest a plausible object.
  Hint _createFallbackHint(
    GeneratedLevel level,
    GameState currentState,
    int solveTimeMs,
    int statesExplored,
  ) {
    // Strategy 1: Find the first rotatable object that would affect ray path
    // For now, use simple heuristic: first rotatable mirror, then prism

    for (int i = 0; i < level.mirrors.length; i++) {
      if (level.mirrors[i].rotatable) {
        return Hint.fallback(
          objectIndex: i,
          objectType: MoveType.rotateMirror,
          reason: 'Budget exceeded - suggesting first rotatable mirror',
          solveTimeMs: solveTimeMs,
          statesExplored: statesExplored,
        );
      }
    }

    for (int i = 0; i < level.prisms.length; i++) {
      if (level.prisms[i].rotatable) {
        return Hint.fallback(
          objectIndex: i,
          objectType: MoveType.rotatePrism,
          reason: 'Budget exceeded - suggesting first rotatable prism',
          solveTimeMs: solveTimeMs,
          statesExplored: statesExplored,
        );
      }
    }

    return Hint.unavailable('No rotatable objects available');
  }

  /// Get remaining moves from current state.
  int? getRemainingMoves(GeneratedLevel level, GameState currentState) {
    final solution = _solver.solve(
      level,
      currentState,
      budget: budgetPolicy.lightBudget,
    );
    return solution.solvable ? solution.optimalMoves : null;
  }
}

/// Hint session for managing hint animation state.
///
/// Takes a snapshot of current state, computes solution,
/// and allows playing animation on a cloned state without
/// modifying the actual game state.
class HintSession {
  final GeneratedLevel level;
  final GameState originalState;
  final Hint hint;
  final RayTracer _rayTracer = RayTracer();

  GameState _animationState;
  int _currentStep = 0;
  bool _isComplete = false;

  HintSession({
    required this.level,
    required this.originalState,
    required this.hint,
  }) : _animationState = originalState.copy();

  /// Whether the animation has completed.
  bool get isComplete => _isComplete;

  /// Current step in the animation.
  int get currentStep => _currentStep;

  /// Total steps in the animation.
  int get totalSteps => hint.rawMoves.length;

  /// Current animation state (cloned, not affecting actual game).
  GameState get animationState => _animationState;

  /// Reset animation to beginning.
  void reset() {
    _animationState = originalState.copy();
    _currentStep = 0;
    _isComplete = false;
  }

  /// Play next move in the animation.
  ///
  /// Returns the move that was applied, or null if animation is complete.
  /// Also returns the updated TraceResult for ray rendering.
  HintAnimationStep? playNextMove() {
    if (_currentStep >= hint.rawMoves.length) {
      _isComplete = true;
      return null;
    }

    final move = hint.rawMoves[_currentStep];

    // Apply move to animation state (not actual game state!)
    switch (move.type) {
      case MoveType.rotateMirror:
        _animationState = _animationState.rotateMirror(move.objectIndex);
        break;
      case MoveType.rotatePrism:
        _animationState = _animationState.rotatePrism(move.objectIndex);
        break;
    }

    // Trace rays with new state
    final traceResult = _rayTracer.trace(level, _animationState);

    _currentStep++;
    if (_currentStep >= hint.rawMoves.length) {
      _isComplete = true;
    }

    return HintAnimationStep(
      move: move,
      stepIndex: _currentStep - 1,
      newState: _animationState.copy(),
      traceResult: traceResult,
      isLastStep: _isComplete,
    );
  }

  /// Get the object to highlight for the current step.
  (MoveType, int)? getCurrentHighlight() {
    if (_currentStep >= hint.rawMoves.length) return null;
    final move = hint.rawMoves[_currentStep];
    return (move.type, move.objectIndex);
  }

  /// Get current trace result for ray visualization.
  TraceResult getCurrentTraceResult() {
    return _rayTracer.trace(level, _animationState);
  }
}

/// Single step in hint animation.
class HintAnimationStep {
  final SolutionMove move;
  final int stepIndex;
  final GameState newState;
  final TraceResult traceResult;
  final bool isLastStep;

  const HintAnimationStep({
    required this.move,
    required this.stepIndex,
    required this.newState,
    required this.traceResult,
    required this.isLastStep,
  });
}

