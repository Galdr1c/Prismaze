/// Batch Validation Tool for level generation.
///
/// Generates many levels and reports statistics for tuning.
library;

import 'dart:convert';
import 'models/models.dart';
import 'level_generator.dart';
import 'solver.dart';

/// Statistics for a batch validation run.
class BatchValidationReport {
  final int episode;
  final int totalAttempted;
  final int totalGenerated;
  final Duration totalTime;

  // Success metrics
  final double acceptanceRate;
  final Map<int, int> movesDistribution;
  final double averageMoves;
  final int minMoves;
  final int maxMoves;

  // Percentiles
  final int p50Moves;
  final int p75Moves;
  final int p90Moves;

  // Solve time percentiles
  final double p50SolveTimeMs;
  final double p90SolveTimeMs;

  // Failure metrics
  final Map<String, int> rejectionReasons;

  // Performance metrics
  final double averageSolveTimeMs;
  final int averageStatesExplored;

  // Quality metrics
  final int trivialWins; // minMoves <= 2
  final double trivialWinRate;

  const BatchValidationReport({
    required this.episode,
    required this.totalAttempted,
    required this.totalGenerated,
    required this.totalTime,
    required this.acceptanceRate,
    required this.movesDistribution,
    required this.averageMoves,
    required this.minMoves,
    required this.maxMoves,
    required this.p50Moves,
    required this.p75Moves,
    required this.p90Moves,
    required this.p50SolveTimeMs,
    required this.p90SolveTimeMs,
    required this.rejectionReasons,
    required this.averageSolveTimeMs,
    required this.averageStatesExplored,
    required this.trivialWins,
    required this.trivialWinRate,
  });

  /// Generate a formatted report string.
  String toReportString() {
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('BATCH VALIDATION REPORT - EPISODE $episode');
    buffer.writeln('=' * 60);
    buffer.writeln();

    // Summary
    buffer.writeln('SUMMARY');
    buffer.writeln('-' * 40);
    buffer.writeln('Total Attempted: $totalAttempted');
    buffer.writeln('Total Generated: $totalGenerated');
    buffer.writeln(
        'Acceptance Rate: ${(acceptanceRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('Total Time: ${totalTime.inSeconds}s');
    buffer.writeln();

    // Moves
    buffer.writeln('OPTIMAL MOVES');
    buffer.writeln('-' * 40);
    buffer.writeln('Average: ${averageMoves.toStringAsFixed(1)}');
    buffer.writeln('Min: $minMoves');
    buffer.writeln('Max: $maxMoves');
    buffer.writeln('p50: $p50Moves');
    buffer.writeln('p75: $p75Moves');
    buffer.writeln('p90: $p90Moves');
    buffer.writeln();

    // Quality
    buffer.writeln('QUALITY');
    buffer.writeln('-' * 40);
    buffer.writeln('Trivial Wins (≤2 moves): $trivialWins (${(trivialWinRate * 100).toStringAsFixed(1)}%)');
    buffer.writeln();

    // Distribution
    buffer.writeln('DISTRIBUTION');
    buffer.writeln('-' * 40);
    final sortedMoves = movesDistribution.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in sortedMoves) {
      final bar = '█' * (entry.value * 20 ~/ totalGenerated).clamp(1, 50);
      buffer.writeln('${entry.key.toString().padLeft(2)} moves: '
          '${entry.value.toString().padLeft(4)} $bar');
    }
    buffer.writeln();

    // Rejections
    if (rejectionReasons.isNotEmpty) {
      buffer.writeln('REJECTION REASONS');
      buffer.writeln('-' * 40);
      final sortedReasons = rejectionReasons.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedReasons) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    // Performance
    buffer.writeln('PERFORMANCE');
    buffer.writeln('-' * 40);
    buffer.writeln('Avg Solve Time: ${averageSolveTimeMs.toStringAsFixed(2)}ms');
    buffer.writeln('p50 Solve Time: ${p50SolveTimeMs.toStringAsFixed(2)}ms');
    buffer.writeln('p90 Solve Time: ${p90SolveTimeMs.toStringAsFixed(2)}ms');
    buffer.writeln('Avg States Explored: $averageStatesExplored');

    return buffer.toString();
  }

  /// Generate a condensed one-line summary.
  String toSummaryLine() {
    return 'E$episode: '
        'accept=${(acceptanceRate * 100).toStringAsFixed(0)}% '
        'moves=[${minMoves}..${p50Moves}..${p90Moves}..${maxMoves}] '
        'avg=${averageMoves.toStringAsFixed(1)} '
        'trivial=${trivialWins} '
        'solveMs=${p90SolveTimeMs.toStringAsFixed(0)}';
  }

  /// Convert to JSON for storage/analysis.
  Map<String, dynamic> toJson() => {
        'episode': episode,
        'totalAttempted': totalAttempted,
        'totalGenerated': totalGenerated,
        'totalTimeMs': totalTime.inMilliseconds,
        'acceptanceRate': acceptanceRate,
        'movesDistribution':
            movesDistribution.map((k, v) => MapEntry(k.toString(), v)),
        'averageMoves': averageMoves,
        'minMoves': minMoves,
        'maxMoves': maxMoves,
        'p50Moves': p50Moves,
        'p75Moves': p75Moves,
        'p90Moves': p90Moves,
        'p50SolveTimeMs': p50SolveTimeMs,
        'p90SolveTimeMs': p90SolveTimeMs,
        'rejectionReasons': rejectionReasons,
        'averageSolveTimeMs': averageSolveTimeMs,
        'averageStatesExplored': averageStatesExplored,
        'trivialWins': trivialWins,
        'trivialWinRate': trivialWinRate,
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Batch validator for testing level generation.
class BatchValidator {
  final LevelGenerator _generator = LevelGenerator();
  final Solver _solver = Solver();

  /// Validate level generation for an episode.
  ///
  /// Generates [count] levels and collects statistics.
  BatchValidationReport validate({
    required int episode,
    required int count,
    int startSeed = 10000,
    void Function(int current, int total)? onProgress,
  }) {
    final stopwatch = Stopwatch()..start();

    final generatedLevels = <GeneratedLevel>[];
    final movesDistribution = <int, int>{};
    final rejectionReasons = <String, int>{};
    final movesList = <int>[];
    final solveTimesList = <double>[];

    int totalSolveTimeMs = 0;
    int totalStatesExplored = 0;
    int attemptsUsed = 0;

    for (int i = 0; i < count; i++) {
      final seed = startSeed + i;

      onProgress?.call(i + 1, count);

      final level = _generator.generate(episode, i + 1, seed);

      if (level != null) {
        generatedLevels.add(level);

        // Track moves
        final moves = level.meta.optimalMoves;
        movesDistribution[moves] = (movesDistribution[moves] ?? 0) + 1;
        movesList.add(moves);

        // Track solve performance
        totalSolveTimeMs += level.meta.solveTime.inMilliseconds;
        solveTimesList.add(level.meta.solveTime.inMilliseconds.toDouble());
        attemptsUsed += level.meta.generationAttempts;

        // Re-solve to get stats
        final initialState = GameState.fromLevel(level);
        final solution = _solver.solve(level, initialState);
        totalStatesExplored += solution.statesExplored;
      } else {
        rejectionReasons['generation_failed'] =
            (rejectionReasons['generation_failed'] ?? 0) + 1;
      }
    }

    stopwatch.stop();

    // Calculate statistics
    final totalGenerated = generatedLevels.length;
    final acceptanceRate = totalGenerated / count;

    double averageMoves = 0;
    int minMoves = 999;
    int maxMoves = 0;

    if (movesDistribution.isNotEmpty) {
      int totalMoves = 0;
      for (final entry in movesDistribution.entries) {
        totalMoves += entry.key * entry.value;
        if (entry.key < minMoves) minMoves = entry.key;
        if (entry.key > maxMoves) maxMoves = entry.key;
      }
      averageMoves = totalMoves / totalGenerated;
    }

    // Calculate percentiles
    movesList.sort();
    solveTimesList.sort();

    int p50Moves = 0, p75Moves = 0, p90Moves = 0;
    double p50SolveTimeMs = 0, p90SolveTimeMs = 0;

    if (movesList.isNotEmpty) {
      p50Moves = _percentile(movesList, 50);
      p75Moves = _percentile(movesList, 75);
      p90Moves = _percentile(movesList, 90);
    }

    if (solveTimesList.isNotEmpty) {
      p50SolveTimeMs = _percentileDouble(solveTimesList, 50);
      p90SolveTimeMs = _percentileDouble(solveTimesList, 90);
    }

    // Count trivial wins (minMoves <= 2)
    int trivialWins = 0;
    for (final moves in movesList) {
      if (moves <= 2) trivialWins++;
    }

    return BatchValidationReport(
      episode: episode,
      totalAttempted: count,
      totalGenerated: totalGenerated,
      totalTime: stopwatch.elapsed,
      acceptanceRate: acceptanceRate,
      movesDistribution: movesDistribution,
      averageMoves: averageMoves,
      minMoves: minMoves == 999 ? 0 : minMoves,
      maxMoves: maxMoves,
      p50Moves: p50Moves,
      p75Moves: p75Moves,
      p90Moves: p90Moves,
      p50SolveTimeMs: p50SolveTimeMs,
      p90SolveTimeMs: p90SolveTimeMs,
      rejectionReasons: rejectionReasons,
      averageSolveTimeMs:
          totalGenerated > 0 ? totalSolveTimeMs / totalGenerated : 0,
      averageStatesExplored:
          totalGenerated > 0 ? totalStatesExplored ~/ totalGenerated : 0,
      trivialWins: trivialWins,
      trivialWinRate: totalGenerated > 0 ? trivialWins / totalGenerated : 0,
    );
  }

  /// Calculate percentile from sorted list.
  int _percentile(List<int> sorted, int p) {
    if (sorted.isEmpty) return 0;
    final index = ((p / 100) * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  double _percentileDouble(List<double> sorted, int p) {
    if (sorted.isEmpty) return 0;
    final index = ((p / 100) * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  /// Validate all episodes.
  List<BatchValidationReport> validateAll({
    int levelsPerEpisode = 100,
    void Function(int episode, int current, int total)? onProgress,
  }) {
    final reports = <BatchValidationReport>[];

    for (int episode = 1; episode <= 5; episode++) {
      final report = validate(
        episode: episode,
        count: levelsPerEpisode,
        startSeed: episode * 100000,
        onProgress: (current, total) =>
            onProgress?.call(episode, current, total),
      );
      reports.add(report);
    }

    return reports;
  }

  /// Generate a combined report for all episodes.
  String generateFullReport(List<BatchValidationReport> reports) {
    final buffer = StringBuffer();

    buffer.writeln('╔' + '═' * 58 + '╗');
    buffer.writeln('║' + 'PRISMAZE LEVEL GENERATION VALIDATION REPORT'.padLeft(40).padRight(58) + '║');
    buffer.writeln('╚' + '═' * 58 + '╝');
    buffer.writeln();

    // Summary table
    buffer.writeln('EPISODE SUMMARY');
    buffer.writeln('─' * 80);
    buffer.writeln('Ep  Accept%   Avg    Min   p50   p75   p90   Max   Trivial  p90SolveMs');
    buffer.writeln('─' * 80);

    for (final r in reports) {
      buffer.writeln(
        '${r.episode.toString().padLeft(2)}  '
        '${(r.acceptanceRate * 100).toStringAsFixed(0).padLeft(5)}%   '
        '${r.averageMoves.toStringAsFixed(1).padLeft(5)}   '
        '${r.minMoves.toString().padLeft(3)}   '
        '${r.p50Moves.toString().padLeft(3)}   '
        '${r.p75Moves.toString().padLeft(3)}   '
        '${r.p90Moves.toString().padLeft(3)}   '
        '${r.maxMoves.toString().padLeft(3)}   '
        '${r.trivialWins.toString().padLeft(5)}    '
        '${r.p90SolveTimeMs.toStringAsFixed(0).padLeft(8)}',
      );
    }
    buffer.writeln('─' * 80);
    buffer.writeln();

    // Individual reports
    for (final report in reports) {
      buffer.writeln(report.toReportString());
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate markdown report for file output.
  String generateMarkdownReport(List<BatchValidationReport> reports, {String? title}) {
    final buffer = StringBuffer();

    buffer.writeln('# ${title ?? "PrisMaze Level Generation Report"}');
    buffer.writeln();
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    // Summary table
    buffer.writeln('## Episode Summary');
    buffer.writeln();
    buffer.writeln('| Episode | Accept% | Avg Moves | Min | p50 | p75 | p90 | Max | Trivial | p90 Solve(ms) |');
    buffer.writeln('|---------|---------|-----------|-----|-----|-----|-----|-----|---------|---------------|');

    for (final r in reports) {
      buffer.writeln(
        '| ${r.episode} | '
        '${(r.acceptanceRate * 100).toStringAsFixed(1)}% | '
        '${r.averageMoves.toStringAsFixed(1)} | '
        '${r.minMoves} | '
        '${r.p50Moves} | '
        '${r.p75Moves} | '
        '${r.p90Moves} | '
        '${r.maxMoves} | '
        '${r.trivialWins} (${(r.trivialWinRate * 100).toStringAsFixed(1)}%) | '
        '${r.p90SolveTimeMs.toStringAsFixed(1)} |',
      );
    }
    buffer.writeln();

    // Individual episode details
    for (final r in reports) {
      buffer.writeln('## Episode ${r.episode} Details');
      buffer.writeln();
      buffer.writeln('- **Acceptance Rate**: ${(r.acceptanceRate * 100).toStringAsFixed(1)}%');
      buffer.writeln('- **Moves**: min=${r.minMoves}, p50=${r.p50Moves}, p75=${r.p75Moves}, p90=${r.p90Moves}, max=${r.maxMoves}');
      buffer.writeln('- **Trivial Wins (≤2 moves)**: ${r.trivialWins} (${(r.trivialWinRate * 100).toStringAsFixed(2)}%)');
      buffer.writeln('- **Avg Solve Time**: ${r.averageSolveTimeMs.toStringAsFixed(2)}ms');
      buffer.writeln('- **p90 Solve Time**: ${r.p90SolveTimeMs.toStringAsFixed(2)}ms');
      buffer.writeln('- **Avg States Explored**: ${r.averageStatesExplored}');
      buffer.writeln();

      // Distribution
      buffer.writeln('### Moves Distribution');
      buffer.writeln();
      buffer.writeln('```');
      final sortedMoves = r.movesDistribution.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in sortedMoves) {
        final bar = '█' * (entry.value * 30 ~/ r.totalGenerated).clamp(1, 50);
        buffer.writeln('${entry.key.toString().padLeft(2)} moves: ${entry.value.toString().padLeft(4)} $bar');
      }
      buffer.writeln('```');
      buffer.writeln();

      // Rejection reasons
      if (r.rejectionReasons.isNotEmpty) {
        buffer.writeln('### Rejection Reasons');
        buffer.writeln();
        final sortedReasons = r.rejectionReasons.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final entry in sortedReasons) {
          buffer.writeln('- ${entry.key}: ${entry.value}');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
