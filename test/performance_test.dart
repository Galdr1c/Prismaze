import 'package:test/test.dart';
import '../lib/game/procedural/level_generator.dart';

void main() {
  group('Performance Benchmarks', () {
    late LevelGenerator generator;

    setUp(() {
      generator = LevelGenerator();
      // Warm up to ensure templates are loaded
      generator.generate(1, 0, 0); 
    });

    // Helper to benchmark
    void benchmarkEpisode(int episode, int count, int maxAvgMs) {
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < count; i++) {
        generator.generate(episode, 0, i);
      }
      stopwatch.stop();
      
      final totalMs = stopwatch.elapsedMilliseconds;
      final avgMs = totalMs / count;
      
      print('Episode $episode: Generated $count levels in ${totalMs}ms (Avg: ${avgMs.toStringAsFixed(2)}ms)');
      
      expect(avgMs, lessThan(maxAvgMs), reason: 'Episode $episode generation too slow');
    }

    test('Episode 1 Generation Speed (< 50ms)', () {
      // Very fast, simple templates
      benchmarkEpisode(1, 100, 50);
    });

    test('Episode 2 Generation Speed (< 50ms)', () {
      benchmarkEpisode(2, 100, 50);
    });

    test('Episode 3 Generation Speed (< 50ms)', () {
      benchmarkEpisode(3, 100, 50);
    });

    test('Episode 4 Generation Speed (< 50ms)', () {
      benchmarkEpisode(4, 100, 50);
    });
    
    test('Episode 5 Generation Speed (< 50ms)', () {
      benchmarkEpisode(5, 100, 50);
    });
  });
}
