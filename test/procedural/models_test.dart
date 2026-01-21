import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/models/models.dart';
import 'package:prismaze/game/procedural/tables/tables.dart';

void main() {
  group('Direction', () {
    test('opposite returns correct direction', () {
      expect(Direction.east.opposite, Direction.west);
      expect(Direction.west.opposite, Direction.east);
      expect(Direction.north.opposite, Direction.south);
      expect(Direction.south.opposite, Direction.north);
    });

    test('rotateLeft cycles correctly', () {
      expect(Direction.east.rotateLeft, Direction.north);
      expect(Direction.north.rotateLeft, Direction.west);
      expect(Direction.west.rotateLeft, Direction.south);
      expect(Direction.south.rotateLeft, Direction.east);
    });

    test('rotateRight cycles correctly', () {
      expect(Direction.east.rotateRight, Direction.south);
      expect(Direction.south.rotateRight, Direction.west);
      expect(Direction.west.rotateRight, Direction.north);
      expect(Direction.north.rotateRight, Direction.east);
    });

    test('dx and dy are correct', () {
      expect(Direction.east.dx, 1);
      expect(Direction.east.dy, 0);
      expect(Direction.west.dx, -1);
      expect(Direction.west.dy, 0);
      expect(Direction.north.dx, 0);
      expect(Direction.north.dy, -1);
      expect(Direction.south.dx, 0);
      expect(Direction.south.dy, 1);
    });
  });

  group('LightColor', () {
    test('base components are correct', () {
      expect(LightColor.red.baseComponents, {LightColor.red});
      expect(LightColor.blue.baseComponents, {LightColor.blue});
      expect(LightColor.yellow.baseComponents, {LightColor.yellow});
      expect(LightColor.purple.baseComponents, {LightColor.red, LightColor.blue});
      expect(LightColor.orange.baseComponents, {LightColor.red, LightColor.yellow});
      expect(LightColor.green.baseComponents, {LightColor.blue, LightColor.yellow});
      expect(LightColor.white.baseComponents, <LightColor>{});
    });

    test('isBase returns correctly', () {
      expect(LightColor.red.isBase, true);
      expect(LightColor.blue.isBase, true);
      expect(LightColor.yellow.isBase, true);
      expect(LightColor.purple.isBase, false);
      expect(LightColor.white.isBase, false);
    });

    test('isMixed returns correctly', () {
      expect(LightColor.purple.isMixed, true);
      expect(LightColor.orange.isMixed, true);
      expect(LightColor.green.isMixed, true);
      expect(LightColor.red.isMixed, false);
      expect(LightColor.white.isMixed, false);
    });
  });

  group('ColorMixer', () {
    test('mixBases returns correct colors', () {
      expect(ColorMixer.mixBases({LightColor.red}), LightColor.red);
      expect(ColorMixer.mixBases({LightColor.red, LightColor.blue}), LightColor.purple);
      expect(ColorMixer.mixBases({LightColor.red, LightColor.yellow}), LightColor.orange);
      expect(ColorMixer.mixBases({LightColor.blue, LightColor.yellow}), LightColor.green);
      expect(ColorMixer.mixBases({LightColor.white}), LightColor.white);
      // Invalid: all three bases
      expect(ColorMixer.mixBases({LightColor.red, LightColor.blue, LightColor.yellow}), null);
    });

    test('satisfiesTarget returns correctly', () {
      // White target only satisfied by white
      expect(ColorMixer.satisfiesTarget({LightColor.white}, LightColor.white), true);
      expect(ColorMixer.satisfiesTarget({LightColor.red}, LightColor.white), false);

      // Base target satisfied by that base
      expect(ColorMixer.satisfiesTarget({LightColor.red}, LightColor.red), true);
      expect(ColorMixer.satisfiesTarget({LightColor.blue}, LightColor.red), false);

      // Mixed target requires exactly those bases
      expect(ColorMixer.satisfiesTarget({LightColor.red, LightColor.blue}, LightColor.purple), true);
      expect(ColorMixer.satisfiesTarget({LightColor.red}, LightColor.purple), false);
      expect(ColorMixer.satisfiesTarget({LightColor.red, LightColor.blue, LightColor.yellow}, LightColor.purple), false);
    });
  });

  group('MirrorReflection', () {
    test('slash mirror (/) reflects east to north', () {
      expect(reflectRay(Direction.east, MirrorOrientation.slash), Direction.north);
    });

    test('slash mirror (/) reflects north to east', () {
      expect(reflectRay(Direction.north, MirrorOrientation.slash), Direction.east);
    });

    test('slash mirror (/) reflects west to south', () {
      expect(reflectRay(Direction.west, MirrorOrientation.slash), Direction.south);
    });

    test('slash mirror (/) reflects south to west', () {
      expect(reflectRay(Direction.south, MirrorOrientation.slash), Direction.west);
    });

    test('backslash mirror (\\) reflects east to south', () {
      expect(reflectRay(Direction.east, MirrorOrientation.backslash), Direction.south);
    });

    test('backslash mirror (\\) reflects south to east', () {
      expect(reflectRay(Direction.south, MirrorOrientation.backslash), Direction.east);
    });

    test('backslash mirror (\\) reflects west to north', () {
      expect(reflectRay(Direction.west, MirrorOrientation.backslash), Direction.north);
    });

    test('backslash mirror (\\) reflects north to west', () {
      expect(reflectRay(Direction.north, MirrorOrientation.backslash), Direction.west);
    });

    test('horizontal mirror (_) reflects north to south', () {
      expect(reflectRay(Direction.north, MirrorOrientation.horizontal), Direction.south);
    });

    test('horizontal mirror (_) reflects south to north', () {
      expect(reflectRay(Direction.south, MirrorOrientation.horizontal), Direction.north);
    });

    test('horizontal mirror (_) passes east/west through', () {
      expect(reflectRay(Direction.east, MirrorOrientation.horizontal), null);
      expect(reflectRay(Direction.west, MirrorOrientation.horizontal), null);
    });

    test('vertical mirror (|) reflects east to west', () {
      expect(reflectRay(Direction.east, MirrorOrientation.vertical), Direction.west);
    });

    test('vertical mirror (|) reflects west to east', () {
      expect(reflectRay(Direction.west, MirrorOrientation.vertical), Direction.east);
    });

    test('vertical mirror (|) passes north/south through', () {
      expect(reflectRay(Direction.north, MirrorOrientation.vertical), null);
      expect(reflectRay(Direction.south, MirrorOrientation.vertical), null);
    });

    test('all reflection cases are properly defined', () {
      int reflections = 0;
      for (final dir in Direction.values) {
        for (final ori in MirrorOrientation.values) {
          final result = reflectRay(dir, ori);
          if (result != null) reflections++;
        }
      }
      // Slash and backslash reflect all 4 directions each = 8
      // Horizontal and vertical reflect 2 directions each = 4
      // Total = 12
      expect(reflections, 12);
    });
  });

  group('PrismTables', () {
    test('splitter splits white into 3 colors', () {
      final result = applySplitter(Direction.east, LightColor.white, 0);
      expect(result.length, 3);
      
      final colors = result.map((r) => r.color).toSet();
      expect(colors.contains(LightColor.red), true);
      expect(colors.contains(LightColor.blue), true);
      expect(colors.contains(LightColor.yellow), true);
    });

    test('splitter passes non-white through', () {
      final result = applySplitter(Direction.east, LightColor.red, 0);
      expect(result.length, 1);
      expect(result.first.color, LightColor.red);
    });

    test('deflector changes direction but keeps color', () {
      final result = applyDeflector(Direction.east, LightColor.red, 0);
      expect(result.length, 1);
      expect(result.first.color, LightColor.red);
      expect(result.first.direction, isNot(Direction.east));
    });
  });

  group('GameState', () {
    test('copy creates independent copy', () {
      final state = GameState.fromLevel(GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(10, 4))],
        walls: const {},
        mirrors: const [
          Mirror(position: GridPosition(5, 4), orientation: MirrorOrientation.slash),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 1, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      ));

      final copy = state.copy();
      expect(copy == state, true);

      // Modify copy to a different orientation (slash=1, so use 2=vertical)
      copy.mirrorOrientations[0] = 2;
      expect(copy == state, false);
    });

    test('rotateMirror creates new state', () {
      final state = GameState.fromLevel(GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [Target(position: GridPosition(10, 4))],
        walls: const {},
        mirrors: const [
          Mirror(position: GridPosition(5, 4), orientation: MirrorOrientation.slash),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 1, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      ));

      final newState = state.rotateMirror(0);
      expect(newState == state, false);
      expect(newState.mirrorOrientations[0], (state.mirrorOrientations[0] + 1) % 4);
    });

    test('hashCode is consistent', () {
      final state1 = GameState.fromLevel(GeneratedLevel(
        seed: 0,
        episode: 1,
        index: 1,
        source: const Source(
          position: GridPosition(0, 4),
          direction: Direction.east,
        ),
        targets: const [],
        walls: const {},
        mirrors: const [
          Mirror(position: GridPosition(5, 4), orientation: MirrorOrientation.slash),
        ],
        prisms: const [],
        meta: const LevelMeta(optimalMoves: 1, difficultyBand: DifficultyBand.tutorial),
        solution: const [],
      ));

      final state2 = state1.copy();
      expect(state1.hashCode, state2.hashCode);

      final state3 = state1.rotateMirror(0);
      expect(state1.hashCode == state3.hashCode, false);
    });
  });
}
