/// BFS Solver for procedural levels.
///
/// Finds optimal solution (minimum moves) using breadth-first search.
/// Optionally uses A* with heuristic for faster solving on complex levels.
library;

import 'dart:collection';
import 'models/models.dart';
import 'ray_tracer.dart';

/// Result of solving a level.
class Solution {
  /// Whether a solution was found.
  final bool solvable;

  /// Minimum moves required to solve.
  final int optimalMoves;

  /// List of moves to solve.
  final List<SolutionMove> moves;

  /// Whether the solver exceeded its budget.
  final bool budgetExceeded;

  /// Number of states explored.
  final int statesExplored;

  /// Time taken to solve.
  final Duration solveTime;

  const Solution({
    required this.solvable,
    required this.optimalMoves,
    required this.moves,
    this.budgetExceeded = false,
    this.statesExplored = 0,
    this.solveTime = Duration.zero,
  });

  /// Create an unsolvable result.
  factory Solution.unsolvable({
    bool budgetExceeded = false,
    int statesExplored = 0,
  }) {
    return Solution(
      solvable: false,
      optimalMoves: -1,
      moves: const [],
      budgetExceeded: budgetExceeded,
      statesExplored: statesExplored,
    );
  }

  /// Create a solved result (already solved, 0 moves).
  factory Solution.alreadySolved() {
    return const Solution(
      solvable: true,
      optimalMoves: 0,
      moves: [],
    );
  }

  @override
  String toString() => solvable
      ? 'Solution(moves: $optimalMoves, explored: $statesExplored)'
      : 'Solution(unsolvable, explored: $statesExplored)';
}

/// BFS Solver for finding optimal solutions.
class Solver {
  /// Default budget (maximum states to explore).
  static const int defaultBudget = 100000;

  /// Maximum search depth.
  static const int maxDepth = 40;

  /// Ray tracer instance.
  final RayTracer _rayTracer = RayTracer();

  /// Solve a level from the given initial state.
  ///
  /// Returns the optimal solution or null if unsolvable within budget.
  Solution solve(
    GeneratedLevel level,
    GameState initialState, {
    int budget = defaultBudget,
  }) {
    final stopwatch = Stopwatch()..start();

    // Check if already solved
    if (_rayTracer.isSolved(level, initialState)) {
      return Solution.alreadySolved();
    }

    // Get rotatable objects
    final rotatableMirrors = <int>[];
    for (int i = 0; i < level.mirrors.length; i++) {
      if (level.mirrors[i].rotatable) {
        rotatableMirrors.add(i);
      }
    }

    final rotatablePrisms = <int>[];
    for (int i = 0; i < level.prisms.length; i++) {
      if (level.prisms[i].rotatable) {
        rotatablePrisms.add(i);
      }
    }

    // If nothing is rotatable, unsolvable
    if (rotatableMirrors.isEmpty && rotatablePrisms.isEmpty) {
      stopwatch.stop();
      return Solution.unsolvable(statesExplored: 1);
    }

    // BFS setup
    final visited = HashSet<int>(); // State hash codes
    final queue = Queue<SearchNode>();

    visited.add(initialState.hashCode);
    queue.add(SearchNode.initial(initialState));

    int statesExplored = 0;

    while (queue.isNotEmpty && statesExplored < budget) {
      final current = queue.removeFirst();
      statesExplored++;

      // Depth limit
      if (current.depth >= maxDepth) {
        continue;
      }

      // Generate successor states
      // 1. Rotate each rotatable mirror
      for (final mirrorIdx in rotatableMirrors) {
        final newState = current.state.rotateMirror(mirrorIdx);
        final stateHash = newState.hashCode;

        if (!visited.contains(stateHash)) {
          visited.add(stateHash);

          final move = SolutionMove(
            type: MoveType.rotateMirror,
            objectIndex: mirrorIdx,
          );

          // Check if solved
          if (_rayTracer.isSolved(level, newState)) {
            stopwatch.stop();
            return Solution(
              solvable: true,
              optimalMoves: current.depth + 1,
              moves: [...current.moves, move],
              statesExplored: statesExplored,
              solveTime: stopwatch.elapsed,
            );
          }

          queue.add(current.withMove(newState, move));
        }
      }

      // 2. Rotate each rotatable prism
      for (final prismIdx in rotatablePrisms) {
        final newState = current.state.rotatePrism(prismIdx);
        final stateHash = newState.hashCode;

        if (!visited.contains(stateHash)) {
          visited.add(stateHash);

          final move = SolutionMove(
            type: MoveType.rotatePrism,
            objectIndex: prismIdx,
          );

          // Check if solved
          if (_rayTracer.isSolved(level, newState)) {
            stopwatch.stop();
            return Solution(
              solvable: true,
              optimalMoves: current.depth + 1,
              moves: [...current.moves, move],
              statesExplored: statesExplored,
              solveTime: stopwatch.elapsed,
            );
          }

          queue.add(current.withMove(newState, move));
        }
      }
    }

    stopwatch.stop();
    return Solution.unsolvable(
      budgetExceeded: statesExplored >= budget,
      statesExplored: statesExplored,
    );
  }

  /// Solve with maximum depth limit (for shortcut detection).
  ///
  /// Returns a solution if one exists within maxDepth moves.
  /// Much faster than full solve when searching for shallow shortcuts.
  Solution solveWithMaxDepth(
    GeneratedLevel level,
    GameState initialState, {
    required int maxDepth,
    int budget = 5000,
  }) {
    final stopwatch = Stopwatch()..start();

    // Check if already solved
    if (_rayTracer.isSolved(level, initialState)) {
      return Solution.alreadySolved();
    }

    // Get rotatable objects
    final rotatableMirrors = <int>[];
    for (int i = 0; i < level.mirrors.length; i++) {
      if (level.mirrors[i].rotatable) rotatableMirrors.add(i);
    }

    final rotatablePrisms = <int>[];
    for (int i = 0; i < level.prisms.length; i++) {
      if (level.prisms[i].rotatable) rotatablePrisms.add(i);
    }

    if (rotatableMirrors.isEmpty && rotatablePrisms.isEmpty) {
      return Solution.unsolvable(statesExplored: 1);
    }

    // BFS with depth limit
    final visited = <int>{};
    final queue = <SearchNode>[];

    visited.add(initialState.hashCode);
    queue.add(SearchNode.initial(initialState));

    int statesExplored = 0;

    while (queue.isNotEmpty && statesExplored < budget) {
      final current = queue.removeAt(0);
      statesExplored++;

      // Strict depth limit
      if (current.depth >= maxDepth) continue;

      // Generate successors
      for (final mirrorIdx in rotatableMirrors) {
        final newState = current.state.rotateMirror(mirrorIdx);
        final stateHash = newState.hashCode;

        if (!visited.contains(stateHash)) {
          visited.add(stateHash);

          final move = SolutionMove(type: MoveType.rotateMirror, objectIndex: mirrorIdx);

          if (_rayTracer.isSolved(level, newState)) {
            stopwatch.stop();
            return Solution(
              solvable: true,
              optimalMoves: current.depth + 1,
              moves: [...current.moves, move],
              statesExplored: statesExplored,
              solveTime: stopwatch.elapsed,
            );
          }

          queue.add(current.withMove(newState, move));
        }
      }

      for (final prismIdx in rotatablePrisms) {
        final newState = current.state.rotatePrism(prismIdx);
        final stateHash = newState.hashCode;

        if (!visited.contains(stateHash)) {
          visited.add(stateHash);

          final move = SolutionMove(type: MoveType.rotatePrism, objectIndex: prismIdx);

          if (_rayTracer.isSolved(level, newState)) {
            stopwatch.stop();
            return Solution(
              solvable: true,
              optimalMoves: current.depth + 1,
              moves: [...current.moves, move],
              statesExplored: statesExplored,
              solveTime: stopwatch.elapsed,
            );
          }

          queue.add(current.withMove(newState, move));
        }
      }
    }

    stopwatch.stop();
    return Solution.unsolvable(
      budgetExceeded: statesExplored >= budget,
      statesExplored: statesExplored,
    );
  }

  /// Solve with stateful color mixing.
  /// 
  /// Each move updates target progress based on arriving colors.
  /// This correctly handles sequence-dependent puzzles where colors
  /// must arrive at targets in order.
  Solution solveStateful(
    GeneratedLevel level,
    GameState initialState, {
    int budget = defaultBudget,
  }) {
    final stopwatch = Stopwatch()..start();

    // Initial trace to set up progress
    final traceResult = _rayTracer.trace(level, initialState);
    var startState = initialState.withTargetProgress(level.targets, traceResult.arrivalMasks);

    // Check if already solved
    if (startState.allTargetsSatisfied(level.targets)) {
      return Solution.alreadySolved();
    }

    // Get rotatable objects
    final rotatableMirrors = <int>[];
    for (int i = 0; i < level.mirrors.length; i++) {
      if (level.mirrors[i].rotatable) rotatableMirrors.add(i);
    }

    final rotatablePrisms = <int>[];
    for (int i = 0; i < level.prisms.length; i++) {
      if (level.prisms[i].rotatable) rotatablePrisms.add(i);
    }

    if (rotatableMirrors.isEmpty && rotatablePrisms.isEmpty) {
      return Solution.unsolvable(statesExplored: 1);
    }

    // BFS with stateful progress
    final visited = <int>{};
    final queue = <SearchNode>[];

    visited.add(startState.hashCode);
    queue.add(SearchNode.initial(startState));

    int statesExplored = 0;

    while (queue.isNotEmpty && statesExplored < budget) {
      final current = queue.removeAt(0);
      statesExplored++;

      if (current.depth >= maxDepth) continue;

      // Generate successor states
      for (final mirrorIdx in rotatableMirrors) {
        // Rotate mirror
        var newState = current.state.rotateMirror(mirrorIdx);
        
        // Trace and update progress
        final traceResult = _rayTracer.trace(level, newState);
        newState = newState.withTargetProgress(level.targets, traceResult.arrivalMasks);

        final stateHash = newState.hashCode;

        if (!visited.contains(stateHash)) {
          visited.add(stateHash);

          final move = SolutionMove(type: MoveType.rotateMirror, objectIndex: mirrorIdx);

          // Check if solved using stateful progress
          if (newState.allTargetsSatisfied(level.targets)) {
            stopwatch.stop();
            return Solution(
              solvable: true,
              optimalMoves: current.depth + 1,
              moves: [...current.moves, move],
              statesExplored: statesExplored,
              solveTime: stopwatch.elapsed,
            );
          }

          queue.add(current.withMove(newState, move));
        }
      }

      for (final prismIdx in rotatablePrisms) {
        var newState = current.state.rotatePrism(prismIdx);
        
        final traceResult = _rayTracer.trace(level, newState);
        newState = newState.withTargetProgress(level.targets, traceResult.arrivalMasks);

        final stateHash = newState.hashCode;

        if (!visited.contains(stateHash)) {
          visited.add(stateHash);

          final move = SolutionMove(type: MoveType.rotatePrism, objectIndex: prismIdx);

          if (newState.allTargetsSatisfied(level.targets)) {
            stopwatch.stop();
            return Solution(
              solvable: true,
              optimalMoves: current.depth + 1,
              moves: [...current.moves, move],
              statesExplored: statesExplored,
              solveTime: stopwatch.elapsed,
            );
          }

          queue.add(current.withMove(newState, move));
        }
      }
    }

    stopwatch.stop();
    return Solution.unsolvable(
      budgetExceeded: statesExplored >= budget,
      statesExplored: statesExplored,
    );
  }

  /// Solve with A* for potentially faster results on complex levels.
  ///
  /// Uses unsatisfied target count as heuristic.
  Solution solveAStar(
    GeneratedLevel level,
    GameState initialState, {
    int budget = defaultBudget,
  }) {
    final stopwatch = Stopwatch()..start();

    // Check if already solved
    if (_rayTracer.isSolved(level, initialState)) {
      return Solution.alreadySolved();
    }

    // Get rotatable objects
    final rotatableMirrors = <int>[];
    for (int i = 0; i < level.mirrors.length; i++) {
      if (level.mirrors[i].rotatable) {
        rotatableMirrors.add(i);
      }
    }

    final rotatablePrisms = <int>[];
    for (int i = 0; i < level.prisms.length; i++) {
      if (level.prisms[i].rotatable) {
        rotatablePrisms.add(i);
      }
    }

    if (rotatableMirrors.isEmpty && rotatablePrisms.isEmpty) {
      stopwatch.stop();
      return Solution.unsolvable(statesExplored: 1);
    }

    // A* with priority queue (sorted by f = g + h)
    final visited = HashSet<int>();
    final openSet = SplayTreeMap<int, List<_AStarNode>>();

    int heuristic(GameState state) {
      final result = _rayTracer.trace(level, state);
      int unsatisfied = 0;
      for (int i = 0; i < level.targets.length; i++) {
        final arriving = result.targetArrivals[i] ?? {};
        if (!ColorMixer.satisfiesTarget(arriving, level.targets[i].requiredColor)) {
          unsatisfied++;
        }
      }
      return unsatisfied;
    }

    final initialNode = _AStarNode(
      state: initialState,
      moves: const [],
      g: 0,
      h: heuristic(initialState),
    );

    _addToOpenSet(openSet, initialNode);
    visited.add(initialState.hashCode);

    int statesExplored = 0;

    while (openSet.isNotEmpty && statesExplored < budget) {
      // Get node with lowest f
      final lowestF = openSet.firstKey()!;
      final nodes = openSet[lowestF]!;
      final current = nodes.removeAt(0);
      if (nodes.isEmpty) {
        openSet.remove(lowestF);
      }

      statesExplored++;

      if (current.g >= maxDepth) {
        continue;
      }

      // Generate successors
      for (final mirrorIdx in rotatableMirrors) {
        final newState = current.state.rotateMirror(mirrorIdx);
        final stateHash = newState.hashCode;

        if (!visited.contains(stateHash)) {
          visited.add(stateHash);

          final move = SolutionMove(
            type: MoveType.rotateMirror,
            objectIndex: mirrorIdx,
          );

          if (_rayTracer.isSolved(level, newState)) {
            stopwatch.stop();
            return Solution(
              solvable: true,
              optimalMoves: current.g + 1,
              moves: [...current.moves, move],
              statesExplored: statesExplored,
              solveTime: stopwatch.elapsed,
            );
          }

          final newNode = _AStarNode(
            state: newState,
            moves: [...current.moves, move],
            g: current.g + 1,
            h: heuristic(newState),
          );
          _addToOpenSet(openSet, newNode);
        }
      }

      for (final prismIdx in rotatablePrisms) {
        final newState = current.state.rotatePrism(prismIdx);
        final stateHash = newState.hashCode;

        if (!visited.contains(stateHash)) {
          visited.add(stateHash);

          final move = SolutionMove(
            type: MoveType.rotatePrism,
            objectIndex: prismIdx,
          );

          if (_rayTracer.isSolved(level, newState)) {
            stopwatch.stop();
            return Solution(
              solvable: true,
              optimalMoves: current.g + 1,
              moves: [...current.moves, move],
              statesExplored: statesExplored,
              solveTime: stopwatch.elapsed,
            );
          }

          final newNode = _AStarNode(
            state: newState,
            moves: [...current.moves, move],
            g: current.g + 1,
            h: heuristic(newState),
          );
          _addToOpenSet(openSet, newNode);
        }
      }
    }

    stopwatch.stop();
    return Solution.unsolvable(
      budgetExceeded: statesExplored >= budget,
      statesExplored: statesExplored,
    );
  }

  void _addToOpenSet(
    SplayTreeMap<int, List<_AStarNode>> openSet,
    _AStarNode node,
  ) {
    final f = node.f;
    if (!openSet.containsKey(f)) {
      openSet[f] = [];
    }
    openSet[f]!.add(node);
  }
}

/// Internal node for A* search.
class _AStarNode {
  final GameState state;
  final List<SolutionMove> moves;
  final int g; // Cost so far (depth)
  final int h; // Heuristic (unsatisfied targets)

  const _AStarNode({
    required this.state,
    required this.moves,
    required this.g,
    required this.h,
  });

  int get f => g + h;
}

