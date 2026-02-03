import '../models/generated_level.dart';
import '../pipeline/headless_ray_tracer.dart';
import '../../core/models/objects.dart';
import '../../core/models/models.dart'; // For GridPosition
import '../templates/template_models.dart'; // For Anchor

class ReplayValidator {
  /// Validates that the level is solvable by applying the solution configuration
  /// and running a headless simulation.
  static bool validate(GeneratedLevel level) {
    // 1. Clone objects for manipulation (optional, but good practice to not mutate input level directly)
    // But GeneratedLevel objects are effectively immutable / final fields.
    // Wait, GameObject subclasses have final fields.
    // We can't mutate them to "Rotate" them.
    // Loophole: GeneratedLevel has `List<GameObject>`, we can replace items in the list.
    
    final validationObjects = <GameObject>[];
    
    for (var obj in level.objects) {
      // Find a solution step for this position
      final stepIndex = level.template.solutionSteps.indexWhere(
        (s) => s.position == obj.position
      );
      
      if (stepIndex != -1) {
        final step = level.template.solutionSteps[stepIndex];
        // Apply rotation!
        if (obj is SourceObject) {
           validationObjects.add(SourceObject(
             position: obj.position, 
             orientation: step.targetOrientation, 
             color: obj.color
           ));
        } else if (obj is MirrorObject) {
           validationObjects.add(MirrorObject(
             position: obj.position, 
             orientation: step.targetOrientation
           ));
        } else if (obj is PrismObject) {
           validationObjects.add(PrismObject(
             position: obj.position, 
             orientation: step.targetOrientation
           ));
        } else {
           validationObjects.add(obj);
        }
      } else {
        // No change
        validationObjects.add(obj);
      }
    }
    
    // 2. Run Headless Ray Tracer
    return HeadlessRayTracer.validateSolution(level.copyWith(objects: validationObjects));
  }
}
