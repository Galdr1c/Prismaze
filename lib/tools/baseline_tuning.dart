/// Baseline tuning script for procedural level generation.
///
/// Runs batch validation and saves baseline metrics.
library;

import 'dart:io';
import '../game/procedural/procedural.dart';

/// Run baseline validation and save report.
Future<void> runBaseline({int levelsPerEpisode = 100}) async {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║   PRISMAZE BASELINE TUNING REPORT                          ║');
  print('╠════════════════════════════════════════════════════════════╣');
  print('║   Levels per episode: $levelsPerEpisode                               ║');
  print('╚════════════════════════════════════════════════════════════╝');
  print('');

  final validator = BatchValidator();
  final startTime = DateTime.now();
  final reports = <BatchValidationReport>[];

  for (int episode = 1; episode <= 5; episode++) {
    print('━━━ Episode $episode ━━━');
    stdout.write('  Generating: ');

    final report = validator.validate(
      episode: episode,
      count: levelsPerEpisode,
      startSeed: episode * 100000,
      onProgress: (current, total) {
        stdout.write('\r  Generating: $current / $total');
      },
    );

    print('');
    print(report.toSummaryLine());
    reports.add(report);
  }

  final totalTime = DateTime.now().difference(startTime);
  print('');
  print('Total time: ${totalTime.inSeconds}s');

  // Generate markdown report
  final markdownReport = validator.generateMarkdownReport(
    reports,
    title: 'PrisMaze Baseline Tuning Report',
  );

  // Save to file
  final logsDir = Directory('lib/tools/logs');
  if (!await logsDir.exists()) {
    await logsDir.create(recursive: true);
  }

  final reportFile = File('lib/tools/logs/baseline_tuning_report.md');
  await reportFile.writeAsString(markdownReport);
  print('');
  print('✓ Report saved to: ${reportFile.path}');
}

/// Quick validation for a single episode.
Future<BatchValidationReport> quickValidate(int episode, {int count = 50}) async {
  print('Quick validate Episode $episode (n=$count)...');

  final validator = BatchValidator();
  final report = validator.validate(
    episode: episode,
    count: count,
    startSeed: episode * 100000,
    onProgress: (current, total) {
      stdout.write('\r  Progress: $current / $total');
    },
  );

  print('');
  print(report.toSummaryLine());
  return report;
}

/// Entry point.
void main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    print('Usage: dart run lib/tools/baseline_tuning.dart [options]');
    print('');
    print('Options:');
    print('  --quick          Quick validation (50 per episode)');
    print('  --full           Full validation (300 per episode)');
    print('  --episode N      Validate only episode N');
    print('  --count N        Number of levels per episode');
    print('  --help, -h       Show this help');
    return;
  }

  final count = _getIntArg(args, '--count') ??
      (args.contains('--full') ? 300 : (args.contains('--quick') ? 50 : 100));

  if (args.contains('--episode')) {
    final episode = _getIntArg(args, '--episode') ?? 3;
    await quickValidate(episode, count: count);
  } else {
    await runBaseline(levelsPerEpisode: count);
  }
}

int? _getIntArg(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index >= 0 && index + 1 < args.length) {
    return int.tryParse(args[index + 1]);
  }
  return null;
}

