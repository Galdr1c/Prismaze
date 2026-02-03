import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Dual Zone family.
/// Characteristics: Two distinct color zones with independent sources.
class DualZone {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.dualZone,
      variantId: 0,
      anchors: [
        // Red Source Left
        Anchor(
          position: GridPosition(0, 0), 
          type: 'source', 
          initialOrientation: 2, // South
          requiredColor: LightColor.red,
        ),
        // Blue Source Right
        Anchor(
          position: GridPosition(5, 0), 
          type: 'source', 
          initialOrientation: 2, // South
          requiredColor: LightColor.blue,
        ),
        // Target Red (0,10)
        Anchor(
          position: GridPosition(0, 10),
          type: 'target',
          requiredColor: LightColor.red,
        ),
        // Target Blue (5,10)
        Anchor(
          position: GridPosition(5, 10),
          type: 'target',
          requiredColor: LightColor.blue,
        ),
      ],
      variableSlots: [],
      wallPresets: [
        WallPattern([
          // Central dividing wall
          GridPosition(2,0), GridPosition(2,1), GridPosition(2,2), GridPosition(2,3), GridPosition(2,4), GridPosition(2,5),
          GridPosition(3,6), GridPosition(3,7), GridPosition(3,8), GridPosition(3,9), GridPosition(3,10), GridPosition(3,11),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(0, 0), targetOrientation: 2), // R Src S
        SolutionStep(position: GridPosition(5, 0), targetOrientation: 2), // B Src S
      ],
    );
  }
}
