// Quick baseline tuning test - run with:
// flutter test test/procedural/quick_baseline_test.dart --no-pub

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  group('Quick Baseline', () {
    late BatchValidator validator;

    setUp(() {
      validator = BatchValidator();
    });

    test('Episode 3 baseline (30 levels)', () {
      print('\n=== Episode 3 Baseline (n=30) ===');

      final report = validator.validate(
        episode: 3,
        count: 30,
        startSeed: 300000,
      );

      print(report.toSummaryLine());
      print('Moves distribution: ${report.movesDistribution}');
      print('Rejections: ${report.rejectionReasons}');

      // Just print, don't assert
      expect(report.totalGenerated, greaterThan(0));
    });

    test('All episodes quick check (20 each)', () {
      final reports = <BatchValidationReport>[];

      for (int episode = 1; episode <= 5; episode++) {
        print('\n=== Episode $episode (n=20) ===');

        final report = validator.validate(
          episode: episode,
          count: 20,
          startSeed: episode * 100000,
        );

        reports.add(report);
        print(report.toSummaryLine());
      }

      // Print summary table
      print('\n' + '=' * 80);
      print('SUMMARY TABLE');
      print('Ep | Accept | AvgMoves | Min | p50 | p75 | p90 | Max | Trivial');
      print('-' * 80);
      for (final r in reports) {
        print('${r.episode}  | '
            '${(r.acceptanceRate * 100).toStringAsFixed(0).padLeft(5)}% | '
            '${r.averageMoves.toStringAsFixed(1).padLeft(8)} | '
            '${r.minMoves.toString().padLeft(3)} | '
            '${r.p50Moves.toString().padLeft(3)} | '
            '${r.p75Moves.toString().padLeft(3)} | '
            '${r.p90Moves.toString().padLeft(3)} | '
            '${r.maxMoves.toString().padLeft(3)} | '
            '${r.trivialWins}');
      }
      print('=' * 80);

      // Save markdown
      final markdown = validator.generateMarkdownReport(reports, title: 'Quick Baseline Report');
      final dir = Directory('lib/tools/logs');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      File('lib/tools/logs/baseline_tuning_report.md').writeAsStringSync(markdown);
      print('✓ Saved to lib/tools/logs/baseline_tuning_report.md');
    });
  });
}
