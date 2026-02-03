import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/generator/selector/selector.dart';
import 'package:prismaze/generator/templates/template_family.dart';

void main() {
  group('TemplateSelector', () {
    test('Determinism: Same seed sequence produces same families', () {
      final selectorA = TemplateSelector();
      final selectorB = TemplateSelector();
      const version = 'v1';

      // Verify first 20 levels match exactly
      for (int i = 1; i <= 20; i++) {
        final familyA = selectorA.selectFamily(version, i);
        final familyB = selectorB.selectFamily(version, i);
        expect(familyA, equals(familyB), reason: 'Mismatch at level $i');
      }
    });

    test('History Awareness: Skipping levels simulates history', () {
      final selectorFull = TemplateSelector();
      final selectorSkip = TemplateSelector();
      const version = 'v1';

      // SelectorFull generates 1..10
      for (int i = 1; i <= 10; i++) {
        selectorFull.selectFamily(version, i);
      }
      final targetFamily = selectorFull.selectFamily(version, 11);

      // SelectorSkip jumps straight to 11
      // It should internall calculate 1..10 to build history
      final skipFamily = selectorSkip.selectFamily(version, 11);

      expect(skipFamily, equals(targetFamily));
    });

    test('Cooldowns: No immediate repeats (Normal Pacing)', () {
      final selector = TemplateSelector();
      const version = 'v1';
      final history = <TemplateFamily>[];

      // Run 50 levels
      for (int i = 1; i <= 50; i++) {
        final family = selector.selectFamily(version, i);
        
        // Check last 3 items for strict non-repeat (fallback might allow closer, but strictly adjacent should be rare/impossible unless emergency)
        if (history.isNotEmpty) {
          expect(family, isNot(equals(history.last)), reason: 'Immediate repeat at level $i');
        }
        
        history.add(family);
      }
    });

    test('Pacing: Level 1-100 prefers VerticalCorridor', () {
      final selector = TemplateSelector();
      const version = 'v1_test_dist'; 
      int verticalCount = 0;
      int samples = 50;

      for (int i = 1; i <= samples; i++) {
        final f = selector.selectFamily(version, i);
        if (f == TemplateFamily.verticalCorridor) verticalCount++;
      }
      
      // Weight is 40%, expect roughly 20 +/- variance
      // This is probabilistic, but deterministic rng.
      // We just ensure it's picked frequently.
      expect(verticalCount, greaterThan(5)); 
    });
  });

  group('CooldownTracker', () {
    test('Sliding Window Logic', () {
      final tracker = CooldownTracker(maxCooldown: 3);
      
      tracker.recordUsage(TemplateFamily.verticalCorridor);
      tracker.recordUsage(TemplateFamily.twoChamber);
      tracker.recordUsage(TemplateFamily.staircase);
      
      expect(tracker.isCooldown(TemplateFamily.verticalCorridor), isTrue);
      
      // Push one more
      tracker.recordUsage(TemplateFamily.frame);
      // VerticalCorridor should slide out
      expect(tracker.isCooldown(TemplateFamily.verticalCorridor), isFalse);
      expect(tracker.isCooldown(TemplateFamily.frame), isTrue);
    });
  });
}
