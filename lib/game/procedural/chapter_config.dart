/// Chapter Configuration
/// Defines difficulty parameters for each of the 5 chapters

class ChapterConfig {
  final int chapter;
  final int minMirrors, maxMirrors;
  final int minPrisms, maxPrisms;
  final int minWalls, maxWalls;
  final int minTargets, maxTargets;
  final int minOptimalMoves, maxOptimalMoves;
  
  const ChapterConfig({
    required this.chapter,
    required this.minMirrors,
    required this.maxMirrors,
    required this.minPrisms,
    required this.maxPrisms,
    required this.minWalls,
    required this.maxWalls,
    required this.minTargets,
    required this.maxTargets,
    required this.minOptimalMoves,
    required this.maxOptimalMoves,
  });
  
  /// Get configuration for a specific chapter and level progression
  /// @param chapter: 1-5
  /// @param levelInChapter: 1-30 (position within chapter)
  factory ChapterConfig.forLevel(int chapter, int levelInChapter) {
    // Progression within chapter (0.0 to 1.0)
    final progression = (levelInChapter - 1) / 29.0; // 30 levels per chapter
    
    switch (chapter) {
      case 1: // Beginning Lights
        return ChapterConfig(
          chapter: chapter,
          minMirrors: 1 + (4 * progression).floor(),
          maxMirrors: 2 + (4 * progression).floor(),
          minPrisms: 0,
          maxPrisms: (1 * progression).floor(), // Small chance of prism
          minWalls: 0,
          maxWalls: (2 * progression).floor(),
          minTargets: 1,
          maxTargets: 1 + (1 * progression).floor(),
          minOptimalMoves: 1 + (5 * progression).floor(),
          maxOptimalMoves: 2 + (6 * progression).floor(),
        );
        
      case 2: // Color Spectrum
        return ChapterConfig(
          chapter: chapter,
          minMirrors: 3 + (4 * progression).floor(),
          maxMirrors: 4 + (4 * progression).floor(),
          minPrisms: 1 + (1 * progression).floor(),
          maxPrisms: 2 + (1 * progression).floor(),
          minWalls: 2,
          maxWalls: 2 + (1 * progression).floor(),
          minTargets: 2,
          maxTargets: 2 + (1 * progression).floor(),
          minOptimalMoves: 4 + (4 * progression).floor(),
          maxOptimalMoves: 6 + (6 * progression).floor(),
        );
        
      case 3: // Mixture Master
        return ChapterConfig(
          chapter: chapter,
          minMirrors: 6 + (4 * progression).floor(),
          maxMirrors: 8 + (4 * progression).floor(),
          minPrisms: 2 + (1 * progression).floor(),
          maxPrisms: 3 + (1 * progression).floor(),
          minWalls: 3,
          maxWalls: 3 + (1 * progression).floor(),
          minTargets: 3,
          maxTargets: 3 + (1 * progression).floor(),
          minOptimalMoves: 8 + (5 * progression).floor(),
          maxOptimalMoves: 12 + (6 * progression).floor(),
        );
        
      case 4: // Crystal Labyrinth
        return ChapterConfig(
          chapter: chapter,
          minMirrors: 10 + (5 * progression).floor(),
          maxMirrors: 12 + (6 * progression).floor(),
          minPrisms: 3 + (2 * progression).floor(),
          maxPrisms: 4 + (2 * progression).floor(),
          minWalls: 4 + (1 * progression).floor(),
          maxWalls: 5 + (1 * progression).floor(),
          minTargets: 4,
          maxTargets: 4 + (1 * progression).floor(),
          minOptimalMoves: 15 + (5 * progression).floor(),
          maxOptimalMoves: 18 + (7 * progression).floor(),
        );
        
      case 5: // Beyond Time
      default:
        return ChapterConfig(
          chapter: chapter,
          minMirrors: 15 + (5 * progression).floor(),
          maxMirrors: 18 + (7 * progression).floor(),
          minPrisms: 4 + (2 * progression).floor(),
          maxPrisms: 6 + (2 * progression).floor(),
          minWalls: 5 + (2 * progression).floor(),
          maxWalls: 6 + (2 * progression).floor(),
          minTargets: 5,
          maxTargets: 5 + (1 * progression).floor(),
          minOptimalMoves: 20 + (7 * progression).floor(),
          maxOptimalMoves: 25 + (10 * progression).floor(),
        );
    }
  }
  
  /// Get object count within min-max range based on random factor
  int getMirrorCount(double random) => 
      minMirrors + ((maxMirrors - minMirrors) * random).floor();
  
  int getPrismCount(double random) => 
      minPrisms + ((maxPrisms - minPrisms) * random).floor();
  
  int getWallCount(double random) => 
      minWalls + ((maxWalls - minWalls) * random).floor();
  
  int getTargetCount(double random) => 
      minTargets + ((maxTargets - minTargets) * random).floor();
  
  @override
  String toString() => 
      'Chapter $chapter: Mirrors($minMirrors-$maxMirrors), '
      'Prisms($minPrisms-$maxPrisms), Walls($minWalls-$maxWalls), '
      'Targets($minTargets-$maxTargets), Moves($minOptimalMoves-$maxOptimalMoves)';
}

