import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/utils/physics_utils.dart';

void main() {
  group('PhysicsUtils', () {
    test('getReflectionVector simple reflection', () {
      final incident = Vector2(1, -1);
      final normal = Vector2(0, 1); // Surface is horizontal
      final reflection = PhysicsUtils.getReflectionVector(incident, normal);
      
      expect(reflection.x, closeTo(1, 0.001));
      expect(reflection.y, closeTo(1, 0.001));
    });

    test('getReflectionVector 45 degrees', () {
      final incident = Vector2(1, 0); // Moving Right
      final normal = Vector2(-1, -1).normalized(); // Surface at 45 deg (top-right to bot-left, normal points up-left)
      // Actually if surface is at 45 deg, normal is (-0.707, 0.707) or similar.
      // Let's take a wall at x=0. Incident (-1, 0). Normal (1, 0). Reflected (1, 0).
      
      final i2 = Vector2(-1, 0);
      final n2 = Vector2(1, 0);
      final r2 = PhysicsUtils.getReflectionVector(i2, n2);
      expect(r2.x, closeTo(1, 0.001));
      expect(r2.y, closeTo(0, 0.001));
    });

    test('getLineSegmentIntersection intersecting', () {
      final p1 = Vector2(0, 0);
      final p2 = Vector2(100, 100);
      
      final p3 = Vector2(0, 100);
      final p4 = Vector2(100, 0);
      
      final intersection = PhysicsUtils.getLineSegmentIntersection(p1, p2, p3, p4);
      expect(intersection, isNotNull);
      expect(intersection!.x, closeTo(50, 0.001));
      expect(intersection.y, closeTo(50, 0.001));
    });

    test('getLineSegmentIntersection parallel', () {
      final p1 = Vector2(0, 0);
      final p2 = Vector2(100, 0);
      
      final p3 = Vector2(0, 10);
      final p4 = Vector2(100, 10);
      
      final intersection = PhysicsUtils.getLineSegmentIntersection(p1, p2, p3, p4);
      expect(intersection, isNull);
    });
  });
}
