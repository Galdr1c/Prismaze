import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Blocker Pivot family.
/// Characteristics: Beam must pivot around a central cluster of blockers.
class BlockerPivot {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.blockerPivot,
      variantId: 0,
      anchors: [
        // Source top-center, aiming South
        Anchor(
          position: GridPosition(2, 0), 
          type: 'source', 
          initialOrientation: 2, // South
        ),
        // M1 (2,5) S->W: / (1)
        Anchor(position: GridPosition(2, 5), type: 'mirror'),
        // M2 (0,5) W->S: \ (3)? No, W->S needs /. 
        // W is 3, S is 2. / is NE-SW. W(3) reflected across normal (-1, 1). 
        // Wait, W reflected across /: (3) -> (2) [S]. Yes, /.
        Anchor(position: GridPosition(0, 5), type: 'mirror'),
        // M3 (0,10) S->E: \ (3)
        Anchor(position: GridPosition(0, 10), type: 'mirror'),
        // Target (5,10)
        Anchor(
          position: GridPosition(5, 10),
          type: 'target',
          requiredColor: LightColor.white,
        ),
      ],
      variableSlots: [],
      wallPresets: [
        WallPattern([
          // Central block forcing the pivot
          GridPosition(1,4), /* Gap at (2,4) */ GridPosition(3,4),
          /* Gap at (1,5) and (2,5) */ GridPosition(3,5),
          GridPosition(1,6), GridPosition(2,6), GridPosition(3,6),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(2, 0), targetOrientation: 2), // Src S
        SolutionStep(position: GridPosition(2, 5), targetOrientation: 1), // M1 / (S->W)
        SolutionStep(position: GridPosition(0, 5), targetOrientation: 1), // M2 / (W->S)
        SolutionStep(position: GridPosition(0, 10), targetOrientation: 3), // M3 \ (S->E)
      ],
    );
  }
}
