import 'package:flutter/material.dart';

/// World/Chapter data model for the game
class WorldData {
  final int id;
  final String nameKey; // localization key
  final int startLevel;
  final int endLevel;
  final Color themeColor;
  final IconData icon;

  const WorldData({
    required this.id,
    required this.nameKey,
    required this.startLevel,
    required this.endLevel,
    required this.themeColor,
    required this.icon,
  });

  int get levelCount => endLevel - startLevel + 1;
  int get maxStars => levelCount * 3;
}

/// All game worlds
class GameWorlds {
  static const List<WorldData> worlds = [
    WorldData(
      id: 1,
      nameKey: 'world_1',
      startLevel: 1,
      endLevel: 30,
      themeColor: Color(0xFF9B59B6), // Purple
      icon: Icons.wb_sunny,
    ),
    WorldData(
      id: 2,
      nameKey: 'world_2',
      startLevel: 31,
      endLevel: 60,
      themeColor: Color(0xFF3498DB), // Blue
      icon: Icons.palette,
    ),
    WorldData(
      id: 3,
      nameKey: 'world_3',
      startLevel: 61,
      endLevel: 100,
      themeColor: Color(0xFF27AE60), // Green
      icon: Icons.auto_awesome,
    ),
    WorldData(
      id: 4,
      nameKey: 'world_4',
      startLevel: 101,
      endLevel: 150,
      themeColor: Color(0xFFE67E22), // Orange
      icon: Icons.diamond,
    ),
    WorldData(
      id: 5,
      nameKey: 'world_5',
      startLevel: 151,
      endLevel: 200,
      themeColor: Color(0xFFE74C3C), // Red
      icon: Icons.access_time,
    ),
  ];

  static WorldData? getWorldForLevel(int levelId) {
    for (final world in worlds) {
      if (levelId >= world.startLevel && levelId <= world.endLevel) {
        return world;
      }
    }
    return null;
  }

  static bool isWorldUnlocked(int worldId, int completedLevels) {
    if (worldId == 1) return true;
    final prevWorld = worlds[worldId - 2];
    // Unlock next world when 80% of previous is complete
    final requiredLevels = (prevWorld.levelCount * 0.8).ceil();
    final prevWorldCompleted = _getLevelsCompletedInWorld(prevWorld, completedLevels);
    return prevWorldCompleted >= requiredLevels;
  }

  static int _getLevelsCompletedInWorld(WorldData world, int totalCompleted) {
    if (totalCompleted < world.startLevel) return 0;
    if (totalCompleted >= world.endLevel) return world.levelCount;
    return totalCompleted - world.startLevel + 1;
  }
}
