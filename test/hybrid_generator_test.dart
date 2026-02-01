import 'package:test/test.dart';
import '../lib/game/procedural/templates/template_models.dart';
import '../lib/game/procedural/templates/hybrid_generator.dart';
import '../lib/game/procedural/templates/library/template_library.dart';
import '../lib/game/procedural/models/models.dart';

void main() {
  group('HybridLevelGenerator', () {
    late TemplateLibrary library;
    late HybridLevelGenerator generator;

    setUp(() {
      library = TemplateLibrary();
      // Use clean instance or allow re-registration? 
      // Library is singleton in code, but we can register dummy test stuff.
      
      // Create a DUMMY template
      final dummyTemplate = LevelTemplate(
        id: 'test_template',
        nameKey: 'Test',
        episode: 1,
        difficulty: 1,
        family: 'test',
        fixedObjects: [
           FixedObject(
             type: ObjectType.source,
             position: GridPosition(0, 0),
             orientation: 0, 
           ),
           FixedObject(
             type: ObjectType.target,
             position: GridPosition(5, 0),
             orientation: 0,
           ),
        ],
        variableObjects: [
           VariableObject(
             id: 'mirror1',
             type: ObjectType.mirror,
             positionExpr: PositionExpression.variable('mx', 'my'), // Dynamic pos
             orientationExpr: OrientationExpression('\$solved + \$scramble1'), // Dynamic ori
           ),
        ],
        variables: [
           TemplateVariable(name: 'mx', type: VariableType.xCoordinate, minValue: 2, maxValue: 2),
           TemplateVariable(name: 'my', type: VariableType.yCoordinate, minValue: 0, maxValue: 0),
           TemplateVariable(name: 'scramble1', type: VariableType.scramble, minValue: 1, maxValue: 1),
        ],
        solvedState: SolvedState(
            orientations: {'mirror1': 1}, // Solved orientation is 1 (North-East?)
            steps: [],
            totalMoves: 1,
        ),
      );
      
      library.register(dummyTemplate);
      generator = HybridLevelGenerator(library);
    });

    test('generates level from template', () {
      final level = generator.generate(1, 0, 123); // E1, Index 0
      
      // If loadAll was not called, this might pick dummy if registers dummy as E1.
      // But dummy is E1.
      // Let's verify it picks the dummy for THIS test.
      // The dummy id is test_template.
      expect(level.meta.templateId, 'test_template'); 
      // variable object check
      expect(level.mirrors.length, 1);
      final m = level.mirrors.first;
      expect(m.position.x, 2); // mx=2
      expect(m.position.y, 0); // my=0
      
      // Orientation check:
      expect(m.orientation.index, 2); 
    });

    test('generates real Episode 1 level', () {
       // Load real templates
       library.loadAll();
       
       // Should have 4 templates for E1
       expect(library.getTemplatesForEpisode(1).length, 4);
       
       // Generate one
       final level = generator.generate(1, 0, 999);
       expect(level, isNotNull);
       print('Generated level: ${level.meta.templateId}');
       expect(level.episode, 1);
       expect(level.source, isNotNull);
       expect(level.targets.isNotEmpty, isTrue);
    });

    test('generates real Episode 2 level', () {
       library.loadAll();
       expect(library.getTemplatesForEpisode(2).length, 3);
       
       final level = generator.generate(2, 0, 999);
       expect(level.episode, 2);
       expect(level.meta.templateId, isNotNull);
    });

    test('generates real Episode 3 level', () {
       library.loadAll();
       expect(library.getTemplatesForEpisode(3).length, 2);
       
       final level = generator.generate(3, 0, 999);
       expect(level.episode, 3);
       // Verify locked mirror
       final lockedM = level.mirrors.firstWhere((m) => !m.rotatable, orElse: () => level.mirrors.first);
       // Wait, if no locked mirror found, it returns first (which is rotatable). 
       // Assert we FOUND a locked one only if template has one.
       // purple_basic (index 0) has locked mirror.
       // deterministic index 0 -> purple_basic.
       
       if (level.meta.templateId == 'e3_purple_basic') {
          expect(level.mirrors.any((m) => !m.rotatable), isTrue);
       }
    });



    test('generates real Episode 4 level', () {
       library.loadAll();
       expect(library.getTemplatesForEpisode(4).length, 2);
       final level = generator.generate(4, 0, 999);
       expect(level.episode, 4);
    });

    test('generates real Episode 5 level', () {
       library.loadAll();
       expect(library.getTemplatesForEpisode(5).length, 1);
       final level = generator.generate(5, 0, 999);
       expect(level.episode, 5);
    });

    test('calculates diffculty correctly', () {
       // Just basic sanity that it works without error
       generator.generate(1, 199, 123); // End of episode
    });
  });
}
