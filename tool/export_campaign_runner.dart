/// Campaign Level Export Runner
///
/// Run with: flutter test tool/export_campaign_runner.dart --no-pub
///
/// To export all episodes:
///   flutter test tool/export_campaign_runner.dart --no-pub

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/procedural.dart';

void main() {
  // Episode 1: Tutorial - simple mirror puzzles
  test('Export Episode 1 levels', () async {
    await _exportEpisode(
      episode: 1,
      count: 100, // Start small, increase to 2000 for production
      seedStart: 0,
    );
  }, timeout: const Timeout(Duration(minutes: 10)));

  // Episode 2: Easy - more mirrors, basic prisms
  test('Export Episode 2 levels', () async {
    await _exportEpisode(
      episode: 2,
      count: 100,
      seedStart: 50000,
    );
  }, timeout: const Timeout(Duration(minutes: 10)));

  // Episode 3: Medium - color mixing introduction
  test('Export Episode 3 levels', () async {
    await _exportEpisode(
      episode: 3,
      count: 100,
      seedStart: 100000,
    );
  }, timeout: const Timeout(Duration(minutes: 30)));

  // Episode 4: Hard - two mixed targets
  test('Export Episode 4 levels', () async {
    await _exportEpisode(
      episode: 4,
      count: 100,
      seedStart: 200000,
    );
  }, timeout: const Timeout(Duration(minutes: 30)));

  // Episode 5: Expert - complex color routing
  test('Export Episode 5 levels', () async {
    await _exportEpisode(
      episode: 5,
      count: 100,
      seedStart: 300000,
    );
  }, timeout: const Timeout(Duration(minutes: 60)));
}

Future<void> _exportEpisode({
  required int episode,
  required int count,
  required int seedStart,
  bool skipSolution = true,
}) async {
  print('\n═══════════════════════════════════════════════════════');
  print('EXPORTING EPISODE $episode');
  print('═══════════════════════════════════════════════════════');
  print('Count: $count');
  print('Seed start: $seedStart');
  print('');

  // Create output directory
  final outputDir = Directory('assets/generated');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Generate levels
  final generator = LevelGenerator();
  final levels = <Map<String, dynamic>>[];

  int seed = seedStart;
  int produced = 0;
  int failed = 0;
  int lastSeed = seedStart;

  final stopwatch = Stopwatch()..start();

  while (produced < count) {
    final level = generator.generate(episode, produced + 1, seed);

    if (level != null) {
      final levelJson = level.toJson();
      if (skipSolution) {
        levelJson.remove('solution');
      }

      levels.add({
        'version': 1,
        'episode': episode,
        'index': produced + 1,
        'seed': seed,
        'level': levelJson,
      });

      produced++;
      lastSeed = seed;

      if (produced % 100 == 0 || produced == count) {
        final elapsed = stopwatch.elapsedMilliseconds / 1000;
        final rate = produced / elapsed;
        print('Progress: $produced/$count (${rate.toStringAsFixed(1)} levels/s)');
      }
    } else {
      failed++;
    }

    seed++;

    if (seed - seedStart > count * 10) {
      print('Too many failures, stopping at $produced levels');
      break;
    }
  }

  stopwatch.stop();

  // Write episode file
  final episodeStr = episode.toString().padLeft(2, '0');
  final outputFile = File('${outputDir.path}/episode_$episodeStr.json');

  final episodeJson = {
    'version': 1,
    'episode': episode,
    'count': levels.length,
    'seedStart': seedStart,
    'seedEnd': lastSeed,
    'generatedAt': DateTime.now().toIso8601String(),
    'levels': levels,
  };

  final encoder = JsonEncoder.withIndent('  ');
  outputFile.writeAsStringSync(encoder.convert(episodeJson));

  final fileSizeKb = outputFile.lengthSync() / 1024;
  print('\nWrote ${outputFile.path} (${fileSizeKb.toStringAsFixed(1)} KB)');

  // Update manifest
  _updateManifest(outputDir, episode, levels.length, seedStart, lastSeed);

  print('');
  print('Summary: ${levels.length} levels, $failed failed, ${stopwatch.elapsedMilliseconds ~/ 1000}s');

  expect(levels.length, greaterThan(0));
}

void _updateManifest(Directory outputDir, int episode, int count, int seedStart, int seedEnd) {
  final manifestFile = File('${outputDir.path}/manifest.json');

  Map<String, dynamic> manifest;
  if (manifestFile.existsSync()) {
    manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  } else {
    manifest = {
      'version': 1,
      'generatedAt': DateTime.now().toIso8601String(),
      'episodes': <String, dynamic>{},
    };
  }

  final episodeStr = episode.toString().padLeft(2, '0');
  (manifest['episodes'] as Map<String, dynamic>)[episode.toString()] = {
    'file': 'assets/generated/episode_$episodeStr.json',
    'count': count,
    'seedStart': seedStart,
    'seedEnd': seedEnd,
    'updatedAt': DateTime.now().toIso8601String(),
  };

  final encoder = JsonEncoder.withIndent('  ');
  manifestFile.writeAsStringSync(encoder.convert(manifest));
  print('Updated ${manifestFile.path}');
}
