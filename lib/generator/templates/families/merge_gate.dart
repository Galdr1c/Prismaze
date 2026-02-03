import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Merge-Gate family.
/// Characteristics: Multiple beams merging into a composite color target.
class MergeGate {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.mergeGate,
      variantId: 0,
      anchors: [
        // Red Source
        Anchor(
          position: GridPosition(0, 0), 
          type: 'source', 
          initialOrientation: 1, // East
          requiredColor: LightColor.red,
        ),
        // Green Source
        Anchor(
          position: GridPosition(5, 0), 
          type: 'source', 
          initialOrientation: 3, // West
          requiredColor: LightColor.green,
        ),
        // M1 (2,0) E->S: \ (3)
        Anchor(position: GridPosition(2, 0), type: 'mirror'),
        // M2 (3,0) W->S: / (1)
        Anchor(position: GridPosition(3, 0), type: 'mirror'),
        // M3 (3,5) S->W: / (1)
        Anchor(position: GridPosition(3, 5), type: 'mirror'),
        // Target (2,5) - Yellow (R+G)
        Anchor(
          position: GridPosition(2, 5),
          type: 'target',
          requiredColor: LightColor.yellow,
        ),
      ],
      variableSlots: [],
      wallPresets: [
        WallPattern([
          GridPosition(1,1), GridPosition(4,1),
          /* Gap at (2,1), (3,1) */
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(0, 0), targetOrientation: 1), // R Src E
        SolutionStep(position: GridPosition(2, 0), targetOrientation: 3), // M1 \ (E->S)
        SolutionStep(position: GridPosition(5, 0), targetOrientation: 3), // G Src W
        SolutionStep(position: GridPosition(3, 0), targetOrientation: 1), // M2 / (W->S)
        SolutionStep(position: GridPosition(3, 5), targetOrientation: 1), // M3 / (S->W)
      ],
    );
  }
}
