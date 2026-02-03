import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Central-Spine family.
/// Characteristics: Structural wall column in the center.
class CentralSpine {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.centralSpine,
      variantId: 0,
      anchors: [
        // Source Top Left
        Anchor(
          position: GridPosition(0, 0), 
          type: 'source', 
          initialOrientation: 2, // South
        ),
        // Mirror 1: (0,5) S -> E. Needs \ (Ori 3)
        Anchor(
          position: GridPosition(0, 5),
          type: 'mirror',
        ),
        // Prism: (2,5) - Split Ori 0 (R:N, G:E, B:W)
        Anchor(
          position: GridPosition(2, 5),
          type: 'prism',
          initialOrientation: 0,
        ),
        // Target: (5,5)
        Anchor(
          position: GridPosition(5, 5),
          type: 'target',
          requiredColor: LightColor.green,
        ),
      ],
      variableSlots: [],
      wallPresets: [
        // Vertical spine
        WallPattern([
          GridPosition(2,0), GridPosition(2,1), GridPosition(2,2), GridPosition(2,3), GridPosition(2,4),
          /* Gap for Prism at (2,5) */
          GridPosition(2,6), GridPosition(2,7), GridPosition(2,8), GridPosition(2,9), GridPosition(2,10), GridPosition(2,11),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(0, 0), targetOrientation: 2), // Source S
        SolutionStep(position: GridPosition(0, 5), targetOrientation: 3), // M1 \ (S->E)
        SolutionStep(position: GridPosition(2, 5), targetOrientation: 0), // Prism Ori 0 (G->E)
      ],
    );
  }
}
