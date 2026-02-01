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

    test('Episode 5 Levels should have walls and differ', () {
       // Generate 5 levels with same Template ID (implied by Episode 5 index 0)
       // but different seeds.
       
       final levels = <GeneratedLevel>[];
       for (int i = 0; i < 5; i++) {
           levels.add(generator.generate(5, 0, i * 100));
       }
       
       for (final level in levels) {
           print('Seed: ${level.seed} -> Mirrors: ${level.mirrors.length}, Walls: ${level.walls.length}');
           expect(level.walls.length, greaterThan(0), reason: 'Level should have random walls now');
       }
       
       // Compare wall sets
       // Walls are Set<Wall>, compare positions
       final wallSets = levels.map((l) => l.walls.map((w) => w.position.toString()).toSet()).toList();
       
       expect(wallSets[0].length, isNot(0));
       
       // Check if sets are different
       bool allIdentical = true;
       for (int i = 1; i < wallSets.length; i++) {
           if (wallSets[i].length != wallSets[0].length || 
               !wallSets[i].containsAll(wallSets[0])) {
               allIdentical = false;
               break;
           }
       }
       
       if (allIdentical) {
           print('WARNING: All 5 levels had identical wall placement!');
       } else {
           print('SUCCESS: Wall placements vary between seeds.');
       }
       expect(allIdentical, isFalse, reason: 'Levels should vary due to random walls');
    });
  });
}
