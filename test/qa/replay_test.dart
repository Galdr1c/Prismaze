import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/generator/generator.dart';

void main() {
  group('QA Replay Validation Suite', () {
    late GeneratorPipeline pipeline;

    setUp(() {
      pipeline = GeneratorPipeline();
    });

    test('Verify 50 levels are solvable (ReplayValidator)', () {
      final int levelCount = 50;
      final String version = 'v1';
      int solvableCount = 0;
      int failures = 0;

      print('Starting Replay Validation on $levelCount levels...');

      for (int i = 1; i <= levelCount; i++) {
        // Use a stride to get varied randomness if sequential indices share seed properties (usually not, but good practice)
        // Here we just use i.
        final level = pipeline.generateLevel(version: version, levelIndex: i);
        
        final isSolvable = ReplayValidator.validate(level);
        
        if (isSolvable) {
          solvableCount++;
        } else {
          failures++;
          print('FAILED: Level $i is not solvable with defined solution steps!');
          print('Template: ${level.template.family.name}-${level.template.variantId}');
          // TODO: Print failing reason if Validator supported it
        }
      }

      print('Replay Result: $solvableCount/$levelCount solvable.');
      
      expect(failures, equals(0), reason: '$failures levels generated were unsolvable!');
    });
  });
}
