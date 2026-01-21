// Debug test for level generation
// Run with: flutter test test/procedural/debug_generation_test.dart --no-pub

import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  test('Debug Episode 3 generation', () {
    print('\n=== Debug E3 Generation ===');
    final generator = LevelGenerator();
    final config = EpisodeConfig.forEpisode(3);
    
    print('Config: minMoves=${config.minMoves}, maxMoves=${config.maxMoves}');
    print('Mirrors: ${config.minCriticalMirrors}-${config.maxCriticalMirrors}');
    print('Prisms: ${config.minCriticalPrisms}-${config.maxCriticalPrisms}');
    print('Attempts: ${config.generationAttempts}');
    
    final level = generator.generate(3, 1, 12345);
    
    if (level != null) {
      print('SUCCESS!');
      print('Moves: ${level.meta.optimalMoves}');
      print('Solution: ${level.solution.length} steps');
    } else {
      print('FAILED');
    }
  });

  test('Debug Episode 1 generation', () {
    print('\n=== Debug E1 Generation ===');
    final generator = LevelGenerator();
    
    for (int i = 0; i < 5; i++) {
      final level = generator.generate(1, i + 1, 10000 + i);
      if (level != null) {
        print('Seed ${10000 + i}: moves=${level.meta.optimalMoves}');
      } else {
        print('Seed ${10000 + i}: FAILED');
      }
    }
  });

  test('Debug Episode 2 generation', () {
    print('\n=== Debug E2 Generation ===');
    final generator = LevelGenerator();
    
    for (int i = 0; i < 5; i++) {
      final level = generator.generate(2, i + 1, 20000 + i);
      if (level != null) {
        print('Seed ${20000 + i}: moves=${level.meta.optimalMoves}');
      } else {
        print('Seed ${20000 + i}: FAILED');
      }
    }
  });
}
