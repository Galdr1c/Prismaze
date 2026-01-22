/// Batch validation command for procedural level generation.
///
/// Generates N levels per episode and reports statistics.
/// Run via: flutter run -d windows --dart-define=RUN_BATCH_VALIDATE=true
library;

import 'dart:io';
import '../game/procedural/procedural.dart';

/// Run batch validation for all episodes.
Future<void> runBatchValidation({
  int levelsPerEpisode = 200,
  bool verbose = false,
}) async {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║   PRISMAZE PROCEDURAL LEVEL BATCH VALIDATION              ║');
  print('╚════════════════════════════════════════════════════════════╝');
  print('');

  final validator = BatchValidator();
  final startTime = DateTime.now();

  final reports = <BatchValidationReport>[];

  for (int episode = 1; episode <= 5; episode++) {
    print('━━━ Episode $episode ━━━');

    final report = validator.validate(
      episode: episode,
      count: levelsPerEpisode,
      startSeed: episode * 100000,
      onProgress: (current, total) {
        if (verbose || current % 20 == 0 || current == total) {
          stdout.write('\r  Generating: $current / $total');
        }
      },
    );

    print(''); // New line after progress
    print('  ✓ Acceptance rate: ${(report.acceptanceRate * 100).toStringAsFixed(1)}%');
    print('  ✓ Average moves: ${report.averageMoves.toStringAsFixed(1)}');
    print('  ✓ Min/Max moves: ${report.minMoves} / ${report.maxMoves}');
    print('  ✓ Solve time: ${report.averageSolveTimeMs.toStringAsFixed(2)}ms avg');

    if (report.rejectionReasons.isNotEmpty) {
      print('  ✗ Rejections:');
      for (final entry in report.rejectionReasons.entries) {
        print('    - ${entry.key}: ${entry.value}');
      }
    }

    reports.add(report);
    print('');
  }

  final totalTime = DateTime.now().difference(startTime);

  // Summary table
  print('╔════════════════════════════════════════════════════════════╗');
  print('║                    SUMMARY TABLE                           ║');
  print('╠════════════════════════════════════════════════════════════╣');
  print('║ Ep │ Accept% │ AvgMoves │ Min │ Max │ StatesAvg │ Time    ║');
  print('╠════════════════════════════════════════════════════════════╣');

  for (final report in reports) {
    final ep = report.episode.toString().padLeft(2);
    final accept = '${(report.acceptanceRate * 100).toStringAsFixed(0)}%'.padLeft(7);
    final avgMoves = report.averageMoves.toStringAsFixed(1).padLeft(8);
    final minMoves = report.minMoves.toString().padLeft(3);
    final maxMoves = report.maxMoves.toString().padLeft(3);
    final states = report.averageStatesExplored.toString().padLeft(9);
    final time = '${report.totalTime.inSeconds}s'.padLeft(7);

    print('║ $ep │ $accept │ $avgMoves │ $minMoves │ $maxMoves │ $states │ $time ║');
  }

  print('╚════════════════════════════════════════════════════════════╝');
  print('');
  print('Total validation time: ${totalTime.inSeconds}s');

  // Check quality gates
  print('');
  print('━━━ Quality Gates ━━━');

  bool allPassed = true;

  for (final report in reports) {
    final targetAcceptance = 0.70; // 70% target
    final passed = report.acceptanceRate >= targetAcceptance;
    final status = passed ? '✓ PASS' : '✗ FAIL';
    print('Episode ${report.episode}: $status (${(report.acceptanceRate * 100).toStringAsFixed(1)}% >= ${(targetAcceptance * 100).toStringAsFixed(0)}%)');

    if (!passed) allPassed = false;
  }

  print('');
  if (allPassed) {
    print('✓ All quality gates passed!');
  } else {
    print('✗ Some quality gates failed. Tuning required.');
  }
}

/// Validate a single episode with detailed output.
Future<BatchValidationReport> validateEpisode({
  required int episode,
  int count = 100,
}) async {
  print('Validating Episode $episode with $count levels...');

  final validator = BatchValidator();
  final report = validator.validate(
    episode: episode,
    count: count,
    startSeed: episode * 100000,
    onProgress: (current, total) {
      stdout.write('\rProgress: $current / $total');
    },
  );

  print('');
  print(report.toReportString());

  return report;
}

/// Quick test: generate and solve a single level.
Future<void> quickTest({
  int episode = 1,
  int seed = 12345,
}) async {
  print('Quick test: Episode $episode, Seed $seed');
  print('');

  final generator = LevelGenerator();
  final solver = Solver();

  final stopwatch = Stopwatch()..start();
  final level = generator.generate(episode, 1, seed);
  stopwatch.stop();

  if (level == null) {
    print('✗ Generation failed');
    return;
  }

  print('✓ Generated in ${stopwatch.elapsedMilliseconds}ms');
  print('  Optimal moves: ${level.meta.optimalMoves}');
  print('  Difficulty: ${level.meta.difficultyBand.name}');
  print('  Mirrors: ${level.mirrors.length} (${level.mirrors.where((m) => m.rotatable).length} rotatable)');
  print('  Prisms: ${level.prisms.length}');
  print('  Targets: ${level.targets.length}');
  print('  Walls: ${level.walls.length}');

  // Solve from initial state
  final state = GameState.fromLevel(level);
  stopwatch.reset();
  stopwatch.start();
  final solution = solver.solve(level, state);
  stopwatch.stop();

  print('');
  if (solution.solvable) {
    print('✓ Solved in ${stopwatch.elapsedMilliseconds}ms');
    print('  Min moves: ${solution.optimalMoves}');
    print('  States explored: ${solution.statesExplored}');
    print('  Solution: ${solution.moves.map((m) => '${m.type.name}[${m.objectIndex}]').join(', ')}');
  } else {
    print('✗ Not solvable from current state');
    print('  States explored: ${solution.statesExplored}');
    print('  Budget exceeded: ${solution.budgetExceeded}');
  }
}

/// Entry point for command-line batch validation.
void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    print('Usage: dart run lib/tools/procedural_batch_validate.dart [options]');
    print('');
    print('Options:');
    print('  --quick          Run quick test (single level)');
    print('  --episode N      Validate episode N only (1-5)');
    print('  --count N        Number of levels per episode (default: 200)');
    print('  --verbose        Show detailed progress');
    print('  --help, -h       Show this help');
    return;
  }

  if (args.contains('--quick')) {
    final episode = _getIntArg(args, '--episode') ?? 1;
    final seed = _getIntArg(args, '--seed') ?? 12345;
    await quickTest(episode: episode, seed: seed);
  } else if (args.contains('--episode')) {
    final episode = _getIntArg(args, '--episode') ?? 1;
    final count = _getIntArg(args, '--count') ?? 100;
    await validateEpisode(episode: episode, count: count);
  } else {
    final count = _getIntArg(args, '--count') ?? 200;
    final verbose = args.contains('--verbose');
    await runBatchValidation(levelsPerEpisode: count, verbose: verbose);
  }
}

int? _getIntArg(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index >= 0 && index + 1 < args.length) {
    return int.tryParse(args[index + 1]);
  }
  return null;
}

