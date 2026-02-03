import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Vertical Corridor family.
/// Characteristics: Narrow path from top to bottom, high focus on reflection angles.
class VerticalCorridor {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.verticalCorridor,
      variantId: 0,
      anchors: [
        // Source Top Center
        Anchor(
          position: GridPosition(2, 1), 
          type: 'source', 
          initialOrientation: 2, // South
          solutionOrientation: 2,
          requiredColor: LightColor.white,
        ),
        // Target Bottom Center
        Anchor(
          position: GridPosition(2, 10), 
          type: 'target', 
          requiredColor: LightColor.white,
        ),
        
        // Reflection Path:
        // Source(2,1) South -> (2,5)
        // M1(2,5) South->West
        Anchor(
          position: GridPosition(2, 5),
          type: 'mirror',
          solutionOrientation: 1, // / NE-SW? Deflects S(2) to W(3)
        ),
        
        // M2(0,5) West->South
        Anchor(
          position: GridPosition(0, 5),
          type: 'mirror',
          solutionOrientation: 1, // / NE-SW deflects West to South
        ),
        
        // M3(0,10) South->East
        Anchor(
          position: GridPosition(0, 10),
          type: 'mirror',
          solutionOrientation: 3, // \ NW-SE deflects South to East
        ),
        
      ],
      variableSlots: [],
      wallPresets: [
        WallPattern([
          GridPosition(0, 4), GridPosition(1, 4), /* Gap at (2,4) */ GridPosition(3, 4),
          GridPosition(5, 4),
          /* Gap at (0,9) */
          GridPosition(2, 9), GridPosition(3, 9), GridPosition(4, 9), GridPosition(5, 9),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(2, 1), targetOrientation: 2), // Source S
        SolutionStep(position: GridPosition(2, 5), targetOrientation: 1), // M1 / (S->W)
        SolutionStep(position: GridPosition(0, 5), targetOrientation: 1), // M2 / (W->S)
        SolutionStep(position: GridPosition(0, 10), targetOrientation: 3), // M3 \ (S->E)
      ],
    );
  }
}
