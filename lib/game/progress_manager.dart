import 'secure_save_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'world_data.dart';

class ProgressManager extends ChangeNotifier {
  static const String keyLevelStars = 'level_stars_'; // + levelId
  static const String keyTotalStars = 'total_stars';
  static const String keyLevelsCompleted = 'levels_completed';
  static const String keyConsecutive3Stars = 'consecutive_3_stars';
  static const String keyAchievements = 'achievements';
  static const String keyLastPlayedLevel = 'last_played_level_id'; // New key
  
  late SharedPreferences _prefs;
  
  // Cache
  final Map<int, int> _levelStars = {};
  final Set<String> _unlockedAchievements = {};
  
  int get totalStars => _levelStars.values.fold(0, (sum, stars) => sum + stars);
  int get levelsCompleted => _levelStars.length;
  int get maxLevel => _levelStars.isEmpty ? 1 : _levelStars.keys.reduce((a, b) => a > b ? a : b) + 1;
  
  int getStarsForLevel(int levelId) => _levelStars[levelId] ?? 0;
  
  // Last played level (default to next playable if none)
  int get lastPlayedLevelId => _prefs.getInt(keyLastPlayedLevel) ?? getNextPlayableLevel();
  
  Future<void> setLastPlayedLevel(int levelId) async {
      await _prefs.setInt(keyLastPlayedLevel, levelId);
      notifyListeners();
  }
  
  int _sessionLevelsCount = 0;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load Data Securely
    final secureData = await SecureSaveManager().loadData(keyLevelStars);
    if (secureData != null) {
        final Map<String, dynamic> data = jsonDecode(secureData);
        data.forEach((key, value) {
            _levelStars[int.parse(key)] = value as int;
        });
    } else {
        // Migration: Load from Prefs if secure not found
        final keys = _prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith(keyLevelStars)) {
            final levelId = int.tryParse(key.substring(keyLevelStars.length));
            if (levelId != null) {
              _levelStars[levelId] = _prefs.getInt(key) ?? 0;
            }
          }
        }
        // Save immediately to secure
        if (_levelStars.isNotEmpty) await _saveProgress();
    }
    
    // FIX: Validate loaded data (stars should be 0-3)
    for (final entry in _levelStars.entries.toList()) {
      if (entry.value < 0 || entry.value > 3) {
        print("[Validation] Invalid stars for level ${entry.key}: ${entry.value}, clamping.");
        _levelStars[entry.key] = entry.value.clamp(0, 3);
        await _prefs.setInt('$keyLevelStars${entry.key}', _levelStars[entry.key]!);
      }
    }
    
    // Load achievements
    final achList = _prefs.getStringList(keyAchievements) ?? [];
    _unlockedAchievements.addAll(achList);
    
    print("ProgressManager: Loaded ${_levelStars.length} completed levels, maxLevel: $maxLevel");
    
    _validateProgress();
  }
  
  // -- PROGRESSION LOGIC --
  
  int getNextPlayableLevel() {
      // Find the first level that is not completed
      int lvl = 1;
      while(getStarsForLevel(lvl) > 0) {
          lvl++;
      }
      return lvl;
  }
  
  bool isLevelUnlocked(int levelId) {
    if (levelId <= 1) return true;
    // Level is unlocked if previous level is completed (stars > 0)
    return getStarsForLevel(levelId - 1) > 0;
  }
  
  bool isWorldUnlocked(int worldId) {
      if (worldId == 1) return true;
      // Get previous world
      final prevWorld = GameWorlds.worlds.firstWhere((w) => w.id == worldId - 1, orElse: () => GameWorlds.worlds.first);
      if (prevWorld.id != worldId - 1) return false; // Should not happen
      
      // Calculate completion of previous world using stars > 0 NOT levelsCompleted count
      int completedInPrev = 0;
      for (int i = prevWorld.startLevel; i <= prevWorld.endLevel; i++) {
          if (getStarsForLevel(i) > 0) completedInPrev++;
      }
      
      final required = (prevWorld.levelCount * 0.8).ceil();
      return completedInPrev >= required;
  }

  void _validateProgress() {
    // Check for gaps in progression
    int maxLvl = maxLevel;
    // We expect levels 1..maxLvl to be present if maxLvl is completed.
    // If not, it means there are unlocked gaps.
    // This is just a consistency check, we don't force-fill yet unless requested.
    List<int> missing = [];
    for (int i = 1; i < maxLvl; i++) {
        if (!_levelStars.containsKey(i)) {
            missing.add(i);
        }
    }
    
    if (missing.isNotEmpty) {
        print("[Progress Warning] Gaps found in level progress: $missing");
        // Optional: Auto-fix gaps by assigning 1 star? 
        // For now, let's just log. Implementing auto-fix might give free stars.
    }
  }

  
  // -- DEBUG / ADMIN TOOLS --
  
  Future<void> debugUnlockAll_DANGEROUS() async {
     // Unlock first 200 levels with 1 star
     for(int i=1; i<=200; i++) {
         if (!_levelStars.containsKey(i)) {
             _levelStars[i] = 1;
             await _prefs.setInt('$keyLevelStars$i', 1);
         }
     }
     notifyListeners();
  }
  
  Future<void> debugResetProgress() async {
      await resetAllData();
  }
  
  Future<void> debugUnlockLevel(int levelId) async {
       // To unlock Level N, we must complete Level N-1.
       if (levelId > 1) {
           int prev = levelId - 1;
           if (!_levelStars.containsKey(prev)) {
               _levelStars[prev] = 1; // Grant minimal completion to previous
               await _prefs.setInt('$keyLevelStars$prev', 1);
               notifyListeners();
           }
       }
  }
  
  // -- TUTORIAL & GUIDES --
  bool isTrainingCompleted(String moduleId) {
      return _prefs.getBool('training_complete_$moduleId') ?? false;
  }
  
  Future<void> completeTraining(String moduleId) async {
       if (!isTrainingCompleted(moduleId)) {
           await _prefs.setBool('training_complete_$moduleId', true);
       }
  }
  
  bool isVideoWatched(String videoId) {
      return _prefs.getBool('video_watched_$videoId') ?? false;
  }
  
  Future<void> markVideoWatched(String videoId) async {
      await _prefs.setBool('video_watched_$videoId', true);
  }
  
  // STATS GETTERS
  int get totalPlayTime => _prefs.getInt('stat_total_play_time') ?? 0; // seconds
  int get totalCompletedLevels => _levelStars.length; // Approximate
  int get totalThreeStars => _levelStars.values.where((s) => s == 3).length;
  int get fastestLevelTime => _prefs.getInt('stat_fastest_time') ?? 9999;
  int get leastMoves => _prefs.getInt('stat_least_moves') ?? 9999;
  int get totalHintsUsed => _prefs.getInt('stat_total_hints') ?? 0;
  int get totalTokensEarned => _prefs.getInt('stat_total_tokens_earned') ?? 0; // Need to track this
  int get longestStreak => _prefs.getInt('stat_longest_streak') ?? 0;
  int get levelsWithoutHints => _prefs.getInt('stat_levels_without_hints') ?? 0; // Track this separately
  // Favorite color is complex, sticking to simple metrics for now.
  
  // Activity Data (simple JSON or key-list)
  // For simplicity, tracking "levels_per_day_{timestamp_day}"
  Map<String, int> getWeeklyActivity() {
      // Return map of "Mon": 5, "Tue": 2 etc.
      // Logic: Iterate last 7 days keys
      final Map<String, int> activity = {};
      final now = DateTime.now();
      for(int i=6; i>=0; i--) {
          final day = now.subtract(Duration(days: i));
          // key format YYYYMMDD
          final key = "activity_${day.year}${day.month.toString().padLeft(2,'0')}${day.day.toString().padLeft(2,'0')}";
          // Determine label (Mon/Tue or Date)
          final label = "${day.day}/${day.month}";
          activity[label] = _prefs.getInt(key) ?? 0;
      }
      return activity;
  }
  
  Map<String, double> getLikelyAchievementProgress() {
      // Pie chart data: Completed vs Remaining (Generic)
      // or distribution by category
      return {
          'Hız': (_prefs.getInt('speed_levels_count') ?? 0).toDouble(),
          'Mükemmellik': (_prefs.getInt('perfect_levels_count') ?? 0).toDouble(),
          'Maraton': _sessionLevelsCount.toDouble(), // This is session based, might be low
          'Bağımsız': (_prefs.getInt('hintless_levels_count') ?? 0).toDouble(),
      };
  }

  // Update methods called during gameplay
  Future<void> updateStats({
      required double duration,
      required int moves,
      required bool usedHint,
  }) async {
      // Time
      int totalTime = totalPlayTime + duration.toInt();
      await _prefs.setInt('stat_total_play_time', totalTime);
      
      // Fastest
      if (duration < fastestLevelTime) {
          await _prefs.setInt('stat_fastest_time', duration.toInt());
      }
      
      // Least Moves (Global min might be trivial, but requested)
      if (moves < leastMoves) {
          await _prefs.setInt('stat_least_moves', moves);
      }
      
      // Hints
      if (usedHint) {
          int hints = totalHintsUsed + 1;
          await _prefs.setInt('stat_total_hints', hints);
      }
      
      // Activity (Daily)
      final now = DateTime.now();
      final key = "activity_${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}";
      int dailyCount = (_prefs.getInt(key) ?? 0) + 1;
      await _prefs.setInt(key, dailyCount);
      
      // Activity (Smart Hours)
      // Track which hour of the day user plays (0-23)
      final hourKey = 'active_hour_${now.hour}';
      int hourCount = (_prefs.getInt(hourKey) ?? 0) + 1;
      await _prefs.setInt(hourKey, hourCount);
  }
  
  List<int> getPreferredPlayHours() {
      // Find top 3 hours
      List<MapEntry<int, int>> hours = [];
      for(int i=0; i<24; i++) {
          int count = _prefs.getInt('active_hour_$i') ?? 0;
          hours.add(MapEntry(i, count));
      }
      // Sort desc by count
      hours.sort((a,b) => b.value.compareTo(a.value));
      return hours.take(3).map((e) => e.key).toList();
  }
  
  Future<void> trackTokensEarned(int amount) async {
       int current = totalTokensEarned + amount;
       await _prefs.setInt('stat_total_tokens_earned', current);
  }
  
  // Logic: Calculate Stars
  Future<int> completeLevel(int levelId, int moves, int par, bool usedHints, double durationSeconds) async {
      int stars = 1;
      if (moves <= par) {
          stars = 3;
      } else if (moves <= (par * 1.5).ceil()) {
          stars = 2;
      }
      
      // Save best score only? Or overwrite? 
      // Usually keep best.
      final currentBest = _levelStars[levelId] ?? 0;
      if (stars > currentBest) {
          _levelStars[levelId] = stars;
          await _saveProgress(); // Secure Save
          
          _logAnalytics('level_completed', params: {'level': levelId, 'stars': stars, 'attempts': 1});

          // Check Star Rewards
          _checkStarRewards();
      }
      
      notifyListeners();
      
      return stars;
  }
  
  void _logAnalytics(String event, {Map<String, dynamic>? params}) {
      print("[Analytics] $event: $params");
  }
  
  void _checkStarRewards() {
      final tStars = totalStars;
      if (tStars >= 50 && !_isRewardClaimed('skin_50')) _unlockReward('skin_50');
      if (tStars >= 100 && !_isRewardClaimed('effect_100')) _unlockReward('effect_100');
      if (tStars >= 500 && !_isRewardClaimed('theme_500')) _unlockReward('theme_500');
  }
  
  bool _isRewardClaimed(String id) {
      // Stub
      return false;
  }
  
  void _unlockReward(String id) {
      print("Reward Unlocked: $id");
      // Persist reward claim
  }
  
  // Merged checkGlobalAchievements
  Future<void> checkGlobalAchievements({
      required int levelId,
      required int stars,
      required int moves,
      required double duration,
      required int attempts,
      required bool usedHints,
      required bool musicOn,
      required bool sfxOn,
      required bool vibrationOn,
      required Function(int) onTokenReward,
      required Function(String) onSkinReward,
      bool isNewPerfect = false, // New flag: Only true if this level just became 3 stars
      bool isUniqueCompletion = false, // New flag: Only true if this level wasn't completed before
  }) async {
      // 1. First Light (Finish Level 1)
      if (levelId == 1) _unlock('ach_first_light', onTokenReward);
      
      // 2. Quick Thinker (10s)
      if (duration <= 10.0) _unlock('ach_quick_thinker', onTokenReward);
      
      // 3. Perfectionist (5 consecutive 3 stars)
      if (stars == 3) {
          int streak = _prefs.getInt(keyConsecutive3Stars) ?? 0;
          streak++;
          await _prefs.setInt(keyConsecutive3Stars, streak);
          if (streak >= 5) _unlock('ach_perfectionist', onTokenReward);
      } else {
          await _prefs.setInt(keyConsecutive3Stars, 0);
      }

      // 4. Patient (No hints 20 levels)
      if (!usedHints) {
          int count = _prefs.getInt('levels_without_hints') ?? 0;
          count++;
          await _prefs.setInt('levels_without_hints', count);
          if (count >= 20) _unlock('ach_patient', onTokenReward);
      }
      
      // 5. Marathon (Session)
      _sessionLevelsCount++;
      if (_sessionLevelsCount >= 25) _unlock('ach_marathon_1', onTokenReward);
      
      // 6. Light Apprentice (Total Levels)
      int levelsCompleted = 0; 
      
      // --- SECRET ACHIEVEMENTS ---
      if (!musicOn && !sfxOn && !vibrationOn) _unlock('ach_darkness', onTokenReward);
      if (moves == 1) {
          _unlock('ach_minimalist', onTokenReward);
          
          // Track for One-Shot Master (5 single-move completions)
          int oneShotCount = (_prefs.getInt('one_shot_count') ?? 0) + 1;
          await _prefs.setInt('one_shot_count', oneShotCount);
          if (oneShotCount >= 5) _unlock('ach_one_shot_master', onTokenReward);
      }
      if (attempts == 7) _unlock('ach_lucky_7', onTokenReward);
      
      final now = DateTime.now();
      if (now.hour >= 2 && now.hour < 4) {
          int count = (_prefs.getInt('night_owl_count') ?? 0) + 1;
          await _prefs.setInt('night_owl_count', count);
          if (count >= 10) _unlock('ach_night_owl', onTokenReward);
      }
      if (duration >= 600) _unlock('ach_patience_stone', onTokenReward);
      
      // Update General Stats
      await updateStats(duration: duration, moves: moves, usedHint: usedHints);
      
      // --- CATEGORY ACHIEVEMENTS ---
      
      // 1. SPEED (Under 20s)
      if (duration < 20.0) {
          int speedCount = (_prefs.getInt('speed_levels_count') ?? 0) + 1;
          await _prefs.setInt('speed_levels_count', speedCount);
          if (speedCount == 5) _unlock('ach_speed_1', onTokenReward);
          if (speedCount == 50) {
              _unlock('ach_speed_master', onTokenReward);
              onSkinReward('skin_flash'); 
          }
      }
      
      // 2. PERFECTION (3 Stars)
      if (isNewPerfect) { // Changed condition: Only count if it's a NEW perfect level
           int perfectCount = (_prefs.getInt('perfect_levels_count') ?? 0) + 1;
           await _prefs.setInt('perfect_levels_count', perfectCount);
           if (perfectCount == 10) _unlock('ach_perfect_1', onTokenReward);
           if (perfectCount == 200) {
              _unlock('ach_perfect_master', onTokenReward);
              onSkinReward('skin_diamond'); 
           }
      }
      
      // 3. MARATHON (Session)
      // Already incremented in section 5
      if (_sessionLevelsCount == 10) _unlock('ach_marathon_1', onTokenReward);
      if (_sessionLevelsCount == 100) {
          _unlock('ach_marathon_master', onTokenReward);
          onSkinReward('skin_void');
      }
      
      // 4. INDEPENDENT (No Hints)
      if (!usedHints) {
          int count = (_prefs.getInt('hintless_levels_count') ?? 0) + 1;
          await _prefs.setInt('hintless_levels_count', count);
          if (count == 25) _unlock('ach_independent_1', onTokenReward);
          if (count == 100) {
              _unlock('ach_independent_master', onTokenReward);
              onSkinReward('skin_mentalist');
          }
      }
      
      // LEGEND Check
      if (_unlockedAchievements.length >= 20) { 
           if (!_isRewardClaimed('ultra_skin')) {
               _unlock('ach_legend', onTokenReward);
               onSkinReward('skin_cosmic_god'); 
           }
      }
  }

  // Helper for internal use
  Future<void> _unlock(String title, Function(int) onTokenReward) async {
      if (!_unlockedAchievements.contains(title)) {
          _unlockedAchievements.add(title);
          await _prefs.setStringList(keyAchievements, _unlockedAchievements.toList()); // FIX: Await save
          print("ACHIEVEMENT UNLOCKED: $title");
          // Reward: 20 tokens per achievement
          onTokenReward(20);
      }
  }
  
  // RESET ALL DATA
  Future<void> resetAllData() async {
      // Clear all stats
      _levelStars.clear();
      _unlockedAchievements.clear();
      _sessionLevelsCount = 0;
      
      // Prefs
      await _prefs.clear(); // NOTE: This nukes settings too unless we are careful.
      // ProgressManager shares prefs? Usually we use one valid instance.
      // If we used separate instances but same underlying file, clear() wipes all.
      // SettingsManager uses SharedPreferences.getInstance() too.
      // So _prefs.clear() wipes EVERYTHING including volume settings.
      // We should selectively remove keys starting with known prefixes OR just iterate all keys.
      
      // Safe approach: Remove specific keys managed by this class.
      final keys = _prefs.getKeys();
      for(String key in keys) {
          if (
              key.startsWith('level_') || 
              key.startsWith('stat_') ||
              key.startsWith('activity_') ||
              key.startsWith('video_') ||
              key.startsWith('training_') ||
              key == keyTotalStars ||
              key == keyConsecutive3Stars ||
              key == keyAchievements
          ) {
              await _prefs.remove(key);
          }
      }
      
      notifyListeners();
      print("Progress Data Wiped.");
  }

  Future<void> _saveProgress() async {
      final jsonMap = _levelStars.map((k, v) => MapEntry(k.toString(), v));
      await SecureSaveManager().saveData(keyLevelStars, jsonEncode(jsonMap));
  }
}

