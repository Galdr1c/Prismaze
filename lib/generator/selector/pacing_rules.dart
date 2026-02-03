import '../templates/template_family.dart';

/// Defines the weighted probability of each TemplateFamily appearing in a given level range.
class PacingRules {
  /// Returns the weight map for a given level index.
  /// Higher weight = higher probability.
  /// 
  /// Rules:
  /// - 1-100: High chance of simpler families (VerticalCorridor).
  /// - 101-500: Balanced mix.
  /// - 501+: Harder families increase in frequency.
  static Map<TemplateFamily, int> getWeights(int levelIndex) {
    if (levelIndex <= 100) {
      return {
        TemplateFamily.verticalCorridor: 30,
        TemplateFamily.twoChamber: 15,
        TemplateFamily.staircase: 10,
        TemplateFamily.sideChannel: 10,
        TemplateFamily.centralSpine: 10,
        TemplateFamily.loopLite: 5,
        TemplateFamily.splitFanout: 5,
        TemplateFamily.mergeGate: 5,
        TemplateFamily.frame: 5,
        TemplateFamily.blockerPivot: 2,
        TemplateFamily.dualZone: 2,
        TemplateFamily.decoyLane: 1,
      };
    } else if (levelIndex <= 500) {
      // Mid-game: Intro more complex families
      return {
        TemplateFamily.verticalCorridor: 20,
        TemplateFamily.twoChamber: 15,
        TemplateFamily.staircase: 10,
        TemplateFamily.sideChannel: 10,
        TemplateFamily.centralSpine: 10,
        TemplateFamily.loopLite: 10,
        TemplateFamily.splitFanout: 5,
        TemplateFamily.mergeGate: 5,
        TemplateFamily.frame: 5,
        TemplateFamily.blockerPivot: 5,
        TemplateFamily.dualZone: 3,
        TemplateFamily.decoyLane: 2,
      };
    } else {
      // Late-game: High complexity weights
      return {
        TemplateFamily.verticalCorridor: 10,
        TemplateFamily.twoChamber: 15,
        TemplateFamily.staircase: 10,
        TemplateFamily.sideChannel: 10,
        TemplateFamily.centralSpine: 10,
        TemplateFamily.loopLite: 10,
        TemplateFamily.splitFanout: 5,
        TemplateFamily.mergeGate: 10,
        TemplateFamily.frame: 10,
        TemplateFamily.blockerPivot: 5,
        TemplateFamily.dualZone: 5,
        TemplateFamily.decoyLane: 0, // Maybe Decoy is too easy for late? 
      };
    }
  }
}
