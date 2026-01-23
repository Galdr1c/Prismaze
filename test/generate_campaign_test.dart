// Campaign Generation Script
// Generates 5 Episodes x 200 Levels (1000 total)
// Run with: dart run bin/generate_campaign.dart

import 'dart:convert';
import 'dart:io';
import 'package:prismaze/game/procedural/level_generator.dart';
import 'package:prismaze/game/procedural/models/level_model.dart';
import 'package:prismaze/game/procedural/episode_config.dart';

void main() async {
  print('🚀 Starting Campaign Generation...');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final generator = LevelGenerator();
  
  // Create output directory if not exists
  final outputDir = Directory('assets/generated');
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  // Generate 5 Episodes
  for (int episode = 1; episode <= 5; episode++) {
    await _generateEpisode(generator, episode);
  }

  print('\n✅ Campaign Generation Complete!');
}

Future<void> _generateEpisode(LevelGenerator generator, int episode) async {
  print('\ngenerating Episode $episode...');
  final stopwatch = Stopwatch()..start();
  
  final levels = <Map<String, dynamic>>[];
  int successCount = 0;
  int retryCount = 0;
  
  // Generate 200 levels per episode
  for (int i = 1; i <= 200; i++) {
    GeneratedLevel? level;
    int seedBase = (episode * 10000) + i;
    int currentSeed = seedBase;
    int localRetryCount = 0;
    
    // EXHAUSTIVE SEED SCANNING
    while (level == null) {
      try {
        level = generator.generate(episode, i, currentSeed);
      } catch (e) {
        // If generate() throws, we try a new seed
        currentSeed += 997; 
        localRetryCount++;
        retryCount++;
        if (localRetryCount % 10 == 0) {
            stdout.write('\rEpisode $episode L$i: Searching seeds... ($localRetryCount attempts)');
        }
      }
    }

    levels.add({
      'version': 1,
      'episode': episode,
      'index': i,
      'seed': currentSeed,
      'level': level.toJson(),
    });
    successCount++;
    stdout.write('\rProgress: Episode $episode [$i/200] OK (Total Retries: $retryCount)    ');
  }

  stopwatch.stop();
  print('\nEpisode $episode Complete: $successCount/200 generated in ${stopwatch.elapsed.inSeconds}s');

  // Format Output JSON
  final output = {
    'version': 1,
    'episode': episode,
    'count': successCount,
    'generatedAt': DateTime.now().toIso8601String(),
    'levels': levels,
  };

  final jsonStr = const JsonEncoder.withIndent('  ').convert(output);
  final filename = 'assets/generated/episode_0$episode.json';
  await File(filename).writeAsString(jsonStr);
  print('Saved to $filename');
}
