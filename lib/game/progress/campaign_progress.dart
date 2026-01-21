/// Campaign Progress Manager (Manifest-Driven)
///
/// Tracks player progress across episodes with support for dynamic episode count.
/// Storage is based on manifest.json - new episodes auto-initialize.
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

/// Episode metadata from manifest.
class ManifestEpisode {
  final int episode;
  final String file;
  final int count;
  final int seedStart;
  final int seedEnd;

  const ManifestEpisode({
    required this.episode,
    required this.file,
    required this.count,
    required this.seedStart,
    required this.seedEnd,
  });

  factory ManifestEpisode.fromJson(int episode, Map<String, dynamic> json) {
    return ManifestEpisode(
      episode: episode,
      file: json['file'] as String? ?? '',
      count: json['count'] as int? ?? 100,
      seedStart: json['seedStart'] as int? ?? 0,
      seedEnd: json['seedEnd'] as int? ?? 0,
    );
  }
}

/// Progress data for a single episode.
class EpisodeProgress {
  final int episode;
  int currentLevelIndex; // 0-based, next level to play
  int unlockedMaxIndex;  // Highest unlocked level index
  Uint8List starsByLevel; // 0-3 stars per level (efficient storage)
  int totalLevels; // From manifest

  EpisodeProgress({
    required this.episode,
    required this.totalLevels,
    this.currentLevelIndex = 0,
    this.unlockedMaxIndex = 0,
    Uint8List? starsByLevel,
  }) : starsByLevel = starsByLevel ?? Uint8List(totalLevels);

  int get completedLevels {
    int count = 0;
    for (int i = 0; i < starsByLevel.length; i++) {
      if (starsByLevel[i] > 0) count++;
    }
    return count;
  }

  int get totalStars {
    int sum = 0;
    for (int i = 0; i < starsByLevel.length; i++) {
      sum += starsByLevel[i];
    }
    return sum;
  }

  double get progressPercent => totalLevels > 0 ? completedLevels / totalLevels : 0;

  /// Get stars for a specific level (0-based index).
  int getStars(int levelIndex) {
    if (levelIndex < 0 || levelIndex >= starsByLevel.length) return 0;
    return starsByLevel[levelIndex];
  }

  /// Set stars for a specific level (keeps max).
  void setStars(int levelIndex, int stars) {
    if (levelIndex < 0 || levelIndex >= starsByLevel.length) return;
    if (stars > starsByLevel[levelIndex]) {
      starsByLevel[levelIndex] = stars;
    }
    
    // Update unlocked max
    if (levelIndex >= unlockedMaxIndex) {
      unlockedMaxIndex = (levelIndex + 1).clamp(0, totalLevels - 1);
    }
  }

  /// Resize storage if manifest count changed.
  void resizeForCount(int newCount) {
    if (newCount == starsByLevel.length) return;
    
    final newStars = Uint8List(newCount);
    final copyLen = newCount < starsByLevel.length ? newCount : starsByLevel.length;
    for (int i = 0; i < copyLen; i++) {
      newStars[i] = starsByLevel[i];
    }
    starsByLevel = newStars;
    totalLevels = newCount;
    
    // Clamp indices
    currentLevelIndex = currentLevelIndex.clamp(0, newCount - 1);
    unlockedMaxIndex = unlockedMaxIndex.clamp(0, newCount - 1);
  }

  Map<String, dynamic> toJson() => {
    'episode': episode,
    'currentLevelIndex': currentLevelIndex,
    'unlockedMaxIndex': unlockedMaxIndex,
    'totalLevels': totalLevels,
    'starsByLevel': base64Encode(starsByLevel), // Compact binary encoding
  };

  factory EpisodeProgress.fromJson(Map<String, dynamic> json, int manifestCount) {
    final episode = json['episode'] as int;
    final savedCount = json['totalLevels'] as int? ?? manifestCount;
    
    // Decode stars
    Uint8List stars;
    final starsData = json['starsByLevel'];
    if (starsData is String) {
      stars = base64Decode(starsData);
    } else if (starsData is List) {
      stars = Uint8List.fromList(starsData.cast<int>());
    } else {
      stars = Uint8List(manifestCount);
    }

    final progress = EpisodeProgress(
      episode: episode,
      totalLevels: savedCount,
      currentLevelIndex: json['currentLevelIndex'] as int? ?? 0,
      unlockedMaxIndex: json['unlockedMaxIndex'] as int? ?? 0,
      starsByLevel: stars,
    );

    // Resize if manifest count changed
    if (manifestCount != savedCount) {
      progress.resizeForCount(manifestCount);
    }

    return progress;
  }
}

/// Manages campaign progress for all episodes (manifest-driven).
class CampaignProgress {
  static const String _storageKey = 'campaign_progress_v3';
  
  final Map<int, EpisodeProgress> _episodes = {};
  final Map<int, ManifestEpisode> _manifest = {};
  bool _initialized = false;

  /// Singleton instance.
  static final CampaignProgress _instance = CampaignProgress._internal();
  factory CampaignProgress() => _instance;
  CampaignProgress._internal();

  /// Initialize with manifest data.
  Future<void> initWithManifest(Map<String, dynamic> manifest) async {
    if (_initialized) return;
    
    // Parse manifest episodes
    final episodes = manifest['episodes'] as Map<String, dynamic>? ?? {};
    for (final entry in episodes.entries) {
      final ep = int.tryParse(entry.key);
      if (ep != null) {
        _manifest[ep] = ManifestEpisode.fromJson(ep, entry.value as Map<String, dynamic>);
      }
    }
    
    await _load();
    _initialized = true;
  }

  /// Get sorted list of episode IDs from manifest.
  List<int> get episodeIds {
    final ids = _manifest.keys.toList()..sort();
    return ids;
  }

  /// Get manifest info for an episode.
  ManifestEpisode? getManifestEpisode(int episode) => _manifest[episode];

  /// Get level count for an episode from manifest.
  int getLevelCount(int episode) => _manifest[episode]?.count ?? 100;

  /// Get progress for an episode.
  EpisodeProgress getEpisodeProgress(int episode) {
    return _episodes.putIfAbsent(
      episode,
      () => EpisodeProgress(
        episode: episode,
        totalLevels: getLevelCount(episode),
      ),
    );
  }

  /// Get current level index for an episode (0-based).
  int getCurrentLevelIndex(int episode) {
    return getEpisodeProgress(episode).currentLevelIndex;
  }

  /// Get current level number (1-based) for display.
  int getCurrentLevelNumber(int episode) {
    return getCurrentLevelIndex(episode) + 1;
  }

  /// Get unlocked max level index for an episode.
  int getUnlockedMaxIndex(int episode) {
    return getEpisodeProgress(episode).unlockedMaxIndex;
  }

  /// Get unlocked max level number (1-based).
  int getUnlockedMaxNumber(int episode) {
    return getUnlockedMaxIndex(episode) + 1;
  }

  /// Get total stars across all episodes.
  int getTotalStars() {
    return _episodes.values.fold(0, (a, ep) => a + ep.totalStars);
  }

  /// Get stars for a specific episode.
  int getEpisodeStars(int episode) {
    return getEpisodeProgress(episode).totalStars;
  }

  /// Get completed levels for a specific episode.
  int getCompletedLevels(int episode) {
    return getEpisodeProgress(episode).completedLevels;
  }

  /// Complete a level with stars.
  Future<void> completeLevel(int episode, int levelIndex, int stars) async {
    final ep = getEpisodeProgress(episode);
    ep.setStars(levelIndex, stars);
    
    // Advance current level if this was the current
    if (levelIndex == ep.currentLevelIndex && levelIndex < ep.totalLevels - 1) {
      ep.currentLevelIndex = levelIndex + 1;
    }
    
    await _save();
  }

  /// Set current level (for jump feature).
  Future<void> setCurrentLevel(int episode, int levelIndex) async {
    final ep = getEpisodeProgress(episode);
    if (levelIndex <= ep.unlockedMaxIndex && levelIndex < ep.totalLevels) {
      ep.currentLevelIndex = levelIndex;
      await _save();
    }
  }

  /// Check if an episode is unlocked.
  /// Default rule: Episode N unlocks when Episode N-1 is 80% complete.
  bool isEpisodeUnlocked(int episode) {
    final ids = episodeIds;
    if (ids.isEmpty) return true;
    if (episode == ids.first) return true; // First episode always unlocked
    
    // Find previous episode
    final idx = ids.indexOf(episode);
    if (idx <= 0) return true;
    
    final prevEpisode = ids[idx - 1];
    final prevProgress = getEpisodeProgress(prevEpisode);
    return prevProgress.progressPercent >= 0.8;
  }

  /// Get unlock progress for next episode (0.0 to 1.0).
  double getUnlockProgressForNext(int episode) {
    final ep = getEpisodeProgress(episode);
    return (ep.progressPercent / 0.8).clamp(0.0, 1.0);
  }

  /// Reset progress for an episode (debug only).
  Future<void> resetEpisode(int episode) async {
    _episodes[episode] = EpisodeProgress(
      episode: episode,
      totalLevels: getLevelCount(episode),
    );
    await _save();
  }

  /// Reset all progress (debug only).
  Future<void> resetAll() async {
    _episodes.clear();
    await _save();
  }

  /// Debug: Set progress to level X with stars.
  Future<void> debugSetProgress(int episode, int level, int stars) async {
    final ep = getEpisodeProgress(episode);
    for (int i = 0; i < level && i < ep.totalLevels; i++) {
      ep.setStars(i, stars);
    }
    ep.currentLevelIndex = level.clamp(0, ep.totalLevels - 1);
    await _save();
  }

  /// Load from SharedPreferences.
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr != null) {
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final episodes = data['episodes'] as Map<String, dynamic>?;
        
        if (episodes != null) {
          for (final entry in episodes.entries) {
            final epId = int.tryParse(entry.key);
            if (epId != null) {
              final manifestCount = getLevelCount(epId);
              final ep = EpisodeProgress.fromJson(
                entry.value as Map<String, dynamic>,
                manifestCount,
              );
              _episodes[epId] = ep;
            }
          }
        }
      } catch (e) {
        // Corrupted data, start fresh
        _episodes.clear();
      }
    }
    
    // Initialize any manifest episodes not in saved data
    for (final epId in _manifest.keys) {
      if (!_episodes.containsKey(epId)) {
        _episodes[epId] = EpisodeProgress(
          episode: epId,
          totalLevels: getLevelCount(epId),
        );
      }
    }
  }

  /// Save to SharedPreferences.
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'version': 3,
      'episodes': {
        for (final ep in _episodes.values)
          ep.episode.toString(): ep.toJson(),
      },
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }
}
