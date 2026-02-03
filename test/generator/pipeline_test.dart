import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/generator/generator.dart';
import 'package:prismaze/core/models/models.dart';
import 'package:prismaze/generator/models/generated_level.dart'; // Import generated_level

void main() {
  group('GeneratorPipeline', () {
    test('Generate Level 1 (Vertical Corridor) - Deterministic', () {
      final pipeline = GeneratorPipeline();
      final levelA = pipeline.generateLevel(version: 'v1', levelIndex: 1);
      final levelB = pipeline.generateLevel(version: 'v1', levelIndex: 1);
      
      expect(levelA.seed, equals(levelB.seed));
      expect(levelA.template.id, equals(levelB.template.id));
      expect(levelA.objects.length, equals(levelB.objects.length));
      
      // Verify objects
      final hasSource = levelA.objects.any((o) => o is SourceObject);
      final hasTarget = levelA.objects.any((o) => o is TargetObject);
      expect(hasSource, isTrue);
      expect(hasTarget, isTrue);
    });

    test('Replay Validation Passes for valid v0', () {
       // Since VerticalCorridor v0 is hardcoded valid, it should pass replay
       // IF the HeadlessRayTracer implementation is correct enough to reflect beams
       final pipeline = GeneratorPipeline();
       final level = pipeline.generateLevel(version: 'v1', levelIndex: 1);
       
       // Manually check validators
       final replayResult = ReplayValidator.validate(level);
       expect(replayResult, isTrue, reason: "Vertical Corridor v0 should be solvable");
    });
    
    test('Fallback Trigger (Simulation)', () {
       // Ideally we'd inject a broken template to force fallback.
       // But pipeline uses real catalog.
       // We can test FallbackHandler directly with a broken template?
    });
  });
}
