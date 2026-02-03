/// The 12 structural families of the Global Endless mode.
enum TemplateFamily {
  verticalCorridor,
  twoChamber,
  staircase,
  sideChannel,
  centralSpine,
  loopLite,
  splitFanout,
  mergeGate,
  frame,
  blockerPivot,
  dualZone,
  decoyLane;

  String get displayName {
    switch (this) {
      case TemplateFamily.verticalCorridor: return 'Vertical Corridor';
      case TemplateFamily.twoChamber: return 'Two Chamber';
      case TemplateFamily.staircase: return 'Staircase';
      case TemplateFamily.sideChannel: return 'Side Channel';
      case TemplateFamily.centralSpine: return 'Central Spine';
      case TemplateFamily.loopLite: return 'Loop Lite';
      case TemplateFamily.splitFanout: return 'Split Fanout';
      case TemplateFamily.mergeGate: return 'Merge Gate';
      case TemplateFamily.frame: return 'Frame';
      case TemplateFamily.blockerPivot: return 'Blocker Pivot';
      case TemplateFamily.dualZone: return 'Dual Zone';
      case TemplateFamily.decoyLane: return 'Decoy Lane';
    }
  }
}
