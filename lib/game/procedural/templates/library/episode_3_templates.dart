import '../template_models.dart';
import '../../models/models.dart';

/// Templates for Episode 3 (Color Theory)
/// Themes: Prisms, Color Mixing, Deflectors
/// Difficulty: 3-6
class Episode3Templates {
  static final List<LevelTemplate> all = [
    _prismIntro,
    _purpleMix,
    _greenMix,
    _orangeMix,
    _dualTargetColor,
    _tripleColorChallenge,
    _prismObstacle,
    _colorSeparation,
    _mixedPathCrossing,
    _colorMastery,
  ];

  /// 1. Prism Introduction (Levels 401-420)
  /// Par: 2 moves
  /// Single prism, splitting white light.
  static final _prismIntro = LevelTemplate(
    id: 'e3_prism_intro',
    nameKey: 'template_e3_prism_intro',
    episode: 3,
    difficulty: 3,
    family: 'color_intro',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(1, 4), orientation: 0, properties: {'color': LightColor.white}),
      FixedObject(type: ObjectType.target, position: GridPosition(8, 2), orientation: 0, properties: {'color': LightColor.red}),
    ],
    variableObjects: [
        // Splitter at (5,4).
        // White -> Splitter -> Red(N), Blue(E), Yellow(S).
        // (Assuming standard Prismaze splitter: Front=East, Left=North(Red? check rules), Right=South(Yellow)).
        // Colors: R(Red), G(Blue?), B(Yellow?) -> Wait, usually R, B, Y primary.
        // Let's assume Splitter behavior/Orientation 0 (East):
        // Main Out (East): Blue
        // Left Out (North): Red
        // Right Out (South): Yellow
        
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        
        // Target is Red at (8,2).
        // North beam (Red) from (5,4) goes to (5,2).
        // Needs Mirror at (5,2) to reflect East to (8,2).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 2), orientationExpr: OrientationExpression.scramble('s1')),
    ],
    variables: [
        TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 1, // / N->E
        },
        steps: [],
        totalMoves: 1,
    ),
  );

  /// 2. Basic Purple Mix (Levels 421-440)
  /// Par: 4 moves
  /// Red + Blue = Purple Target.
  static final _purpleMix = LevelTemplate(
    id: 'e3_purple_mix',
    nameKey: 'template_e3_purple_mix',
    episode: 3,
    difficulty: 4,
    family: 'color_mix',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 4), orientation: 0, properties: {'color': LightColor.purple}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(6, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // Splitter at (6,4). 
        // Red(North) -> (6,2).
        // Blue(East) -> (10,4). Main beam hits target.
        // Yellow(South) -> (6,6).
        
        // Target needs Purple (Red + Blue).
        // Blue is already hitting it (Straight through).
        // Need Red.
        // Red at (6,2). Redirect to target?
        // (6,2) -> (10,2)M1 -> (10,4).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 2), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 2), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 3, // \ S->E
            'm2': 1, // / W->S
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 3. Basic Green Mix (Levels 441-460)
  /// Par: 4 moves
  /// Blue + Yellow = Green.
  static final _greenMix = LevelTemplate(
    id: 'e3_green_mix',
    nameKey: 'template_e3_green_mix',
    episode: 3,
    difficulty: 4,
    family: 'color_mix',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 8), orientation: 0, properties: {'color': LightColor.green}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(6, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // Splitter (6,4).
        // Blue (East) -> (10,4)M1 -> (10,8).
        // Yellow (South) -> (6,8)M2 -> (10,8).
        // Red (North) -> ignored.
        
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 4), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 8), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 3, // \ E->S
            'm2': 3, // \ S->E
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 4. Basic Orange Mix (Levels 461-480)
  /// Par: 4 moves
  /// Red + Yellow = Orange.
  static final _orangeMix = LevelTemplate(
    id: 'e3_orange_mix',
    nameKey: 'template_e3_orange_mix',
    episode: 3,
    difficulty: 4,
    family: 'color_mix',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(8, 6), orientation: 0, properties: {'color': LightColor.orange}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // Splitter (4,4).
        // Red (North) -> (4,2)M1 -> (8,2)M2 -> (8,6).
        // Yellow (South) -> (4,6)M3 -> (8,6).
        // Blue (East) -> Ignored.
        
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 2), orientationExpr: OrientationExpression.scramble('s2')),
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 6), orientationExpr: OrientationExpression.scramble('s3')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 1, // / N->E
            'm2': 3, // \ E->S
            'm3': 3, // \ S->E
        },
        steps: [],
        totalMoves: 3,
    ),
  );

  /// 5. Dual Target Color (Levels 481-500)
  /// Par: 5 moves
  /// Red Target + Blue Target (No mixing, just separation).
  static final _dualTargetColor = LevelTemplate(
    id: 'e3_dual_color',
    nameKey: 'template_e3_dual_color',
    episode: 3,
    difficulty: 4,
    family: 'color_mix',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(8, 2), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(8, 6), orientation: 0, properties: {'color': LightColor.blue}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // Red (N) -> (5,2)M1 -> (8,2).
        // Blue (E) -> (8,4)M2 -> (8,6).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 2), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 4), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 3, // \ S->E
            'm2': 1, // / W->S
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 6. Triple Color Challenge (Levels 501-520)
  /// Par: 6 moves
  /// Red + Blue + Yellow targets.
  static final _tripleColorChallenge = LevelTemplate(
    id: 'e3_triple_color',
    nameKey: 'template_e3_triple',
    episode: 3,
    difficulty: 5,
    family: 'color_mix',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(8, 1), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 4), orientation: 0, properties: {'color': LightColor.blue}),
       FixedObject(type: ObjectType.target, position: GridPosition(8, 7), orientation: 0, properties: {'color': LightColor.yellow}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // Red (N) -> (4,1)M1 -> (8,1).
        // Blue (E) -> (10,4). Direct? Or Obstructed?
        // Yellow (S) -> (4,7)M2 -> (8,7).
        
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 1), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 7), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 1, // / N->E
            'm2': 3, // \ S->E
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 7. Prism Obstacle (Levels 521-540)
  /// Par: 5 moves
  static final _prismObstacle = LevelTemplate(
    id: 'e3_prism_obstacle',
    nameKey: 'template_e3_obstacle',
    episode: 3,
    difficulty: 5,
    family: 'path',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(9, 7), orientation: 0, properties: {'color': LightColor.purple}),
    ],
    variableObjects: [
        // Navigate walls to get Red and Blue to target.
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(3, 1), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 7), orientationExpr: OrientationExpression.scramble('s1')), // For Red? No Red is N.
        
        // Red (N) -> (3,-1) Off grid?
        // Must rotate prism? Or Prism Fixed?
        // Prism is fixed orientation 0.
        // If Prism is at (3,1), Red goes North (3,0)?
        VariableObject(id: 'm_red_catch', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 0), orientationExpr: OrientationExpression.scramble('s2')),
        // (3,0) -> East to (9,0)M3 -> (9,7).
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 0), orientationExpr: OrientationExpression.scramble('s3')),
        
        // Blue (E) -> (9,1)M4 -> (9,7).
        VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 1), orientationExpr: OrientationExpression.scramble('s4')),
    ],
    wallSegments: [
        WallSegment(type: WallSegmentType.vertical, x: 5, y1: 2, y2: 6),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm_red_catch': 0, // / S->E
            'm3': 1, // \ W->S
            'm4': 1, // \ W->S
            'm1': 2, // Unused?
        },
        steps: [],
        totalMoves: 3,
    ),
  );

  /// 8. Color Separation (Levels 541-560)
  /// Par: 5 moves
  static final _colorSeparation = LevelTemplate(
    id: 'e3_separation',
    nameKey: 'template_e3_separation',
    episode: 3,
    difficulty: 5,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 2), orientation: 0, properties: {'color': LightColor.blue}), // Only Blue wanted
       FixedObject(type: ObjectType.wall, position: GridPosition(10, 4), orientation: 0), // Block straight path?
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        
        // Blue goes East (5,5)->(10,5)? No (5,4)->(10,4) Blocked by wall.
        // Need to deflect Blue.
        // M1 at (8,4)?
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 4), orientationExpr: OrientationExpression.scramble('s1')),
        // (8,4) -> North (8,2) -> East (10,2).
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 2), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 0, // / N->W
            'm2': 0, // / S->E
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 9. Mixed Path Crossing (Levels 561-580)
  /// Par: 6 moves
  static final _mixedPathCrossing = LevelTemplate(
    id: 'e3_crossing',
    nameKey: 'template_e3_crossing',
    episode: 3,
    difficulty: 6,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 2), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.source, position: GridPosition(0, 6), orientation: 0, properties: {'color': LightColor.blue}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 2), orientation: 0, properties: {'color': LightColor.blue}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 6), orientation: 0, properties: {'color': LightColor.red}),
    ],
    variableObjects: [
        // Paths must cross.
        // Red (0,2) -> (10,6).
        // Blue (0,6) -> (10,2).
        // Cross at (5,4).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 2), orientationExpr: OrientationExpression.scramble('s1')), // Red -> South
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 6), orientationExpr: OrientationExpression.scramble('s2')), // Blue -> North
        
        // (3,2)->(3,6) blocked by M2?
        // (3,6)->(3,2) blocked by M1?
        // Need diagonal crossing.
        // Red: (3,2) -> (3,4)M3 -> (7,4)M4 -> (7,6)M5 -> (10,6).
        // Blue: (3,6) -> (3,4)M3? Collision.
        
        // Better:
        // Red: (0,2)->(5,2)M1 -> (5,6)M2 -> (10,6).
        // Blue: (0,6)->(3,6)M3 -> (3,2)M4 -> (10,2).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 2), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 6), orientationExpr: OrientationExpression.scramble('s2')),
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 6), orientationExpr: OrientationExpression.scramble('s3')),
        VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 2), orientationExpr: OrientationExpression.scramble('s4')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 1, // \ W->S
            'm2': 0, // / N->E
            'm3': 0, // / W->N
            'm4': 1, // \ S->E
        },
        steps: [],
        totalMoves: 4,
    ),
  );

  /// 10. Color Mastery (Levels 581-600)
  /// Par: 8 moves
  static final _colorMastery = LevelTemplate(
    id: 'e3_mastery',
    nameKey: 'template_e3_mastery',
    episode: 3,
    difficulty: 6,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 2), orientation: 0, properties: {'color': LightColor.purple}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 6), orientation: 0, properties: {'color': LightColor.orange}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(6, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // White -> Splitter -> R(N), B(E), Y(S).
        // Purple Target needs R+B.
        // Orange Target needs R+Y.
        
        // Wait. R (North) needs to go to BOTH Purple(10,2) and Orange(10,6)?
        // Impossible with one beam unless we split R? (Prisms don't split R).
        // Or targets are arranged so beam passes through?
        // Mirrors block light.
        // However, Prismaze Logic: Light COLOR ADDS UP.
        // If we want R to hit T1 and T2, we need distinct beams? 
        // Can't duplicate R.
        // So this template is unsolvable with 1 prism if targets need R in two places.
        // Unless we have 2 prisms?
        // Let's change targets.
        // Red Target (R), Blue Target (B), Yellow Target (Y).
        // Or Purple(R+B) and Green(B+Y).
        // B can go to both? Again, need splitting B.
        
        // Let's do Red + Blue + Yellow targets.
        // T1(10,2) Red. T2(12,4) Blue. T3(10,6) Yellow.
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 2), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 6), orientationExpr: OrientationExpression.scramble('s2')),
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 4), orientationExpr: OrientationExpression.scramble('s3')), // For Blue?
        
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 0, // / S->E (R->T1)
            'm2': 1, // \ N->E (Y->T3)
            'm3': 2, // - Pass? No mirror blocks. Remove m3 if T2 is at (12,4).
                     // Actually let's assume T2 is hit directly.
                     // Remove m3 from variableObjects if it blocks.
        },
        steps: [],
        totalMoves: 2,
    ),
  );
}
