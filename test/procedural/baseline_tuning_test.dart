// Baseline tuning test - run with:
// flutter test test/procedural/baseline_tuning_test.dart --no-pub

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  group('Baseline Tuning', () {
    late BatchValidator validator;

    setUp(() {
      validator = BatchValidator();
    });

    test('Collect baseline metrics for all episodes', () {
      final reports = <BatchValidationReport>[];
      const levelsPerEpisode = 100; // Reduce for faster testing

      for (int episode = 1; episode <= 5; episode++) {
        print('\n=== Episode $episode ===');

        final report = validator.validate(
          episode: episode,
          count: levelsPerEpisode,
          startSeed: episode * 100000,
        );

        reports.add(report);

        // Print summary
        print(report.toSummaryLine());
        print('  Acceptance: ${(report.acceptanceRate * 100).toStringAsFixed(1)}%');
        print('  Moves: min=${report.minMoves}, p50=${report.p50Moves}, p75=${report.p75Moves}, p90=${report.p90Moves}, max=${report.maxMoves}');
        print('  Trivial: ${report.trivialWins} (${(report.trivialWinRate * 100).toStringAsFixed(1)}%)');
        print('  p90 Solve: ${report.p90SolveTimeMs.toStringAsFixed(1)}ms');

        if (report.rejectionReasons.isNotEmpty) {
          print('  Rejections: ${report.rejectionReasons}');
        }
      }

      // Generate markdown report
      final markdown = validator.generateMarkdownReport(reports, title: 'Baseline Tuning Report');

      // Save to file
      final dir = Directory('lib/tools/logs');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      File('lib/tools/logs/baseline_tuning_report.md').writeAsStringSync(markdown);
      print('\n✓ Report saved to lib/tools/logs/baseline_tuning_report.md');

      // Print full report
      print('\n' + '=' * 80);
      print(validator.generateFullReport(reports));
    });

    test('Quick Episode 3 validation', () {
      print('\n=== Quick Episode 3 Validation ===');

      final report = validator.validate(
        episode: 3,
        count: 50,
        startSeed: 300000,
      );

      print(report.toSummaryLine());
      print('Acceptance: ${(report.acceptanceRate * 100).toStringAsFixed(1)}%');
      print('Moves: min=${report.minMoves}, p50=${report.p50Moves}, p75=${report.p75Moves}, p90=${report.p90Moves}, max=${report.maxMoves}');
      print('Trivial wins: ${report.trivialWins} (${(report.trivialWinRate * 100).toStringAsFixed(2)}%)');
      print('p90 Solve Time: ${report.p90SolveTimeMs.toStringAsFixed(1)}ms');

      if (report.rejectionReasons.isNotEmpty) {
        print('Rejections:');
        final sorted = report.rejectionReasons.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final e in sorted) {
          print('  ${e.key}: ${e.value}');
        }
      }

      // Baseline assertions (will fail initially, showing current state)
      print('\n--- Quality Checks ---');
      print('Accept >= 70%: ${report.acceptanceRate >= 0.70 ? "PASS" : "FAIL"} (${(report.acceptanceRate * 100).toStringAsFixed(1)}%)');
      print('p50 in [10..18]: ${report.p50Moves >= 10 && report.p50Moves <= 18 ? "PASS" : "FAIL"} (${report.p50Moves})');
      print('Trivial < 0.5%: ${report.trivialWinRate < 0.005 ? "PASS" : "FAIL"} (${(report.trivialWinRate * 100).toStringAsFixed(2)}%)');
    });
  });
}
