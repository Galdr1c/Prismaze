import '../../core/utils/deterministic_rng.dart';
import '../../core/utils/deterministic_hash.dart';
import '../recipe_deriver.dart';
import '../persistence/recipe_repository.dart';
import '../models/level_recipe.dart';
import '../models/generated_level.dart';
import '../templates/template_family.dart';
import '../templates/templates.dart'; // Import TemplateCatalog
import 'fallback_handler.dart';

class GeneratorPipeline {
  /// Generates a validated, deterministic level for the given parameters.
  Future<GeneratedLevel> generateLevel({
    required String version,
    required int levelIndex,
  }) async {
    // 1. Get or Derive Recipe (HATA 4)
    LevelRecipe? recipe = await RecipeRepository.getRecipe(levelIndex);
    if (recipe == null || recipe.generatorVersion != version) {
       recipe = RecipeDeriver.deriveRecipe(version, levelIndex);
       await RecipeRepository.saveRecipe(recipe);
    }
    
    // 2. Resolve Template
    final family = TemplateFamily.values.firstWhere((f) => f.name == recipe!.templateId);
    final variantId = 0; // v0 assumed
    final template = TemplateCatalog.getTemplate(family, variantId);
    
    // 3. Resolve (Instantiate + Validate + Fallback)
    final result = FallbackHandler.resolve(
      baseTemplate: template,
      levelIndex: levelIndex,
      baseSeed: recipe.seed,
    );
    
    if (result != null) {
      return result;
    }
    
    // 4. Ultimate Fail-Safe
    throw Exception('Failed to generate solvable level for Index: $levelIndex. '
        'Template: ${template.family.name}.');
  }
}
