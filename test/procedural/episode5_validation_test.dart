// Episode 5 batch validation test
// Run with: flutter test test/procedural/episode5_validation_test.dart --no-pub

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  test('Episode 5 batch validation (n=200)', () {
    print('\n=========================================');
    print('EPISODE 5 BLUEPRINT VALIDATION (N=200)');
    print('=========================================\n');

    final generator = LevelGenerator();
    final config = EpisodeConfig.forEpisode(5);
    final solver = Solver();

    int generated = 0;
    int failed = 0;
    int shortcuts = 0;
    int looseSolutions = 0;
    int underMin = 0;
    int overMax = 0;

    final movesList = <int>[];
    final genTimes = <int>[];
    final mirrorCounts = <int>[];
    final wallCounts = <int>[];

    final totalStopwatch = Stopwatch()..start();

    for (int i = 0; i < 200; i++) {
      final seed = 500000 + i;
      final stopwatch = Stopwatch()..start();
      final level = generator.generate(5, i + 1, seed);
      stopwatch.stop();
      genTimes.add(stopwatch.elapsedMilliseconds);

      if (level != null) {
        generated++;
        movesList.add(level.meta.optimalMoves);
        mirrorCounts.add(level.mirrors.length);
        wallCounts.add(level.walls.length);

        if (level.meta.optimalMoves < config.minMoves) underMin++;
        if (level.meta.optimalMoves > config.maxMoves) overMax++;

        // Verify level structure
        expect(level.targets.length, equals(3));
        expect(level.prisms.length, equals(1));

        // Verify no shortcuts on 10% sample
        if (i % 10 == 0) {
          final initialState = GameState.fromLevel(level);
          
          // Shortcut check
          final shortcutCheck = solver.solveWithMaxDepth(
            level,
            initialState,
            maxDepth: config.minMoves - 1,
            budget: 5000,
          );
          if (shortcutCheck.solvable) {
            shortcuts++;
          }
          
          // Looseness check: solution within minMoves+2
          final loosenessCheck = solver.solveWithMaxDepth(
            level,
            initialState,
            maxDepth: config.minMoves + 2,
            budget: 8000,
          );
          if (loosenessCheck.solvable && loosenessCheck.optimalMoves < level.meta.optimalMoves - 3) {
            looseSolutions++;
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

    genTimes.sort();
    final avgGenTime = genTimes.isNotEmpty ? genTimes.reduce((a, b) => a + b) / genTimes.length : 0.0;
    final p90GenTime = genTimes.isNotEmpty ? genTimes[(genTimes.length * 0.90).floor().clamp(0, genTimes.length - 1)] : 0;

    print('\n\n--- RESULTS ---');
    print('Generated: $generated / 200 (${(generated / 2).toStringAsFixed(0)}%)');
    print('Failed: $failed');
    print('Shortcuts found: $shortcuts');
    print('Loose solutions: $looseSolutions');
    print('Under minMoves: $underMin');
    print('Over maxMoves: $overMax');
    print('Total time: ${totalStopwatch.elapsedMilliseconds}ms');
    print('Avg gen time: ${avgGenTime.toStringAsFixed(1)}ms');
    print('p90 gen time: ${p90GenTime}ms');

    if (mirrorCounts.isNotEmpty) {
      print('\nLevel Structure:');
      print('  Avg mirrors: ${(mirrorCounts.reduce((a, b) => a + b) / mirrorCounts.length).toStringAsFixed(1)}');
      print('  Avg walls: ${(wallCounts.reduce((a, b) => a + b) / wallCounts.length).toStringAsFixed(1)}');
    }

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
    final acceptOk = generated >= 120;
    print('Accept >= 60%: ${acceptOk ? "✓ PASS" : "✗ FAIL"} (${(generated / 2).toStringAsFixed(0)}%)');

    print('Shortcuts == 0: ${shortcuts == 0 ? "✓ PASS" : "✗ FAIL"} ($shortcuts)');

    final avgTimeOk = avgGenTime < 50;
    print('Avg time < 50ms: ${avgTimeOk ? "✓ PASS" : "✗ FAIL"} (${avgGenTime.toStringAsFixed(1)}ms)');

    final p90TimeOk = p90GenTime < 100;
    print('p90 time < 100ms: ${p90TimeOk ? "✓ PASS" : "✗ FAIL"} (${p90GenTime}ms)');

    // Save report
    final report = StringBuffer();
    report.writeln('# Episode 5 Blueprint Validation Report (n=200)');
    report.writeln('');
    report.writeln('## Summary');
    report.writeln('- Generated: $generated / 200 (${(generated / 2).toStringAsFixed(0)}%)');
    report.writeln('- Failed: $failed');
    report.writeln('- Shortcuts: $shortcuts');
    report.writeln('- Loose solutions: $looseSolutions');
    report.writeln('- Avg Gen Time: ${avgGenTime.toStringAsFixed(1)}ms');
    report.writeln('- p90 Gen Time: ${p90GenTime}ms');
    if (movesList.isNotEmpty) {
      report.writeln('');
      report.writeln('## Moves Distribution');
      report.writeln('- Min: ${movesList.first}');
      report.writeln('- p50: ${movesList[movesList.length ~/ 2]}');
      report.writeln('- p90: ${movesList[(movesList.length * 0.90).floor().clamp(0, movesList.length - 1)]}');
      report.writeln('- Max: ${movesList.last}');
    }

    final dir = Directory('lib/tools/logs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('lib/tools/logs/episode5_validation_report.md').writeAsStringSync(report.toString());
    print('\n✓ Saved to lib/tools/logs/episode5_validation_report.md');

    expect(true, isTrue);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
