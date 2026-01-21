import 'dart:convert';
import 'dart:math';

/// Campaign Level Generator - Creates levels 1-100 based on LEVEL_DESIGN_GUIDE.md specs
class CampaignLevelGenerator {
  final Random _random = Random(42); // Fixed seed for reproducible levels
  
  /// Generate all 100 campaign levels
  List<Map<String, dynamic>> generateAllLevels() {
    final levels = <Map<String, dynamic>>[];
    for (int i = 1; i <= 100; i++) {
      levels.add(generateLevel(i));
    }
    return levels;
  }
  
  /// Generate a single level based on its ID
  Map<String, dynamic> generateLevel(int levelId) {
    final config = _getLevelConfig(levelId);
    final gridSize = config.gridSize;
    final usedPositions = <String>{};
    
    final objects = <Map<String, dynamic>>[];
    
    // Place light source(s)
    for (int i = 0; i < config.lightCount; i++) {
      objects.add(_placeLightSource(gridSize, usedPositions, config.lightColors[i % config.lightColors.length]));
    }
    
    // Place targets
    for (int i = 0; i < config.targetCount; i++) {
      objects.add(_placeTarget(gridSize, usedPositions, config.targetColors[i % config.targetColors.length]));
    }
    
    // Place mirrors/prisms
    final interactiveCount = config.objectCount - config.lightCount - config.targetCount;
    for (int i = 0; i < interactiveCount; i++) {
      objects.add(_placeInteractive(gridSize, usedPositions, config));
    }
    
    // Place obstacles
    for (int i = 0; i < config.obstacleCount; i++) {
      objects.add(_placeObstacle(gridSize, usedPositions, config));
    }
    
    return {
      'id': levelId,
      'name': config.name,
      'par': config.par,
      'difficulty': config.difficulty,
      'theme': config.theme,
      'music': config.music,
      'mechanics': config.mechanics,
      'gridSize': gridSize,
      'isBoss': levelId % 50 == 0,
      'isReview': levelId % 25 == 0 && levelId % 50 != 0,
      'timeLimit': config.maxTime,
      'objects': objects,
    };
  }
  
  /// Get level configuration based on level range
  _LevelConfig _getLevelConfig(int levelId) {
    if (levelId <= 10) return _getLevel1to10Config(levelId);
    if (levelId <= 20) return _getLevel11to20Config(levelId);
    if (levelId <= 30) return _getLevel21to30Config(levelId);
    if (levelId <= 40) return _getLevel31to40Config(levelId);
    if (levelId <= 50) return _getLevel41to50Config(levelId);
    if (levelId <= 60) return _getLevel51to60Config(levelId);
    if (levelId <= 70) return _getLevel61to70Config(levelId);
    if (levelId <= 80) return _getLevel71to80Config(levelId);
    if (levelId <= 90) return _getLevel81to90Config(levelId);
    return _getLevel91to100Config(levelId);
  }
  
  // ==========================================
  // LEVEL 1-10: TEMEL YANSIMA
  // ==========================================
  _LevelConfig _getLevel1to10Config(int id) {
    final objectCount = 1 + (id ~/ 3); // 1-3 mirrors
    final par = max(1, id ~/ 3); // 1-3 moves
    
    return _LevelConfig(
      name: _getLevelName(id, 'Işık Yolu'),
      objectCount: objectCount + 2, // mirrors + light + target
      lightCount: 1,
      targetCount: 1,
      obstacleCount: 0,
      par: par,
      minTime: 10,
      maxTime: 30,
      gridSize: 5,
      difficulty: 'easy',
      theme: 'space_nebula',
      music: 'bgm_game_low.mp3',
      mechanics: ['mirror'],
      lightColors: ['white'],
      targetColors: ['white'],
      allowedAngles: [45, 90, 135, 180, 225, 270, 315],
    );
  }
  
  // ==========================================
  // LEVEL 11-20: ÇOKLU YANSIMA
  // ==========================================
  _LevelConfig _getLevel11to20Config(int id) {
    final idx = id - 10;
    final objectCount = 3 + (idx ~/ 3); // 3-5 mirrors
    final par = 3 + (idx ~/ 5); // 3-5 moves
    
    return _LevelConfig(
      name: _getLevelName(id, 'Zincir'),
      objectCount: objectCount + 2,
      lightCount: 1,
      targetCount: 1,
      obstacleCount: 1 + idx ~/ 5, // Add walls
      par: par,
      minTime: 30,
      maxTime: 60,
      gridSize: 5,
      difficulty: 'easy',
      theme: 'neon_city',
      music: 'bgm_game_low.mp3',
      mechanics: ['mirror', 'wall'],
      lightColors: ['white'],
      targetColors: ['white'],
      allowedAngles: [45, 90, 135, 225, 270, 315],
    );
  }
  
  // ==========================================
  // LEVEL 21-30: İLK ZORLUKLAR
  // ==========================================
  _LevelConfig _getLevel21to30Config(int id) {
    final idx = id - 20;
    final objectCount = 5 + (idx ~/ 3); // 5-7 mirrors
    final par = 4 + idx ~/ 2; // 4-7 moves
    final targets = idx >= 5 ? 2 : 1;
    
    return _LevelConfig(
      name: _getLevelName(id, 'Hassas'),
      objectCount: objectCount + 1 + targets,
      lightCount: 1,
      targetCount: targets,
      obstacleCount: 2 + idx ~/ 4,
      par: par,
      minTime: 45,
      maxTime: 90,
      gridSize: 6,
      difficulty: 'medium',
      theme: 'ocean_depths',
      music: 'bgm_game_low.mp3',
      mechanics: ['mirror', 'wall', 'fixed_mirror'],
      lightColors: ['white'],
      targetColors: ['white', 'white'],
      allowedAngles: [22.5, 45, 67.5, 90, 112.5, 135, 157.5, 180],
    );
  }
  
  // ==========================================
  // LEVEL 31-40: RENK TANIŞMASI
  // ==========================================
  _LevelConfig _getLevel31to40Config(int id) {
    final idx = id - 30;
    final objectCount = 4 + (idx ~/ 3); // 4-6 objects
    final par = 4 + idx ~/ 3; // 4-6 moves
    
    return _LevelConfig(
      name: _getLevelName(id, 'Kırmızı'),
      objectCount: objectCount + 2,
      lightCount: 1,
      targetCount: 1,
      obstacleCount: 1 + idx ~/ 5,
      par: par,
      minTime: 40,
      maxTime: 70,
      gridSize: 6,
      difficulty: 'medium',
      theme: 'crystal_cave',
      music: 'bgm_game_mid.mp3',
      mechanics: ['mirror', 'prism', 'filter'],
      lightColors: ['red'],
      targetColors: ['red'],
      allowedAngles: [45, 90, 135, 180, 225, 270, 315],
    );
  }
  
  // ==========================================
  // LEVEL 41-50: ÇİFT RENK
  // ==========================================
  _LevelConfig _getLevel41to50Config(int id) {
    final idx = id - 40;
    final objectCount = 6 + (idx ~/ 3); // 6-8 objects
    final par = 6 + idx ~/ 2; // 6-10 moves
    
    return _LevelConfig(
      name: _getLevelName(id, 'İkili'),
      objectCount: objectCount + 4, // 2 lights + 2 targets
      lightCount: 2,
      targetCount: 2,
      obstacleCount: 2,
      par: par,
      minTime: 60,
      maxTime: 90,
      gridSize: 6,
      difficulty: 'medium',
      theme: 'volcanic_core',
      music: 'bgm_game_mid.mp3',
      mechanics: ['mirror', 'prism', 'filter'],
      lightColors: ['red', 'blue'],
      targetColors: ['red', 'blue'],
      allowedAngles: [45, 90, 135, 225, 270, 315],
    );
  }
  
  // ==========================================
  // LEVEL 51-60: RENK KARIŞIMI
  // ==========================================
  _LevelConfig _getLevel51to60Config(int id) {
    final idx = id - 50;
    final objectCount = 7 + (idx ~/ 2); // 7-10 objects
    final par = 7 + idx ~/ 2; // 7-12 moves
    
    return _LevelConfig(
      name: _getLevelName(id, 'Karışım'),
      objectCount: objectCount + 3,
      lightCount: 2,
      targetCount: 1, // Purple target from mixing
      obstacleCount: 2 + idx ~/ 4,
      par: par,
      minTime: 75,
      maxTime: 120,
      gridSize: 7,
      difficulty: 'hard',
      theme: 'arctic_aurora',
      music: 'bgm_game_mid.mp3',
      mechanics: ['mirror', 'prism', 'filter', 'color_mix'],
      lightColors: ['red', 'blue'],
      targetColors: ['purple'], // Mixed color
      allowedAngles: [45, 90, 135, 225, 270, 315],
    );
  }
  
  // ==========================================
  // LEVEL 61-70: GELİŞMİŞ KARIŞIM
  // ==========================================
  _LevelConfig _getLevel61to70Config(int id) {
    final idx = id - 60;
    final objectCount = 8 + (idx ~/ 2); // 8-12 objects
    final par = 10 + idx ~/ 2; // 10-15 moves
    final targets = 2 + idx ~/ 4; // 2-3 targets
    
    return _LevelConfig(
      name: _getLevelName(id, 'Spektrum'),
      objectCount: objectCount + 4,
      lightCount: 3, // RGB
      targetCount: targets,
      obstacleCount: 3,
      par: par,
      minTime: 90,
      maxTime: 150,
      gridSize: 7,
      difficulty: 'hard',
      theme: 'jungle_temple',
      music: 'bgm_game_high.mp3',
      mechanics: ['mirror', 'prism', 'filter', 'color_mix', 'absorbing_wall'],
      lightColors: ['red', 'blue', 'yellow'],
      targetColors: ['purple', 'orange', 'green'],
      allowedAngles: [45, 90, 135, 180, 225, 270, 315],
    );
  }
  
  // ==========================================
  // LEVEL 71-80: FİLTRE LABİRENTİ
  // ==========================================
  _LevelConfig _getLevel71to80Config(int id) {
    final idx = id - 70;
    final objectCount = 10 + (idx ~/ 2); // 10-14 objects
    final par = 12 + idx ~/ 2; // 12-18 moves
    
    return _LevelConfig(
      name: _getLevelName(id, 'Filtre'),
      objectCount: objectCount + 4,
      lightCount: 1, // White light
      targetCount: 3,
      obstacleCount: 4 + idx ~/ 3,
      par: par,
      minTime: 100,
      maxTime: 180,
      gridSize: 7,
      difficulty: 'hard',
      theme: 'digital_matrix',
      music: 'bgm_game_high.mp3',
      mechanics: ['mirror', 'prism', 'filter', 'color_mix', 'filter_chain'],
      lightColors: ['white'],
      targetColors: ['red', 'blue', 'yellow'],
      allowedAngles: [45, 90, 135, 225, 270, 315],
    );
  }
  
  // ==========================================
  // LEVEL 81-90: HAREKETLİ PARÇALAR
  // ==========================================
  _LevelConfig _getLevel81to90Config(int id) {
    final idx = id - 80;
    final objectCount = 12 + (idx ~/ 2); // 12-16 objects
    final par = 15 + idx ~/ 2; // 15-22 moves
    final targets = 3 + idx ~/ 4; // 3-4 targets
    
    return _LevelConfig(
      name: _getLevelName(id, 'Hareket'),
      objectCount: objectCount + 4,
      lightCount: 2,
      targetCount: targets,
      obstacleCount: 4,
      par: par,
      minTime: 120,
      maxTime: 200,
      gridSize: 8,
      difficulty: 'expert',
      theme: 'desert_mirage',
      music: 'bgm_game_high.mp3',
      mechanics: ['mirror', 'prism', 'filter', 'moving_prism'],
      lightColors: ['red', 'blue'],
      targetColors: ['red', 'blue', 'purple', 'white'],
      allowedAngles: [45, 90, 135, 225, 270, 315],
      hasMovingPrisms: true,
    );
  }
  
  // ==========================================
  // LEVEL 91-100: USTA SEVİYELERİ
  // ==========================================
  _LevelConfig _getLevel91to100Config(int id) {
    final idx = id - 90;
    final objectCount = 15 + (idx ~/ 2); // 15-20 objects
    final par = 20 + idx; // 20-30 moves
    final targets = 4 + idx ~/ 3; // 4-5 targets
    
    return _LevelConfig(
      name: id == 100 ? 'Büyük Final' : _getLevelName(id, 'Usta'),
      objectCount: objectCount + 5,
      lightCount: 3,
      targetCount: targets,
      obstacleCount: 5 + idx ~/ 3,
      par: par,
      minTime: 150,
      maxTime: 300,
      gridSize: 8,
      difficulty: 'master',
      theme: 'cosmic_throne',
      music: 'bgm_game_high.mp3',
      mechanics: ['mirror', 'prism', 'filter', 'color_mix', 'moving_prism', 'splitter'],
      lightColors: ['red', 'blue', 'yellow'],
      targetColors: ['red', 'blue', 'yellow', 'purple', 'orange'],
      allowedAngles: [22.5, 45, 67.5, 90, 112.5, 135, 157.5, 180, 202.5, 225, 247.5, 270, 292.5, 315, 337.5],
      hasMovingPrisms: true,
    );
  }
  
  // ==========================================
  // OBJECT PLACEMENT
  // ==========================================
  
  Map<String, dynamic> _placeLightSource(int gridSize, Set<String> used, String color) {
    final pos = _getRandomPosition(gridSize, used, edge: true);
    return {
      'type': 'light_source',
      'x': pos.$1,
      'y': pos.$2,
      'color': color,
      'direction': _getEdgeDirection(pos.$1, pos.$2, gridSize),
    };
  }
  
  Map<String, dynamic> _placeTarget(int gridSize, Set<String> used, String color) {
    final pos = _getRandomPosition(gridSize, used, edge: true);
    return {
      'type': 'target',
      'x': pos.$1,
      'y': pos.$2,
      'color': color,
    };
  }
  
  Map<String, dynamic> _placeInteractive(int gridSize, Set<String> used, _LevelConfig config) {
    final pos = _getRandomPosition(gridSize, used);
    
    // Choose type based on mechanics
    String type = 'mirror';
    if (config.mechanics.contains('prism') && _random.nextDouble() < 0.3) {
      type = 'prism';
    }
    if (config.mechanics.contains('splitter') && _random.nextDouble() < 0.2) {
      type = 'splitter';
    }
    
    final angle = config.allowedAngles[_random.nextInt(config.allowedAngles.length)];
    final isMovable = !config.mechanics.contains('fixed_mirror') || _random.nextDouble() > 0.3;
    
    return {
      'type': type,
      'x': pos.$1,
      'y': pos.$2,
      'angle': angle,
      'movable': isMovable,
      'rotatable': true,
      if (config.hasMovingPrisms && _random.nextDouble() < 0.2) 'moving': true,
    };
  }
  
  Map<String, dynamic> _placeObstacle(int gridSize, Set<String> used, _LevelConfig config) {
    final pos = _getRandomPosition(gridSize, used);
    
    String type = 'wall';
    if (config.mechanics.contains('filter') && _random.nextDouble() < 0.4) {
      type = 'filter';
    }
    if (config.mechanics.contains('absorbing_wall') && _random.nextDouble() < 0.3) {
      type = 'absorbing_wall';
    }
    if (config.mechanics.contains('glass_wall') && _random.nextDouble() < 0.3) {
      type = 'glass_wall';
    }
    
    return {
      'type': type,
      'x': pos.$1,
      'y': pos.$2,
      if (type == 'filter') 'color': config.targetColors[_random.nextInt(config.targetColors.length)],
    };
  }
  
  (int, int) _getRandomPosition(int gridSize, Set<String> used, {bool edge = false}) {
    int x, y;
    String key;
    int attempts = 0;
    
    do {
      if (edge) {
        // Place on edge
        final side = _random.nextInt(4);
        switch (side) {
          case 0: x = 0; y = _random.nextInt(gridSize); break; // Left
          case 1: x = gridSize - 1; y = _random.nextInt(gridSize); break; // Right
          case 2: x = _random.nextInt(gridSize); y = 0; break; // Top
          default: x = _random.nextInt(gridSize); y = gridSize - 1; break; // Bottom
        }
      } else {
        x = 1 + _random.nextInt(gridSize - 2);
        y = 1 + _random.nextInt(gridSize - 2);
      }
      key = '$x,$y';
      attempts++;
    } while (used.contains(key) && attempts < 100);
    
    used.add(key);
    return (x, y);
  }
  
  double _getEdgeDirection(int x, int y, int gridSize) {
    if (x == 0) return 0; // Right
    if (x == gridSize - 1) return 180; // Left
    if (y == 0) return 90; // Down
    return 270; // Up
  }
  
  String _getLevelName(int id, String prefix) {
    final suffixes = ['Alfa', 'Beta', 'Gama', 'Delta', 'Epsilon', 'Zeta', 'Eta', 'Teta', 'Iota', 'Kappa'];
    return '$prefix ${suffixes[(id - 1) % 10]}';
  }
  
  /// Export all levels as JSON
  String exportAsJson() {
    final levels = generateAllLevels();
    return const JsonEncoder.withIndent('  ').convert({'levels': levels});
  }
}

/// Level configuration data class
class _LevelConfig {
  final String name;
  final int objectCount;
  final int lightCount;
  final int targetCount;
  final int obstacleCount;
  final int par;
  final int minTime;
  final int maxTime;
  final int gridSize;
  final String difficulty;
  final String theme;
  final String music;
  final List<String> mechanics;
  final List<String> lightColors;
  final List<String> targetColors;
  final List<double> allowedAngles;
  final bool hasMovingPrisms;
  
  const _LevelConfig({
    required this.name,
    required this.objectCount,
    required this.lightCount,
    required this.targetCount,
    required this.obstacleCount,
    required this.par,
    required this.minTime,
    required this.maxTime,
    required this.gridSize,
    required this.difficulty,
    required this.theme,
    required this.music,
    required this.mechanics,
    required this.lightColors,
    required this.targetColors,
    required this.allowedAngles,
    this.hasMovingPrisms = false,
  });
}
