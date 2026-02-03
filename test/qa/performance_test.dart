import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/generator/generator.dart';

void main() {
  group('QA Performance Benchmarks', () {
    late GeneratorPipeline pipeline;

    setUp(() {
      pipeline = GeneratorPipeline();
    });

    test('Verify resource limits and generation latency (100 samples)', () {
      final int levelCount = 100;
      final String version = 'v1';
      
      final latencies = <int>[];
      int totalRays = 0;
      int totalBounces = 0;
      int totalSegments = 0;
      
      int maxRays = 0;
      int maxBounces = 0;
      int maxSegments = 0;

      print('Running Performance Benchmarks on $levelCount levels...');

      for (int i = 1; i <= levelCount; i++) {
        final stopwatch = Stopwatch()..start();
        final level = pipeline.generateLevel(version: version, levelIndex: i);
        stopwatch.stop();
        
        latencies.add(stopwatch.elapsedMilliseconds);
        
        // Use HeadlessRayTracer to get complexity metrics
        final stats = HeadlessRayTracer.trace(level);
        
        totalRays += stats.rayCount;
        totalBounces += stats.bounceCount;
        totalSegments += stats.segmentCount;
        
        if (stats.rayCount > maxRays) maxRays = stats.rayCount;
        if (stats.bounceCount > maxBounces) maxBounces = stats.bounceCount;
        if (stats.segmentCount > maxSegments) maxSegments = stats.segmentCount;
        
        // Enforce per-level Hard Limits
        expect(stats.rayCount, lessThanOrEqualTo(50), reason: 'Level $i exceeded ray limit of 50');
        expect(stats.bounceCount, lessThanOrEqualTo(20), reason: 'Level $i exceeded bounce limit of 20');
        expect(stats.segmentCount, lessThanOrEqualTo(100), reason: 'Level $i exceeded segment limit of 100');
      }

      // Calculate Percentiles
      latencies.sort();
      final p50 = latencies[(levelCount * 0.5).floor()];
      final p95 = latencies[(levelCount * 0.95).floor()];
      final p99 = latencies[(levelCount * 0.99).floor()];
      
      print('--- Performance Report ---');
      print('Generation Time: p50=${p50}ms, p95=${p95}ms, p99=${p99}ms');
      print('Complexity (Avg): Rays: ${(totalRays/levelCount).toStringAsFixed(1)}, Bounces: ${(totalBounces/levelCount).toStringAsFixed(1)}, Segments: ${(totalSegments/levelCount).toStringAsFixed(1)}');
      print('Complexity (Max): Rays: $maxRays, Bounces: $maxBounces, Segments: $maxSegments');
      
      // Enforce 95th percentile latency
      expect(p95, lessThan(500), reason: '95th percentile generation time exceeded 500ms');
    });
  });
}
