class GameWorld {
  final int id;
  final int startLevel;
  final int endLevel;
  final int levelCount;

  const GameWorld({
    required this.id,
    required this.startLevel,
    required this.endLevel,
    required this.levelCount,
  });
}

class GameWorlds {
  static const List<GameWorld> worlds = [
    GameWorld(id: 1, startLevel: 1, endLevel: 200, levelCount: 200),
    GameWorld(id: 2, startLevel: 201, endLevel: 400, levelCount: 200),
    GameWorld(id: 3, startLevel: 401, endLevel: 600, levelCount: 200),
    GameWorld(id: 4, startLevel: 601, endLevel: 800, levelCount: 200),
    GameWorld(id: 5, startLevel: 801, endLevel: 1000, levelCount: 200),
  ];
}
