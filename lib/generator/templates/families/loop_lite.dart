import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Loop-Lite family.
/// Characteristics: Circular path before hitting the final target.
class LoopLite {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.loopLite,
      variantId: 0,
      anchors: [
        // Source Top Left
        Anchor(
          position: GridPosition(0, 0), 
          type: 'source', 
          initialOrientation: 1, // East
        ),
        // M1 (5,0) E->S: \ (3)
        Anchor(position: GridPosition(5, 0), type: 'mirror'),
        // M2 (5,5) S->W: / (1)
        Anchor(position: GridPosition(5, 5), type: 'mirror'),
        // M3 (0,5) W->N: \ (3)
        Anchor(position: GridPosition(0, 5), type: 'mirror'),
        // M4 (0,3) N->E: / (1)
        Anchor(position: GridPosition(0, 3), type: 'mirror'),
        // Target (5,3)
        Anchor(
          position: GridPosition(5, 3),
          type: 'target',
          requiredColor: LightColor.white,
        ),
      ],
      variableSlots: [
        VariableSlot(position: GridPosition(2, 4), allowedTypes: ['blocker'], probability: 0.5),
        VariableSlot(position: GridPosition(3, 4), allowedTypes: ['blocker'], probability: 0.5),
      ],
      wallPresets: [
         WallPattern([
            GridPosition(2,2), GridPosition(3,2),
         ]),
         WallPattern([
            GridPosition(0,4), GridPosition(5,4),
         ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(0, 0), targetOrientation: 1), // Source E
        SolutionStep(position: GridPosition(5, 0), targetOrientation: 3), // M1 \ (E->S)
        SolutionStep(position: GridPosition(5, 5), targetOrientation: 1), // M2 / (S->W) 
        SolutionStep(position: GridPosition(0, 5), targetOrientation: 3), // M3 \ (W->N)
        SolutionStep(position: GridPosition(0, 3), targetOrientation: 1), // M4 / (N->E)
      ],
    );
  }
}
