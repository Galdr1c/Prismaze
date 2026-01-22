/// Game state for solver and hint engine.
///
/// Lightweight mutable state representation for BFS search.
/// Contains orientations of rotatable objects and target progress.
library;

import 'dart:typed_data';
import 'game_objects.dart';
import 'level_model.dart';
import 'light_color.dart';

/// Immutable game state representing current orientations and target progress.
///
/// Used by the solver to track visited states and by the hint engine
/// to re-solve from the current player position.
class GameState {
  /// Mirror orientations (0-3 for each mirror).
  final Uint8List mirrorOrientations;

  /// Prism orientations (0-3 for each prism).
  final Uint8List prismOrientations;

  /// Target collected masks (bitmask of collected color components per target).
  /// Each entry stores collected components: R=1, B=2, Y=4, W=8
  final Uint8List targetCollected;

  GameState({
    required this.mirrorOrientations,
    required this.prismOrientations,
    required this.targetCollected,
  });

  /// Create initial state from a level (all targets start with 0 collected).
  factory GameState.fromLevel(GeneratedLevel level) {
    return GameState(
      mirrorOrientations: Uint8List.fromList(
        level.mirrors.map((m) => m.orientation.index).toList(),
      ),
      prismOrientations: Uint8List.fromList(
        level.prisms.map((p) => p.orientation).toList(),
      ),
      targetCollected: Uint8List(level.targets.length), // All zeros
    );
  }

  /// Create a copy of this state.
  GameState copy() {
    return GameState(
      mirrorOrientations: Uint8List.fromList(mirrorOrientations),
      prismOrientations: Uint8List.fromList(prismOrientations),
      targetCollected: Uint8List.fromList(targetCollected),
    );
  }

  /// Create a new state with a mirror rotated.
  GameState rotateMirror(int index) {
    final newState = copy();
    newState.mirrorOrientations[index] =
        (newState.mirrorOrientations[index] + 1) % 4;
    return newState;
  }

  /// Create a new state with a prism rotated.
  GameState rotatePrism(int index) {
    final newState = copy();
    newState.prismOrientations[index] =
        (newState.prismOrientations[index] + 1) % 4;
    return newState;
  }

  /// Create a new state with target progress updated from ray trace.
  /// 
  /// Applies the stateful accumulation rule:
  /// collectedMask |= (arrivedMask & requiredMask)
  GameState withTargetProgress(
    List<Target> targets,
    Map<int, int> arrivedMasks, // targetIndex -> arrived component mask
  ) {
    final newState = copy();
    for (int i = 0; i < targets.length && i < newState.targetCollected.length; i++) {
      final required = targets[i].requiredColor.requiredMask;
      final arrived = arrivedMasks[i] ?? 0;
      // Only collect components that match required (wrong colors ignored)
      newState.targetCollected[i] |= (arrived & required);
    }
    return newState;
  }

  /// Get collected mask for a target.
  int getTargetCollected(int index) {
    if (index < 0 || index >= targetCollected.length) return 0;
    return targetCollected[index];
  }

  /// Check if a specific target is satisfied.
  bool isTargetSatisfied(int index, LightColor requiredColor) {
    final required = requiredColor.requiredMask;
    final collected = getTargetCollected(index);
    return ColorMask.satisfies(collected, required);
  }

  /// Check if all targets are satisfied.
  bool allTargetsSatisfied(List<Target> targets) {
    for (int i = 0; i < targets.length; i++) {
      if (!isTargetSatisfied(i, targets[i].requiredColor)) {
        return false;
      }
    }
    return true;
  }

  /// Get mirror orientation at index.
  MirrorOrientation getMirrorOrientation(int index) {
    return MirrorOrientationExtension.fromInt(mirrorOrientations[index]);
  }

  /// Get prism orientation at index.
  int getPrismOrientation(int index) {
    return prismOrientations[index];
  }

  /// Check if this state equals another.
  /// Includes target progress in comparison for solver correctness.
  @override
  bool operator ==(Object other) {
    if (other is! GameState) return false;
    if (mirrorOrientations.length != other.mirrorOrientations.length) {
      return false;
    }
    if (prismOrientations.length != other.prismOrientations.length) {
      return false;
    }
    if (targetCollected.length != other.targetCollected.length) {
      return false;
    }
    for (int i = 0; i < mirrorOrientations.length; i++) {
      if (mirrorOrientations[i] != other.mirrorOrientations[i]) return false;
    }
    for (int i = 0; i < prismOrientations.length; i++) {
      if (prismOrientations[i] != other.prismOrientations[i]) return false;
    }
    for (int i = 0; i < targetCollected.length; i++) {
      if (targetCollected[i] != other.targetCollected[i]) return false;
    }
    return true;
  }

  /// Compute hash code for visited set.
  /// Includes target progress for correct solver behavior.
  @override
  int get hashCode {
    int hash = 0;
    const int prime = 31;

    for (int i = 0; i < mirrorOrientations.length; i++) {
      hash = hash * prime + mirrorOrientations[i];
    }
    for (int i = 0; i < prismOrientations.length; i++) {
      hash = hash * prime + prismOrientations[i];
    }
    for (int i = 0; i < targetCollected.length; i++) {
      hash = hash * prime + targetCollected[i];
    }

    return hash;
  }

  /// Fast hash for orientation-only comparison (for render caching).
  /// Excludes targetCollected since beam rendering only depends on mirror/prism orientations.
  int get orientationHash {
    int hash = 17;
    for (int i = 0; i < mirrorOrientations.length; i++) {
      hash = hash * 31 + mirrorOrientations[i];
    }
    for (int i = 0; i < prismOrientations.length; i++) {
      hash = hash * 31 + prismOrientations[i];
    }
    return hash;
  }

  /// Encode state to a compact string for debugging.
  String encode() {
    final buffer = StringBuffer();
    buffer.write('M:');
    for (final o in mirrorOrientations) {
      buffer.write(o.toString());
    }
    buffer.write('|P:');
    for (final o in prismOrientations) {
      buffer.write(o.toString());
    }
    buffer.write('|T:');
    for (final c in targetCollected) {
      buffer.write(c.toRadixString(16));
    }
    return buffer.toString();
  }

  /// Decode state from encoded string.
  factory GameState.decode(String encoded) {
    final parts = encoded.split('|');
    final mirrorPart = parts[0].substring(2); // Remove "M:"
    final prismPart = parts.length > 1 ? parts[1].substring(2) : ''; // Remove "P:"
    final targetPart = parts.length > 2 ? parts[2].substring(2) : ''; // Remove "T:"

    return GameState(
      mirrorOrientations: Uint8List.fromList(
        mirrorPart.isEmpty ? [] : mirrorPart.split('').map((c) => int.parse(c)).toList(),
      ),
      prismOrientations: Uint8List.fromList(
        prismPart.isEmpty ? [] : prismPart.split('').map((c) => int.parse(c)).toList(),
      ),
      targetCollected: Uint8List.fromList(
        targetPart.isEmpty ? [] : targetPart.split('').map((c) => int.parse(c, radix: 16)).toList(),
      ),
    );
  }

  @override
  String toString() => 'GameState(${encode()})';
}

/// Search node for BFS solver.
class SearchNode {
  final GameState state;
  final List<SolutionMove> moves;
  final int depth;

  const SearchNode({
    required this.state,
    required this.moves,
    required this.depth,
  });

  /// Create initial search node.
  factory SearchNode.initial(GameState state) {
    return SearchNode(state: state, moves: const [], depth: 0);
  }

  /// Create child node with a new move.
  SearchNode withMove(GameState newState, SolutionMove move) {
    return SearchNode(
      state: newState,
      moves: [...moves, move],
      depth: depth + 1,
    );
  }
}

