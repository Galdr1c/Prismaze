import 'package:test/test.dart';
import '../lib/game/procedural/level_generator.dart';
import '../lib/game/procedural/models/models.dart';

void main() {
  group('Full System Integration', () {
    late LevelGenerator mainGenerator;

    setUp(() {
      mainGenerator = LevelGenerator();
    });

    test('Episode 1 uses Hybrid System (Template)', () {
       final level = mainGenerator.generate(1, 0, 123);
       expect(level.episode, 1);
       expect(level.meta.templateId, isNotNull, reason: 'E1 should use template');
       print('E1 Template: ${level.meta.templateId}');
    });

    test('Episode 5 uses Hybrid System (Template)', () {
       final level = mainGenerator.generate(5, 0, 123);
       expect(level.episode, 5);
       expect(level.meta.templateId, isNotNull, reason: 'E5 should use template');
       print('E5 Template: ${level.meta.templateId}');
    });

    test('Episode 6 uses Procedural System (Fallback)', () {
       // E6 is > 5, so should fallback.
       // Note: Procedural generation is SLOW, so we might need higher timeout.
       // Or we trust logic flow.
       // procedural generated levels usually have null templateId unless I assigned one?
       // _generateBlueprint method (for E3+) uses LevelMeta constructor.
       // In Step 521, _generateBlueprint calls LevelMeta(...). It does NOT pass templateId.
       // So templateId should be null.
       
       final level = mainGenerator.generate(6, 0, 123);
       expect(level.episode, 6);
       expect(level.meta.templateId, isNull, reason: 'E6 should use procedural (no templateId)');
    });
  });
}
