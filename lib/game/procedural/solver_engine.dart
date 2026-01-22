/// Solver Engine
/// Handles ray tracing simulation and BFS-based optimal move calculation

import 'dart:math';
import 'procedural_level.dart';

/// Represents a ray segment in the simulation
class RaySegment {
  final Vector2 start;
  final Vector2 end;
  final String color;
  
  const RaySegment(this.start, this.end, this.color);
}

/// Represents the state of a level for BFS search
class LevelState {
  final Map<int, GridPos> mirrorPositions;
  final Map<int, double> mirrorAngles;
  final Map<int, GridPos> prismPositions;
  final Map<int, double> prismAngles;
  
  const LevelState({
    required this.mirrorPositions,
    required this.mirrorAngles,
    required this.prismPositions,
    required this.prismAngles,
  });
  
  /// Create from procedural level
  factory LevelState.fromLevel(ProceduralLevel level) {
    final mirrorPos = <int, GridPos>{};
    final mirrorAng = <int, double>{};
    final prismPos = <int, GridPos>{};
    final prismAng = <int, double>{};
    
    for (int i = 0; i < level.mirrors.length; i++) {
      mirrorPos[i] = level.mirrors[i].position;
      mirrorAng[i] = level.mirrors[i].angle;
    }
    
    for (int i = 0; i < level.prisms.length; i++) {
      prismPos[i] = level.prisms[i].position;
      prismAng[i] = level.prisms[i].angle;
    }
    
    return LevelState(
      mirrorPositions: mirrorPos,
      mirrorAngles: mirrorAng,
      prismPositions: prismPos,
      prismAngles: prismAng,
    );
  }
  
  /// Create a copy with a move applied
  LevelState applyMove(SolutionStep move) {
    final newMirrorPos = Map<int, GridPos>.from(mirrorPositions);
    final newMirrorAng = Map<int, double>.from(mirrorAngles);
    final newPrismPos = Map<int, GridPos>.from(prismPositions);
    final newPrismAng = Map<int, double>.from(prismAngles);
    
    final idx = move.objectIndex;
    
    if (move.action == 'move' && move.targetPos != null) {
      if (idx < newMirrorPos.length) {
        newMirrorPos[idx] = move.targetPos!;
      } else {
        newPrismPos[idx - newMirrorPos.length] = move.targetPos!;
      }
    } else if (move.action == 'rotate' && move.targetAngle != null) {
      if (idx < newMirrorAng.length) {
        newMirrorAng[idx] = move.targetAngle!;
      } else {
        newPrismAng[idx - newMirrorAng.length] = move.targetAngle!;
      }
    }
    
    return LevelState(
      mirrorPositions: newMirrorPos,
      mirrorAngles: newMirrorAng,
      prismPositions: newPrismPos,
      prismAngles: newPrismAng,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (other is! LevelState) return false;
    return _mapsEqual(mirrorPositions, other.mirrorPositions) &&
           _mapsEqual(mirrorAngles, other.mirrorAngles) &&
           _mapsEqual(prismPositions, other.prismPositions) &&
           _mapsEqual(prismAngles, other.prismAngles);
  }
  
  bool _mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
  
  @override
  int get hashCode => Object.hash(
    mirrorPositions.hashCode,
    mirrorAngles.hashCode,
    prismPositions.hashCode,
    prismAngles.hashCode,
  );
}

/// Solution result from solver
class SolutionResult {
  final bool solvable;
  final int optimalMoves;
  final List<SolutionStep> steps;
  
  const SolutionResult({
    required this.solvable,
    required this.optimalMoves,
    required this.steps,
  });
  
  factory SolutionResult.unsolvable() => const SolutionResult(
    solvable: false,
    optimalMoves: -1,
    steps: [],
  );
}

/// Main solver engine
class SolverEngine {
  static const int maxSearchDepth = 15;
  static const double cellSize = 55.0;
  
  /// Simulate ray tracing for a level state
  List<RaySegment> simulateRays(
    ProceduralLevel level,
    LevelState state,
  ) {
    final segments = <RaySegment>[];
    
    // Start from light source
    final source = level.lightSource;
    final startPos = source.position.toPixel();
    final direction = _directionToVector(source.direction);
    
    _castRay(
      startPos,
      direction,
      source.color,
      level,
      state,
      segments,
      0,
    );
    
    return segments;
  }
  
  /// Check if all targets are reached by rays
  bool allTargetsReached(
    List<RaySegment> rays,
    List<TargetDef> targets,
  ) {
    for (final target in targets) {
      final targetPixel = target.position.toPixel();
      bool hit = false;
      
      for (final ray in rays) {
        if (_rayHitsTarget(ray, targetPixel, target.requiredColor)) {
          hit = true;
          break;
        }
      }
      
      if (!hit) return false;
    }
    
    return true;
  }
  
  /// Find optimal solution using BFS
  SolutionResult findOptimalSolution(ProceduralLevel level) {
    final initialState = LevelState.fromLevel(level);
    
    // Check if already solved
    final initialRays = simulateRays(level, initialState);
    if (allTargetsReached(initialRays, level.targets)) {
      return const SolutionResult(solvable: true, optimalMoves: 0, steps: []);
    }
    
    // BFS
    final visited = <LevelState>{initialState};
    final queue = <_SearchNode>[_SearchNode(initialState, [])];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      
      if (current.moves.length >= maxSearchDepth) continue;
      
      // Generate all possible moves
      final possibleMoves = _generatePossibleMoves(level, current.state);
      
      for (final move in possibleMoves) {
        final newState = current.state.applyMove(move);
        
        if (visited.contains(newState)) continue;
        visited.add(newState);
        
        final newMoves = [...current.moves, move];
        
        // Check if solved
        final rays = simulateRays(level, newState);
        if (allTargetsReached(rays, level.targets)) {
          return SolutionResult(
            solvable: true,
            optimalMoves: newMoves.length,
            steps: newMoves,
          );
        }
        
        queue.add(_SearchNode(newState, newMoves));
      }
    }
    
    return SolutionResult.unsolvable();
  }
  
  /// Generate all possible moves from current state
  List<SolutionStep> _generatePossibleMoves(
    ProceduralLevel level,
    LevelState state,
  ) {
    final moves = <SolutionStep>[];
    
    // Mirror rotations (single direction - advance to next position)
    for (int i = 0; i < level.mirrors.length; i++) {
      if (!level.mirrors[i].rotatable) continue;
      
      final currentAngle = state.mirrorAngles[i] ?? 0;
      
      // Rotate to next discrete position (+45°)
      moves.add(SolutionStep(
        objectIndex: i,
        action: 'rotate',
        targetAngle: (currentAngle + 45) % 360,
      ));
    }
    
    // Mirror movements (to adjacent cells)
    for (int i = 0; i < level.mirrors.length; i++) {
      if (!level.mirrors[i].movable) continue;
      
      final currentPos = state.mirrorPositions[i]!;
      
      // Move to adjacent cells
      for (final delta in [
        const GridPos(1, 0), const GridPos(-1, 0),
        const GridPos(0, 1), const GridPos(0, -1),
      ]) {
        final newPos = GridPos(currentPos.x + delta.x, currentPos.y + delta.y);
        
        if (_isValidPosition(newPos, level, state, i)) {
          moves.add(SolutionStep(
            objectIndex: i,
            action: 'move',
            targetPos: newPos,
          ));
        }
      }
    }
    
    // Prism movements and rotations (similar logic)
    for (int i = 0; i < level.prisms.length; i++) {
      final prismIdx = level.mirrors.length + i;
      
      if (level.prisms[i].movable) {
        final currentPos = state.prismPositions[i]!;
        
        for (final delta in [
          const GridPos(1, 0), const GridPos(-1, 0),
          const GridPos(0, 1), const GridPos(0, -1),
        ]) {
          final newPos = GridPos(currentPos.x + delta.x, currentPos.y + delta.y);
          
          if (newPos.isValid) {
            moves.add(SolutionStep(
              objectIndex: prismIdx,
              action: 'move',
              targetPos: newPos,
            ));
          }
        }
        
        // Rotation
        final currentAngle = state.prismAngles[i] ?? 0;
        moves.add(SolutionStep(
          objectIndex: prismIdx,
          action: 'rotate',
          targetAngle: (currentAngle + 45) % 360,
        ));
      }
    }
    
    return moves;
  }
  
  bool _isValidPosition(GridPos pos, ProceduralLevel level, LevelState state, int excludeMirrorIdx) {
    if (!pos.isValid) return false;
    
    // Check walls
    for (final wall in level.walls) {
      if (wall.blocksCell(pos)) return false;
    }
    
    // Check other mirrors
    for (int i = 0; i < level.mirrors.length; i++) {
      if (i == excludeMirrorIdx) continue;
      if (state.mirrorPositions[i] == pos) return false;
    }
    
    // Check targets
    for (final target in level.targets) {
      if (target.position == pos) return false;
    }
    
    return true;
  }
  
  // ===== Ray Tracing Helpers =====
  
  Vector2 _directionToVector(LightDirection dir) {
    switch (dir) {
      case LightDirection.east: return const Vector2(1, 0);
      case LightDirection.west: return const Vector2(-1, 0);
      case LightDirection.north: return const Vector2(0, -1);
      case LightDirection.south: return const Vector2(0, 1);
    }
  }
  
  void _castRay(
    Vector2 start,
    Vector2 direction,
    String color,
    ProceduralLevel level,
    LevelState state,
    List<RaySegment> segments,
    int bounces,
  ) {
    if (bounces > 10) return;
    
    const maxLength = 2500.0;
    final end = start + direction * maxLength;
    
    // Find closest intersection
    Vector2? hitPoint;
    double? minDist;
    int? hitMirror;
    bool hitWall = false;
    
    // Check walls
    for (final wall in level.walls) {
      final wallStart = wall.start.toPixel();
      final wallEnd = wall.end.toPixel();
      
      // Expand wall to rectangle for intersection
      final intersection = _lineIntersection(start, end, wallStart, wallEnd);
      if (intersection != null) {
        final dist = (intersection - start).length;
        if (minDist == null || dist < minDist) {
          minDist = dist;
          hitPoint = intersection;
          hitWall = true;
          hitMirror = null;
        }
      }
    }
    
    // Check mirrors
    for (int i = 0; i < level.mirrors.length; i++) {
      final mirrorPos = state.mirrorPositions[i]!.toPixel();
      final mirrorAngle = (state.mirrorAngles[i] ?? 0) * pi / 180;
      
      // Mirror as line segment
      const mirrorHalfLen = 40.0;
      final mirrorDir = Vector2(cos(mirrorAngle), sin(mirrorAngle));
      final mirrorStart = mirrorPos - mirrorDir * mirrorHalfLen;
      final mirrorEnd = mirrorPos + mirrorDir * mirrorHalfLen;
      
      final intersection = _lineIntersection(start, end, mirrorStart, mirrorEnd);
      if (intersection != null) {
        final dist = (intersection - start).length;
        if (dist > 5 && (minDist == null || dist < minDist)) {
          minDist = dist;
          hitPoint = intersection;
          hitMirror = i;
          hitWall = false;
        }
      }
    }
    
    // Add segment
    if (hitPoint != null) {
      segments.add(RaySegment(start, hitPoint, color));
      
      // Reflect off mirror
      if (hitMirror != null && !hitWall) {
        final mirrorAngle = (state.mirrorAngles[hitMirror] ?? 0) * pi / 180;
        final normal = Vector2(-sin(mirrorAngle), cos(mirrorAngle));
        
        // Reflection formula: r = d - 2(d·n)n
        final dot = direction.x * normal.x + direction.y * normal.y;
        final reflected = Vector2(
          direction.x - 2 * dot * normal.x,
          direction.y - 2 * dot * normal.y,
        ).normalized;
        
        _castRay(hitPoint, reflected, color, level, state, segments, bounces + 1);
      }
    } else {
      segments.add(RaySegment(start, end, color));
    }
  }
  
  Vector2? _lineIntersection(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4) {
    final d1 = p2 - p1;
    final d2 = p4 - p3;
    
    final cross = d1.x * d2.y - d1.y * d2.x;
    if (cross.abs() < 0.001) return null;
    
    final d3 = p3 - p1;
    final t = (d3.x * d2.y - d3.y * d2.x) / cross;
    final u = (d3.x * d1.y - d3.y * d1.x) / cross;
    
    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return p1 + d1 * t;
    }
    
    return null;
  }
  
  bool _rayHitsTarget(RaySegment ray, Vector2 targetPos, String requiredColor) {
    // Check if ray color matches
    if (ray.color != requiredColor && requiredColor != 'any') {
      return false;
    }
    
    // Check distance from ray segment to target
    const hitRadius = 50.0; // Target hit radius
    
    // Point to line segment distance
    final d = ray.end - ray.start;
    final len = d.length;
    if (len < 1) return false;
    
    final n = d.normalized;
    final v = targetPos - ray.start;
    final t = (v.x * n.x + v.y * n.y).clamp(0.0, len);
    final closest = ray.start + n * t;
    final dist = (targetPos - closest).length;
    
    return dist <= hitRadius;
  }
}

class _SearchNode {
  final LevelState state;
  final List<SolutionStep> moves;
  
  const _SearchNode(this.state, this.moves);
}

