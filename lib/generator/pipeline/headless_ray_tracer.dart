import 'dart:math';
import '../../core/models/models.dart';
import '../../core/models/objects.dart';
import '../models/generated_level.dart';

/// Deterministic Trace Stats
class TraceStats {
  final int rayCount;
  final int bounceCount;
  final int segmentCount;
  final bool solved;
  final bool loopDetected;

  TraceStats({
    required this.rayCount, 
    required this.bounceCount, 
    required this.segmentCount,
    required this.solved,
    this.loopDetected = false,
  });
}

/// HeadlessRayTracer using Fixed-Point Integer Math (HATA 1 Compliance)
/// Scale factor: 10,000 (1.0 grid unit = 10,000 units)
class HeadlessRayTracer {
  static const int scale = 10000;
  static const int halfScale = 5000;
  static const int maxBounces = 20;
  static const int maxRayLength = 20 * scale; // 20 units

  static TraceStats trace(GeneratedLevel level) {
    int rayCount = 0;
    int bounceCount = 0;
    int segmentCount = 0;
    
    // 1. Build Geometry (Integer Space)
    final mirrors = <_SimMirror>[];
    final walls = <_SimWall>[];
    final prisms = <_SimPrism>[];
    final targets = <_SimTarget>[];
    final sources = <_SimSource>[];
    
    for (var obj in level.objects) {
      final gridX = obj.position.x;
      final gridY = obj.position.y;
      
      if (obj is WallObject) {
        walls.add(_SimWall(gridX * scale, gridY * scale, scale, scale));
      } else if (obj is MirrorObject) {
         final cx = gridX * scale + halfScale;
         final cy = gridY * scale + halfScale;
         mirrors.add(_SimMirror(cx, cy, obj.orientation));
      } else if (obj is PrismObject) {
         final cx = gridX * scale + halfScale;
         final cy = gridY * scale + halfScale;
         prisms.add(_SimPrism(cx, cy, obj.orientation));
      } else if (obj is TargetObject) {
         final cx = gridX * scale + halfScale;
         final cy = gridY * scale + halfScale;
         targets.add(_SimTarget(cx, cy, obj.requiredColor));
      } else if (obj is SourceObject) {
         final cx = gridX * scale + halfScale;
         final cy = gridY * scale + halfScale;
         sources.add(_SimSource(cx, cy, obj.orientation, obj.color));
      }
    }
    
    final Set<int> visited = {}; // State tracking for loop detection
    bool loopDetected = false;

    // 2. Cast Rays
    for (var source in sources) {
       if (loopDetected) break;
       rayCount++;
       final dir = _getDirection(source.orientation);
       _cast(
         source.x, source.y, 
         dir.dx, dir.dy, 
         source.color, 
         0, 
         mirrors, walls, targets, prisms,
         (b) => bounceCount += b,
         (s) => segmentCount += s,
         visited,
         () => loopDetected = true,
       );
    }
    
    // Strict Policy: Loop detected = Unsolved/Rejected (HATA 4)
    bool solved = !loopDetected && targets.every((t) => t.isLit);
    
    return TraceStats(
      rayCount: rayCount, 
      bounceCount: bounceCount,
      segmentCount: segmentCount,
      solved: solved,
      loopDetected: loopDetected,
    );
  }
  
  static bool validateSolution(GeneratedLevel level) {
    return trace(level).solved;
  }
  
  static void _cast(
    int x1, int y1,
    int dx, int dy,
    LightColor color,
    int depth,
    List<_SimMirror> mirrors,
    List<_SimWall> walls,
    List<_SimTarget> targets,
    List<_SimPrism> prisms,
    Function(int) addBounce,
    Function(int) addSegment,
    Set<int> visited,
    Function() onLoop,
  ) {
    if (depth > maxBounces) {
      onLoop();
      return;
    }
    
    // State tracking: (X, Y, DX, DY, Mask)
    // Using a simple hash for visited set
    final int stateHash = Object.hash(x1, y1, dx, dy, color.mask);
    if (visited.contains(stateHash)) {
       onLoop();
       return;
    }
    visited.add(stateHash);

    addSegment(1);
    
    int x2 = x1 + dx * maxRayLength;
    int y2 = y1 + dy * maxRayLength;
    
    int closestDistSq = 0x7FFFFFFFFFFFFFFF; // Max int
    _SimMirror? hitMirror;
    _SimPrism? hitPrism;
    _IntPoint? hitPoint;
    bool hitWall = false;
    
    // Check Mirrors
    for (var m in mirrors) {
      final intersect = m.getIntersection(x1, y1, x2, y2);
      if (intersect != null) {
        int dSq = _distSq(x1, y1, intersect.x, intersect.y);
        if (dSq < closestDistSq && dSq > 100) { // Small epsilon in scale
           closestDistSq = dSq;
           hitPoint = intersect;
           hitMirror = m;
           hitWall = false;
        }
      }
    }
    
    // Check Walls
    for (var w in walls) {
       final intersect = w.getIntersection(x1, y1, x2, y2);
       if (intersect != null) {
         int dSq = _distSq(x1, y1, intersect.x, intersect.y);
         if (dSq < closestDistSq && dSq > 100) {
            closestDistSq = dSq;
            hitPoint = intersect;
            hitWall = true;
            hitMirror = null;
            hitPrism = null;
         }
       }
    }
    
    // Check Prisms
    for (var p in prisms) {
       final intersect = p.getIntersection(x1, y1, x2, y2);
       if (intersect != null) {
          int dSq = _distSq(x1, y1, intersect.x, intersect.y);
          if (dSq < closestDistSq && dSq > 100) {
             closestDistSq = dSq;
             hitPoint = intersect;
             hitPrism = p;
             hitMirror = null;
             hitWall = false;
          }
       }
    }
    
    // Finalize actual segment endpoint for target check
    int actualX2 = x2;
    int actualY2 = y2;
    if (hitPoint != null) {
       actualX2 = hitPoint.x;
       actualY2 = hitPoint.y;
    }

    // Check Targets (Occlusion-aware)
    for (var t in targets) {
       t.checkHit(x1, y1, actualX2, actualY2, color);
    }
    
    // Recursion
    if (hitMirror != null && hitPoint != null) {
       addBounce(1);
       final newDir = _reflect(dx, dy, hitMirror.orientation);
       _cast(hitPoint.x, hitPoint.y, newDir.dx, newDir.dy, color, depth + 1, mirrors, walls, targets, prisms, addBounce, addSegment, visited, onLoop);
    } else if (hitPrism != null && hitPoint != null) {
       addBounce(1);
       if (color == LightColor.white) {
          // Split into 3 rays from the Prism's CENTER
          final dirs = _split(hitPrism.orientation);
          for (var d in dirs) {
             _cast(hitPrism.cx, hitPrism.cy, d.dir.dx, d.dir.dy, d.color, depth + 1, mirrors, walls, targets, prisms, addBounce, addSegment, visited, onLoop);
          }
       } else {
          // Pass through
          _cast(hitPoint.x, hitPoint.y, dx, dy, color, depth + 1, mirrors, walls, targets, prisms, addBounce, addSegment, visited, onLoop);
       }
    }
  }

  static List<_SplitResult> _split(int prismOri) {
    // Base Ori 0: Red N(0), Green E(1), Blue W(3)
    return [
       _SplitResult(_getDirection((0 + prismOri) % 4), LightColor.red),
       _SplitResult(_getDirection((1 + prismOri) % 4), LightColor.green),
       _SplitResult(_getDirection((3 + prismOri) % 4), LightColor.blue),
    ];
  }

  static _IntDir _getDirection(int ori) {
    switch (ori % 4) {
      case 0: return _IntDir(0, -1); // N
      case 1: return _IntDir(1, 0);  // E
      case 2: return _IntDir(0, 1);  // S
      case 3: return _IntDir(-1, 0); // W
      default: return _IntDir(0, 0);
    }
  }

  static _IntDir _reflect(int dx, int dy, int mirrorOri) {
    // mirrorOri 0: |, 1: /, 2: -, 3: \
    switch (mirrorOri % 4) {
      case 0: // |
        return _IntDir(-dx, dy);
      case 1: // /
        // (1,0) -> (0,-1)
        // (0,1) -> (-1,0)
        return _IntDir(-dy, -dx);
      case 2: // -
        return _IntDir(dx, -dy);
      case 3: // \
        // (1,0) -> (0,1)
        // (0,-1) -> (-1,0)
        return _IntDir(dy, dx);
      default:
        return _IntDir(dx, dy);
    }
  }

  static int _distSq(int x1, int y1, int x2, int y2) {
    int dx = x2 - x1;
    int dy = y2 - y1;
    return dx * dx + dy * dy;
  }
}

class _IntPoint {
  final int x, y;
  _IntPoint(this.x, this.y);
}

class _IntDir {
  final int dx, dy;
  const _IntDir(this.dx, this.dy);
}

class _SimMirror {
  final int cx, cy;
  final int orientation;
  late final int x1, y1, x2, y2;

  _SimMirror(this.cx, this.cy, this.orientation) {
    // 0: |, 1: /, 2: -, 3: \
    // Size approx 0.8 units
    const int len = 4000; 
    switch (orientation % 4) {
      case 0: // |
        x1 = cx; y1 = cy - len; x2 = cx; y2 = cy + len;
        break;
      case 1: // /
        x1 = cx - len; y1 = cy + len; x2 = cx + len; y2 = cy - len;
        break;
      case 2: // -
        x1 = cx - len; y1 = cy; x2 = cx + len; y2 = cy;
        break;
      case 3: // \
        x1 = cx - len; y1 = cy - len; x2 = cx + len; y2 = cy + len;
        break;
      default:
        x1 = cx; y1 = cy; x2 = cx; y2 = cy;
    }
  }

  _IntPoint? getIntersection(int rx1, int ry1, int rx2, int ry2) {
    return _intersect(rx1, ry1, rx2, ry2, x1, y1, x2, y2);
  }
}

class _SimWall {
  final int x, y, w, h;
  _SimWall(this.x, this.y, this.w, this.h);

  _IntPoint? getIntersection(int rx1, int ry1, int rx2, int ry2) {
    // 4 sides
    final points = [
      _intersect(rx1, ry1, rx2, ry2, x, y, x + w, y),
      _intersect(rx1, ry1, rx2, ry2, x + w, y, x + w, y + h),
      _intersect(rx1, ry1, rx2, ry2, x + w, y + h, x, y + h),
      _intersect(rx1, ry1, rx2, ry2, x, y + h, x, y),
    ];
    _IntPoint? best;
    int minDistSq = 0x7FFFFFFFFFFFFFFF;
    for (var p in points) {
      if (p != null) {
        int dSq = (p.x - rx1) * (p.x - rx1) + (p.y - ry1) * (p.y - ry1);
        if (dSq < minDistSq) {
          minDistSq = dSq;
          best = p;
        }
      }
    }
    return best;
  }
}

class _SimTarget {
  final int cx, cy;
  final LightColor reqColor;
  int currentMask = 0;
  
  bool get isLit => currentMask == reqColor.mask;

  _SimTarget(this.cx, this.cy, this.reqColor);

  void checkHit(int x1, int y1, int x2, int y2, LightColor color) {
    int dx = x2 - x1;
    int dy = y2 - y1;
    int lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return;

    int num = (cx - x1) * dx + (cy - y1) * dy;
    int px, py;
    
    if (num <= 0) {
      px = x1;
      py = y1;
    } else if (num >= lenSq) {
      px = x2;
      py = y2;
    } else {
      int halfLenSq = lenSq ~/ 2;
      int signX = (num * dx < 0) ? -1 : 1;
      px = x1 + (num * dx + signX * halfLenSq) ~/ lenSq;
      int signY = (num * dy < 0) ? -1 : 1;
      py = y1 + (num * dy + signY * halfLenSq) ~/ lenSq;
    }
    
    int dSq = (cx - px) * (cx - px) + (cy - py) * (cy - py);
    if (dSq < (3000 * 3000)) {
       currentMask |= color.mask;
    }
  }
}

class _SimSource {
  final int x, y, orientation;
  final LightColor color;
  _SimSource(this.x, this.y, this.orientation, this.color);
}

class _SplitResult {
  final _IntDir dir;
  final LightColor color;
  _SplitResult(this.dir, this.color);
}

class _SimPrism {
  final int cx, cy, orientation;
  _SimPrism(this.cx, this.cy, this.orientation);

  _IntPoint? getIntersection(int rx1, int ry1, int rx2, int ry2) {
    // Square check approx 0.8 units
    const int half = 4000;
    final points = [
      _intersect(rx1, ry1, rx2, ry2, cx - half, cy - half, cx + half, cy - half),
      _intersect(rx1, ry1, rx2, ry2, cx + half, cy - half, cx + half, cy + half),
      _intersect(rx1, ry1, rx2, ry2, cx + half, cy + half, cx - half, cy + half),
      _intersect(rx1, ry1, rx2, ry2, cx - half, cy + half, cx - half, cy - half),
    ];
    _IntPoint? best;
    int minDistSq = 0x7FFFFFFFFFFFFFFF;
    for (var p in points) {
      if (p != null) {
        int dSq = (p.x - rx1) * (p.x - rx1) + (p.y - ry1) * (p.y - ry1);
        if (dSq < minDistSq) {
          minDistSq = dSq;
          best = p;
        }
      }
    }
    return best;
  }
}

_IntPoint? _intersect(int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4) {
  int denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
  if (denom == 0) return null;

  int numA = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
  int numB = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3);

  bool intersect;
  if (denom > 0) {
    intersect = (numA >= 0 && numA <= denom && numB >= 0 && numB <= denom);
  } else {
    intersect = (numA <= 0 && numA >= denom && numB <= 0 && numB >= denom);
  }

  if (intersect) {
    // Rounding division: (num * delta + halfDenom) ~/ denom
    int halfDenom = denom.abs() ~/ 2;
    int sign = (numA * (x2 - x1) < 0) ? -1 : 1;
    int ix = x1 + (numA * (x2 - x1) + sign * halfDenom) ~/ denom;
    
    sign = (numA * (y2 - y1) < 0) ? -1 : 1;
    int iy = y1 + (numA * (y2 - y1) + sign * halfDenom) ~/ denom;
    
    return _IntPoint(ix, iy);
  }
  return null;
}
