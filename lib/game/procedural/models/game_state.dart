/// Game state for solver and hint engine.
///
/// Lightweight immutable state representation for BFS search.
/// Contains only orientations of rotatable objects.
/// Win checking is done per-frame via RayTracer (simultaneous arrival).
library;

import 'dart:typed_data';
import 'game_objects.dart';
import 'level_model.dart';

/// Immutable game state representing current orientations.
///
/// Used by the solver to track visited states and by the hint engine
/// to re-solve from the current player position.
/// 
/// NOTE: Target satisfaction is checked per-frame via RayTracer.trace()
/// which returns TraceResult.allTargetsSatisfied. This implements
/// "simultaneous arrival" - all required colors must arrive at the
/// same time, not accumulate over multiple frames.
class GameState {
  /// Mirror orientations (0-3 for each mirror).
  final Uint8List mirrorOrientations;

  /// Prism orientations (0-3 for each prism).
  final Uint8List prismOrientations;

  const GameState({
    required this.mirrorOrientations,
    required this.prismOrientations,
  });

  /// Create initial state from a level.
  factory GameState.fromLevel(GeneratedLevel level) {
    return GameState(
      mirrorOrientations: Uint8List.fromList(
        level.mirrors.map((m) => m.orientation.index).toList(),
      ),
      prismOrientations: Uint8List.fromList(
        level.prisms.map((p) => p.orientation).toList(),
      ),
    );
  }

  /// Create a copy of this state.
  GameState copy() {
    return GameState(
      mirrorOrientations: Uint8List.fromList(mirrorOrientations),
      prismOrientations: Uint8List.fromList(prismOrientations),
    );
  }

  /// Create a new state with a mirror rotated.
  GameState rotateMirror(int index) {
    final newOrientations = Uint8List.fromList(mirrorOrientations);
    newOrientations[index] = (newOrientations[index] + 1) % 4;
    return GameState(
      mirrorOrientations: newOrientations,
      prismOrientations: prismOrientations,
    );
  }

  /// Create a new state with a prism rotated.
  GameState rotatePrism(int index) {
    final newOrientations = Uint8List.fromList(prismOrientations);
    newOrientations[index] = (newOrientations[index] + 1) % 4;
    return GameState(
      mirrorOrientations: mirrorOrientations,
      prismOrientations: newOrientations,
    );
  }
  
  /// Create a new state with specific mirror orientation.
  GameState withMirrorOrientation(int index, int orientation) {
    final newOrientations = Uint8List.fromList(mirrorOrientations);
    newOrientations[index] = orientation % 4;
    return GameState(
      mirrorOrientations: newOrientations,
      prismOrientations: prismOrientations,
    );
  }

  /// Create a new state with specific prism orientation.
  GameState withPrismOrientation(int index, int orientation) {
    final newOrientations = Uint8List.fromList(prismOrientations);
    newOrientations[index] = orientation % 4;
    return GameState(
      mirrorOrientations: mirrorOrientations,
      prismOrientations: newOrientations,
    );
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
  @override
  bool operator ==(Object other) {
    if (other is! GameState) return false;
    if (mirrorOrientations.length != other.mirrorOrientations.length) {
      return false;
    }
    if (prismOrientations.length != other.prismOrientations.length) {
      return false;
    }
    for (int i = 0; i < mirrorOrientations.length; i++) {
      if (mirrorOrientations[i] != other.mirrorOrientations[i]) return false;
    }
    for (int i = 0; i < prismOrientations.length; i++) {
      if (prismOrientations[i] != other.prismOrientations[i]) return false;
    }
    return true;
  }

  /// Compute hash code for visited set.
  @override
  int get hashCode {
    int hash = 17;
    const int prime = 31;

    for (int i = 0; i < mirrorOrientations.length; i++) {
      hash = hash * prime + mirrorOrientations[i];
    }
    for (int i = 0; i < prismOrientations.length; i++) {
      hash = hash * prime + prismOrientations[i];
    }

    return hash;
  }

  /// Fast hash for orientation-only comparison (for render caching).
  /// Same as hashCode now since we only track orientations.
  int get orientationHash => hashCode;

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
    return buffer.toString();
  }

  /// Decode state from encoded string.
  factory GameState.decode(String encoded) {
    final parts = encoded.split('|');
    final mirrorPart = parts[0].substring(2); // Remove "M:"
    final prismPart = parts.length > 1 ? parts[1].substring(2) : ''; // Remove "P:"

    return GameState(
      mirrorOrientations: Uint8List.fromList(
        mirrorPart.isEmpty ? [] : mirrorPart.split('').map((c) => int.parse(c)).toList(),
      ),
      prismOrientations: Uint8List.fromList(
        prismPart.isEmpty ? [] : prismPart.split('').map((c) => int.parse(c)).toList(),
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
