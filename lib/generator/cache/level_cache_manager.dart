import 'dart:async';
import 'dart:collection';

import '../pipeline/generator_pipeline.dart';
import '../models/generated_level.dart';

/// Singleton manager for level caching, prefetching, and retrieval.
/// Implements an LRU (Least Recently Used) policy to manage memory.
class LevelCacheManager {
  static final LevelCacheManager _instance = LevelCacheManager._internal();
  factory LevelCacheManager() => _instance;

  LevelCacheManager._internal();

  // LRU Strategy: LinkedHashMap maintains insertion order.
  // We use key=LevelIndex.
  final LinkedHashMap<int, GeneratedLevel> _cache = LinkedHashMap();
  
  final GeneratorPipeline _pipeline = GeneratorPipeline();
  
  // Configuration
  static const int maxCacheSize = 10;
  
  // Track ongoing generations to dedupe requests
  final Map<int, Future<GeneratedLevel>> _pendingGenerations = {};

  /// Retrieves a level by [index] for the given [version].
  /// 
  /// 1. Checks Cache (Instant).
  /// 2. If Miss, triggers Async Generation.
  /// 3. Returns cached or generated level.
  Future<GeneratedLevel> getLevel(String version, int index) async {
    // 1. Check Cache
    if (_cache.containsKey(index)) {
      // Move to end (Recently Used)
      final level = _cache.remove(index)!;
      _cache[index] = level;
      return level;
    }

    // 2. Check Pending
    if (_pendingGenerations.containsKey(index)) {
      return _pendingGenerations[index]!;
    }
    
    // 3. Generate
    final future = _generateAndCache(version, index);
    _pendingGenerations[index] = future;
    
    try {
      final level = await future;
      _pendingGenerations.remove(index);
      return level;
    } catch (e) {
      _pendingGenerations.remove(index);
      rethrow;
    }
  }

  Future<GeneratedLevel> _generateAndCache(String version, int index) async {
    // Artificial slight delay to yield loop?
    // Since pipeline is synchronous computation, we should probably wrap in scheduleMicrotask
    // or run in isolate if strictly necessary. For now, simple async wrapper.
    await Future.delayed(Duration.zero);
    
    final level = await _pipeline.generateLevel(version: version, levelIndex: index);
    
    // Add to Cache
    if (_cache.length >= maxCacheSize) {
      // Evict oldest (First Key)
      _cache.remove(_cache.keys.first);
    }
    _cache[index] = level;
    
    return level;
  }

  /// Triggers background generation for the next [count] levels starting after [currentIndex].
  /// This is "Fire and Forget".
  void prepareNextLevels(String version, int currentIndex, {int count = 5}) {
    for (int i = 1; i <= count; i++) {
      final targetIndex = currentIndex + i;
      
      // Skip if already cached or pending
      if (_cache.containsKey(targetIndex) || _pendingGenerations.containsKey(targetIndex)) {
        continue;
      }
      
      // Trigger background generation
      // We don't await this result here.
      // We just store the Future in pending so getLevel can hook into it.
      _pendingGenerations[targetIndex] = _generateAndCache(version, targetIndex)
          .catchError((e) {
             print('Prefetch failed for Level $targetIndex: $e');
             // On fail, we remove from pending so retry is possible for actual getLevel
             // _generateAndCache handles removal? No, getLevel wrapper does.
             // But here we call _generateAndCache directly. 
             // We should probably share the wrapper or duplicate active management.
             _pendingGenerations.remove(targetIndex);
             // Return dummy to satisfy Future<GeneratedLevel> return type of catchError?
             // Actually catchError returns Future<T>. We just throw invalid.
             throw e; 
          });
    }
  }

  // Alias for readability (HATA 5)
  void onLevelComplete(String version, int completedLevelId) {
      // Logic: If I just finished level 10, prefetch 11, 12, 13...
      // Also potentially clear OLD levels?
      // For LRU, removing 8 when at 10 is good.
      
      // Prefetch Next 3 aggressively
      prepareNextLevels(version, completedLevelId, count: 3);
  }

  // Alias for New Game (HATA 5)
  void preGenerateLevel(String version, int levelId) {
      prepareNextLevels(version, levelId - 1, count: 1);
  }

  /// Clears the cache strictly.
  void clear() {
    _cache.clear();
    _pendingGenerations.clear();
  }
  
  // Debug Helpers
  bool isCached(int index) => _cache.containsKey(index);
  int get cacheSize => _cache.length;
}
