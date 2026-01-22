/// Level Loader - Unified Pipeline
/// 
/// Only supports:
/// - loadCampaignLevel(episode, levelIndex) - For campaign mode
/// - loadGeneratedLevel(GeneratedLevel) - For endless/custom modes
library;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'prismaze_game.dart';
import 'components/light_source.dart';
import 'components/mirror.dart';
import 'components/prism.dart';
import 'components/wall.dart';
import 'components/target.dart';
import 'components/glass_wall.dart';
import 'components/splitter.dart';
import 'components/portal.dart';
import 'components/filter.dart';
import 'components/timed_light_source.dart';
import 'components/move_behavior.dart';
import 'components/absorbing_wall.dart';
import 'data/level_design_system.dart' as lds;
import 'procedural/models/models.dart' as proc;
import 'procedural/campaign_loader.dart';

class LevelLoader extends Component with HasGameRef<PrismazeGame> {
  
  Map<int, PositionComponent> objectMap = {};

  /// Load a campaign level from pre-generated JSON assets.
  /// [episode] - Episode number (1-5)
  /// [levelIndex] - 0-based level index within the episode
  Future<void> loadCampaignLevel(int episode, int levelIndex) async {
    print(">>> LevelLoader.loadCampaignLevel CALLED: E$episode L${levelIndex + 1}");
    try {
      print(">>> Calling CampaignLevelLoader.loadLevel...");
      final level = await CampaignLevelLoader.loadLevel(episode, levelIndex + 1);
      print(">>> CampaignLevelLoader.loadLevel returned: ${level != null ? 'Level found' : 'NULL'}");
      if (level != null) {
        print(">>> Calling loadGeneratedLevel...");
        loadGeneratedLevel(level);
        print(">>> loadGeneratedLevel completed");
      } else {
        print("ERROR: Campaign Level E$episode L${levelIndex + 1} not found in assets.");
      }
    } catch (e, stack) {
      print("ERROR loading campaign level E$episode L${levelIndex + 1}: $e");
      print("Stack: $stack");
    }
  }

  /// Load a GeneratedLevel (from campaign assets or endless generator).
  void loadGeneratedLevel(proc.GeneratedLevel level) {
    gameRef.moves = 0;
    gameRef.resetLevelState();
    clearLevelEntities();
    objectMap.clear();
    
    // Grid constants
    const double cellSize = 55.0;
    const double offsetX = 35.0;
    const double offsetY = 112.5;
    
    // Helper to convert grid to pixel (centered in cell)
    Vector2 toPixel(int x, int y) {
      return Vector2(
        offsetX + x * cellSize + cellSize / 2,
        offsetY + y * cellSize + cellSize / 2,
      );
    }
    
    // Setup Par
    gameRef.currentLevelPar = level.meta.optimalMoves;
    
    // Create boundaries
    _createBoundaries();
    
    int idCounter = 0;
    
    // 1. Light Source
    final src = level.source;
    final srcColor = _mapProcColor(src.color);
    final source = LightSource(
      position: toPixel(src.position.x, src.position.y),
      color: lds.mapColor(srcColor),
      angle: src.direction.angleRad,
    );
    gameRef.world.add(source);
    objectMap[idCounter++] = source;
    
    // 2. Targets
    for (final t in level.targets) {
      final tColor = _mapProcColor(t.requiredColor);
      final target = Target(
        position: toPixel(t.position.x, t.position.y),
        requiredColor: lds.mapColor(tColor),
        sequenceIndex: 0,
      );
      gameRef.world.add(target);
      objectMap[idCounter++] = target;
    }
    
    // 3. Mirrors
    for (final m in level.mirrors) {
      final mirror = Mirror.fromProcedural(m);
      gameRef.world.add(mirror);
      objectMap[idCounter++] = mirror;
    }
    
    // 4. Prisms
    for (final p in level.prisms) {
      final prism = Prism.fromProcedural(p);
      gameRef.world.add(prism);
      objectMap[idCounter++] = prism;
    }
    
    // 5. Walls (single cell walls)
    for (final w in level.walls) {
      final pos = lds.GridConverter.gridToPixelTopLeft(lds.GridPos(w.position.x, w.position.y));
      final size = Vector2.all(lds.GridConverter.cellSize);
      final wall = Wall(position: pos, size: size);
      gameRef.world.add(wall);
    }
    
    // 6. Solution (for hints)
    final List<Map<String, dynamic>> solutionJson = level.solution.map((step) => {
      'objectIndex': step.objectIndex,
      'rotationDelta': step.taps,
    }).toList();
    gameRef.hintManager.loadSolution(solutionJson, objectMap);
    
    debugPrint("LevelLoader: Generated level loaded - Episode ${level.episode} Index ${level.index}, ${objectMap.length} objects");
  }

  /// Map procedural LightColor to level design system LightColor
  lds.LightColor _mapProcColor(proc.LightColor c) {
    switch (c) {
      case proc.LightColor.white: return lds.LightColor.white;
      case proc.LightColor.red: return lds.LightColor.red;
      case proc.LightColor.green: return lds.LightColor.green;
      case proc.LightColor.blue: return lds.LightColor.blue;
      case proc.LightColor.yellow: return lds.LightColor.yellow;
      case proc.LightColor.purple: return lds.LightColor.magenta;
      case proc.LightColor.orange: return lds.LightColor.red;
    }
  }

  /// Clear all level entities from the world
  void clearLevelEntities() {
    
    gameRef.world.children.whereType<LightSource>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Mirror>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Wall>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Prism>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Target>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Filter>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<GlassWall>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Splitter>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<Portal>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<TimedLightSource>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<AbsorbingWall>().forEach((e) => e.removeFromParent());
    gameRef.world.children.whereType<MoveBehavior>().forEach((e) => e.removeFromParent());
  }

  /// Create boundary walls around the play area
  void _createBoundaries() {
    // Visible physics walls outside the grid (Grid X range: 35.0 - 1245.0)
    const double thickness = 15.0;
    const double width = 1280.0;
    const double height = 720.0;
    
    // Top wall
    gameRef.world.add(Wall(position: Vector2(15, 30), size: Vector2(1250, thickness))..opacity = 1.0);
    // Bottom wall
    gameRef.world.add(Wall(position: Vector2(15, height - 30 - thickness), size: Vector2(1250, thickness))..opacity = 1.0);
    // Left wall
    gameRef.world.add(Wall(position: Vector2(15, 30 + thickness), size: Vector2(thickness, height - 60 - thickness * 2))..opacity = 1.0);
    // Right wall
    gameRef.world.add(Wall(position: Vector2(1250, 30 + thickness), size: Vector2(thickness, height - 60 - thickness * 2))..opacity = 1.0);
  }
}

