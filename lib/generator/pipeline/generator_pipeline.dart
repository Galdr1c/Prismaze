import '../../core/utils/deterministic_rng.dart';
import '../../core/utils/deterministic_hash.dart';
import '../recipe_deriver.dart';
import '../selector/template_selector.dart';
import '../models/generated_level.dart';
import '../templates/templates.dart'; // Import TemplateCatalog
import 'fallback_handler.dart';

class GeneratorPipeline {
  final TemplateSelector _selector = TemplateSelector(); // Stateful? 
  // Selector is stateful for caching.
  
  /// Generates a validated, deterministic level for the given parameters.
  GeneratedLevel generateLevel({
    required String version,
    required int levelIndex,
  }) {
    // 1. Derive Recipe (Seed)
    final seed = RecipeDeriver.deriveSeed(version, levelIndex);
    
    // 2. Select Template
    // Note: Selector uses its own internal logic to derive family from levelIndex+version.
    final family = _selector.selectFamily(version, levelIndex);
    final variantId = 0; // Currently only v0 implemented
    final template = TemplateCatalog.getTemplate(family, variantId);
    
    // 3. Resolve (Instantiate + Validate + Fallback)
    final result = FallbackHandler.resolve(
      baseTemplate: template,
      levelIndex: levelIndex,
      baseSeed: seed,
    );
    
    if (result != null) {
      return result;
    }
    
    // 4. Ultimate Fail-Safe
    throw Exception('Failed to generate solvable level for Index: $levelIndex. '
        'Template: ${template.family.name}. Check Replay/Geometry logs.');
  }
}
