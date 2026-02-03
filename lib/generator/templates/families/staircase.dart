import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Staircase family.
/// Characteristics: Z-shaped logic flowing from North to South.
class Staircase {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.staircase,
      variantId: 0,
      anchors: [
        // Source Top Left
        Anchor(
          position: GridPosition(0, 0), 
          type: 'source', 
          initialOrientation: 1, // East
        ),
        // Corner 1: (5,0) East -> South. Needs \ (Ori 3)
        Anchor(
          position: GridPosition(5, 0),
          type: 'mirror',
        ),
        // Corner 2: (5,5) South -> West. Needs / (Ori 1)
        Anchor(
          position: GridPosition(5, 5),
          type: 'mirror',
        ),
        // Corner 3: (0,5) West -> South. Needs \ (Ori 3)
        Anchor(
          position: GridPosition(0, 5),
          type: 'mirror',
        ),
        // Corner 4: (0,10) South -> East. Needs \ (Ori 3)
        Anchor(
          position: GridPosition(0, 10),
          type: 'mirror',
        ),
        // Target: (5,10)
        Anchor(
          position: GridPosition(5, 10),
          type: 'target',
          requiredColor: LightColor.white,
        ),
      ],
      variableSlots: [
        VariableSlot(position: GridPosition(0, 1), allowedTypes: ['blocker'], probability: 0.3),
        VariableSlot(position: GridPosition(5, 9), allowedTypes: ['blocker'], probability: 0.4),
      ],
      wallPresets: [
         WallPattern([
            GridPosition(1,1), GridPosition(2,1), GridPosition(3,1), GridPosition(4,1),
            GridPosition(1,6), GridPosition(2,6), GridPosition(3,6), GridPosition(4,6),
         ]),
         WallPattern([
            GridPosition(1,2), GridPosition(2,2), GridPosition(3,2), GridPosition(4,2),
            GridPosition(1,7), GridPosition(2,7), GridPosition(3,7), GridPosition(4,7),
         ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(0, 0), targetOrientation: 1), // Source E
        SolutionStep(position: GridPosition(5, 0), targetOrientation: 3), // M1 \ (E->S)
        SolutionStep(position: GridPosition(5, 5), targetOrientation: 1), // M2 / (S->W) 
        SolutionStep(position: GridPosition(0, 5), targetOrientation: 1), // M3 / (W->S)
        SolutionStep(position: GridPosition(0, 10), targetOrientation: 3), // M4 \ (S->E)
      ],
    );
  }
}
