// Episode 3 batch validation test with full metrics output
// Run with: dart test/procedural/episode3_validation_test.dart

import 'dart:io';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  print('\n=========================================');
  print('EPISODE 3 BLUEPRINT VALIDATION (N=200)');
  print('=========================================\n');

  final generator = LevelGenerator();
  final config = EpisodeConfig.forEpisode(3);
  final solver = Solver();

  int generated = 0;
  int failed = 0;
  int shortcuts = 0;
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

      // Verify no shortcuts on 10% sample
      if (i % 10 == 0) {
        final initialState = GameState.fromLevel(level);
        final shortcutCheck = solver.solveWithMaxDepth(
          level,
          initialState,
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

  final avgGenTime =
      genTimes.isNotEmpty ? genTimes.reduce((a, b) => a + b) / genTimes.length : 0.0;

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
  final acceptOk = generated >= 120;
  print('Accept >= 60%: ${acceptOk ? "✓ PASS" : "✗ FAIL"} (${(generated / 2).toStringAsFixed(0)}%)');
  print('Shortcuts == 0: ${shortcuts == 0 ? "✓ PASS" : "✗ FAIL"} ($shortcuts)');
  final avgTimeOk = avgGenTime < 200;
  print(
      'Avg time < 200ms: ${avgTimeOk ? "✓ PASS" : "✗ FAIL"} (${avgGenTime.toStringAsFixed(1)}ms)');

  // Save to file
  final report = StringBuffer();
  report.writeln('# Episode 3 Blueprint Validation Report');
  report.writeln('');
  report.writeln('## Summary');
  report.writeln('- Generated: $generated / 200 (${(generated / 2).toStringAsFixed(0)}%)');
  report.writeln('- Failed: $failed');
  report.writeln('- Shortcuts: $shortcuts');
  report.writeln('- Avg Gen Time: ${avgGenTime.toStringAsFixed(1)}ms');
  if (movesList.isNotEmpty) {
    report.writeln('');
    report.writeln('## Moves Distribution');
    report.writeln('- Min: ${movesList.first}');
    report.writeln('- p50: ${movesList[movesList.length ~/ 2]}');
    report.writeln('- Max: ${movesList.last}');
  }

  File('lib/tools/logs/episode3_validation_report.md').writeAsStringSync(report.toString());
  print('\n✓ Saved to lib/tools/logs/episode3_validation_report.md');
}
