import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/core/models/models.dart';
import 'package:prismaze/core/models/objects.dart';
import 'package:prismaze/generator/models/generated_level.dart';
import 'package:prismaze/core/logic/ray_tracer.dart';
import 'package:prismaze/core/logic/trace_result.dart';
import 'package:prismaze/generator/templates/templates.dart'; // Barrel file

void main() {
  // Helper to create a dummy level
  GeneratedLevel createLevel(List<GameObject> objects) {
    return GeneratedLevel(
      id: 1,
      seed: 0,
      template: const Template(family: TemplateFamily.verticalCorridor, variantId: 0, anchors: [], variableSlots: [], wallPresets: [], solutionSteps: []),
      objects: objects,
      appliedWallPattern: const WallPattern([]),
    );
  }

  group('RayTracer', () {
    test('Basic Reflection: Source -> Mirror -> Target', () {
      // 2 sources, 1 mirror, 1 target
      // Source at (0,0) East -> Mirror at (5,0) / -> Target at (5,5) South? No Mirror / reflects to North or South?
      
      // Mirror 1 (/ NE-SW): 
      // Incoming East(1) -> Reflected North(0).
      // Incoming South(2) -> Reflected West(3).
      
      // Let's setup:
      // Source at (0,2) pointing East(1).
      // Mirror at (4,2) with orientation 1 (/).
      // Should reflect North(0).
      // Target at (4,0) needing Red.
      
      final objects = [
        const SourceObject(position: GridPosition(0, 2), orientation: 1, color: LightColor.red),
        const MirrorObject(position: GridPosition(4, 2), orientation: 1),
        const TargetObject(position: GridPosition(4, 0), requiredColor: LightColor.red),
      ];
      
      final level = createLevel(objects);
      final result = RayTracer.trace(level);
      
      expect(result.success, isTrue);
      // Check Hit Map
      // Target Hash
      final tHash = objects[2].position.hashCode;
      expect(result.hitMap.containsKey(tHash), isTrue);
      expect(result.hitMap[tHash]!.contains(LightColor.red.mask), isTrue);
    });

    test('Prism Splitting: White -> R, G, B', () {
      // Source White at (2,2) South(2) -> Prism at (2,4)
      // Prism Orientation 0.
      // Emitters: N(R), E(G), W(B).
      // Since Prism is at (2,4), 
      // Red Ray -> (2,3) -> TargetR at (2,0)
      // Green Ray -> (3,4) -> TargetG at (5,4)
      // Blue Ray -> (1,4) -> TargetB at (0,4)
      
      final objects = [
        const SourceObject(position: GridPosition(2, 2), orientation: 2, color: LightColor.white),
        const PrismObject(position: GridPosition(2, 4) /*, orientation: 0 default */),
        const TargetObject(position: GridPosition(2, 0), requiredColor: LightColor.red),
        const TargetObject(position: GridPosition(5, 4), requiredColor: LightColor.green),
        const TargetObject(position: GridPosition(0, 4), requiredColor: LightColor.blue),
      ];
      
      final level = createLevel(objects);
      final result = RayTracer.trace(level);
      
      expect(result.success, isTrue, reason: "Prism should split and hit all 3 targets");
    });
    
    test('Loop Detection: Infinite Mirror Loop', () {
      // Two mirrors facing each other
      // M1 (0,0) Facing East? No mirrors don't 'face'.
      // M1 (0,0) | (0)
      // M2 (4,0) | (0)
      // Source at (2,0) East
      // Hit M2 -> Reflect West -> Hit M1 -> Reflect East ... Loop.
      
      // Mirror 0 (|) reflects East<->West.
      
      final objects = [
        const SourceObject(position: GridPosition(2, 0), orientation: 1, color: LightColor.red),
        const MirrorObject(position: GridPosition(0, 0), orientation: 0),
        const MirrorObject(position: GridPosition(4, 0), orientation: 0),
      ];
      
      final level = createLevel(objects);
      
      // Should finish without hanging
      final result = RayTracer.trace(level);
      
      // Just check it returns.
      expect(result.segments.length, greaterThan(0));
      expect(result.segments.length, lessThan(1000)); // Should stop well before maxSteps
    });

    test('Blocker stops ray', () {
      // Source -> Blocker -> Target
      final objects = [
        const SourceObject(position: GridPosition(0, 0), orientation: 1, color: LightColor.red),
        const BlockerObject(position: GridPosition(2, 0)),
        const TargetObject(position: GridPosition(4, 0), requiredColor: LightColor.red),
      ];
      
      final level = createLevel(objects);
      final result = RayTracer.trace(level);
      
      expect(result.success, isFalse);
       // Target not hit
       final tHash = objects[2].position.hashCode;
       expect(result.hitMap.containsKey(tHash), isFalse);
    });
  });
}
