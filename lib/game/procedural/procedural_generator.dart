/// Main Procedural Level Generator
/// Ties together all components to generate complete, solvable levels

import 'dart:math';
import 'procedural_level.dart';
import 'chapter_config.dart';
import 'placement_engine.dart';
import 'solver_engine.dart';

class ProceduralGenerator {
  late final PlacementEngine _placementEngine;
  late final SolverEngine _solverEngine;
  final Random _rng;
  
  ProceduralGenerator([int? seed]) : _rng = Random(seed) {
    _placementEngine = PlacementEngine(seed);
    _solverEngine = SolverEngine();
  }
  
  /// Generate a single level
  /// @param chapter: 1-5
  /// @param levelNumber: Global level number (1-200)
  ProceduralLevel? generateLevel(int chapter, int levelNumber) {
    // Calculate level position within chapter (1-30)
    final levelInChapter = ((levelNumber - 1) % 30) + 1;
    
    // Get chapter configuration
    final config = ChapterConfig.forLevel(chapter, levelInChapter);
    
    // Try multiple times to generate a solvable level
    for (int attempt = 0; attempt < 20; attempt++) {
      final level = _tryGenerateLevel(
        chapter: chapter,
        levelNumber: levelNumber,
        config: config,
        attempt: attempt,
      );
      
      if (level != null) {
        print('✓ Level $levelNumber generated (attempt ${attempt + 1}): ${level.optimalMoves} moves');
        return level;
      }
    }
    
    print('✗ Failed to generate level $levelNumber after 20 attempts');
    return null;
  }
  
  /// Internal level generation attempt
  ProceduralLevel? _tryGenerateLevel({
    required int chapter,
    required int levelNumber,
    required ChapterConfig config,
    required int attempt,
  }) {
    // Random factors for this attempt
    final rand1 = _rng.nextDouble();
    final rand2 = _rng.nextDouble();
    final rand3 = _rng.nextDouble();
    final rand4 = _rng.nextDouble();
    
    // Determine object counts
    final mirrorCount = config.getMirrorCount(rand1);
    final prismCount = config.getPrismCount(rand2);
    final wallCount = config.getWallCount(rand3);
    final targetCount = config.getTargetCount(rand4);
    
    // Phase 1: Generate walls first (to establish maze structure)
    final walls = _placementEngine.generateWallPattern(wallCount);
    
    // Phase 2: Place light source on edge
    final lightSource = _placementEngine.placeLightSource(
      color: _getLightColor(chapter),
    );
    
    // Track occupied positions
    final occupied = <GridPos>[lightSource.position];
    
    // Phase 3: Place targets
    final targets = _placementEngine.placeTargets(
      count: targetCount,
      walls: walls,
      lightSource: lightSource,
      occupied: occupied,
      color: _getTargetColor(chapter),
    );
    
    if (targets.length < targetCount) {
      return null; // Couldn't place all targets
    }
    
    // Update occupied
    for (final t in targets) {
      occupied.add(t.position);
    }
    
    // Phase 4: Place mirrors
    final mirrors = _placementEngine.placeMirrors(
      count: mirrorCount,
      walls: walls,
      occupied: occupied,
      someFixed: chapter >= 3, // Some fixed mirrors in later chapters
    );
    
    if (mirrors.length < mirrorCount ~/ 2) {
      return null; // Couldn't place enough mirrors
    }
    
    // Update occupied
    for (final m in mirrors) {
      occupied.add(m.position);
    }
    
    // Phase 5: Place prisms (if applicable)
    final prisms = _placementEngine.placePrisms(
      count: prismCount,
      walls: walls,
      occupied: occupied,
    );
    
    // Phase 6: Create provisional level
    final level = ProceduralLevel(
      levelId: levelNumber,
      chapter: chapter,
      optimalMoves: 0, // Will be calculated
      lightSource: lightSource,
      targets: targets,
      mirrors: mirrors,
      prisms: prisms,
      walls: walls,
      solution: [], // Will be calculated
    );
    
    // Phase 7: Verify solvability and get optimal moves
    final solution = _solverEngine.findOptimalSolution(level);
    
    if (!solution.solvable) {
      return null; // Level is not solvable
    }
    
    // Phase 8: Validate difficulty
    if (solution.optimalMoves < config.minOptimalMoves ||
        solution.optimalMoves > config.maxOptimalMoves) {
      // Difficulty mismatch, but still usable level
      // Could adjust here, but for now just accept it
    }
    
    // Create final level with solution
    return ProceduralLevel(
      levelId: levelNumber,
      chapter: chapter,
      optimalMoves: solution.optimalMoves,
      lightSource: lightSource,
      targets: targets,
      mirrors: mirrors,
      prisms: prisms,
      walls: walls,
      solution: solution.steps,
    );
  }
  
  /// Generate a batch of levels for a chapter
  List<ProceduralLevel> generateChapter(int chapter, {int levelsPerChapter = 30}) {
    final levels = <ProceduralLevel>[];
    final startLevel = (chapter - 1) * levelsPerChapter + 1;
    
    for (int i = 0; i < levelsPerChapter; i++) {
      final level = generateLevel(chapter, startLevel + i);
      if (level != null) {
        levels.add(level);
      }
    }
    
    return levels;
  }
  
  /// Generate all 5 chapters (150 levels total)
  List<ProceduralLevel> generateAllChapters({int levelsPerChapter = 30}) {
    final allLevels = <ProceduralLevel>[];
    
    for (int chapter = 1; chapter <= 5; chapter++) {
      print('Generating Chapter $chapter...');
      allLevels.addAll(generateChapter(chapter, levelsPerChapter: levelsPerChapter));
      print('Chapter $chapter complete: ${allLevels.length} levels total');
    }
    
    return allLevels;
  }
  
  /// Get light color based on chapter
  String _getLightColor(int chapter) {
    switch (chapter) {
      case 1: return 'white';
      case 2: return _rng.nextBool() ? 'white' : ['red', 'blue', 'yellow'][_rng.nextInt(3)];
      case 3: return ['white', 'red', 'blue', 'yellow'][_rng.nextInt(4)];
      case 4: return ['white', 'red', 'blue', 'yellow', 'purple', 'green'][_rng.nextInt(6)];
      default: return 'white';
    }
  }
  
  /// Get target color requirement based on chapter
  String _getTargetColor(int chapter) {
    switch (chapter) {
      case 1: return 'white';
      case 2: return _rng.nextBool() ? 'white' : ['red', 'blue', 'yellow'][_rng.nextInt(3)];
      default: return 'any'; // Later chapters allow any color
    }
  }
}
