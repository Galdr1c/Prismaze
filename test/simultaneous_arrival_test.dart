import 'package:test/test.dart';
import 'package:prismaze/game/procedural/models/models.dart';
import 'package:prismaze/game/procedural/ray_tracer.dart';
import 'package:prismaze/game/procedural/level_generator.dart';

void main() {
  group('Simultaneous Arrival Tests', () {
    test('Purple target requires Red AND Blue together', () {
      // Robust Level Design:
      // Source(0,3) East -> Prism(2,3) Ori 1
      // Prism Output:
      // - Straight(East) -> Red -> Target(5,3) (Always Arrives)
      // - Right(South) -> Blue -> Mirror(2,6) (Controllable)
      // - Left(North) -> Yellow -> Mirror(2,0) -> Dumped
      
      final level = GeneratedLevel(
        seed: 12345,
        episode: 3,
        index: 1,
        source: Source(position: GridPosition(0, 3), direction: Direction.east, color: LightColor.white),
        targets: [Target(position: GridPosition(5, 3), requiredColor: LightColor.purple)],
        walls: {},
        mirrors: [
          // Yellow Dumping Path (North)
          Mirror(position: GridPosition(2, 0), orientation: MirrorOrientation.slash, rotatable: false), // / Reflects East
          Mirror(position: GridPosition(5, 0), orientation: MirrorOrientation.slash, rotatable: false), // / Reflects North -> Out
          
          // Blue Control Path (South)
          // Index 2 is at (2,6). Start Vertical (|) to block/dump. Needs (\) to route.
          Mirror(position: GridPosition(2, 6), orientation: MirrorOrientation.vertical, rotatable: true), 
          Mirror(position: GridPosition(5, 6), orientation: MirrorOrientation.slash, rotatable: false), // / Reflects Up -> Target
        ],
        prisms: [
          Prism(position: GridPosition(2, 3), orientation: 1, rotatable: false),
        ],
        meta: LevelMeta(optimalMoves: 1, difficultyBand: DifficultyBand.tutorial, generationAttempts: 1),
        solution: [],
      );
      
      final tracer = RayTracer();
      
      // 2. Test Partial Arrival (Red Only)
      // Mirror(2,6) is Vertical. Blue goes South -> Out.
      var state = GameState.fromLevel(level);
      var result = tracer.trace(level, state);
      
      bool redArrives = result.targetArrivals[0]!.contains(LightColor.red);
      bool blueArrives = result.targetArrivals[0]!.contains(LightColor.blue);
      
      expect(redArrives, true, reason: 'Red should arrive directly');
      expect(blueArrives, false, reason: 'Blue should be dumped by Vertical mirror');
      expect(result.allTargetsSatisfied, false, reason: 'Target requires Purple (R+B), but only Red arrived');
      
      // 3. Test Full Arrival (Red + Blue)
      // Rotate Mirror(2,6) to Backslash (\).
      // Vertical(2) + 1 tap -> Backslash(3).
      state = state.rotateMirror(2); 
      
      result = tracer.trace(level, state);
      redArrives = result.targetArrivals[0]!.contains(LightColor.red);
      blueArrives = result.targetArrivals[0]!.contains(LightColor.blue);
      
      expect(redArrives, true, reason: 'Red should still arrive');
      expect(blueArrives, true, reason: 'Blue should arrive via Backslash mirror');
      expect(result.allTargetsSatisfied, true, reason: 'Target requires Purple and both R+B arrived simultaneously');
    });

    test('Generator validation rejects partial solutions', () {
      // Same level logic
       final level = GeneratedLevel(
        seed: 12345,
        episode: 3,
        index: 1,
        source: Source(position: GridPosition(0, 3), direction: Direction.east, color: LightColor.white),
        targets: [Target(position: GridPosition(5, 3), requiredColor: LightColor.purple)],
        walls: {},
        mirrors: [
          Mirror(position: GridPosition(2, 0), orientation: MirrorOrientation.slash, rotatable: false),
          Mirror(position: GridPosition(5, 0), orientation: MirrorOrientation.slash, rotatable: false),
          Mirror(position: GridPosition(2, 6), orientation: MirrorOrientation.vertical, rotatable: true), // Index 2
          Mirror(position: GridPosition(5, 6), orientation: MirrorOrientation.slash, rotatable: false),
        ],
        prisms: [
          Prism(position: GridPosition(2, 3), orientation: 1, rotatable: false),
        ],
        meta: LevelMeta(optimalMoves: 1, difficultyBand: DifficultyBand.tutorial, generationAttempts: 1),
        solution: [],
      );

      final emptyMoves = <PlannedMove>[];
      final validEmpty = LevelGenerator.validatePlannedSolutionStatic(level, emptyMoves);
      expect(validEmpty, false, reason: 'Initial state is unsolved (Blue missing), should fail');
      
      // Correct Move: Rotate Mirror Index 2 (at 2,6) by 1 tap
      final correctMoves = [
         PlannedMove(type: MoveType.rotateMirror, objectIndex: 2, taps: 1) // | (2) -> \ (3)
      ];
      final validCorrect = LevelGenerator.validatePlannedSolutionStatic(level, correctMoves);
      expect(validCorrect, true, reason: 'Correct move delivers Blue, Simultaneous Arrival achieved');
    });
  });
}
