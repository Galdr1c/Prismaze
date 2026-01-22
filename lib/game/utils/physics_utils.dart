import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class PhysicsUtils {
  /// Calculates the reflection vector given an incident vector and a normal.
  /// R = I - 2(I . N)N
  static Vector2 getReflectionVector(Vector2 incident, Vector2 normal) {
    // Normal must be normalized
    final n = normal.normalized();
    final dotProduct = incident.dot(n);
    return incident - (n * (2 * dotProduct));
  }

  /// Calculates the intersection point of two line segments (p1-p2 and p3-p4).
  /// Returns null if parallel or not intersecting within segments.
  static Vector2? getLineSegmentIntersection(
    Vector2 p1,
    Vector2 p2,
    Vector2 p3,
    Vector2 p4,
  ) {
    final x1 = p1.x, y1 = p1.y;
    final x2 = p2.x, y2 = p2.y;
    final x3 = p3.x, y3 = p3.y;
    final x4 = p4.x, y4 = p4.y;

    final denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);

    if (denom == 0) {
      return null; // Parallel
    }

    final ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom;
    final ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom;

    if (ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1) {
      return Vector2(
        x1 + ua * (x2 - x1),
        y1 + ua * (y2 - y1),
      );
    }

    return null;
  }

  /// Calculates the refraction vector using Snell's Law.
  /// n1: refractive index of current medium
  /// n2: refractive index of new medium
  /// incident: normalized incident vector
  /// normal: normalized surface normal (pointing towards the side the ray comes from)
  /// Returns null if total internal reflection occurs.
  static Vector2? getRefractionVector(Vector2 incident, Vector2 normal, double n1, double n2) {
    final n = n1 / n2;
    final cosI = -normal.dot(incident);
    final sinT2 = n * n * (1.0 - cosI * cosI);
    
    if (sinT2 > 1.0) return null; // Total internal reflection

    final cosT = sqrt(1.0 - sinT2);
    return incident * n + normal * (n * cosI - cosT);
  }
  
  /// Applies a subtractive filter (Masking).
  /// NewColor = BeamColor & FilterColor (Bitwise AND on channels)
  static Color applyFilter(Color beam, Color filter) {
      if (beam.value == 0xFFFFFFFF) return filter; // White takes filter color (Optimization)
      
      int r = (beam.red * (filter.red / 255)).round();
      int g = (beam.green * (filter.green / 255)).round();
      int b = (beam.blue * (filter.blue / 255)).round();
      
      // Thresholding to clean up "nearly black" or preserve vividness
      // For gameplay, we usually want strict primary/secondary colors.
      // Let's assume standard RGB/CMY logic.
      
      return Color.fromARGB(255, r, g, b);
  }
  
  /// Mixes two additive light colors.
  /// Result = Color A + Color B (Clamped)
  static Color mixColors(Color c1, Color c2) {
      int r = (c1.red + c2.red).clamp(0, 255);
      int g = (c1.green + c2.green).clamp(0, 255);
      int b = (c1.blue + c2.blue).clamp(0, 255);
      return Color.fromARGB(255, r, g, b);
  }
}

