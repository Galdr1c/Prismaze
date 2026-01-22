/// Level Exporter
/// Converts procedural levels to the game's LevelDef format

import 'dart:convert';
import 'procedural_level.dart';
import '../data/level_design_system.dart' as game;

class LevelExporter {
  
  /// Convert ProceduralLevel to the game's LevelDef format
  /// Note: Procedural uses 22x9 grid (100px), Game uses 16x9 grid (70px)
  static game.LevelDef toGameFormat(ProceduralLevel level) {
    // Scale factor: procedural grid to game grid
    // Procedural: 22 cols, 100px cells = 2200px
    // Game: 16 cols, 70px cells + offset = 1280px
    // We need to map coordinates
    
    return game.LevelDef(
      levelNumber: level.levelId,
      name: 'Level ${level.levelId}',
      optimalMoves: level.optimalMoves,
      lightSource: _convertLightSource(level.lightSource),
      targets: level.targets.map((t) => _convertTarget(t)).toList(),
      mirrors: level.mirrors.map((m) => _convertMirror(m)).toList(),
      prisms: level.prisms.map((p) => _convertPrism(p)).toList(),
      walls: level.walls.map((w) => _convertWall(w)).toList(),
      solutionSteps: level.solution.map((s) => _formatStep(s)).toList(),
    );
  }
  
  static game.GridLightSource _convertLightSource(LightSourceDef source) {
    // Map 22x9 to 16x9 grid position
    final scaledX = (source.position.x * 16 / 22).round().clamp(0, 15);
    final scaledY = source.position.y.clamp(0, 8);
    
    return game.GridLightSource(
      pos: game.GridPos(scaledX, scaledY),
      direction: _convertDirection(source.direction),
      color: _parseColor(source.color),
    );
  }
  
  static game.GridTarget _convertTarget(TargetDef target) {
    final scaledX = (target.position.x * 16 / 22).round().clamp(0, 15);
    final scaledY = target.position.y.clamp(0, 8);
    
    return game.GridTarget(
      pos: game.GridPos(scaledX, scaledY),
      color: _parseColor(target.requiredColor),
    );
  }
  
  static game.GridMirror _convertMirror(MirrorDef mirror) {
    final scaledX = (mirror.position.x * 16 / 22).round().clamp(0, 15);
    final scaledY = mirror.position.y.clamp(0, 8);
    
    return game.GridMirror(
      pos: game.GridPos(scaledX, scaledY),
      angle: mirror.angle,
      movable: mirror.movable,
      rotatable: mirror.rotatable,
    );
  }
  
  static game.GridPrism _convertPrism(PrismDef prism) {
    final scaledX = (prism.position.x * 16 / 22).round().clamp(0, 15);
    final scaledY = prism.position.y.clamp(0, 8);
    
    return game.GridPrism(
      pos: game.GridPos(scaledX, scaledY),
      angle: prism.angle,
      movable: prism.movable,
    );
  }
  
  static game.GridWall _convertWall(WallDef wall) {
    final scaledFromX = (wall.start.x * 16 / 22).round().clamp(0, 15);
    final scaledFromY = wall.start.y.clamp(0, 8);
    final scaledToX = (wall.end.x * 16 / 22).round().clamp(0, 15);
    final scaledToY = wall.end.y.clamp(0, 8);
    
    return game.GridWall(
      from: game.GridPos(scaledFromX, scaledFromY),
      to: game.GridPos(scaledToX, scaledToY),
    );
  }
  
  static game.Direction _convertDirection(LightDirection dir) {
    switch (dir) {
      case LightDirection.east: return game.Direction.right;
      case LightDirection.west: return game.Direction.left;
      case LightDirection.north: return game.Direction.up;
      case LightDirection.south: return game.Direction.down;
    }
  }
  
  static game.LightColor _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return game.LightColor.red;
      case 'blue': return game.LightColor.blue;
      case 'yellow': return game.LightColor.yellow;
      case 'green': return game.LightColor.green;
      case 'purple': 
      case 'magenta': return game.LightColor.magenta;
      case 'cyan': return game.LightColor.cyan;
      default: return game.LightColor.white;
    }
  }
  
  static String _formatStep(SolutionStep step) {
    if (step.action == 'rotate' && step.targetAngle != null) {
      return 'Rotate object ${step.objectIndex} to ${step.targetAngle}°';
    } else if (step.action == 'move' && step.targetPos != null) {
      return 'Move object ${step.objectIndex} to (${step.targetPos!.x}, ${step.targetPos!.y})';
    }
    return 'Object ${step.objectIndex}: ${step.action}';
  }
  
  /// Convert ProceduralLevel to JSON string
  static String toJson(ProceduralLevel level) {
    return const JsonEncoder.withIndent('  ').convert(level.toJson());
  }
  
  /// Export multiple levels to JSON array
  static String exportChapter(List<ProceduralLevel> levels) {
    final jsonList = levels.map((l) => l.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }
}

