import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Decoy Lane family.
/// Characteristics: Forced turns to avoid hitting "blind" walls.
class DecoyLane {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.decoyLane,
      variantId: 0,
      anchors: [
        // Source top-center aiming South
        Anchor(
          position: GridPosition(2, 0), 
          type: 'source', 
          initialOrientation: 2, // South
        ),
        // M1 (2,10) S->E: \ (3)
        // Wait, if we keep going South hit (2,11). 
        // Goal: Target at (5,10).
        Anchor(position: GridPosition(2, 10), type: 'mirror'),
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
          // Wall directly below source at (2,11)? 
          GridPosition(2,11),
          // Decoy path blocker (Above the path)
          GridPosition(3,9), GridPosition(4,9),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(2, 0), targetOrientation: 2), // Src S
        SolutionStep(position: GridPosition(2, 10), targetOrientation: 3), // M1 \ (S->E)
      ],
    );
  }
}
