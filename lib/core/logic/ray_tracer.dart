import '../models/models.dart';
import '../../generator/models/generated_level.dart';
import 'color_mixer.dart';
import 'trace_result.dart';

/// Deterministic, integer-based Ray Tracer.
class RayTracer {
  static const int maxSteps = 500;
  static const int width = 6;
  static const int height = 12;

  /// Traces all beams in the level state and returns the result.
  static TraceResult trace(GeneratedLevel level) {
    // 1. Index objects for fast lookup
    final Map<int, GameObject> grid = {}; // PosHash -> Object
    // Pre-filter types
    final mirrors = <int, MirrorObject>{};
    final walls = <int, WallObject>{};
    final prisms = <int, PrismObject>{};
    final targets = <int, TargetObject>{};
    final absorbWalls = <int, BlockerObject>{}; // Assuming BlockerObject acts as absorber
    final sources = <SourceObject>[];

    for (var obj in level.objects) {
      final hash = obj.position.hashCode;
      grid[hash] = obj;
      
      if (obj is MirrorObject) mirrors[hash] = obj;
      else if (obj is WallObject) walls[hash] = obj;
      else if (obj is PrismObject) prisms[hash] = obj;
      else if (obj is TargetObject) targets[hash] = obj;
      else if (obj is BlockerObject) absorbWalls[hash] = obj;
      else if (obj is SourceObject) sources.add(obj);
    }
    
    // 2. Initialize tracking
    final List<RaySegment> segments = [];
    final Map<int, Set<int>> hitMap = {}; // PosHash -> Set<ColorMask>
    
    // Visited states for loop detection: Hash(x, y, dir, colorMask) is not enough?
    // We need Position + Direction + Color.
    // Let's use string key for simplicity or efficient int packing.
    // Key: (x << 24) | (y << 16) | (dir << 8) | color
    final Set<int> visited = {}; 

    // 3. Queue sources
    // Each source emits a ray.
    // If Prism splitting happens, we add to a queue.
    // Use an iterative queue to avoid recursion depth issues.
    final List<_RayState> queue = [];
    
    for (var src in sources) {
       // Direction mapping:
       // Source.orientation: 0=N, 1=E, 2=S, 3=W (matches Direction enum)
       final dir = Direction.fromInt(src.orientation);
       queue.add(_RayState(src.position, dir, src.color));
    }
    
    int steps = 0;
    
    // 4. Process Queue
    while (queue.isNotEmpty && steps < maxSteps) {
      steps++;
      final currentRay = queue.removeAt(0);
      
      // Step loop for this ray until it hits something or leaves bounds
      GridPosition pos = currentRay.start;
      Direction dir = currentRay.dir;
      LightColor color = currentRay.color;
      
      // Prevent infinite loops identical state
      // Note: State tracking should ideally be per-cell-entry.
      // But checking every step is expensive?
      // Since grid is small (6x12), checking every step is fine validation wise.
      
      // Start of segment
      GridPosition segStart = pos;
      
      // Advance ray cell by cell
      bool active = true;
      while (active && steps < maxSteps) {
         // Pack state: x(8) y(8) dir(4) color(4) -> 24 bits
         final stateKey = (pos.x << 20) | (pos.y << 12) | (dir.index << 8) | color.mask;
         if (visited.contains(stateKey)) {
           active = false;
           break; // Loop detected
         }
         visited.add(stateKey);

         // Move forward
         final nextPos = GridPosition(pos.x + dir.dx, pos.y + dir.dy);
         
         // Bounds check
         if (!_isValid(nextPos)) {
            // Hit world edge -> Stop
            segments.add(RaySegment(segStart, nextPos, color)); // Visualize hitting edge?
            active = false;
            break;
         }
         
         // Collision Check at NextPos
         final hash = nextPos.hashCode;
         final obj = grid[hash];
         
         if (obj != null) {
            // HIT LOGIC
            // 1. Target: Pass through but record hit
             if (targets.containsKey(hash)) {
                // Record hit
                hitMap.putIfAbsent(hash, () => {}).add(color.mask);
                // Continue passing through? 
                // Specs say "Target: Pass through".
                pos = nextPos;
                continue; 
             }
             
             // 2. Wall / Blocker: Absorb
             if (walls.containsKey(hash) || absorbWalls.containsKey(hash)) {
                segments.add(RaySegment(segStart, nextPos, color));
                active = false;
                break;
             }
             
             // 3. Mirror: Reflect
             if (mirrors.containsKey(hash)) {
                final mirror = mirrors[hash]!;
                // Can we reflect?
                // Logic: 
                // Orientation 0-7.
                // Let's implement a helper for reflection.
                // Return new direction or null (absorbed/invalid).
                final newDir = _getReflection(dir, mirror.orientation);
                 
                segments.add(RaySegment(segStart, nextPos, color));
                 
                if (newDir != null) {
                    // Reflected ray starts here and goes newDir
                    // Add to queue to process fresh state
                     queue.add(_RayState(nextPos, newDir, color));
                }
                active = false; // This ray segment ends
                break;
             }
             
             // 4. Prism: Split/Pass
             if (prisms.containsKey(hash)) {
                 // Prism logic:
                 // If Color White -> Split R, G, B
                 // Else -> Pass Through straight? Or stop?
                 // Usually Prism acts as Glass for non-white?
                 
                 segments.add(RaySegment(segStart, nextPos, color));
                 
                 if (color == LightColor.white) {
                    // SPLIT
                    // Orientation needed? Usually Prisms rotatable?
                    // PrismObject doesn't have orientation field in minimal model?
                    // Let's check PrismObject definition.
                    // It extends GameObject, so it HAS orientation (default 0).
                    
                    final prismOri = (obj as PrismObject).orientation; // Cast safe
                    _enqueueSplits(queue, nextPos, prismOri);
                 } else {
                    // Pass through straight (glass effect)
                    // Start new ray from here to avoid "passing through" complexity in one loop?
                    // Or just continue?
                    // Simpler to queue new ray to keep segment logic clean.
                    queue.add(_RayState(nextPos, dir, color));
                 }
                 active = false;
                 break;
             }
             
             // Default: Pass through (e.g. source, or unknown)
             // Source usually blocks? No, transparent.
         }
         
         // No blocking collision, continue walking
         pos = nextPos;
         steps++; // Count walking steps too? Yes for loop safety
      }
      
      // If loop ended naturally (active=true but loop condition broke?), 
      // likely maxSteps or queue processed.
      // If we walked out of active loop without collision (step limit?), finalize segment.
      if (active) {
         segments.add(RaySegment(segStart, pos, color));
      }
    }
    
    // 5. Evaluate Success
    bool allSatisfied = true;
    for (var tHash in targets.keys) {
      final req = targets[tHash]!.requiredColor;
      final hits = hitMap[tHash] ?? {};
      
      // Merge all hits
      int combinedMask = 0;
      for (var m in hits) combinedMask |= m;
      
      if (combinedMask != req.mask) {
        allSatisfied = false;
        break;
      }
    }
    
    return TraceResult(
      segments: segments,
      hitMap: hitMap,
      success: allSatisfied,
    );
  }

  /// Check if position is within traceable area (includes border layer).
  /// Border walls at -1 and 6/12 should stop beams.
  static bool _isValid(GridPosition p) {
    // Include border layer: x in [-1, 6], y in [-1, 12]
    return p.x >= -1 && p.x <= 6 && p.y >= -1 && p.y <= 12;
  }
  
  /// Check if position is within the playable grid (excludes border).
  static bool _isPlayArea(GridPosition p) {
    return p.x >= 0 && p.x < width && p.y >= 0 && p.y < height;
  }
  
  // Look Up Table for Mirror Reflection
  // Incoming Direction (N,E,S,W) vs Mirror Orientation (0..7)
  // Directions: 0=N, 1=E, 2=S, 3=W (Int)
  // Mirror 0: | (Vertical). Reflects E<->W. Absorbs N/S (or passes?).
  // Standard Mirror:
  // 0: | (Vertical)
  // 1: / (NE-SW)
  // 2: - (Horizontal)
  // 3: \ (NW-SE)
  // 4...7: Repeats? Usually 180 symmetry.
  
  static Direction? _getReflection(Direction incoming, int mirrorOri) {
    final i = incoming.index; // 0..3
    final m = mirrorOri % 4; // 0..3 symmetry
    
    // Note: Incoming is direction OF MOTION.
    // e.g. Moving North (0). Hitting Mirror.
    
    // Map: (Incoming, Mirror) -> Outgoing
    // Mirror 0 (|): 
    //   E(1) -> W(3), W(3) -> E(1). 
    //   N(0) -> Continue? Or Absorb? 
    //   Real mirror reflects everything based on normal.
    //   But in Grid, "Grazing" hits (N hitting |) usually ignore or hit edge?
    //   Let's assume "Edge Hit" = Block/Absorb for perpendicular/parallel mismatch?
    //   Or standard physics: Reflect across Normal.
    //   Mirror | Normal is (1,0) [East] or (-1,0) [West].
    //   N(0,-1) reflected across (1,0)? 
    //   R = I - 2(I.N)N.  (0,-1) . (1,0) = 0.
    //   R = I. So N->N. 
    //   So parallel rays PASS or GRAZE. 
    //   Let's assume BLOCK for simplicity if parallel? Or Pass?
    //   Prismaze logic: Mirrors are thin.
    
    // Let's implement Standard Diagonal Mirrors first (1, 3).
    // Mirror 1 (/): Normal (-1, 1). 
    // N(0) -> E(1). 
    // E(1) -> N(0).
    // S(2) -> W(3).
    // W(3) -> S(2).
    
    // Mirror 3 (\): Normal (1, 1).
    // N(0) -> W(3).
    // W(3) -> N(0).
    // S(2) -> E(1).
    // E(1) -> S(2).
    
    // Mirror 0 (|):
    // E(1) -> W(3).
    // W(3) -> E(1).
    // N(0), S(2) -> Absorb/Block (Backside?) or Pass?
    
    // Mirror 2 (-):
    // N(0) -> S(2).
    // S(2) -> N(0).
    
    switch (m) {
      case 0: // |
        if (i == 1) return Direction.west;
        if (i == 3) return Direction.east;
        return null; // Block N/S
      case 1: // /
        if (i == 0) return Direction.east;
        if (i == 1) return Direction.north;
        if (i == 2) return Direction.west;
        if (i == 3) return Direction.south;
        return null;
      case 2: // -
        if (i == 0) return Direction.south;
        if (i == 2) return Direction.north;
        return null;
      case 3: // \
        if (i == 0) return Direction.west;
        if (i == 3) return Direction.north;
        if (i == 2) return Direction.east;
        if (i == 1) return Direction.south;
        return null;
    }
    return null;
  }
  
  static void _enqueueSplits(List<_RayState> queue, GridPosition pos, int orientation) {
      // Prism Split Logic (Fixed T-Split)
      // Ori 0 (Upright): Input S->N(0)? 
      // Actually Prism usually takes INPUT from specific side? 
      // Or Omnidirectional?
      // Assuming Omnidirectional Source-Like emission for simplicty:
      // R, G, B emit in fixed directions relative to orientation.
      
      // Let's assume standard "White Hit" -> Explosion of color.
      // Orientation 0:
      // Red -> North
      // Blue -> East 
      // Yellow -> West? (Or Green?)
      // Wait, LightColor has Red(1), Green(2), Blue(4). Yellow=R+G.
      // Primary Splits: R, G, B?
      // Prismaze usually splits to R, G, B.
      
      // Directions:
      // Base (Ori 0):
      // Red: North
      // Green: East
      // Blue: West 
      // (Just guessing a T-shape).
      
      // Rotated by orientation (clockwise 90).
      
      // Base:
      // R: N(0)
      // G: E(1)
      // B: W(3)
      
      // Rotate indices by orientation.
      
      void add(LightColor c, int baseDirIdx) {
          int finalDir = (baseDirIdx + orientation) % 4;
          queue.add(_RayState(pos, Direction.fromInt(finalDir), c));
      }
      
      add(LightColor.red, 0);   // North
      add(LightColor.green, 1); // East
      add(LightColor.blue, 3);  // West
  }
}

class _RayState {
  final GridPosition start;
  final Direction dir;
  final LightColor color;
  
  _RayState(this.start, this.dir, this.color);
}
