import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prismaze/core/models/level_recipe.dart';
import 'package:prismaze/generator/recipe_deriver.dart';
import 'package:prismaze/game/version_manager.dart';
import 'package:prismaze/cache/progress_manager.dart';

void main() {
  group('RecipeDeriver', () {
    test('Law of the Seed: strict determinism', () {
      // v1:1 -> must always be same hash
      final seed1 = RecipeDeriver.deriveSeed('v1', 1);
      final seed2 = RecipeDeriver.deriveSeed('v1', 1);
      
      expect(seed1, equals(seed2));
      
      // v1:2 -> different
      final seed3 = RecipeDeriver.deriveSeed('v1', 2);
      expect(seed1, isNot(equals(seed3)));
      
      // v2:1 -> different
      final seed4 = RecipeDeriver.deriveSeed('v2', 1);
      expect(seed1, isNot(equals(seed4)));
    });
  });

  group('LevelRecipe', () {
    test('Serialization Roundtrip', () {
      const original = LevelRecipe(
        levelIndex: 10,
        generatorVersion: 'v1',
        seed: 123456789,
        templateId: 'basic_room',
      );

      final json = original.toJson();
      final restored = LevelRecipe.fromJson(json);

      expect(restored, equals(original));
    });
  });

  group('VersionManager', () {
    test('Locks version on first run', () async {
      SharedPreferences.setMockInitialValues({}); // Empty
      final prefs = await SharedPreferences.getInstance();
      final manager = VersionManager(prefs);

      // First call -> sets to default (v1)
      final v1 = manager.getCurrentVersion();
      expect(v1, equals(VersionManager.latestVersion));
      
      // Verify persistence
      expect(prefs.getString('generator_version'), equals(VersionManager.latestVersion));
    });

    test('Respects existing version', () async {
      SharedPreferences.setMockInitialValues({'generator_version': 'legacy_v0'});
      final prefs = await SharedPreferences.getInstance();
      final manager = VersionManager(prefs);

      // Should return saved legacy version, not current latest
      final version = manager.getCurrentVersion();
      expect(version, equals('legacy_v0'));
    });
  });
  
  group('EndlessProgressManager', () {
    test('Tracking logic', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final manager = EndlessProgressManager(prefs);
        
        // Default 1
        expect(manager.getCurrentLevelIndex(), equals(1));
        
        // Advance
        await manager.setCurrentLevelIndex(2);
        expect(manager.getCurrentLevelIndex(), equals(2));
        
        // Prevent regression
        await manager.setCurrentLevelIndex(1);
        expect(manager.getCurrentLevelIndex(), equals(2));
        
        // Force regression
        await manager.setCurrentLevelIndex(1, force: true);
        expect(manager.getCurrentLevelIndex(), equals(1));
    });
  });
}
