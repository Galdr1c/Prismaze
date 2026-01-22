/// Endless Run Manager
/// 
/// Handles deterministic seeding and persistence for endless mode.
/// Ensures same (runSeed, levelIndex) always produces identical level.
library;

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Singleton manager for endless mode state.
class EndlessRunManager {
  static final EndlessRunManager _instance = EndlessRunManager._internal();
  factory EndlessRunManager() => _instance;
  EndlessRunManager._internal();

  static const String _prefKeyRunSeed = 'endless_run_seed';
  static const String _prefKeyCurrentIndex = 'endless_current_index';
  static const String _prefKeyHighestIndex = 'endless_highest_index';
  
  /// Episode config version for seed isolation (bump on generator changes)
  static const int _configVersion = 1;

  /// Current run seed (null if no active run)
  int? runSeed;
  
  /// Current level index in the endless run (1-indexed)
  int currentIndex = 1;
  
  /// Highest level reached in current run
  int highestIndex = 0;
  
  /// Whether manager has been initialized
  bool _initialized = false;

  /// Initialize manager and load persisted state.
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    runSeed = prefs.getInt(_prefKeyRunSeed);
    currentIndex = prefs.getInt(_prefKeyCurrentIndex) ?? 1;
    highestIndex = prefs.getInt(_prefKeyHighestIndex) ?? 0;
    
    debugPrint('EndlessRunManager: Loaded runSeed=$runSeed, currentIndex=$currentIndex, highestIndex=$highestIndex');
    _initialized = true;
  }

  /// Check if there's an active run that can be continued.
  bool get hasActiveRun => runSeed != null && highestIndex > 0;

  /// Derive deterministic seed for a specific level index.
  /// 
  /// Formula: (runSeed * 1000003) ^ (levelIndex * 9176) ^ (version * 1013) & 0x7fffffff
  /// Ensures same (runSeed, index, version) always produces identical level.
  int deriveSeed(int levelIndex) {
    if (runSeed == null) {
      throw StateError('Cannot derive seed without active run. Call startNewRun() first.');
    }
    
    final derived = ((runSeed! * 1000003) ^ (levelIndex * 9176) ^ (_configVersion * 1013)) & 0x7fffffff;
    debugPrint('EndlessRunManager: Derived seed $derived for level $levelIndex (runSeed=$runSeed, version=$_configVersion)');
    return derived;
  }

  /// Start a new endless run with fresh seed.
  Future<void> startNewRun() async {
    runSeed = Random().nextInt(0x7fffffff);
    currentIndex = 1;
    highestIndex = 0;
    
    await saveProgress();
    debugPrint('EndlessRunManager: Started new run with seed $runSeed');
  }

  /// Continue from persisted run state.
  /// Returns true if there was an active run to continue.
  bool continueRun() {
    if (!hasActiveRun) {
      debugPrint('EndlessRunManager: No active run to continue');
      return false;
    }
    
    currentIndex = highestIndex;
    debugPrint('EndlessRunManager: Continuing run at level $currentIndex');
    return true;
  }

  /// Called when a level is completed.
  Future<void> onLevelComplete() async {
    currentIndex++;
    if (currentIndex > highestIndex) {
      highestIndex = currentIndex;
    }
    await saveProgress();
    debugPrint('EndlessRunManager: Level complete, now at index $currentIndex');
  }

  /// Save current progress to SharedPreferences.
  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (runSeed != null) {
      await prefs.setInt(_prefKeyRunSeed, runSeed!);
    } else {
      await prefs.remove(_prefKeyRunSeed);
    }
    
    await prefs.setInt(_prefKeyCurrentIndex, currentIndex);
    await prefs.setInt(_prefKeyHighestIndex, highestIndex);
    
    debugPrint('EndlessRunManager: Saved progress (runSeed=$runSeed, current=$currentIndex, highest=$highestIndex)');
  }

  /// Reset endless progress (for debug/testing).
  Future<void> resetProgress() async {
    runSeed = null;
    currentIndex = 1;
    highestIndex = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRunSeed);
    await prefs.remove(_prefKeyCurrentIndex);
    await prefs.remove(_prefKeyHighestIndex);
    
    debugPrint('EndlessRunManager: Progress reset');
  }

  /// Get difficulty episode based on current level.
  /// Endless uses increasing difficulty: levels 1-50 = Episode 1, 51-100 = Episode 2, etc.
  int getDifficultyEpisode() {
    if (currentIndex <= 50) return 1;
    if (currentIndex <= 100) return 2;
    if (currentIndex <= 150) return 3;
    if (currentIndex <= 200) return 4;
    return 5;
  }
}

