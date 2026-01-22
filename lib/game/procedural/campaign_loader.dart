/// Campaign Level Loader
///
/// Loads pre-generated campaign levels from bundled JSON assets.
/// These levels are generated offline using tool/export_campaign.dart.
/// 
/// Includes strict manifest and schema validation with descriptive errors.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models/models.dart' as proc;
import 'occupancy_grid.dart';

/// Supported manifest version(s).
const int _supportedManifestVersion = 1;

/// Error thrown when campaign asset validation fails.
class CampaignValidationError implements Exception {
  final String message;
  final int? episode;
  final int? levelIndex;
  final String? filePath;
  final String? offendingKey;
  final dynamic offendingValue;

  CampaignValidationError(
    this.message, {
    this.episode,
    this.levelIndex,
    this.filePath,
    this.offendingKey,
    this.offendingValue,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CampaignValidationError: $message');
    if (episode != null) buffer.write(' [Episode: $episode]');
    if (levelIndex != null) buffer.write(' [Level: $levelIndex]');
    if (filePath != null) buffer.write(' [File: $filePath]');
    if (offendingKey != null) buffer.write(' [Key: $offendingKey]');
    if (offendingValue != null) buffer.write(' [Value: $offendingValue]');
    return buffer.toString();
  }
}

/// Loader for pre-generated campaign levels.
class CampaignLevelLoader {
  /// Cache of loaded episode data.
  static final Map<int, List<proc.GeneratedLevel>> _cache = {};

  /// Cached manifest data.
  static Map<String, dynamic>? _manifestCache;

  /// Load and validate manifest from assets.
  /// 
  /// Throws [CampaignValidationError] if:
  /// - Manifest file is missing
  /// - Version is unsupported
  /// - Episodes map is missing or invalid
  static Future<Map<String, dynamic>> loadManifest() async {
    if (_manifestCache != null) return _manifestCache!;

    const assetPath = 'assets/generated/manifest.json';
    
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate version
      if (!json.containsKey('version')) {
        throw CampaignValidationError(
          'Manifest missing required field "version"',
          filePath: assetPath,
          offendingKey: 'version',
        );
      }
      
      final version = json['version'];
      if (version is! int || version != _supportedManifestVersion) {
        throw CampaignValidationError(
          'Unsupported manifest version. Expected: $_supportedManifestVersion',
          filePath: assetPath,
          offendingKey: 'version',
          offendingValue: version,
        );
      }
      
      // Validate episodes map exists
      if (!json.containsKey('episodes')) {
        throw CampaignValidationError(
          'Manifest missing required field "episodes"',
          filePath: assetPath,
          offendingKey: 'episodes',
        );
      }
      
      final episodes = json['episodes'];
      if (episodes is! Map<String, dynamic>) {
        throw CampaignValidationError(
          'Manifest "episodes" must be a map',
          filePath: assetPath,
          offendingKey: 'episodes',
          offendingValue: episodes.runtimeType.toString(),
        );
      }
      
      _manifestCache = json;
      debugPrint('CampaignLoader: Manifest loaded - version $version, ${episodes.length} episodes');
      return json;
      
    } on FlutterError {
      throw CampaignValidationError(
        'Manifest file not found. Run export_campaign.dart to generate campaign assets.',
        filePath: assetPath,
      );
    }
  }

  /// Validate episode entry in manifest.
  static void _validateManifestEpisodeEntry(
    Map<String, dynamic> manifest,
    int episode,
  ) {
    final episodes = manifest['episodes'] as Map<String, dynamic>;
    final episodeKey = episode.toString();
    
    if (!episodes.containsKey(episodeKey)) {
      throw CampaignValidationError(
        'Episode $episode not found in manifest',
        episode: episode,
        filePath: 'assets/generated/manifest.json',
        offendingKey: 'episodes.$episodeKey',
      );
    }
    
    final entry = episodes[episodeKey];
    if (entry is! Map<String, dynamic>) {
      throw CampaignValidationError(
        'Episode entry must be a map',
        episode: episode,
        offendingKey: 'episodes.$episodeKey',
        offendingValue: entry.runtimeType.toString(),
      );
    }
    
    // Validate required fields
    if (!entry.containsKey('file')) {
      throw CampaignValidationError(
        'Episode entry missing required field "file"',
        episode: episode,
        offendingKey: 'episodes.$episodeKey.file',
      );
    }
    
    if (!entry.containsKey('count')) {
      throw CampaignValidationError(
        'Episode entry missing required field "count"',
        episode: episode,
        offendingKey: 'episodes.$episodeKey.count',
      );
    }
    
    final count = entry['count'];
    if (count is! int || count <= 0) {
      throw CampaignValidationError(
        'Episode count must be a positive integer',
        episode: episode,
        offendingKey: 'episodes.$episodeKey.count',
        offendingValue: count,
      );
    }
  }

  /// Load all levels for an episode from the bundled JSON asset.
  ///
  /// Returns cached data if already loaded.
  /// Throws [CampaignValidationError] if asset is missing or invalid.
  static Future<List<proc.GeneratedLevel>> loadEpisode(int episode) async {
    // Return cached if available
    if (_cache.containsKey(episode)) {
      return _cache[episode]!;
    }

    // Load and validate manifest first
    final manifest = await loadManifest();
    _validateManifestEpisodeEntry(manifest, episode);
    
    final episodeEntry = (manifest['episodes'] as Map<String, dynamic>)[episode.toString()] as Map<String, dynamic>;
    final expectedCount = episodeEntry['count'] as int;
    final fileName = episodeEntry['file'] as String;
    final assetPath = 'assets/generated/$fileName';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate episode file schema
      _validateEpisodeFileSchema(json, episode, assetPath, expectedCount);

      final levelsList = json['levels'] as List;
      final levels = <proc.GeneratedLevel>[];
      
      for (int i = 0; i < levelsList.length; i++) {
        final entry = levelsList[i];
        _validateLevelEntry(entry, episode, i + 1, assetPath);
        
        final levelJson = entry['level'] as Map<String, dynamic>;
        levels.add(proc.GeneratedLevel.fromJson(levelJson));
      }

      // Cache the result
      _cache[episode] = levels;
      
      // Validate occupancy for all levels (should never fail in production)
      for (int i = 0; i < levels.length; i++) {
        final level = levels[i];
        final occupancyResult = OccupancyGrid.validateLevel(level);
        if (!occupancyResult.valid) {
          throw CampaignValidationError(
            'Level has occupancy collision',
            episode: episode,
            filePath: assetPath,
            levelIndex: i + 1,
            offendingKey: 'occupancy',
            offendingValue: occupancyResult.collisions.join(', '),
          );
        }
      }
      
      debugPrint('CampaignLoader: Episode $episode loaded - ${levels.length} levels (occupancy validated)');
      return levels;
      
    } on FlutterError {
      throw CampaignValidationError(
        'Episode asset file not found',
        episode: episode,
        filePath: assetPath,
      );
    }
  }

  /// Validate episode file top-level schema.
  static void _validateEpisodeFileSchema(
    Map<String, dynamic> json,
    int episode,
    String assetPath,
    int expectedCount,
  ) {
    // Version check
    if (json.containsKey('version')) {
      final version = json['version'];
      if (version is! int || version != _supportedManifestVersion) {
        throw CampaignValidationError(
          'Unsupported episode file version',
          episode: episode,
          filePath: assetPath,
          offendingKey: 'version',
          offendingValue: version,
        );
      }
    }
    
    // Episode number check
    if (json.containsKey('episode')) {
      final fileEpisode = json['episode'];
      if (fileEpisode is! int || fileEpisode != episode) {
        throw CampaignValidationError(
          'Episode number mismatch. File claims episode $fileEpisode but requested $episode',
          episode: episode,
          filePath: assetPath,
          offendingKey: 'episode',
          offendingValue: fileEpisode,
        );
      }
    }
    
    // Levels array check
    if (!json.containsKey('levels')) {
      throw CampaignValidationError(
        'Episode file missing required field "levels"',
        episode: episode,
        filePath: assetPath,
        offendingKey: 'levels',
      );
    }
    
    final levels = json['levels'];
    if (levels is! List) {
      throw CampaignValidationError(
        'Episode "levels" must be an array',
        episode: episode,
        filePath: assetPath,
        offendingKey: 'levels',
        offendingValue: levels.runtimeType.toString(),
      );
    }
    
    // Count mismatch warning (not error, but logged)
    if (levels.length != expectedCount) {
      debugPrint(
        'WARNING: Episode $episode level count mismatch. '
        'Manifest claims $expectedCount but file has ${levels.length}',
      );
    }
  }

  /// Validate individual level entry in episode file.
  static void _validateLevelEntry(
    dynamic entry,
    int episode,
    int levelIndex,
    String assetPath,
  ) {
    if (entry is! Map<String, dynamic>) {
      throw CampaignValidationError(
        'Level entry must be a map',
        episode: episode,
        levelIndex: levelIndex,
        filePath: assetPath,
        offendingValue: entry.runtimeType.toString(),
      );
    }
    
    if (!entry.containsKey('level')) {
      throw CampaignValidationError(
        'Level entry missing required field "level"',
        episode: episode,
        levelIndex: levelIndex,
        filePath: assetPath,
        offendingKey: 'level',
      );
    }
    
    final levelData = entry['level'];
    if (levelData is! Map<String, dynamic>) {
      throw CampaignValidationError(
        'Level "level" field must be a map',
        episode: episode,
        levelIndex: levelIndex,
        filePath: assetPath,
        offendingKey: 'level',
        offendingValue: levelData.runtimeType.toString(),
      );
    }
    
    // Validate required level fields
    const requiredFields = ['seed', 'episode', 'index', 'source', 'targets', 'mirrors'];
    for (final field in requiredFields) {
      if (!levelData.containsKey(field)) {
        throw CampaignValidationError(
          'Level data missing required field "$field"',
          episode: episode,
          levelIndex: levelIndex,
          filePath: assetPath,
          offendingKey: 'level.$field',
        );
      }
    }
  }

  /// Get a specific level by index (1-based).
  ///
  /// Returns null if index is out of bounds.
  /// Throws [CampaignValidationError] if validation fails.
  static Future<proc.GeneratedLevel?> loadLevel(int episode, int index) async {
    final levels = await loadEpisode(episode);
    if (index < 1 || index > levels.length) {
      debugPrint('CampaignLoader: Level $index out of bounds for Episode $episode (1-${levels.length})');
      return null;
    }
    return levels[index - 1];
  }

  /// Get the count of levels for an episode.
  static Future<int> getLevelCount(int episode) async {
    final levels = await loadEpisode(episode);
    return levels.length;
  }

  /// Check if campaign assets exist for an episode.
  static Future<bool> hasEpisode(int episode) async {
    try {
      final manifest = await loadManifest();
      final episodes = manifest['episodes'] as Map<String, dynamic>;
      return episodes.containsKey(episode.toString());
    } on CampaignValidationError {
      return false;
    }
  }

  /// Clear all caches.
  static void clearCache() {
    _cache.clear();
    _manifestCache = null;
  }

  /// Clear the cache for a specific episode.
  static void clearEpisodeCache(int episode) {
    _cache.remove(episode);
  }
}

