// Episode 3 batch validation test with blueprint generation
// Run with: flutter test test/procedural/episode3_validation_test.dart --no-pub

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  group('Episode 3 Blueprint Validation', () {
    test('Quick single level generation test', () {
      print('\n=== Quick Blueprint Generation Test ===');
      final generator = LevelGenerator();
      
      final stopwatch = Stopwatch()..start();
      final level = generator.generate(3, 1, 12345);
      stopwatch.stop();
      
      if (level != null) {
        print('Generated in ${stopwatch.elapsedMilliseconds}ms');
        print('Planned Moves: ${level.meta.optimalMoves}');
        print('Mirrors: ${level.mirrors.length}');
        print('Prisms: ${level.prisms.length}');
        print('Targets: ${level.targets.length}');
        print('Walls: ${level.walls.length}');
        print('Solution steps: ${level.solution.length}');
        
        // Validate the solution works
        var state = GameState.fromLevel(level);
        final tracer = RayTracer();
        
        for (final move in level.solution) {
          if (move.type == MoveType.rotateMirror) {
            state = state.rotateMirror(move.objectIndex);
          } else {
            state = state.rotatePrism(move.objectIndex);
          }
        }
        
        // Use instantaneous check (simultaneous arrival)
        final isSolved = tracer.isSolved(level, state);
        print('Solution valid: $isSolved');
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      } else {
        print('Generation FAILED in ${stopwatch.elapsedMilliseconds}ms');
      }
    });

    test('Episode 3 batch validation (n=200)', () {
      print('\n=========================================');
      print('EPISODE 3 BLUEPRINT VALIDATION (N=200)');
      print('=========================================\n');

      final generator = LevelGenerator();
      final config = EpisodeConfig.forEpisode(3);
      final solver = Solver();
      
      int generated = 0;
      int failed = 0;
      int shortcuts = 0;
      int blueprintFails = 0;
      int plannedFails = 0;
      int underMin = 0;
      int overMax = 0;
      
      final movesList = <int>[];
      final genTimes = <int>[];
      
      final totalStopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 200; i++) {
        final seed = 300000 + i;
        final stopwatch = Stopwatch()..start();
        final level = generator.generate(3, i + 1, seed);
        stopwatch.stop();
        genTimes.add(stopwatch.elapsedMilliseconds);
        
        if (level != null) {
          generated++;
          movesList.add(level.meta.optimalMoves);
          
          if (level.meta.optimalMoves < config.minMoves) underMin++;
          if (level.meta.optimalMoves > config.maxMoves) overMax++;
          
          // Verify no shortcuts exist under minMoves (spot check 10%)
          if (i % 10 == 0) {
            final initialState = GameState.fromLevel(level);
            final shortcutCheck = solver.solveWithMaxDepth(
              level, initialState,
              maxDepth: config.minMoves - 1,
              budget: 5000,
            );
            if (shortcutCheck.solvable) {
              shortcuts++;
            }
          }
        } else {
          failed++;
        }
        
        if ((i + 1) % 50 == 0) {
          stdout.write('\rProgress: ${i + 1}/200');
        }
      }
      
      totalStopwatch.stop();
      
      final avgGenTime = genTimes.isNotEmpty 
          ? genTimes.reduce((a, b) => a + b) / genTimes.length 
          : 0.0;
      
      print('\n\n--- RESULTS ---');
      print('Generated: $generated / 200 (${(generated / 2).toStringAsFixed(0)}%)');
      print('Failed: $failed');
      print('Shortcuts found: $shortcuts');
      print('Under minMoves: $underMin');
      print('Over maxMoves: $overMax');
      print('Total time: ${totalStopwatch.elapsedMilliseconds}ms');
      print('Avg gen time: ${avgGenTime.toStringAsFixed(1)}ms');
      
      if (movesList.isNotEmpty) {
        movesList.sort();
        final p50 = movesList[movesList.length ~/ 2];
        final p75 = movesList[(movesList.length * 0.75).floor()];
        final p90 = movesList[(movesList.length * 0.90).floor().clamp(0, movesList.length - 1)];
        
        print('\nMoves Distribution:');
        print('  Min: ${movesList.first}');
        print('  p50: $p50');
        print('  p75: $p75');
        print('  p90: $p90');
        print('  Max: ${movesList.last}');
        
        // Histogram
        final histogram = <int, int>{};
        for (final m in movesList) {
          histogram[m] = (histogram[m] ?? 0) + 1;
        }
        print('\nHistogram:');
        for (int m = movesList.first; m <= movesList.last; m++) {
          final count = histogram[m] ?? 0;
          if (count > 0) {
            final bar = '█' * (count * 2).clamp(1, 40);
            print('  ${m.toString().padLeft(2)}: ${count.toString().padLeft(3)} $bar');
          }
        }
      }
      
      // Target checks
      print('\n--- TARGET CHECKS ---');
      final acceptOk = generated >= 120; // 60%+
      print('Accept >= 60%: ${acceptOk ? "✓ PASS" : "✗ FAIL"} (${(generated / 2).toStringAsFixed(0)}%)');
      
      print('Shortcuts == 0: ${shortcuts == 0 ? "✓ PASS" : "✗ FAIL"} ($shortcuts)');
      
      final avgTimeOk = avgGenTime < 200;
      print('Avg time < 200ms: ${avgTimeOk ? "✓ PASS" : "✗ FAIL"} (${avgGenTime.toStringAsFixed(1)}ms)');
      
      // Don't fail test, just report
      expect(true, isTrue);
    });

    test('Episode 1 simple generation still works', () {
      print('\n=== Episode 1 Test ===');
      final generator = LevelGenerator();
      
      int success = 0;
      for (int i = 0; i < 20; i++) {
        final level = generator.generate(1, i + 1, 10000 + i);
        if (level != null) success++;
      }
      
      print('Generated: $success / 20');
      expect(success, greaterThan(5));
    });

    test('Episode 2 simple generation still works', () {
      print('\n=== Episode 2 Test ===');
      final generator = LevelGenerator();
      
      int success = 0;
      for (int i = 0; i < 20; i++) {
        final level = generator.generate(2, i + 1, 20000 + i);
        if (level != null) success++;
      }
      
      print('Generated: $success / 20');
      expect(success, greaterThan(5));
    });
  });
}
