import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/generator/generator.dart';
import 'package:prismaze/generator/cache/level_cache_manager.dart';

void main() {
  // Note: LevelCacheManager is a Singleton. Tests share state unless cleared.
  
  setUp(() {
    LevelCacheManager().clear();
  });

  group('LevelCacheManager', () {
    test('Cache Hit vs Miss', () async {
      final cache = LevelCacheManager();
      const version = 'v1';
      
      // 1. Initial Miss
      final start = DateTime.now();
      expect(cache.isCached(1), isFalse);
      
      final level1 = await cache.getLevel(version, 1);
      
      // Delay simulated in generation? (Code currently runs sync wrapped in async)
      
      expect(level1.id, equals(1));
      expect(cache.isCached(1), isTrue);
      
      // 2. Cache Hit
      final level1Hit = await cache.getLevel(version, 1);
      expect(level1Hit, equals(level1)); // Same instance
    });

    test('Prefetching populates cache', () async {
      final cache = LevelCacheManager();
      const version = 'v1';
      
      // Request prefetch for 2, 3, 4
      cache.prepareNextLevels(version, 1, count: 3);
      
      // Wait a bit specifically for microtasks
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(cache.isCached(2), isTrue);
      expect(cache.isCached(3), isTrue);
      expect(cache.isCached(4), isTrue);
    });

    test('LRU Eviction (Max Size 10)', () async {
      final cache = LevelCacheManager();
      const version = 'v1';
      
      // Fill cache with 10 items (1..10)
      for (int i = 1; i <= 10; i++) {
        await cache.getLevel(version, i);
      }
      expect(cache.cacheSize, equals(10));
      expect(cache.isCached(1), isTrue);
      
      // Add 11th item
      await cache.getLevel(version, 11);
      
      // Should result in size 10, item 1 evicted?
      expect(cache.cacheSize, equals(10));
      expect(cache.isCached(11), isTrue);
      expect(cache.isCached(1), isFalse); // Oldest accessed
      expect(cache.isCached(2), isTrue); // Should still be there
    });

    test('LRU updates order on access', () async {
      final cache = LevelCacheManager();
      const version = 'v1';
      
      // Fill 1..10
      for (int i = 1; i <= 10; i++) {
        await cache.getLevel(version, i);
      }
      
      // Access 1 again (refreshing it)
      await cache.getLevel(version, 1);
      
      // Now add 11.
      // Expected: 2 should be evicted (since 1 was just refreshed), not 1.
      await cache.getLevel(version, 11);
      
      expect(cache.isCached(1), isTrue); // Should be KEPT
      expect(cache.isCached(2), isFalse); // Should be EVICTED
      expect(cache.isCached(11), isTrue);
    });
  });
}
