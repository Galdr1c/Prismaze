import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Split-Fanout family.
/// Characteristics: Single white source split into 3 primary colors.
class SplitFanout {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.splitFanout,
      variantId: 0,
      anchors: [
        // Source Top Center
        Anchor(
          position: GridPosition(2, 0), 
          type: 'source', 
          initialOrientation: 2, // South
        ),
        // Prism at (2,5) - Ori 2 (R:S, G:W, B:E)
        Anchor(
          position: GridPosition(2, 5),
          type: 'prism',
          initialOrientation: 0,
        ),
        // Target Red (S)
        Anchor(
          position: GridPosition(2, 10),
          type: 'target',
          requiredColor: LightColor.red,
        ),
        // Target Green (W)
        Anchor(
          position: GridPosition(0, 5),
          type: 'target',
          requiredColor: LightColor.green,
        ),
        // Target Blue (E)
        Anchor(
          position: GridPosition(5, 5),
          type: 'target',
          requiredColor: LightColor.blue,
        ),
      ],
      variableSlots: [],
      wallPresets: [
        WallPattern([
          GridPosition(1,4), GridPosition(3,4),
          GridPosition(1,6), GridPosition(3,6),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(2, 0), targetOrientation: 2), // Source S
        SolutionStep(position: GridPosition(2, 5), targetOrientation: 2), // Prism Ori 2 (R:S, G:W, B:E)
      ],
    );
  }
}
