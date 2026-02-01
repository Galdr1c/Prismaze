/// Episode configuration for level generation.
///
/// Defines comprehensive difficulty parameters for each episode (1-5).
/// Episode 3+ enforces hard difficulty gates with prisms, walls, decoys.
library;

import 'models/models.dart';

/// Configuration for a single episode.
class EpisodeConfig {
  final int episode;

  // Move targets (HARD THRESHOLDS)
  final int minMoves;
  final int maxMoves;

  // Critical objects (on solution path)
  final int minCriticalMirrors;
  final int maxCriticalMirrors;
  final int minCriticalPrisms;
  final int maxCriticalPrisms;

  // Decoy objects (not on solution path)
  final int minDecoyMirrors;
  final int maxDecoyMirrors;
  final int minDecoyPrisms;
  final int maxDecoyPrisms;

  // Targets
  final int minBaseTargets;
  final int maxBaseTargets;
  final int minMixedTargets;
  final int maxMixedTargets;
  final double mixedTargetProbability; // Chance any target is mixed color
  final double lockedMirrorProbability; // Chance a mirror is non-rotatable (E3+)

  // Walls
  final int minWalls;
  final int maxWalls;

  // Scrambling
  final int minIncorrectCritical; // How many critical objects start wrong
  final int maxIncorrectCritical;
  final double twoTapsAwayRatio; // What % of incorrect are 2 taps away (vs 1)

  // Generation behavior
  final int generationAttempts;
  final int validationBudget; // Solver budget for level validation
  final bool rejectTrivials; // Reject if minMoves <= 2
  final double maxTrivialRate; // Max acceptable trivial rate

  const EpisodeConfig({
    required this.episode,
    required this.minMoves,
    required this.maxMoves,
    required this.minCriticalMirrors,
    required this.maxCriticalMirrors,
    required this.minCriticalPrisms,
    required this.maxCriticalPrisms,
    required this.minDecoyMirrors,
    required this.maxDecoyMirrors,
    required this.minDecoyPrisms,
    required this.maxDecoyPrisms,
    required this.minBaseTargets,
    required this.maxBaseTargets,
    required this.minMixedTargets,
    required this.maxMixedTargets,
    required this.mixedTargetProbability,
    required this.minWalls,
    required this.maxWalls,
    required this.minIncorrectCritical,
    required this.maxIncorrectCritical,
    required this.twoTapsAwayRatio,
    required this.generationAttempts,
    required this.validationBudget,
    required this.rejectTrivials,
    required this.maxTrivialRate,
    this.lockedMirrorProbability = 0.0,
  });

  /// Total mirror count range
  int get minMirrors => minCriticalMirrors + minDecoyMirrors;
  int get maxMirrors => maxCriticalMirrors + maxDecoyMirrors;

  /// Total prism count range
  int get minPrisms => minCriticalPrisms + minDecoyPrisms;
  int get maxPrisms => maxCriticalPrisms + maxDecoyPrisms;

  /// Total target count range
  int get minTargets => minBaseTargets + minMixedTargets;
  int get maxTargets => maxBaseTargets + maxMixedTargets;

  /// Get configuration for an episode.
  factory EpisodeConfig.forEpisode(int episode) {
    switch (episode) {
      case 1:
        // TUTORIAL: [1..4] moves, simple puzzles
        return const EpisodeConfig(
          episode: 1,
          minMoves: 1,
          maxMoves: 4,
          // Critical objects
          minCriticalMirrors: 2,
          maxCriticalMirrors: 3,
          minCriticalPrisms: 0,
          maxCriticalPrisms: 0,
          // Decoys
          minDecoyMirrors: 0,
          maxDecoyMirrors: 0,
          minDecoyPrisms: 0,
          maxDecoyPrisms: 0,
          // Targets (white only)
          minBaseTargets: 1,
          maxBaseTargets: 1,
          minMixedTargets: 0,
          maxMixedTargets: 0,
          mixedTargetProbability: 0.0,
          // Walls
          minWalls: 2,
          maxWalls: 4,
          // Scrambling
          minIncorrectCritical: 1,
          maxIncorrectCritical: 2,
          twoTapsAwayRatio: 0.2,
          // Generation
          generationAttempts: 50,
          validationBudget: 5000,
          rejectTrivials: false,
          maxTrivialRate: 1.0,
          lockedMirrorProbability: 0.0,
        );

      case 2:
        // EASY: [2..6] moves
        return const EpisodeConfig(
          episode: 2,
          minMoves: 2,
          maxMoves: 6,
          // Critical objects
          minCriticalMirrors: 3,
          maxCriticalMirrors: 4,
          minCriticalPrisms: 0,
          maxCriticalPrisms: 0,
          // Decoys
          minDecoyMirrors: 0,
          maxDecoyMirrors: 1,
          minDecoyPrisms: 0,
          maxDecoyPrisms: 0,
          // Targets
          minBaseTargets: 1,
          maxBaseTargets: 1,
          minMixedTargets: 0,
          maxMixedTargets: 0,
          mixedTargetProbability: 0.0,
          // Walls
          minWalls: 5,
          maxWalls: 10,
          // Scrambling
          minIncorrectCritical: 2,
          maxIncorrectCritical: 3,
          twoTapsAwayRatio: 0.2,
          // Generation
          generationAttempts: 80,
          validationBudget: 10000,
          rejectTrivials: true,
          maxTrivialRate: 0.2,
          lockedMirrorProbability: 0.0,
        );

      case 3:
        // HARD: [10..18] STRICT, trivial <0.5%
        // MUST include: Splitter Prism, Mixed target often
        return const EpisodeConfig(
          episode: 3,
          minMoves: 9, // Slightly tighter (was 8)
          maxMoves: 18,
          // Critical objects
          minCriticalMirrors: 6,
          maxCriticalMirrors: 8,
          minCriticalPrisms: 1, // At least 1 Splitter
          maxCriticalPrisms: 1,
          // Decoys
          minDecoyMirrors: 2,
          maxDecoyMirrors: 4,
          minDecoyPrisms: 0,
          maxDecoyPrisms: 1,
          // Targets (mixed required often)
          minBaseTargets: 2,
          maxBaseTargets: 3,
          minMixedTargets: 1,
          maxMixedTargets: 1,
          mixedTargetProbability: 0.7, // 70% have mixed target
          // Walls (anti-shortcut)
          minWalls: 12,
          maxWalls: 20,
          // Scrambling (60% two-taps, 40% one-tap)
          minIncorrectCritical: 5,
          maxIncorrectCritical: 7,
          twoTapsAwayRatio: 0.6,
          // Generation
          generationAttempts: 50, // Reduced from 200
          validationBudget: 50000, // Reduced from 100000
          rejectTrivials: true,
          maxTrivialRate: 0.05, // Relaxed to 5% (was 0.5%)
          lockedMirrorProbability: 0.1, // 10% chance for locked mirrors
        );

      case 4:
        // EXPERT: [16..26] STRICT
        return const EpisodeConfig(
          episode: 4,
          minMoves: 14, // Slightly tighter (was 12)
          maxMoves: 26,
          // Critical objects
          minCriticalMirrors: 8,
          maxCriticalMirrors: 10,
          minCriticalPrisms: 1,
          maxCriticalPrisms: 2,
          // Decoys
          minDecoyMirrors: 3,
          maxDecoyMirrors: 5,
          minDecoyPrisms: 0,
          maxDecoyPrisms: 1,
          // Targets
          minBaseTargets: 3,
          maxBaseTargets: 4,
          minMixedTargets: 1,
          maxMixedTargets: 2,
          mixedTargetProbability: 0.8,
          // Walls
          minWalls: 18,
          maxWalls: 30,
          // Scrambling
          minIncorrectCritical: 7,
          maxIncorrectCritical: 9,
          twoTapsAwayRatio: 0.65,
          // Generation
          generationAttempts: 80, // Reduced from 300
          validationBudget: 80000, // Reduced from 150000
          rejectTrivials: true,
          maxTrivialRate: 0.05,
          lockedMirrorProbability: 0.15,
        );

      case 5:
      default:
        // MASTER: [22..35] STRICT
        return const EpisodeConfig(
          episode: 5,
          minMoves: 20, // Slightly tighter (was 18)
          maxMoves: 35,
          // Critical objects
          minCriticalMirrors: 10,
          maxCriticalMirrors: 12,
          minCriticalPrisms: 2, // 2 Splitters
          maxCriticalPrisms: 2,
          // Decoys
          minDecoyMirrors: 4,
          maxDecoyMirrors: 6,
          minDecoyPrisms: 1,
          maxDecoyPrisms: 2,
          // Targets
          minBaseTargets: 4,
          maxBaseTargets: 5,
          minMixedTargets: 2,
          maxMixedTargets: 2,
          mixedTargetProbability: 0.9,
          // Walls
          minWalls: 25,
          maxWalls: 45,
          // Scrambling
          minIncorrectCritical: 9,
          maxIncorrectCritical: 11,
          twoTapsAwayRatio: 0.7,
          // Generation - balanced for 3-target levels
          generationAttempts: 100, // Reduced from 500
          validationBudget: 120000, // Reduced from 250000
          rejectTrivials: true,
          maxTrivialRate: 0.05,
          lockedMirrorProbability: 0.2,
        );
    }
  }

  /// Get difficulty band for this episode.
  DifficultyBand get difficultyBand {
    switch (episode) {
      case 1:
        return DifficultyBand.tutorial;
      case 2:
        return DifficultyBand.easy;
      case 3:
        return DifficultyBand.medium;
      case 4:
        return DifficultyBand.hard;
      case 5:
      default:
        return DifficultyBand.expert;
    }
  }

  /// Get a random value in range using random factor [0, 1).
  int getInRange(int min, int max, double random) {
    if (max <= min) return min;
    return min + ((max - min + 1) * random).floor().clamp(0, max - min);
  }

  @override
  String toString() => 'EpisodeConfig(E$episode, moves:[$minMoves..$maxMoves], '
      'mirrors:${minMirrors}-${maxMirrors}, prisms:${minPrisms}-${maxPrisms}, '
      'targets:${minTargets}-${maxTargets}, walls:${minWalls}-${maxWalls})';
  /// Get a relaxed version of this config for retry attempts.
  EpisodeConfig relaxed() {
    return EpisodeConfig(
      episode: episode,
      minMoves: (minMoves - 2).clamp(1, 100), // Slightly easier moves
      maxMoves: maxMoves + 4,                 // Allow longer solutions if needed
      // RELAXED: Reduce critical mirror requirement slightly to fit in tighter spaces
      minCriticalMirrors: (minCriticalMirrors - 1).clamp(0, 50),
      maxCriticalMirrors: maxCriticalMirrors,
      // KEEP PRISMS: Do not relax prism requirements (core mechanic)
      minCriticalPrisms: minCriticalPrisms,
      maxCriticalPrisms: maxCriticalPrisms,
      // DECOYS: Reduce decoy requirements to reduce clutter failure
      minDecoyMirrors: (minDecoyMirrors - 1).clamp(0, 20),
      maxDecoyMirrors: maxDecoyMirrors,
      minDecoyPrisms: 0,
      maxDecoyPrisms: maxDecoyPrisms,
      // TARGETS: Keep same
      minBaseTargets: minBaseTargets,
      maxBaseTargets: maxBaseTargets,
      minMixedTargets: minMixedTargets,
      maxMixedTargets: maxMixedTargets,
      mixedTargetProbability: mixedTargetProbability,
      // WALLS: Relax minimum wall count to allow successful pathfinding
      minWalls: (minWalls * 0.7).floor().clamp(0, 100),
      maxWalls: maxWalls,
      // SCRAMBLING
      minIncorrectCritical: minIncorrectCritical,
      maxIncorrectCritical: maxIncorrectCritical,
      twoTapsAwayRatio: twoTapsAwayRatio,
      // GENERATION
      generationAttempts: generationAttempts,
      validationBudget: validationBudget * 2, // Double budget for retry
      rejectTrivials: rejectTrivials,
      maxTrivialRate: maxTrivialRate,
      lockedMirrorProbability: lockedMirrorProbability * 0.5,
    );
  }
}

