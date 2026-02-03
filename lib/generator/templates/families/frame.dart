import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Frame family.
/// Characteristics: Rectangular path following the grid perimeter.
class Frame {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.frame,
      variantId: 0,
      anchors: [
        // Source top-left, aiming East
        Anchor(
          position: GridPosition(0, 0), 
          type: 'source', 
          initialOrientation: 1, // East
        ),
        // M1 (5,0) E->S: \ (3)
        Anchor(position: GridPosition(5, 0), type: 'mirror'),
        // M2 (5,11) S->W: / (1)
        Anchor(position: GridPosition(5, 11), type: 'mirror'),
        // M3 (0,11) W->N: \ (3)
        Anchor(position: GridPosition(0, 11), type: 'mirror'),
        // M4 (0,2) N->E: / (1)
        Anchor(position: GridPosition(0, 2), type: 'mirror'),
        // Target (2,2)
        Anchor(
          position: GridPosition(2, 2),
          type: 'target',
          requiredColor: LightColor.white,
        ),
      ],
      variableSlots: [],
      wallPresets: [
        WallPattern([
          GridPosition(1,1), GridPosition(2,1), GridPosition(3,1), GridPosition(4,1),
          GridPosition(1,10), GridPosition(2,10), GridPosition(3,10), GridPosition(4,10),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(0, 0), targetOrientation: 1), // Src E
        SolutionStep(position: GridPosition(5, 0), targetOrientation: 3), // M1 \ (E->S)
        SolutionStep(position: GridPosition(5, 11), targetOrientation: 1), // M2 / (S->W)
        SolutionStep(position: GridPosition(0, 11), targetOrientation: 3), // M3 \ (W->N)
        SolutionStep(position: GridPosition(0, 2), targetOrientation: 1), // M4 / (N->E)
      ],
    );
  }
}
