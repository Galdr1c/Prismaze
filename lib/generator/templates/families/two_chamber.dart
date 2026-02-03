import 'package:prismaze/core/models/models.dart';
import '../template_models.dart';
import '../template_family.dart';

/// Implementation of the Two-Chamber family.
/// Characteristics: Divided grid with a gate, often using prisms or multiple colors.
class TwoChamber {
  static Template get v0_basic {
    return const Template(
      family: TemplateFamily.twoChamber,
      variantId: 0,
      anchors: [
        // Source Top Center
        Anchor(
          position: GridPosition(2, 1), 
          type: 'source', 
          initialOrientation: 2, // South
          requiredColor: LightColor.white,
        ),
        // Prism at (2,3) - Split White S -> R(S), G(E), B(W) [Ori 2]
        // Wait, Base Ori 0: R(N), G(E), B(W).
        // If we want R(S), we need to rotate 180 (Ori 2).
        // Ori 2: R(S), G(W), B(E).
        Anchor(
          position: GridPosition(2, 3),
          type: 'prism',
          initialOrientation: 0,
        ),
        
        // Target 1 (Red) - Top Chamber
        Anchor(
          position: GridPosition(5, 3),
          type: 'target',
          requiredColor: LightColor.red,
        ),
        // Target 2 (Green) - Bottom Chamber
        Anchor(
          position: GridPosition(2, 10),
          type: 'target',
          requiredColor: LightColor.green,
        ),
        
        // Mirror for Red: (2,3) R(S) -> Needs to go to (5,3).
        // Let's change Prism to Ori 2: R is South, B is East, G is West.
        // Wait, R at South doesn't help for (5,3).
        // If Prism at (2,3) Ori 1: R(E), G(S), B(N).
        // R(E) goes straight to (5,3)? Correct!
        // G(S) goes through gate at (2,6) to (2,10)? Correct!
      ],
      variableSlots: [],
      wallPresets: [
        WallPattern([
          // Horizontal shelf at Y=6
          GridPosition(0, 6), GridPosition(1, 6), 
          /* Gap at (2,6) */
          GridPosition(3, 6), GridPosition(4, 6), GridPosition(5, 6),
        ]),
      ],
      solutionSteps: [
        SolutionStep(position: GridPosition(2, 1), targetOrientation: 2), // Source S
        SolutionStep(position: GridPosition(2, 3), targetOrientation: 1), // Prism Ori 1 (R->E, G->S)
      ],
    );
  }
}
