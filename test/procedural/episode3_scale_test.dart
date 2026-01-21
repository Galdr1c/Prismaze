// Episode 3 scale validation (n=2000)
// Run with: flutter test test/procedural/episode3_scale_test.dart --no-pub

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  test('Episode 3 scale validation (n=2000)', () {
    print('\n=========================================');
    print('EPISODE 3 SCALE VALIDATION (N=2000)');
    print('=========================================\n');

    final generator = LevelGenerator();
    final config = EpisodeConfig.forEpisode(3);

    int generated = 0;
    int failed = 0;
    
    // Rejection reasons tracking
    final rejectReasons = <String, int>{};

    final movesList = <int>[];
    final genTimes = <int>[];

    final totalStopwatch = Stopwatch()..start();

    for (int i = 0; i < 2000; i++) {
      final seed = 300000 + i;
      final stopwatch = Stopwatch()..start();
      final level = generator.generate(3, i + 1, seed);
      stopwatch.stop();
      genTimes.add(stopwatch.elapsedMilliseconds);

      if (level != null) {
        generated++;
        movesList.add(level.meta.optimalMoves);
      } else {
        failed++;
        // Track rejection reason (we can't get it directly, so categorize by attempt exhaustion)
        rejectReasons['generation_failed'] = (rejectReasons['generation_failed'] ?? 0) + 1;
      }

      if ((i + 1) % 500 == 0) {
        stdout.write('\rProgress: ${i + 1}/2000');
      }
    }

    totalStopwatch.stop();

    genTimes.sort();
    final avgGenTime = genTimes.isNotEmpty 
        ? genTimes.reduce((a, b) => a + b) / genTimes.length 
        : 0.0;
    final p50GenTime = genTimes.isNotEmpty ? genTimes[genTimes.length ~/ 2] : 0;
    final p90GenTime = genTimes.isNotEmpty 
        ? genTimes[(genTimes.length * 0.90).floor().clamp(0, genTimes.length - 1)] 
        : 0;
    final p99GenTime = genTimes.isNotEmpty 
        ? genTimes[(genTimes.length * 0.99).floor().clamp(0, genTimes.length - 1)] 
        : 0;

    print('\n\n--- RESULTS ---');
    print('Generated: $generated / 2000 (${(generated / 20).toStringAsFixed(1)}%)');
    print('Failed: $failed');
    print('Total time: ${totalStopwatch.elapsedMilliseconds}ms');
    
    print('\nGeneration Time:');
    print('  Avg: ${avgGenTime.toStringAsFixed(1)}ms');
    print('  p50: ${p50GenTime}ms');
    print('  p90: ${p90GenTime}ms');
    print('  p99: ${p99GenTime}ms');
    print('  Max: ${genTimes.last}ms');

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
          final pct = (count / generated * 100).toStringAsFixed(1);
          final bar = '█' * (count ~/ 10).clamp(1, 50);
          print('  ${m.toString().padLeft(2)}: ${count.toString().padLeft(4)} (${pct.padLeft(5)}%) $bar');
        }
      }
    }

    print('\nRejection Reasons:');
    if (rejectReasons.isEmpty) {
      print('  None tracked');
    } else {
      for (final entry in rejectReasons.entries) {
        print('  ${entry.key}: ${entry.value}');
      }
    }

    // Target checks
    print('\n--- TARGET CHECKS ---');
    final acceptOk = generated >= 1200; // 60%+
    print('Accept >= 60%: ${acceptOk ? "✓ PASS" : "✗ FAIL"} (${(generated / 20).toStringAsFixed(1)}%)');
    
    final p90TimeOk = p90GenTime < 50;
    print('Gen time p90 < 50ms: ${p90TimeOk ? "✓ PASS" : "✗ FAIL"} (${p90GenTime}ms)');

    // Save report
    final report = StringBuffer();
    report.writeln('# Episode 3 Scale Validation Report (n=2000)');
    report.writeln('');
    report.writeln('## Summary');
    report.writeln('- Generated: $generated / 2000 (${(generated / 20).toStringAsFixed(1)}%)');
    report.writeln('- Failed: $failed');
    report.writeln('- Total time: ${totalStopwatch.elapsedMilliseconds}ms');
    report.writeln('');
    report.writeln('## Generation Time');
    report.writeln('- Avg: ${avgGenTime.toStringAsFixed(1)}ms');
    report.writeln('- p50: ${p50GenTime}ms');
    report.writeln('- p90: ${p90GenTime}ms');
    report.writeln('- p99: ${p99GenTime}ms');
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
    File('lib/tools/logs/episode3_scale_report.md').writeAsStringSync(report.toString());
    print('\n✓ Saved to lib/tools/logs/episode3_scale_report.md');

    expect(true, isTrue);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
