import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/core/utils/utils.dart';
import 'package:prismaze/generator/recipe_deriver.dart';

void main() {
  group('Cross-Platform Determinism Contract (HATA 2)', () {
    
    test('DeterministicHash (SHA256 based) Test Vectors', () {
      // Test Vector 1: Empty string
      expect(DeterministicHash.hash(""), equals(2018687061));
      
      // Test Vector 2: Standard Level Recipe Key
      expect(DeterministicHash.hash("v1:1"), equals(1511505615));
      
      // Test Vector 3: Long string
      expect(DeterministicHash.hash("the quick brown fox jumps over the lazy dog"), equals(-683340820));
    });

    test('DeterministicRNG (LCG) Test Vectors', () {
      final rng = DeterministicRNG(12345);
      
      // Sequence check
      expect(rng.nextInt(100), equals(6));
      expect(rng.nextInt(1000), equals(775));
      expect(rng.nextBool(), isTrue);
    });

    test('Full Recipe Chain Integrity', () {
      // Level 1, Version v1
      final seed = RecipeDeriver.deriveSeed("v1", 1);
      expect(seed, equals(1511505615));
      
      final rng = DeterministicRNG(seed);
      expect(rng.nextInt(5), equals(3)); 
    });
  });
}
