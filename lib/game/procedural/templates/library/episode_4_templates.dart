import '../template_models.dart';
import '../../models/models.dart';

/// Templates for Episode 4 (Very Hard)
class Episode4Templates {
  static final List<LevelTemplate> all = [
    _multiMix,
    _lockedGauntlet,
  ];

  /// 1. Multi Mix
  /// Requires creating Orange (R+Y) and Green (B+Y) from R, B, Y sources.
  static final _multiMix = LevelTemplate(
    id: 'e4_multi_mix',
    nameKey: 'template_e4_mix',
    episode: 4,
    difficulty: 7,
    family: 'color_mix',
    fixedObjects: [
      // Sources
      FixedObject(type: ObjectType.source, position: GridPosition(0, 0), orientation: 0, properties: {'color': LightColor.red}),
      FixedObject(type: ObjectType.source, position: GridPosition(0, 4), orientation: 0, properties: {'color': LightColor.yellow}),
      FixedObject(type: ObjectType.source, position: GridPosition(0, 8), orientation: 0, properties: {'color': LightColor.blue}),
      
      // Targets
      FixedObject(type: ObjectType.target, position: GridPosition(8, 2), orientation: 0, properties: {'color': LightColor.orange}), // needs R+Y
      FixedObject(type: ObjectType.target, position: GridPosition(8, 6), orientation: 0, properties: {'color': LightColor.green}),  // needs B+Y
    ],
    variableObjects: [
       // Yellow needs to split? Or Red/Blue need to reach targets?
       // Orange (8,2) needs Red(0,0) and Yellow(0,4).
       // Green (8,6) needs Blue(0,8) and Yellow(0,4).
       // So Yellow must go to BOTH (8,2) and (8,6).
       // Yellow (0,4) -> (4,4) [Splitter].
       // Splitter (West->East): North->(4,2), South->(4,6), East->(8,4)(Waste).
       
       VariableObject(id: 'prism_y', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.scramble('s0'), properties: {'type': PrismType.splitter}),
       
       // Route Red: (0,0) -> (4,0) [M1] -> (4,2) [Hit Y-Split Beam? Collision? No. Y-Split is at (4,4) going N to (4,2)?
       // If Y-Split at 4,4 faces East. Main beam W->E.
       // Split beams: N at 4,4 goes to 4,3...4,0.
       // S at 4,4 goes to 4,5...4,8.
       // So Y-Beam is at column 4.
       // Red Beam needs to merge at (8,2).
       // Red (0,0) -> (8,0) -> (8,2).
       VariableObject(id: 'm_red', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 0), orientationExpr: OrientationExpression.scramble('s1')),
       
       // Yellow North Beam (from 4,4 going N? Wait, splitter N beam goes... North? (x, y-1).
       // (4,4) -> (4,0)?
       // We need it at (8,2).
       // (4,2) -> (8,2).
       // Place Mirror at (4,2) to reflect East.
       VariableObject(id: 'm_y_north', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s2')),
       
       // Yellow South Beam
       // (4,4) -> SOUTH -> (4,6) -> Mirror -> East -> (8,6).
       VariableObject(id: 'm_y_south', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 6), orientationExpr: OrientationExpression.scramble('s3')),

       // Blue Path
       // (0,8) -> (8,8) -> (8,6).
       VariableObject(id: 'm_blue', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 8), orientationExpr: OrientationExpression.scramble('s4')),
    ],
    variables: [
       TemplateVariable(name: 's0', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {
           'prism_y': 0, // Faces East. Splits W->E input to N/S/E.
           'm_y_north': 1, // / S->E (Input from South (4,4)). Out East (8,2).
           'm_y_south': 3, // \ N->E (Input from North (4,4)). Out East (8,6).
           'm_red': 3,     // \ W->S (0,0)->8,0. Needs to go South to 8,2. Correct.
           'm_blue': 1,    // / W->N (0,8)->8,8. Needs to go North to 8,6. Correct.
       },
       steps: [],
       totalMoves: 5,
    ),
  );
  
  /// 2. Locked Gauntlet
  /// 3 Locked mirrors forming a partial path, user must fill gaps.
  static final _lockedGauntlet = LevelTemplate(
    id: 'e4_locked_gauntlet',
    nameKey: 'template_e4_gauntlet',
    episode: 4,
    difficulty: 8,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 4), orientation: 0),
       FixedObject(type: ObjectType.target, position: GridPosition(14, 4), orientation: 0),
    ],
    variableObjects: [
       // Path: (0,4) -> (2,4) [L1 \ S] -> (2,6) [U1 / E] -> (6,6) [L2 / N] -> (6,2) [U2 \ E] -> (10,2) [L3 \ S] -> (10,4) [Target]
       
       // Locked 1: (2,4) reflects E->S.
       VariableObject(id: 'l1', type: ObjectType.mirror, positionExpr: PositionExpression.static(2, 4), orientationExpr: OrientationExpression.static(3), properties: {'locked': true}),
       
       // User 1: (2,6) reflects N->E (Input from North).
       VariableObject(id: 'u1', type: ObjectType.mirror, positionExpr: PositionExpression.static(2, 6), orientationExpr: OrientationExpression.scramble('s1')),
       
       // Locked 2: (6,6) reflects W->N. (Input from West).
       VariableObject(id: 'l2', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 6), orientationExpr: OrientationExpression.static(1), properties: {'locked': true}),
       
       // User 2: (6,2) reflects S->E (Input from South).
       VariableObject(id: 'u2', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 2), orientationExpr: OrientationExpression.scramble('s2')),
       
       // Locked 3: (10,2) reflects W->S. (Input from West).
       VariableObject(id: 'l3', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 2), orientationExpr: OrientationExpression.static(3), properties: {'locked': true}),
       
       // User 3? No, L3 sends South to (10,something).
       // Target is at (14,4).
       // L3 sends South to (10,4)? 
       // Need mirror at (10,4) to send East to (14,4).
       VariableObject(id: 'u3', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 4), orientationExpr: OrientationExpression.scramble('s3')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {
           'l1': 3,
           'l2': 1,
           'l3': 3,
           'u1': 1, // / N->E
           'u2': 3, // \ S->E (Input South 0,1. Output E 1,0. \ 3. Correct)
           'u3': 1, // / N->E (Input North 0,-1 from L3? No L3 is at 10,2. U3 at 10,4.
                    // Ray travels South from L3 to U3.
                    // Incoming (0,1)? Yes.
                    // Needs to go East (1,0).
                    // S->E needs \ (3).
           'u3': 3, // Correction.
       },
       steps: [],
       totalMoves: 3,
    ),
  );
}
