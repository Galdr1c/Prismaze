// Debug blueprint generation
// Run with: flutter test test/procedural/debug_blueprint_test.dart --no-pub

import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  test('Debug blueprint generation', () {
    print('\n=== Debug Blueprint ===');
    final generator = LevelGenerator();
    
    // Try multiple seeds to see success rate
    int success = 0;
    int failed = 0;
    
    for (int seed = 0; seed < 20; seed++) {
      final level = generator.generate(3, 1, seed);
      if (level != null) {
        success++;
        print('Seed $seed: OK - moves=${level.meta.optimalMoves}, mirrors=${level.mirrors.length}, prisms=${level.prisms.length}');
        
        // Verify with tracer
        var state = GameState.fromLevel(level);
        final tracer = RayTracer();
        state = tracer.traceAndUpdateProgress(level, state);
        
        for (final move in level.solution) {
          if (move.type == MoveType.rotateMirror) {
            state = state.rotateMirror(move.objectIndex);
          } else {
            state = state.rotatePrism(move.objectIndex);
          }
          state = tracer.traceAndUpdateProgress(level, state);
        }
        
        print('  → Solved: ${state.allTargetsSatisfied(level.targets)}');
      } else {
        failed++;
        print('Seed $seed: FAILED');
      }
    }
    
    print('\nSuccess: $success / 20 (${(success * 5)}%)');
    print('Failed: $failed');
  });

  test('Simple E1/E2 still work', () {
    final generator = LevelGenerator();
    
    print('\n=== E1 ===');
    int e1 = 0;
    for (int i = 0; i < 10; i++) {
      if (generator.generate(1, i+1, 10000+i) != null) e1++;
    }
    print('E1: $e1/10');
    
    print('\n=== E2 ===');
    int e2 = 0;
    for (int i = 0; i < 10; i++) {
      if (generator.generate(2, i+1, 20000+i) != null) e2++;
    }
    print('E2: $e2/10');
  });
}
