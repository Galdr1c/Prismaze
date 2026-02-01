import '../template_models.dart';
import '../../models/models.dart';

/// Templates for Episode 3 (Hard) - Color Mixing & Locked Mirrors
class Episode3Templates {
  static final List<LevelTemplate> all = [
    _purpleBasic,
    _greenBasic,
  ];

  /// 1. Purple Basic
  /// Mix Red + Blue to get Purple.
  /// Introduces Colored Sources and Locked Mirrors (obstacles).
  static final _purpleBasic = LevelTemplate(
    id: 'e3_purple_basic',
    nameKey: 'template_e3_purple',
    episode: 3,
    difficulty: 5,
    family: 'color_mix',
    fixedObjects: [
      // Red Source
      FixedObject(type: ObjectType.source, position: GridPosition(0, 2), orientation: 0, properties: {'color': LightColor.red}),
      // Blue Source
      FixedObject(type: ObjectType.source, position: GridPosition(0, 6), orientation: 0, properties: {'color': LightColor.blue}),
      // Purple Target at (6, 4)
      FixedObject(type: ObjectType.target, position: GridPosition(6, 4), orientation: 0, properties: {'color': LightColor.purple}),
      // Locked Mirror blocking direct path or forcing deviation?
      // Let's place a locked mirror that helps one beam but might need the other to go around.
      // Locked Mirror at (4, 4)?
    ],
    variableObjects: [
       // Red path: (0,2) -> (6,2) [M1] -> (6,4).
       // Blue path: (0,6) -> (6,6) [M2] -> (6,4).
       // Simple mix.
       VariableObject(
          id: 'm1', 
          type: ObjectType.mirror, 
          positionExpr: PositionExpression.static(6, 2), 
          orientationExpr: OrientationExpression.scramble('s1'),
       ),
       VariableObject(
          id: 'm2', 
          type: ObjectType.mirror, 
          positionExpr: PositionExpression.static(6, 6), 
          orientationExpr: OrientationExpression.scramble('s2'),
       ),
       // Locked mirror distraction or helper?
       // Let's make M1 locked in correct position?
       // "Locked Mirrors" feature demo.
       // Let's make M1 LOCKED CORRECTLY.
       // VariableObject but with locked prop.
       // And orientation static?
       // If locked, orientation is usually fixed?
       // Or locked means "User cannot rotate". But generator can set initial rotation.
       // If generator sets it to solved state, it's a "helper".
       // If generator sets it to WRONG state, it's an IMPOSSIBLE puzzle (unless solvable another way).
       // Usually Locked Mirrors are set to correct orientation by design (or used as obstacles).
       // Let's add a Locked Mirror at (3,2) that is useful.
       // Red beam (0,2) -> (3,2) -> (3,4) -> (6,4).
       // Blue beam (0,6) -> (6,6) -> (6,4).
       
       VariableObject(
          id: 'locked_m',
          type: ObjectType.mirror,
          positionExpr: PositionExpression.static(3, 2),
          orientationExpr: OrientationExpression.static(3), // \ E->S
          properties: {'locked': true},
       ),
       
       // Move M1 to (3,4)? 
       VariableObject(id: 'm_mobile', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 4), orientationExpr: OrientationExpression.scramble('s3')),
       
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3), // For m2
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3), // For m_mobile
    ],
    solvedState: SolvedState(
       orientations: {
           'locked_m': 3, // \ (Already static, but good to track)
           'm_mobile': 1, // / S->E (Incoming South (0,1) from locked_m? No, locked_m reflects E->S.
                          // Ray from (3,2) goes South to (3,4).
                          // Incoming North (0,-1). Outgoing East (1,0). / (1).
           'm2': 1,       // / E->N (Wait. M2 at (6,6). Source Blue (0,6) -> (6,6).
                          // Incoming West? No source E. Ray (1,0). E->N(0,-1) to hit (6,4).
                          // E->N requires /.
       },
       steps: [],
       totalMoves: 2, // m_mobile and m2 need rotating. locked_m is fixed.
    ),
  );

  /// 2. Green Basic
  /// Blue + Yellow = Green.
  static final _greenBasic = LevelTemplate(
    id: 'e3_green_basic',
    nameKey: 'template_e3_green',
    episode: 3,
    difficulty: 6,
    family: 'color_mix',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 0, properties: {'color': LightColor.blue}),
       FixedObject(type: ObjectType.source, position: GridPosition(1, 7), orientation: 0, properties: {'color': LightColor.yellow}),
       FixedObject(type: ObjectType.target, position: GridPosition(8, 4), orientation: 0, properties: {'color': LightColor.green}),
    ],
    variableObjects: [
        // Blue path: (1,1) -> (4,1) -> (4,4) -> (8,4).
        // Yellow path: (1,7) -> (4,7) -> (4,4) (Collision/Merge? No, beams cross/mix at target).
        // If we want them to mix AT target, they must arrive at target from different directions or same?
        // Target can accept from multiple sides.
        // Or mix at a prism?
        // Prisms split. Do they combine?
        // Prismaze logic: Colors accumulate at the target cell.
        // So we can hit target from North (Blue) and South (Yellow) and it becomes Green.
        
        // Path 1 (Blue): (1,1) -> (8,1) -> (8,4).
        VariableObject(id: 'm_blue', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 1), orientationExpr: OrientationExpression.scramble('s1')),
        
        // Path 2 (Yellow): (1,7) -> (8,7) -> (8,4).
        VariableObject(id: 'm_yellow', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 7), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    variables: [
        TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
        TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm_blue': 3,   // \ E->S. (1,1)->(8,1) East. Hits \. South -> (8,4). Correct.
            'm_yellow': 1, // / E->N. (1,7)->(8,7) East. Hits /. North -> (8,4). Correct.
        },
        steps: [],
        totalMoves: 2,
    ),
  );
}
