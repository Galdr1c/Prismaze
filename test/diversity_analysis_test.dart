import 'package:test/test.dart';
import '../lib/game/procedural/level_generator.dart';
import '../lib/game/procedural/models/models.dart';

void main() {
  group('Diversity Analysis', () {
    late LevelGenerator generator;

    setUp(() {
      generator = LevelGenerator();
      generator.generate(1, 0, 0); // Warmup
    });

    test('Episode 1 Levels should use various templates', () {
       // Generate 20 levels to hit multiple templates (index usually maps to template)
       final templatesUsed = <String>{};
       
       for (int i = 0; i < 20; i++) {
           final level = generator.generate(1, i, i * 100);
           print('Level $i (Seed ${level.seed}) -> Template: ${level.meta.templateId}');
           templatesUsed.add(level.meta.templateId!);
           
           // Basic validation
           expect(level.source, isNotNull);
           expect(level.targets, isNotEmpty);
       }
       
       print('Templates used: $templatesUsed');
       expect(templatesUsed.length, greaterThan(1), reason: 'Should use multiple templates');
       expect(templatesUsed.contains('e1_straight_shot'), isTrue);
       expect(templatesUsed.contains('e1_l_turn'), isTrue);
    });
  });
}
