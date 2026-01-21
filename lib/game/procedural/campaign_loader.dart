/// Campaign Level Loader
///
/// Loads pre-generated campaign levels from bundled JSON assets.
/// These levels are generated offline using tool/export_campaign.dart.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models/models.dart' as proc;

/// Loader for pre-generated campaign levels.
class CampaignLevelLoader {
  /// Cache of loaded episode data.
  static final Map<int, List<proc.GeneratedLevel>> _cache = {};

  /// Load all levels for an episode from the bundled JSON asset.
  ///
  /// Returns cached data if already loaded.
  /// Throws an exception if the asset is not found or invalid.
  static Future<List<proc.GeneratedLevel>> loadEpisode(int episode) async {
    // Return cached if available
    if (_cache.containsKey(episode)) {
      return _cache[episode]!;
    }

    // Load from asset
    final episodeStr = episode.toString().padLeft(2, '0');
    final assetPath = 'assets/generated/episode_$episodeStr.json';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final levelsList = json['levels'] as List;
      final levels = levelsList.map((entry) {
        final levelJson = entry['level'] as Map<String, dynamic>;
        return proc.GeneratedLevel.fromJson(levelJson);
      }).toList();

      // Cache the result
      _cache[episode] = levels;

      return levels;
    } on FlutterError {
      throw Exception('Asset not found: $assetPath. Run export_campaign.dart first.');
    }
  }

  /// Get a specific level by index (1-based).
  ///
  /// Returns null if index is out of bounds.
  static Future<proc.GeneratedLevel?> loadLevel(int episode, int index) async {
    final levels = await loadEpisode(episode);
    if (index < 1 || index > levels.length) {
      return null;
    }
    return levels[index - 1];
  }

  /// Get the count of levels for an episode.
  ///
  /// Returns 0 if episode not loaded.
  static Future<int> getLevelCount(int episode) async {
    final levels = await loadEpisode(episode);
    return levels.length;
  }

  /// Load manifest with metadata about all episodes.
  static Future<Map<String, dynamic>> loadManifest() async {
    const assetPath = 'assets/generated/manifest.json';
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } on FlutterError {
      return {
        'version': 1,
        'episodes': {},
      };
    }
  }

  /// Check if campaign assets exist for an episode.
  static Future<bool> hasEpisode(int episode) async {
    try {
      final manifest = await loadManifest();
      final episodes = manifest['episodes'] as Map<String, dynamic>?;
      return episodes?.containsKey(episode.toString()) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Clear the cache for all episodes.
  static void clearCache() {
    _cache.clear();
  }

  /// Clear the cache for a specific episode.
  static void clearEpisodeCache(int episode) {
    _cache.remove(episode);
  }
}
