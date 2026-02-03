import 'package:prismaze/generator/templates/template_models.dart';
import '../../core/utils/deterministic_rng.dart';
import '../../generator/selector/pacing_rules.dart'; // Unused here but available
import '../validators/validators.dart';
import '../models/generated_level.dart';
import 'instantiator.dart';
import '../../generator/templates/templates.dart';

class FallbackHandler {
  static const int maxAttempts = 12;

  /// Attempts to generate a valid level by iterating fallback strategies.
  static GeneratedLevel? resolve({
    required Template baseTemplate,
    required int levelIndex,
    required int baseSeed,
  }) {
    // Strategy:
    // 0-3: Re-roll slots (using modified seeds)
    // 4-6: Swap Wall Preset (if multiple) - Not implemented support yet, skipping
    // 7-9: Simplify (Not implemented)
    // 10+: Emergency Template

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // 1. Derive Attempt Seed
      // To vary the outcome, we mix the baseSeed with attempt index
      final attemptSeed = baseSeed + attempt * 7919; // Prime multiplier
      
      // 2. Use Emergency Template if exhausted
      Template currentTemplate = baseTemplate;
      if (attempt >= 10) {
        // Emergency: Vertical Corridor v0 (guaranteed solvable basic)
        currentTemplate = VerticalCorridor.v0_basic;
      }
      
      // 3. Instantiate
      final level = Instantiator.instantiate(
        template: currentTemplate,
        seed: attemptSeed,
        levelIndex: levelIndex,
      );
      
      // 4. Validate
      if (_validateAll(level)) {
        return level;
      }
      
      // Fail -> Loop
    }
    
    return null; // Failed all attempts
  }
  
  static bool _validateAll(GeneratedLevel level) {
    // 1. Geometry
    final geomErrors = GeometryValidator.validate(level);
    if (geomErrors.isNotEmpty) return false;
    
    // 2. Performance
    if (!PerformanceValidator.validate(level)) return false;
    
    // 3. Replay
    if (!ReplayValidator.validate(level)) return false;
    
    return true;
  }
}
