
import 'package:test/test.dart';
import 'package:prismaze/game/procedural/level_generator.dart';
import 'package:prismaze/game/procedural/episode_config.dart';
import 'package:prismaze/game/procedural/solver.dart';
import 'package:prismaze/game/procedural/models/models.dart';

void main() {
  group('LevelGenerator Verification', () {
    late LevelGenerator generator;
    late Solver solver;

    setUp(() {
      generator = LevelGenerator();
      solver = Solver();
    });

    test('Episode 3 levels are solvable', () {
      _verifyEpisode(generator, solver, 3, 20);
    });

    test('Episode 4 levels are solvable', () {
      _verifyEpisode(generator, solver, 4, 20);
    });

    test('Episode 5 levels are solvable', () {
      _verifyEpisode(generator, solver, 5, 20);
    });
  });
}

void _verifyEpisode(LevelGenerator generator, Solver solver, int episode, int count) {
  int validCount = 0;
  for (int i = 0; i < count; i++) {
    try {
      final level = generator.generate(episode, i, 1000 + i);
      final initialState = GameState.fromLevel(level);
      
      // Use a generous budget for verification
      final solution = solver.solve(level, initialState, budget: 100000);
      
      if (solution.solvable) {
        validCount++;
      } else {
        // If regular solver fails, check if the PLANNED solution is valid
        // (This mimics the game's acceptance criteria, but strictly)
        if (LevelGenerator.validateLevelSolution(level)) {
           // It's valid by blueprint, even if solver timed out
           validCount++;
        } else {
           print('❌ Level E$episode:$i (Seed ${1000+i}) is UNSOLVABLE');
        }
      }
    } catch (e) {
      print('❌ Level E$episode:$i generation failed with error: $e');
    }
  }
  
  print('✅ Episode $episode: $validCount/$count levels solvable');
  expect(validCount, equals(count), reason: 'All generated levels should be solvable');
}
