import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'prismaze_game.dart';
import 'components/light_source.dart';
import 'components/mirror.dart';
import 'components/prism.dart';
import 'components/wall.dart';
import 'components/wall_cluster.dart';
import 'components/target.dart';
import 'components/portal.dart';
import 'components/timed_light_source.dart';
import 'components/move_behavior.dart';
import 'components/hint_manager.dart';
import 'components/absorbing_wall.dart';
import 'data/level_design_system.dart' as lds; // Grid System
import 'data/campaign_levels.dart'; // Levels
import 'procedural/models/models.dart' as proc; // Procedural Models
import 'procedural/campaign_loader.dart'; // Campaign Loader
import 'package:flutter/foundation.dart';
import 'dart:math';

class LevelLoader extends Component with HasGameRef<PrismazeGame> {
  
  Map<int, PositionComponent> objectMap = {};
  
  // OPTIMIZATION: LRU Cache for parsed level data
  final Map<int, dynamic> _levelCache = {};
  final List<int> _usageHistory = [];
  static const int _maxCacheSize = 10;
  
  Future<void> loadLevel(int levelId) async {
    gameRef.currentLevelId = levelId;
    
    // Check Cache First
    if (_levelCache.containsKey(levelId)) {
       print("Loading Level $levelId from CACHE");
       final data = _levelCache[levelId];
       _processLevelData(levelId, data);
       _updateCacheUsage(levelId);
       return;
    }
  }

  Future<void> loadCampaignLevel(int episode, int levelIndex) async {
    try {
      final level = await CampaignLevelLoader.loadLevel(episode, levelIndex + 1);
      if (level != null) {
        loadGeneratedLevel(level);
      } else {
        debugPrint("Error: Campaign Level E$episode L$levelIndex not found.");
      }
    } catch (e) {
      debugPrint("Error loading campaign level: $e");
    }
  }

  void loadGeneratedLevel(proc.GeneratedLevel level) {
    gameRef.moves = 0;
    gameRef.resetLevelState();
    objectMap.clear();
    clearLevelEntities();
    
    // Init GameState
    gameRef.currentState = proc.GameState.fromLevel(level);
    
    // Setup Par
    gameRef.currentLevelPar = level.meta.optimalMoves;
    gameRef.parNotifier.value = level.meta.optimalMoves;
    gameRef.currentLevelMeta = level.meta;

    // Center 14x7 grid (85px cells) in 1280x720
    // 14 * 85 = 1190 (Offset X: 45)
    // 7 * 85 = 595 (Offset Y: 62.5)
    final double cellSize = 85.0;
    final double offsetX = 45.0;
    final double offsetY = 62.5;

    // Local conversion helper
    Vector2 toPixel(int x, int y) {
      return Vector2(
        offsetX + x * cellSize + cellSize / 2,
        offsetY + y * cellSize + cellSize / 2,
      );
    }

    _createBoundaries();

    int idCounter = 0;

    // 1. Light Source
    final ls = LightSource(
      position: toPixel(level.source.position.x, level.source.position.y),
      angle: level.source.direction.angleRad,
      color: lds.mapColor(_mapProcColor(level.source.color)),
    );
    gameRef.world.add(ls);
    objectMap[idCounter++] = ls;

    // 2. Targets
    for (final t in level.targets) {
      final target = Target(
        position: toPixel(t.position.x, t.position.y),
        requiredColor: lds.mapColor(_mapProcColor(t.requiredColor)),
      );
      gameRef.world.add(target);
      objectMap[idCounter++] = target;
    }

    // 3. Mirrors
    int mIndex = 0;
    for (final m in level.mirrors) {
      final mirror = Mirror(
        position: toPixel(m.position.x, m.position.y),
        angle: m.orientation.angleRad,
        isLocked: !m.rotatable,
        useDiscreteOrientation: true,
        index: mIndex++, // Bind to GameState
      );
      gameRef.world.add(mirror);
      objectMap[idCounter++] = mirror;
    }

    // 4. Prisms
    int pIndex = 0;
    for (final p in level.prisms) {
      final prism = Prism(
        position: toPixel(p.position.x, p.position.y),
        // Prisms in procedural system use discrete 0-3 orientation
        // We need to map this to radians. Assuming 90 deg steps?
        angle: p.orientation * (pi / 2.0),
        isLocked: !p.rotatable,
        useDiscreteOrientation: true,
        index: pIndex++,
      );
      gameRef.world.add(prism);
      objectMap[idCounter++] = prism;
    }

    // 5. Walls
    // 5. Walls
    final List<Wall> gridWalls = [];
    for (final w in level.walls) {
      final pos = toPixel(w.position.x, w.position.y) - Vector2.all(cellSize / 2);
      final wall = Wall(
        position: pos,
        size: Vector2.all(cellSize),
      );
      gameRef.world.add(wall);
      gridWalls.add(wall);
    }
    _clusterWalls(gridWalls);
    
    // 6. Solution (for Hints)
    // The HintManager expects formatted JSON solution steps for now
    final solutionJson = level.solution.map((s) => s.toJson()).toList();
    gameRef.hintManager.loadSolution(solutionJson, objectMap);
    
    // CRITICAL: Refresh BeamSystem cache to drop old components and pick up new ones
    gameRef.beamSystem.refreshCache();
    gameRef.beamSystem.clearBeams(); // Reset hash and clear segments
    gameRef.beamSystem.updateBeams(); // Force immediate recalculation
    
    debugPrint("Generated level loaded: Episode ${level.episode} Index ${level.index}");
  }

  lds.LightColor _mapProcColor(proc.LightColor c) {
    switch (c) {
      case proc.LightColor.white: return lds.LightColor.white;
      case proc.LightColor.red: return lds.LightColor.red;
      case proc.LightColor.green: return lds.LightColor.green;
      case proc.LightColor.blue: return lds.LightColor.blue;
      case proc.LightColor.yellow: return lds.LightColor.yellow;
      case proc.LightColor.purple: return lds.LightColor.magenta;
      case proc.LightColor.orange: return lds.LightColor.red; // No orange in legacy, map to red
    }
  }

  void _addToCache(int levelId, dynamic data) {
    if (_levelCache.length >= _maxCacheSize) {
      final oldest = _usageHistory.removeAt(0);
      _levelCache.remove(oldest);
    }
    _levelCache[levelId] = data;
    _usageHistory.add(levelId);
  }

  void _updateCacheUsage(int levelId) {
    _usageHistory.remove(levelId);
    _usageHistory.add(levelId);
  }

  void _processLevelData(int levelId, dynamic data) {
      // All levels now use procedural format (has 'lightSource.pos' structure)
      if (data.containsKey('lightSource') && data['lightSource'] is Map && data['lightSource'].containsKey('pos')) {
        print("Loading Procedural Level $levelId");
        _loadFromProceduralJson(data);
      } else {
        // Unsupported legacy format - should not happen with new levels
        print("ERROR: Unsupported legacy level format for level $levelId");
      }
  }
  
  /// Parse new procedural JSON format (pos.x, pos.y structure)
  void _loadFromProceduralJson(Map<String, dynamic> data) {
    gameRef.moves = 0;
    gameRef.resetLevelState();
    objectMap.clear();
    clearLevelEntities();
    
    // Init GameState manually
    final mirrorList = data['mirrors'] as List? ?? [];
    final prismList = data['prisms'] as List? ?? [];
    final targetList = data['targets'] as List? ?? [];
     
    final mirrorO = Uint8List(mirrorList.length);
    for(int i=0; i<mirrorList.length; i++) {
        double a = ((mirrorList[i]['angle'] ?? 0) as num).toDouble();
        mirrorO[i] = (a / 45).round() % 4; 
    }
    
    final prismO = Uint8List(prismList.length);
    for(int i=0; i<prismList.length; i++) {
        double a = ((prismList[i]['angle'] ?? 0) as num).toDouble();
        prismO[i] = (a / 90).round() % 4; 
    }
    
    gameRef.currentState = proc.GameState(
        mirrorOrientations: mirrorO,
        prismOrientations: prismO,
        targetCollected: Uint8List(targetList.length),
    );
    
    // Setup Par
    final parMoves = data['parMoves'] ?? 5;
    gameRef.currentLevelPar = parMoves;
    gameRef.parNotifier.value = parMoves;

    // Enable efficient RayTracer rendering for BeamSystem
    gameRef.beamSystem.useRayTracerMode = true;
    
    _createBoundaries();
    
    int idCounter = 0;
    
    // 1. Light Source
    final lsData = data['lightSource'];
    final lsPos = lds.GridPos(lsData['pos']['x'], lsData['pos']['y']);
    final lsPixel = lds.GridConverter.gridToPixel(lsPos);
    final lsAngle = (lsData['angleRad'] ?? 0.0).toDouble();
    
    final ls = LightSource(
      position: lsPixel,
      angle: lsAngle,
      color: lds.mapColor(_parseColorString(lsData['color'] ?? 'white')),
    );
    gameRef.world.add(ls);
    objectMap[idCounter++] = ls;
    
    // 2. Targets
    final targets = data['targets'] as List? ?? [];
    for (final t in targets) {
      final tPos = lds.GridPos(t['pos']['x'], t['pos']['y']);
      final tPixel = lds.GridConverter.gridToPixel(tPos);
      final target = Target(
        position: tPixel,
        requiredColor: lds.mapColor(_parseColorString(t['color'] ?? 'white')),
      );
      gameRef.world.add(target);
      objectMap[idCounter++] = target;
    }
    
    // 3. Mirrors
    int mIndex = 0;
    final mirrors = data['mirrors'] as List? ?? [];
    for (final m in mirrors) {
      final mPos = lds.GridPos(m['pos']['x'], m['pos']['y']);
      final mPixel = lds.GridConverter.gridToPixel(mPos);
      final angle = ((m['angle'] ?? 45) as num).toDouble();
      final mirror = Mirror(
        position: mPixel,
        angle: angle * (pi / 180.0),
        isLocked: !(m['movable'] ?? true),
        useDiscreteOrientation: true,
        index: mIndex++,
      );
      gameRef.world.add(mirror);
      objectMap[idCounter++] = mirror;
    }
    
    // 4. Prisms
    int pIndex = 0;
    final prisms = data['prisms'] as List? ?? [];
    for (final p in prisms) {
      final pPos = lds.GridPos(p['pos']['x'], p['pos']['y']);
      final pPixel = lds.GridConverter.gridToPixel(pPos);
      final prism = Prism(
        position: pPixel,
        angle: ((p['angle'] ?? 0) as num).toDouble() * (pi / 180.0),
        useDiscreteOrientation: true,
        index: pIndex++,
      );
      gameRef.world.add(prism);
      objectMap[idCounter++] = prism;
    }
    
    // 5. Walls
    final walls = data['walls'] as List? ?? [];
    final List<Wall> gridWalls = [];
    for (final w in walls) {
      final from = lds.GridPos(w['from']['x'], w['from']['y']);
      final to = lds.GridPos(w['to']['x'], w['to']['y']);
      final start = lds.GridConverter.gridToPixelTopLeft(from);
      final endBottomRight = lds.GridConverter.gridToPixelTopLeft(to) + Vector2.all(lds.GridConverter.cellSize);
      final size = endBottomRight - start;
      
      final wall = Wall(position: start, size: size);
      gameRef.world.add(wall);
      gridWalls.add(wall);
    }
    _clusterWalls(gridWalls);
    
    // 6. Solution
    final solutionSteps = data['solutionSteps'] as List? ?? [];
    gameRef.hintManager.loadSolution(solutionSteps, objectMap);
    
    // CRITICAL: Refresh BeamSystem cache
    gameRef.beamSystem.refreshCache();
    gameRef.beamSystem.clearBeams();
    gameRef.beamSystem.updateBeams();
    
    print("Procedural level loaded: ${objectMap.length} objects");
  }
  
  lds.LightColor _parseColorString(String color) {
    switch (color.toLowerCase()) {
      case 'red': return lds.LightColor.red;
      case 'blue': return lds.LightColor.blue;
      case 'yellow': return lds.LightColor.yellow;
      case 'green': return lds.LightColor.green;
      case 'cyan': return lds.LightColor.cyan;
      case 'magenta': 
      case 'purple': return lds.LightColor.magenta;
      default: return lds.LightColor.white;
    }
  }

  // Convert Grid lds.LevelDef to Pixel Level Model
  void _loadFromDef(lds.LevelDef def) {
     print("DEBUG _loadFromDef: Starting for level ${def.levelNumber}");
     gameRef.moves = 0;
     gameRef.resetLevelState();
     objectMap.clear();
     clearLevelEntities();
     
     // Legacy GameState Init
     final mirrorO = Uint8List(def.mirrors.length);
     for(int i=0; i<def.mirrors.length; i++) {
        mirrorO[i] = (def.mirrors[i].angle / 45).round() % 4;
     }
     
     gameRef.currentState = proc.GameState(
        mirrorOrientations: mirrorO,
        prismOrientations: Uint8List(0),
        targetCollected: Uint8List(def.targets.length),
     );
     
     
     // Setup Par
     gameRef.currentLevelPar = def.optimalMoves;
     gameRef.parNotifier.value = def.optimalMoves;

     print("DEBUG: Creating boundaries...");
     _createBoundaries();
     print("DEBUG: Boundaries created");
     
     // Spawn Objects from Grid Def
     int idCounter = 0;
     
     // 1. Light Source
     final lsPixel = lds.GridConverter.gridToPixel(def.lightSource.pos);
     final lsDir = def.lightSource.angleRad; // already radians
     print("DEBUG: Spawning LightSource at $lsPixel");
     
     final ls = LightSource(
       position: lsPixel,
       angle: lsDir,
       color: lds.mapColor(def.lightSource.color),
     );
     gameRef.world.add(ls);  // FIXED: Use world.add for camera rendering
     objectMap[idCounter++] = ls;
     print("DEBUG: LightSource added to world");
     
     // 2. Targets
     for(final t in def.targets) {
         final tPixel = lds.GridConverter.gridToPixel(t.pos);
         final target = Target(
             position: tPixel,
             requiredColor: lds.mapColor(t.color),
         );
         gameRef.world.add(target);  // FIXED
         objectMap[idCounter++] = target;
         print("DEBUG: Target added at $tPixel");
     }

     // 3. Mirrors
     print("DEBUG: Spawning ${def.mirrors.length} mirrors...");
     int mIndex = 0;
     for(final m in def.mirrors) {
         final mPixel = lds.GridConverter.gridToPixel(m.pos);
         final mirror = Mirror(
             position: mPixel,
             angle: m.angle * (pi / 180.0), // Convert deg to rad
             isLocked: !m.movable && !m.rotatable, // Assume locked if neither
             useDiscreteOrientation: true,
             index: mIndex++,
         );
         gameRef.world.add(mirror);  // FIXED
         objectMap[idCounter++] = mirror;
         print("DEBUG: Mirror added at $mPixel, angle=${m.angle}");
     }
     
     // 4. Walls
     print("DEBUG: Spawning ${def.walls.length} walls...");
     final List<Wall> gridWalls = [];
     for(final w in def.walls) {
         // GridWall(from, to)
         final start = lds.GridConverter.gridToPixelTopLeft(w.from);
         final endGrid = w.to;
         final endBottomRight = lds.GridConverter.gridToPixelTopLeft(endGrid) + Vector2.all(lds.GridConverter.cellSize);
         
         final size = endBottomRight - start;
         
         // Wall expects position=TopLeft
         final wall = Wall(
             position: start,
             size: size
         );
         gameRef.world.add(wall);
         gridWalls.add(wall);
         print("DEBUG: Wall added at $start, size=$size");
     }

     // 6. Hint/Solution
     gameRef.hintManager.loadSolution(def.solutionSteps, objectMap);
    _clusterWalls(gridWalls);
    
    // CRITICAL: Refresh BeamSystem cache
     gameRef.beamSystem.refreshCache();
     gameRef.beamSystem.clearBeams();
     gameRef.beamSystem.updateBeams();
     
     print("DEBUG _loadFromDef: COMPLETE - ${objectMap.length} objects loaded");
  }

  void clearLevelEntities() {
    gameRef.world.children.whereType<LightSource>().toList().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Mirror>().toList().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Wall>().toList().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<WallCluster>().toList().forEach((e) => e.removeFromParent()); // FIX: Remove clustered walls
    gameRef.world.children.whereType<Prism>().toList().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Target>().toList().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Portal>().toList().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<TimedLightSource>().toList().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<AbsorbingWall>().toList().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<MoveBehavior>().toList().forEach((e) => e.removeFromParent());
  }

  void _createBoundaries() {
    // Visible physics walls outside the grid (Grid X range: 35.0 - 1245.0)
    // Left Wall: X=15 (End=30) -> 5px gap from grid
    // Right Wall: X=1250 -> 5px gap from grid
    const double thickness = 15.0;
    const double width = 1280.0;
    const double height = 720.0;
    
    // Top wall (Extended to meet Left/Right walls: X=15 to 1265, Width=1250)
    gameRef.world.add(Wall(position: Vector2(15, 30), size: Vector2(1250, thickness))..opacity = 1.0);
    // Bottom wall (Extended to meet Left/Right walls)
    gameRef.world.add(Wall(position: Vector2(15, height - 30 - thickness), size: Vector2(1250, thickness))..opacity = 1.0);
    
    // Left wall (X=15 to clear grid start at 35)
    gameRef.world.add(Wall(position: Vector2(15, 30 + thickness), size: Vector2(thickness, height - 60 - thickness * 2))..opacity = 1.0);
    // Right wall (X=1250 to clear grid end at 1245)
    gameRef.world.add(Wall(position: Vector2(1250, 30 + thickness), size: Vector2(thickness, height - 60 - thickness * 2))..opacity = 1.0);

  }

  void _clusterWalls(List<Wall> allWalls) {
    if (allWalls.isEmpty) return;
    
    // 1. Filter out boundary walls (which have opacity initialized to 1.0 and fixed positions)
    final gridWalls = allWalls.where((w) => w.size.x < 100 && w.size.y < 100).toList();
    if (gridWalls.isEmpty) return;
    
    // 2. Group walls by adjacency (Simple grouping for now: all in one cluster is safe if they are visible)
    
    for (final wall in gridWalls) {
        wall.shouldRender = false; // Hide individual render
    }
    
    gameRef.world.add(WallCluster(gridWalls));
    print("Wall Clustering: Grouped ${gridWalls.length} grid walls into 1 cluster.");
  }
}
