// Timing test - run with:
// flutter test test/procedural/timing_test.dart --no-pub

import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  test('Single level timing', () {
    final generator = LevelGenerator();
    
    print('\n=== TIMING TEST ===');
    
    for (int episode = 1; episode <= 3; episode++) {
      final stopwatch = Stopwatch()..start();
      final level = generator.generate(episode, 1, 12345 + episode);
      stopwatch.stop();
      
      if (level != null) {
        print('Episode $episode: ${stopwatch.elapsedMilliseconds}ms, moves=${level.meta.optimalMoves}');
      } else {
        print('Episode $episode: ${stopwatch.elapsedMilliseconds}ms (FAILED)');
      }
    }
  });

  test('Episode 1 only - 5 levels', () {
    final generator = LevelGenerator();
    
    print('\n=== EPISODE 1 (5 levels) ===');
    
    final stopwatch = Stopwatch()..start();
    int success = 0;
    
    for (int i = 0; i < 5; i++) {
      final level = generator.generate(1, i + 1, 10000 + i);
      if (level != null) success++;
    }
    
    stopwatch.stop();
    print('Generated $success/5 in ${stopwatch.elapsedMilliseconds}ms');
    print('Avg: ${stopwatch.elapsedMilliseconds / 5}ms per level');
  });
}
