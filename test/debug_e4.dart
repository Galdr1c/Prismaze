import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/level_generator.dart';
import 'package:prismaze/game/procedural/models/level_model.dart';

void main() {
  test('Debug E4 Generation', () {
    print('DEBUG: Starting E4 Generation Test...');
    final generator = LevelGenerator();
    
    try {
      print('Generating E4 L1...');
      final level = generator.generate(4, 1, 12345);
      print('SUCCESS: Generated E4 L1');
      print('Moves: ${level.meta.optimalMoves}');
      print('Prisms: ${level.prisms.length}');
      for(var p in level.prisms) {
         print('Prism at ${p.position} Type: ${p.type} Ori: ${p.orientation}');
      }
    } catch (e, stack) {
      print('ERROR: $e');
      print(stack);
      rethrow;
    }
  });
}
