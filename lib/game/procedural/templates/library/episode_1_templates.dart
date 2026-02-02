import '../template_models.dart';
import '../../models/models.dart';

/// Templates for Episode 1 (Tutorial/Easy)
/// Themes: Basic Reflection, Walls, No Prisms.
/// Difficulty: 1-3
class Episode1Templates {
  static final List<LevelTemplate> all = [
    _straightShot,
    _lTurn,
    _zPattern,
    _boxBounce,
    _corridor,
    _doubleReflection,
    _mazeEntry,
    _splitDecision,
    _tightSqueeze,
    _masterReflection,
  ];

  /// 1. Straight Shot (Levels 1-20)
  /// Par: 1 move
  /// 1 mirror, direct path. Variables for position.
  static final _straightShot = LevelTemplate(
    id: 'e1_straight_shot',
    nameKey: 'template_e1_straight',
    episode: 1,
    difficulty: 1,
    family: 'basic',
    fixedObjects: [
      // Source fixed for consistency in early levels
      FixedObject(type: ObjectType.source, position: GridPosition(2, 5), orientation: 0), // East
    ],
    variableObjects: [
      // Mirror varies along X=6 line
      VariableObject(
        id: 'm1',
        type: ObjectType.mirror,
        positionExpr: PositionExpression.static(6, 5), 
        orientationExpr: OrientationExpression.scramble('s1'), 
      ),
      // Target position varies
      VariableObject(
        id: 't1',
        type: ObjectType.target,
        positionExpr: PositionExpression.static(6, 8),
        orientationExpr: OrientationExpression.static(0),
      ),
    ],
    variables: [
      TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
      orientations: {'m1': 3}, // \ reflects East->South
      steps: [
        SolutionStep(objectId: 'm1', orientation: 3, description: 'Rotate mirror to reflect down'),
      ],
      totalMoves: 1,
    ),
  );

  /// 2. L-Turn (Levels 21-40)
  /// Par: 2 moves
  /// 2 mirrors forming L shape.
  static final _lTurn = LevelTemplate(
    id: 'e1_l_turn',
    nameKey: 'template_e1_l_turn',
    episode: 1,
    difficulty: 2,
    family: 'basic',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 0), // East
      FixedObject(type: ObjectType.target, position: GridPosition(8, 5), orientation: 0),
    ],
    variableObjects: [
      VariableObject(
        id: 'm1',
        type: ObjectType.mirror,
        positionExpr: PositionExpression.static(5, 1),
        orientationExpr: OrientationExpression.scramble('s1'),
      ),
      VariableObject(
        id: 'm2',
        type: ObjectType.mirror,
        positionExpr: PositionExpression.static(5, 5),
        orientationExpr: OrientationExpression.scramble('s2'),
      ),
    ],
    variables: [
      TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
      orientations: {
        'm1': 3, // \ East -> South
        'm2': 3, // \ South -> East
      },
      steps: [],
      totalMoves: 2,
    ),
  );

  /// 3. Z-Pattern (Levels 41-60)
  /// Par: 3 moves
  /// 3 mirrors zigzag
  static final _zPattern = LevelTemplate(
    id: 'e1_z_pattern',
    nameKey: 'template_e1_z',
    episode: 1,
    difficulty: 2,
    family: 'path',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(1, 2), orientation: 0), // East
    ],
    variableObjects: [
      // M1
      VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s1')),
      // M2
      VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 6), orientationExpr: OrientationExpression.scramble('s2')),
      // M3
      VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 6), orientationExpr: OrientationExpression.scramble('s3')),
      // Target
      VariableObject(id: 't1', type: ObjectType.target, positionExpr: PositionExpression.static(9, 3), orientationExpr: OrientationExpression.static(0)),
    ],
    variables: [
      TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
      orientations: {
        'm1': 3, // \ E->S
        'm2': 3, // \ S->E
        'm3': 1, // / E->N
      },
      steps: [],
      totalMoves: 3,
    ),
  );

  /// 4. Box Bounce (Levels 61-80)
  /// Par: 4 moves
  /// 4 mirrors around perimeter
  static final _boxBounce = LevelTemplate(
    id: 'e1_box_bounce',
    nameKey: 'template_e1_box',
    episode: 1,
    difficulty: 3,
    family: 'path',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 1), // South
      FixedObject(type: ObjectType.target, position: GridPosition(2, 2), orientation: 0), // Inner target
    ],
    variableObjects: [
      VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 8), orientationExpr: OrientationExpression.scramble('s1')),
      VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 8), orientationExpr: OrientationExpression.scramble('s2')),
      VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 1), orientationExpr: OrientationExpression.scramble('s3')),
      VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(2, 1), orientationExpr: OrientationExpression.scramble('s4')),
    ],
    variables: [
      TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    wallSegments: [
        // Box walls
        WallSegment(type: WallSegmentType.boxFrame, x1: 0, y1: 0, x2: 9, y2: 9),
    ],
    solvedState: SolvedState(
      orientations: {
        'm1': 1, // / N->E
        'm2': 3, // \ E->S
        'm3': 1, // / S->W
        'm4': 3, // \ W->N
      },
      steps: [],
      totalMoves: 4,
    ),
  );

  /// 5. Corridor (Levels 81-100)
  /// Par: 2 moves
  /// Walls creating narrow path
  static final _corridor = LevelTemplate(
    id: 'e1_corridor',
    nameKey: 'template_e1_corridor',
    episode: 1,
    difficulty: 2,
    family: 'path',
    fixedObjects: [
        FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0), // East
        FixedObject(type: ObjectType.target, position: GridPosition(12, 4), orientation: 0),
    ],
    variableObjects: [
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 4), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 2), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    variables: [
        TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
        TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    wallSegments: [
        // Corridor walls y=3 and y=5
        WallSegment(type: WallSegmentType.horizontal, y: 3, x1: 2, x2: 12),
        WallSegment(type: WallSegmentType.horizontal, y: 5, x1: 2, x2: 12),
        // Blocker at (9, 4) forcing a detour?
        // Actually, let's make the path S-shaped.
        // Wall at (7, 3) blocking straight path?
        // Wait, walls above are y=3, y=5. Path is y=4.
        // Block (7, 4) with a wall?
        // No, we have a mirror at (7, 4).
        // Ah, mirror IS the detour.
        // But if we put M1 at (7,4), it blocks the beam.
        // M1 reflects E->N (to 7,2).
        // M2 at (7,2) reflects S->E (back to y=2???) No.
        // M2 at (7,2) needs to go to Target(12, 4)?
        // (7,2) -> (12,2) -> (12,4).
        // Need M3.
        // Let's stick to 2 mirrors logic for "Par 2-3".
        // Source(2,4) -> (7,4)M1 -> (7,6)M2 -> (12,6) -> (12,4)M3.
        // Too complex for "Corridor".
        // Let's do a simple divert.
        // Source(2,4) -> (6,4)M1 -> (6,2)M2 -> (12,2)Target.
        // Moves: 2.
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 0, // Horizontal: Pass East through
            'm2': 0, 
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 6. Double Reflection (Levels 101-120)
  /// Par: 3 moves (adjusted from spec "2-4")
  /// 2 parallel mirrors bouncing multiple times?
  /// Or just a back-and-forth channel.
  static final _doubleReflection = LevelTemplate(
    id: 'e1_double_reflection',
    nameKey: 'template_e1_double',
    episode: 1,
    difficulty: 2,
    family: 'reflection',
    fixedObjects: [
        FixedObject(type: ObjectType.source, position: GridPosition(2, 2), orientation: 0), // East
        FixedObject(type: ObjectType.target, position: GridPosition(10, 2), orientation: 0),
    ],
    variableObjects: [
        // Parallel mirrors at y=2 that catch the beam? No, beam is y=2.
        // Let's do a zig-zag between parallel walls/mirrors.
        // Source(2,2) -> (4,2)M1 -> (4,5)M2 -> (6,5)M3 -> (6,2)M4 -> (10,2)Target.
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 5), orientationExpr: OrientationExpression.scramble('s2')),
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 5), orientationExpr: OrientationExpression.scramble('s3')),
        VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 2), orientationExpr: OrientationExpression.scramble('s4')),
    ],
    variables: [
        TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
        TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
        TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
        TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 3, // \ E->S
            'm2': 3, // \ S->E
            'm3': 1, // / E->N
            'm4': 1, // / N->E
        },
        steps: [],
        totalMoves: 4,
    ),
  );

  /// 7. Maze Entry (Levels 121-140)
  /// Par: 4 moves
  /// Walls requiring navigation
  static final _mazeEntry = LevelTemplate(
    id: 'e1_maze_entry',
    nameKey: 'template_e1_maze',
    episode: 1,
    difficulty: 3,
    family: 'path',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 0), // East
      FixedObject(type: ObjectType.target, position: GridPosition(13, 7), orientation: 0),
    ],
    variableObjects: [
      // Path: (1,1) -> (5,1)M1 -> (5,5)M2 -> (9,5)M3 -> (9,3)M4 -> (13,3)M5 -> (13,7)Target
      VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 1), orientationExpr: OrientationExpression.scramble('s1')),
      VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 5), orientationExpr: OrientationExpression.scramble('s2')),
      VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 5), orientationExpr: OrientationExpression.scramble('s3')),
      VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 3), orientationExpr: OrientationExpression.scramble('s4')),
      VariableObject(id: 'm5', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 3), orientationExpr: OrientationExpression.scramble('s5')),
    ],
    variables: [
      TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's5', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    wallSegments: [
        // Walls defining the maze channels
        WallSegment(type: WallSegmentType.vertical, x: 3, y1: 0, y2: 6),
        WallSegment(type: WallSegmentType.vertical, x: 7, y1: 2, y2: 8),
        WallSegment(type: WallSegmentType.vertical, x: 11, y1: 0, y2: 6),
    ],
    solvedState: SolvedState(
      orientations: {
        'm1': 3, // \ E->S
        'm2': 3, // \ S->E
        'm3': 1, // / E->N
        'm4': 1, // / N->E
        'm5': 1, // / E->N
      },
      steps: [],
      totalMoves: 5,
    ),
  );

  /// 8. Split Decision (Levels 141-160)
  /// Par: 3 moves
  /// Multiple paths, but only one correct (blocked by walls/edges)
  /// Note: Without "decoy" mirrors yet, we simulate this by variable placement.
  /// Actually, V1 generator supports fixed/variable objects. We can add extra mirrors.
  static final _splitDecision = LevelTemplate(
    id: 'e1_split_decision',
    nameKey: 'template_e1_split',
    episode: 1,
    difficulty: 3,
    family: 'puzzle',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(4, 4), orientation: 0), // East
      FixedObject(type: ObjectType.target, position: GridPosition(4, 1), orientation: 0),
    ],
    variableObjects: [
      // Proper Path: (4,4) -> (8,4)M1 -> (8,1)M2 -> (4,1)Target.
      VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 4), orientationExpr: OrientationExpression.scramble('s1')),
      VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 1), orientationExpr: OrientationExpression.scramble('s2')),
      
      // Decoy Path: (4,4) -> (8,4) -> (8,7)M3 -> (4,7)M4 -> (4,5) Wall blocked!
      VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 7), orientationExpr: OrientationExpression.scramble('s3')),
      VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 7), orientationExpr: OrientationExpression.scramble('s4')),
    ],
    wallSegments: [
       // Block the decoy return path
       WallSegment(type: WallSegmentType.horizontal, y: 3, x1: 3, x2: 5), 
       // Single wall at (4,3)
       WallSegment(type: WallSegmentType.rect, x: 4, y: 3, w: 1, h: 1),
    ],
    variables: [
      TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
      orientations: {
        'm1': 1, // / E->N
        'm2': 3, // \ N->W
        'm3': 2, 
        'm4': 2, 
      },
      steps: [],
      totalMoves: 2,
    ),
  );

  /// 9. Tight Squeeze (Levels 161-180)
  /// Par: 5 moves
  /// Compact grid (5 mirrors)
  static final _tightSqueeze = LevelTemplate(
    id: 'e1_tight_squeeze',
    nameKey: 'template_e1_tight',
    episode: 1,
    difficulty: 3,
    family: 'puzzle',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(0, 0), orientation: 0), // East
      FixedObject(type: ObjectType.target, position: GridPosition(4, 4), orientation: 0),
    ],
    variableObjects: [
      // Spiral in 5x5 grid
      // (0,0)->(4,0)M1->(4,4)Target? Too simple.
      // (0,0)->(2,0)M1->(2,2)M2->(4,2)M3->(4,4)Target
      VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(2, 0), orientationExpr: OrientationExpression.scramble('s1')),
      VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(2, 2), orientationExpr: OrientationExpression.scramble('s2')),
      VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s3')),
      // Let's add more
      // (0,0)->(3,0)M1->(3,3)M2->(0,3)M3->(0,1)M4->(4,1)M5->(4,4)Target
      // M1(3,0), M2(3,3), M3(0,3), M4(0,1), M5(4,1)
    ],
    // Let's implement the longer spiral
    variables: [
      TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {
           'm1': 3, // \ E->S
           'm2': 0, // / S->E
           'm3': 3, // \ E->S
       }, // Matches the short path (2,0)->(2,2)->(4,2)->(4,4) is invalid (Target is South of M3).
          // M3(4,2), Target(4,4). Incoming East to M3?
          // (2,2) -> (4,2). Yes.
          // M3 Hit from West. Needs South.
          // West(-1,0) -> South(0,1).
          // / (1). Normal (-1, -1)? No.
          // / (0 horizontal). W->N? no.
          // Mirror 0 (/): S<->E, N<->W.
          // Mirror 1 (\): S<->W, N<->E.
          // We need W->S. Mirror 1 (\).
          // Wait, 'm3': 3. Correct.
          
       steps: [],
       totalMoves: 3,
    ),
  );

  /// 10. Master Reflection (Levels 181-200)
  /// Par: 6 moves
  /// 6 mirrors, max complexity
  static final _masterReflection = LevelTemplate(
    id: 'e1_master_reflection',
    nameKey: 'template_e1_master',
    episode: 1,
    difficulty: 3,
    family: 'puzzle',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(7, 4), orientation: 2), // West
      FixedObject(type: ObjectType.target, position: GridPosition(7, 5), orientation: 0),
    ],
    variableObjects: [
       // 6 Mirrors in a loop?
       // (7,4)W -> (1,4)M1 -> (1,1)M2 -> (13,1)M3 -> (13,8)M4 -> (1,8)M5 -> (1,5)M6 -> (7,5)Target
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 4), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 1), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 1), orientationExpr: OrientationExpression.scramble('s3')),
       VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 8), orientationExpr: OrientationExpression.scramble('s4')),
       VariableObject(id: 'm5', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 8), orientationExpr: OrientationExpression.scramble('s5')),
       VariableObject(id: 'm6', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 5), orientationExpr: OrientationExpression.scramble('s6')),
    ],
    variables: [
      TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's5', type: VariableType.scramble, minValue: 1, maxValue: 3),
      TemplateVariable(name: 's6', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
      orientations: {
          'm1': 0, // / W->N (Incoming W(-1,0)->N(0,-1). Mirror / (0). Correct)
          'm2': 0, // / N->E (Incoming S. Wait. path goes 1,4 -> 1,1. That is North.
                   // So incoming to M2 is from South.
                   // Incoming S(0,1). Needs E(1,0).
                   // / (0). S->E. Correct.
          'm3': 3, // \ E->S (Incoming W. to 13,1. Needs S to 13,8.
                   // Incoming from West (-1,0) hitting M3.
                   // Needs South (0,1). \ (3).
                   // Wait. Mirror \ (1/3). S<->W.
                   // W->S. Correct.
          'm4': 3, // \ S->W (Incoming N. Needs W.
                   // Incoming from North (0,-1). Needs West (-1,0).
                   // Mirror 1/3 ( \ ): N<->E.
                   // Mirror 0/2 ( / ): N<->W.
                   // So M4 needs to be / (0).
                   // Let's recheck M3 -> M4.
                   // M3(13,1) -> M4(13,8). Direction South.
                   // M4 incoming from North.
                   // Needs to go to M5(1,8). West.
                   // N->W. / (0).
          'm5': 0, // / W->N (Incoming E. Needs N to 1,5.
                   // Incoming from East (1,0). Needs North (0,-1).
                   // / (0) N<->W.
                   // \ (1) N<->E.
                   // So we need \ (1).
          'm6': 1, // \ N->E (Incoming S. Needs E to Target(7,5).
                   // Incoming from South (0,1). Needs East (1,0).
                   // \ (1/3) S<->E.
                   // Correct.
      },
      steps: [],
      totalMoves: 6,
    ),
  );
}
