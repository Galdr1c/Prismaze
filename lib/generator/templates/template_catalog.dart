import 'template_family.dart';
import 'template_models.dart';
import 'families/vertical_corridor.dart';
import 'families/two_chamber.dart';
import 'families/staircase.dart';
import 'families/side_channel.dart';
import 'families/central_spine.dart';
import 'families/split_fanout.dart';
import 'families/loop_lite.dart';
import 'families/merge_gate.dart';
import 'families/frame.dart';
import 'families/blocker_pivot.dart';
import 'families/dual_zone.dart';
import 'families/decoy_lane.dart';

/// Registry for all templates in the game.
class TemplateCatalog {
  /// Retrieves a specific template by family and variant ID.
  static Template getTemplate(TemplateFamily family, int variantId) {
    if (variantId == 0) {
      switch (family) {
        case TemplateFamily.verticalCorridor: return VerticalCorridor.v0_basic;
        case TemplateFamily.twoChamber: return TwoChamber.v0_basic;
        case TemplateFamily.staircase: return Staircase.v0_basic;
        case TemplateFamily.sideChannel: return SideChannel.v0_basic;
        case TemplateFamily.centralSpine: return CentralSpine.v0_basic;
        case TemplateFamily.splitFanout: return SplitFanout.v0_basic;
        case TemplateFamily.loopLite: return LoopLite.v0_basic;
        case TemplateFamily.mergeGate: return MergeGate.v0_basic;
        case TemplateFamily.frame: return Frame.v0_basic;
        case TemplateFamily.blockerPivot: return BlockerPivot.v0_basic;
        case TemplateFamily.dualZone: return DualZone.v0_basic;
        case TemplateFamily.decoyLane: return DecoyLane.v0_basic;
      }
    }
    
    // Fallback for unimplemented variants
    return VerticalCorridor.v0_basic; 
  }

  /// Returns total implemented templates count.
  static int get totalImplemented => 12; 
}
