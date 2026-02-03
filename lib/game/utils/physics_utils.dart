import 'package:flame/components.dart';

class PhysicsUtils {
  /// Calculate intersection point of two line segments: (p1-p2) and (p3-p4)
  static Vector2? getLineSegmentIntersection(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4) {
    final x1 = p1.x; final y1 = p1.y;
    final x2 = p2.x; final y2 = p2.y;
    final x3 = p3.x; final y3 = p3.y;
    final x4 = p4.x; final y4 = p4.y;

    double denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
    
    if (denom == 0) return null; // Parallel lines
    
    double ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom;
    double ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom;
    
    if (ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1) {
      return Vector2(x1 + ua * (x2 - x1), y1 + ua * (y2 - y1));
    }
    
    return null;
  }

  /// Calculate reflection vector given incident vector and normal
  static Vector2 getReflectionVector(Vector2 incident, Vector2 normal) {
    // R = I - 2 * (I . N) * N
    final dot = incident.dot(normal);
    return incident - normal * (2 * dot);
  }
}
