import 'dart:math';
import 'dart:typed_data';

import '../ray_tracer.dart';
import '../models/models.dart';
import '../models/game_objects.dart'; 
import 'template_models.dart';
import 'library/template_library.dart';

/// Exceptions for generation failures
class GenerationException implements Exception {
  final String message;
  GenerationException(this.message);
  @override
  String toString() => 'GenerationException: $message';
}

/// Hybrid generator that uses templates for E1-5 and procedural for E6+
class HybridLevelGenerator {
  final TemplateLibrary _library;
  // Fallback procedural generator would be injected here if needed for E6+

  final RayTracer _rayTracer = RayTracer();

  HybridLevelGenerator(this._library);

  /// Main entry point for generating a level
  GeneratedLevel generate(int episode, int index, int seed) {
    if (episode <= 5) {
      return _generateFromTemplate(episode, index, seed);
    } else {
      // Future: Procedural fallback for E6+
      throw UnimplementedError('Procedural generation for Episode 6+ not yet connected.');
    }
  }

  GeneratedLevel _generateFromTemplate(int episode, int index, int seed) {
     final rng = Random(seed);
     
     // 1. Select Template
     final template = _selectTemplate(episode, index, rng);
     
     // 2. Generate Variables
     final variableValues = _generateVariableValues(template, rng);
     
     // 3. Instantiate
     var level = _instantiateTemplate(template, variableValues, episode, index, seed);
     
     // 4. Decorate with Walls (Diversity)
     level = _decorateWithWalls(level, template, variableValues, rng);
     
     return level;
  }

  /// Selects a template based on episode and difficulty progression
  LevelTemplate _selectTemplate(int episode, int index, Random rng) {
    final difficulty = _calculateDifficulty(episode, index);
    final candidates = _library.getTemplatesForEpisode(episode)
        .where((t) => (t.difficulty - difficulty).abs() <= 1)
        .toList();
        
    if (candidates.isEmpty) {
        // Fallback to all episode templates if strict match fails
        final all = _library.getTemplatesForEpisode(episode);
        if (all.isEmpty) throw GenerationException('No templates found for Episode $episode');
        return all[index % all.length];
    }
    
    // Deterministic selection
    return candidates[index % candidates.length];
  }

  int _calculateDifficulty(int episode, int index) {
      // Base difficulty: E1=1, E2=3, E3=5, E4=7, E5=8
      int baseDiff;
      switch(episode) {
          case 1: baseDiff = 1; break;
          case 2: baseDiff = 3; break;
          case 3: baseDiff = 5; break;
          case 4: baseDiff = 7; break;
          case 5: baseDiff = 8; break;
          default: baseDiff = 1;
      }
      
      // Progression: Ramp up difficulty slightly over 200 levels
      // +2 difficulty max
      final progress = index / 200.0;
      final bonus = (progress * 2).round();
      
      return (baseDiff + bonus).clamp(1, 10);
  }

  Map<String, int> _generateVariableValues(LevelTemplate template, Random rng) {
    final values = <String, int>{};
    
    for (final variable in template.variables) {
      int val;
      if (variable.type == VariableType.orientation) {
          val = rng.nextInt(4);
      } else if (variable.type == VariableType.scramble) {
          // Scramble is 1-3 taps away from solved (never 0)
          val = 1 + rng.nextInt(3);
      } else {
          val = variable.minValue + rng.nextInt(variable.maxValue - variable.minValue + 1);
      }
      values[variable.name] = val;
    }
    return values;
  }

  GeneratedLevel _instantiateTemplate(
    LevelTemplate template, 
    Map<String, int> values,
    int episode,
    int index,
    int seed
  ) {
      // Use dynamic list since procedural models don't share a base class
      final objects = <dynamic>[];
      
      // 1. Fixed Objects
      for (final obj in template.fixedObjects) {
          objects.add(_createObject(obj.type, obj.position, obj.orientation, obj.properties));
      }
      
      // 2. Variable Objects
      for (final obj in template.variableObjects) {
          final pos = _evaluatePosition(obj.positionExpr, values);
          final solvedOri = template.solvedState.orientations[obj.id] ?? 0;
          final ori = _evaluateOrientation(obj.orientationExpr, values, solvedOri);
          
          objects.add(_createObject(obj.type, pos, ori, obj.properties));
      }
      
      // 3. Components
      Source? source;
      final targets = <Target>[];
      final mirrors = <Mirror>[];
      final prisms = <Prism>[];
      final walls = <Wall>{};
      
      for (final obj in objects) {
          if (obj is Source) source = obj;
          else if (obj is Target) targets.add(obj);
          else if (obj is Mirror) mirrors.add(obj);
          else if (obj is Prism) prisms.add(obj);
          else if (obj is Wall) walls.add(obj);
      }
      
      if (source == null) throw GenerationException('Template ${template.id} produced no Source');

      // 4. Par Moves
      int parMoves = template.solvedState.totalMoves;

      // Calculate added moves from scrambling
      int addedMoves = 0;
      for (final entry in values.entries) {
          final def = template.variables.firstWhere((v) => v.name == entry.key);
          if (def.type == VariableType.scramble) {
              addedMoves += entry.value; 
          }
      }
      
      return GeneratedLevel(
          seed: seed,
          episode: episode,
          index: index,
          source: source,
          targets: targets,
          mirrors: mirrors,
          prisms: prisms,
          walls: walls,
          meta: LevelMeta(
              optimalMoves: addedMoves > 0 ? addedMoves : parMoves, 
              difficultyBand: _getBand(template.difficulty),
              generationAttempts: 1,
              templateId: template.id,
          ),
          solution: [], 
      );
  }

  dynamic _createObject(ObjectType type, GridPosition pos, int ori, Map<String, dynamic> props) {
      switch(type) {
          case ObjectType.source:
             LightColor color = LightColor.white;
             if (props.containsKey('color')) color = props['color'] as LightColor;
             return Source(position: pos, direction: Direction.values[ori % 4], color: color);
          case ObjectType.target:
             LightColor color = LightColor.white;
             if (props.containsKey('color')) color = props['color'] as LightColor;
             return Target(position: pos, requiredColor: color);
          case ObjectType.mirror:
             bool rotatable = true;
             if (props.containsKey('locked') && props['locked'] == true) rotatable = false;
             return Mirror(position: pos, orientation: MirrorOrientationExtension.fromInt(ori % 4), rotatable: rotatable);
          case ObjectType.prism:
             PrismType pType = PrismType.splitter;
             if (props.containsKey('type')) pType = props['type'] as PrismType;
             return Prism(position: pos, orientation: ori % 4); // Prism doesn't have type field in new model?
          case ObjectType.wall:
             return Wall(position: pos);
      }
  }

  GridPosition _evaluatePosition(PositionExpression expr, Map<String, int> values) {
      int parse(String s) {
          if (s.startsWith('\$')) return values[s.substring(1)] ?? 0;
          return int.tryParse(s) ?? 0;
      }
      return GridPosition(parse(expr.xExpr), parse(expr.yExpr));
  }
  
  int _evaluateOrientation(OrientationExpression expr, Map<String, int> values, int solved) {
      // Very simple parser for "$solved + $scramble" or constant "0"
      String e = expr.expression;
      if (e == '\$solved') return solved;
      
      // Check for "$solved + $var"
      if (e.startsWith('\$solved') && e.contains('+')) {
          final parts = e.split('+');
          final varName = parts[1].trim().substring(1); // remove $
          final offset = values[varName] ?? 0;
          return (solved + offset);
      }
      
      // Constant
      return int.tryParse(e) ?? 0;
  }
  
  DifficultyBand _getBand(int diff) {
      if (diff <= 2) return DifficultyBand.tutorial;
      if (diff <= 4) return DifficultyBand.easy;
      if (diff <= 6) return DifficultyBand.medium;
      if (diff <= 8) return DifficultyBand.hard;
      return DifficultyBand.expert;
  }

  /// Adds random walls to the level to increase variety,
  /// ensuring the SOLUTION path is not blocked.
  GeneratedLevel _decorateWithWalls(
    GeneratedLevel level, 
    LevelTemplate template, 
    Map<String, int> values, 
    Random rng
  ) {
      // 1. Calculate Solved State to find the Beam Path
      final solvedState = _createSolvedState(level, template, values);
      final beamPath = _rayTracer.trace(level, solvedState).segments; 
      // Note: segments contains RaySegment list.
      
      final protectedCells = <String>{};
      
      // Protect existing objects
      protectedCells.add(level.source.position.toString()); 
      for (final t in level.targets) protectedCells.add(t.position.toString());
      for (final m in level.mirrors) protectedCells.add(m.position.toString());
      for (final p in level.prisms) protectedCells.add(p.position.toString());
      for (final w in level.walls) protectedCells.add(w.position.toString());
      
      // Protect Beam Path
      // Simplification: Protect all cells intersected by the beam segments.
      // Since segments are orthogonal, we can iterate range.
      for (final seg in beamPath) {
          int x = seg.startX;
          int y = seg.startY;
          // Calculate direction manually
          int dx = (seg.endX - seg.startX).sign;
          int dy = (seg.endY - seg.startY).sign;
          // Calculate length (Chebyshev distance since axis-aligned)
          int steps = max((seg.endX - seg.startX).abs(), (seg.endY - seg.startY).abs());
          
          for (int i = 0; i <= steps; i++) {
               protectedCells.add(GridPosition(x + dx * i, y + dy * i).toString());
          }
      }
      
      // 2. Add Random Walls
      // Density depends on episode/difficulty. E1=low, E5=high.
      // Roughly 5% to 15% of empty space.
      double density = 0.05 + (level.episode * 0.02);
      density = density.clamp(0.05, 0.15);
      
      final newWalls = <Wall>{...level.walls};
      int attempts = 100; // soft limit
      
      for (int i = 0; i < attempts; i++) {
           int x = rng.nextInt(GridPosition.gridWidth);
           int y = rng.nextInt(GridPosition.gridHeight);
           final pos = GridPosition(x, y);
           
           // Don't place on edge (reserved for border usually, or valid inside)
           // Prismaze allows walls inside.
           
           if (!protectedCells.contains(pos.toString())) {
               // Chance to place
               if (rng.nextDouble() < density) {
                   newWalls.add(Wall(position: pos));
                   protectedCells.add(pos.toString());
               }
           }
      }
      
      return GeneratedLevel(
          seed: level.seed,
          episode: level.episode,
          index: level.index,
          source: level.source,
          targets: level.targets,
          mirrors: level.mirrors,
          prisms: level.prisms,
          walls: newWalls,
          meta: level.meta,
          solution: level.solution,
      );
  }

  /// Creates a GameState representing the INTENDED solution configuration.
  GameState _createSolvedState(GeneratedLevel level, LevelTemplate template, Map<String, int> values) {
      // Clone initial state
      var state = GameState.fromLevel(level);
      
      // Apply solved orientations
      // We need to map variableObject ID to the GeneratedObject index.
      // This is tricky because GeneratedLevel lists don't store the ID.
      // BUT, the order of instantiation is deterministic:
      // Fixed objects first? No, _instantiateTemplate puts them all in one list, then filters.
      // Wait, _instantiateTemplate separates them by type. The order WITHIN type lists is consistent.
      
      // This mapping is hard.
      // EASIER APPROACH: Instead of complex ID mapping, let's just use the `solvedState` from the template
      // and re-evaluate the orientations using the same logic, but forcing "solved" state.
      
      // Actually, we can just iterate the `variableObjects` again.
      // We know which `Mirror`/`Prism` corresponds to which `VariableObject` 
      // because we created them in order.
      
      // Let's count indices.
      int mirrorIndex = 0;
      int prismIndex = 0;
      
      // Fixed objects first
      for (final obj in template.fixedObjects) {
          if (obj.type == ObjectType.mirror) mirrorIndex++;
          if (obj.type == ObjectType.prism) prismIndex++;
      }
      
      // Variable objects
      for (final obj in template.variableObjects) {
          // Calculate the orientation THIS object should have in the solved state
          final solvedOriParam = template.solvedState.orientations[obj.id] ?? 0;
          
          if (obj.type == ObjectType.mirror) {
              // The mirror at `mirrorIndex` needs to be set to `solvedOriParam`
              // We need to update the `state`.
              // GameState stores `mirrorOrientations` list.
              if (mirrorIndex < state.mirrorOrientations.length) {
                  // We need to set it. GameState is immutable, uses copyWith/methods.
                  // But we can construct a customized state OR just use internal lists if accessible?
                  // State stores `List<int> mirrorOrientations`.
                  // We can't easily "set" it without iterating.
                  // Let's build the list of solved orientations directly.
              }
              mirrorIndex++;
          }
          if (obj.type == ObjectType.prism) {
              prismIndex++;
          }
      }
      
      // RE-IMPLEMENTATION:
      // Construct the `solvedMirrorOrientations` and `solvedPrismOrientations` lists directly.
      
      final solvedMirrorOris = <int>[];
      final solvedPrismOris = <int>[];
      
      // 1. Fixed Objects
      for (final obj in template.fixedObjects) {
          if (obj.type == ObjectType.mirror) solvedMirrorOris.add(obj.orientation % 4);
          if (obj.type == ObjectType.prism) solvedPrismOris.add(obj.orientation % 4);
      }
      
      // 2. Variable Objects
      for (final obj in template.variableObjects) {
          final targetOri = template.solvedState.orientations[obj.id] ?? 0;
          
          if (obj.type == ObjectType.mirror) solvedMirrorOris.add(targetOri);
          if (obj.type == ObjectType.prism) solvedPrismOris.add(targetOri);
      }
      
      return GameState(
          mirrorOrientations: Uint8List.fromList(solvedMirrorOris),
          prismOrientations: Uint8List.fromList(solvedPrismOris),
      );
  }
}
