import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Side-Channel family.
/// Characteristics: Forced path along one edge, typically the side.
class SideChannel {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.sideChannel,
      variantId: 0,
      anchors: [
        // Source Top Left
        Anchor(
          position: GridPosition(0, 1), 
          type: 'source', 
          initialOrientation: 1, // East
        ),
        // Mirror 1: (5,1) E -> S. Needs \ (Ori 3)
        Anchor(
          position: GridPosition(5, 1),
          type: 'mirror',
        ),
        // Mirror 2: (5,10) S -> W. Needs / (Ori 1)
        Anchor(
          position: GridPosition(5, 10),
          type: 'mirror',
        ),
        // Target: (1,10)
        Anchor(
          position: GridPosition(1, 10),
          type: 'target',
          requiredColor: LightColor.white,
        ),
      ],
      variableSlots: [
        VariableSlot(
          position: GridPosition(0, 10),
          allowedTypes: ['blocker'],
          probability: 0.5,
        ),
      ],
      wallPresets: [
        // Giant blocker in the center
        WallPattern([
          GridPosition(1,2), GridPosition(2,2), GridPosition(3,2), GridPosition(4,2),
          GridPosition(1,3), GridPosition(2,3), GridPosition(3,3), GridPosition(4,3),
          GridPosition(1,4), GridPosition(2,4), GridPosition(3,4), GridPosition(4,4),
          GridPosition(1,5), GridPosition(2,5), GridPosition(3,5), GridPosition(4,5),
          GridPosition(1,6), GridPosition(2,6), GridPosition(3,6), GridPosition(4,6),
          GridPosition(1,7), GridPosition(2,7), GridPosition(3,7), GridPosition(4,7),
          GridPosition(1,8), GridPosition(2,8), GridPosition(3,8), GridPosition(4,8),
          GridPosition(1,9), GridPosition(2,9), GridPosition(3,9), GridPosition(4,9),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(0, 1), targetOrientation: 1), // Source E
        SolutionStep(position: GridPosition(5, 1), targetOrientation: 3), // M1 \ (E->S)
        SolutionStep(position: GridPosition(5, 10), targetOrientation: 1), // M2 / (S->W)
      ],
    );
  }
}
