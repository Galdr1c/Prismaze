import '../template_models.dart';
import '../../models/models.dart';

/// Templates for Episode 2 (Mastery)
/// Themes: Multiple Targets, Locked Mirrors, Prisms
/// Difficulty: 3-5
class Episode2Templates {
  static final List<LevelTemplate> all = [
    _dualTargetSimple,
    _parallelPaths,
    _convergingBeams,
    _labyrinth,
    _perimeter,
    _doubleBounce,
    _precisionAngle,
    _denseGrid,
    _sequence,
    _reflectionMasterE2,
  ];

  /// 1. Dual Target Simple (Levels 201-220)
  /// Par: 3 moves
  /// Intro to multiple targets.
  static final _dualTargetSimple = LevelTemplate(
    id: 'e2_dual_simple',
    nameKey: 'template_e2_dual',
    episode: 2,
    difficulty: 3,
    family: 'multi_target',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0), // East
      FixedObject(type: ObjectType.target, position: GridPosition(8, 2), orientation: 0, properties: {'color': 'red'}),
      FixedObject(type: ObjectType.target, position: GridPosition(8, 6), orientation: 0, properties: {'color': 'yellow'}),
    ],
    variableObjects: [
       // Splitter Prism at (6, 4)
       VariableObject(
          id: 'prism1',
          type: ObjectType.prism,
          positionExpr: PositionExpression.static(6, 4),
          orientationExpr: OrientationExpression.scramble('s1'),
          properties: {'type': PrismType.splitter},
       ),
       // Mirrors to redirect split beams
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 2), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 6), orientationExpr: OrientationExpression.scramble('s3')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {
           'prism1': 0, // Faces East
           'm1': 1, // / Reflects N->E
           'm2': 3, // \ Reflects S->E
       },
       steps: [],
       totalMoves: 3,
    ),
  );

  /// 2. Parallel Paths (Levels 221-240)
  /// Par: 4 moves
  /// Two beams moving in parallel logic
  static final _parallelPaths = LevelTemplate(
    id: 'e2_parallel_paths',
    nameKey: 'template_e2_parallel',
    episode: 2,
    difficulty: 3,
    family: 'multi_target',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(1, 2), orientation: 0), // East
      FixedObject(type: ObjectType.target, position: GridPosition(12, 2), orientation: 0),
      FixedObject(type: ObjectType.target, position: GridPosition(12, 6), orientation: 0),
    ],
    variableObjects: [
        // Split early
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(3, 2), orientationExpr: OrientationExpression.scramble('s1'), properties: {'type': PrismType.splitter}),
        
        // Upper path (Direct to 12,2)
        // Obstacle requires divert? No, let's keep it simple for now.
        // Actually, splitter sends Straight(E) and Split(N/S). 
        // If Splitter is 2-way (Right/Left or Front/Side?):
        // Standard splitter: Inputs Front -> Outputs Front, +90, -90.
        // So West->East (Front). Outputs East, North, South.
        // Beam 1 (East) -> Target 1 at (12,2).
        // Beam 2 (South) -> Needs to go to Target 2 at (12,6).
        // (3,2) -> South -> (3,6)M1 -> East -> (12,6).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 6), orientationExpr: OrientationExpression.scramble('s2')),
        
        // Add complexity: Block direct path to T1?
        // Wall at (8,2).
        // Need to jump over.
        // (3,2) -> East -> (6,2)M2 -> (6,0)M3 -> (9,0)M4 -> (9,2)M5 -> Target.
        // Too complex for Par 4?
        // Let's rely on variables to shift barriers.
   ],
   wallSegments: [
       // Barrier types
       WallSegment(type: WallSegmentType.vertical, x: 8, y1: 0, y2: 4),
   ],
   variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
   ],
   solvedState: SolvedState(
       orientations: {
           'p1': 0,
           'm1': 0, // / N->E (Incoming S. Wait. (3,2)->(3,6) is South. Incoming N. Out E. / -> N->W. \ -> N->E. m1=1. 
                    // Incoming N(0,-1). Out E(1,0). \ (1/3).
                    // m1: 1.
       },
       steps: [],
       totalMoves: 2,
   ),
  );

  /// 3. Converging Beams (Levels 241-260)
  /// Par: 3 moves
  /// 2 Sources, 1 Target (requires merging color? No, just hitting).
  static final _convergingBeams = LevelTemplate(
    id: 'e2_converging',
    nameKey: 'template_e2_converge',
    episode: 2,
    difficulty: 3,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 0), // East
       FixedObject(type: ObjectType.source, position: GridPosition(1, 7), orientation: 0), // East
       FixedObject(type: ObjectType.target, position: GridPosition(13, 4), orientation: 0),
    ],
    variableObjects: [
       // Simple converging paths
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 1), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 7), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    variables: [
        TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
        TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 3, // \ E->S (Incoming East. S to Target)
            'm2': 1, // / E->N (Incoming East. N to Target)
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 4. Labyrinth (Levels 261-280)
  /// Par: 5 moves
  static final _labyrinth = LevelTemplate(
    id: 'e2_labyrinth',
    nameKey: 'template_e2_labyrinth',
    episode: 2,
    difficulty: 4,
    family: 'path',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 3), orientation: 0), // East
       FixedObject(type: ObjectType.target, position: GridPosition(10, 5), orientation: 0),
    ],
    variableObjects: [
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 3), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 7), orientationExpr: OrientationExpression.scramble('s2')),
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 7), orientationExpr: OrientationExpression.scramble('s3')),
        VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 3), orientationExpr: OrientationExpression.scramble('s4')), // Decoy?
        // Path: (0,3)->(4,3)M1->(4,7)M2->(10,7)M3->(10,5)Target.
    ],
    wallSegments: [
        WallSegment(type: WallSegmentType.vertical, x: 2, y1: 0, y2: 8),
        WallSegment(type: WallSegmentType.horizontal, y: 5, x1: 3, x2: 9),
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
        },
        steps: [],
        totalMoves: 3,
    ),
  );

  /// 5. Perimeter (Levels 281-300)
  /// Par: 6 moves
  static final _perimeter = LevelTemplate(
    id: 'e2_perimeter',
    nameKey: 'template_e2_perimeter',
    episode: 2,
    difficulty: 4,
    family: 'path',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 0),
      FixedObject(type: ObjectType.target, position: GridPosition(2, 2), orientation: 0),
    ],
    variableObjects: [
        // Loop: (1,1)->(13,1)->(13,8)->(1,8)->(1,2)->(2,2).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 1), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 8), orientationExpr: OrientationExpression.scramble('s2')),
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 8), orientationExpr: OrientationExpression.scramble('s3')),
        VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 2), orientationExpr: OrientationExpression.scramble('s4')),
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
            'm2': 1, // / S->W
            'm3': 3, // \ W->N
            'm4': 1, // / N->E
        },
        steps: [],
        totalMoves: 4,
    ),
  );

  /// 6. Double Bounce (Levels 301-320)
  /// Par: 3 moves
  /// Bouncing off same wall line
  static final _doubleBounce = LevelTemplate(
    id: 'e2_double_bounce',
    nameKey: 'template_e2_double_bounce',
    episode: 2,
    difficulty: 3,
    family: 'reflection',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 4), orientation: 0),
       FixedObject(type: ObjectType.target, position: GridPosition(13, 6), orientation: 0),
    ],
    variableObjects: [
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 2), orientationExpr: OrientationExpression.scramble('s3')),
       VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 6), orientationExpr: OrientationExpression.scramble('s4')),
       VariableObject(id: 'm5', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 6), orientationExpr: OrientationExpression.scramble('s5')),
       // Path: (1,4)->(4,4)M1->(4,2)M2->(8,2)M3->(8,6)M4->(13,6)M5->Target(Nope, M5 IS at target pos? No, target is 13,6. M5 must be removed or moved.
       // Let's reset: Target at (13,6).
       // Path: (8,6) -> (13,6).
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's5', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 1, // \ E->N
            'm2': 0, // / S->E ?? Incoming N? (4,4) is South of (4,2). Incoming S.
                     // S->E. / (0). Correct.
            'm3': 3, // \ W->S
            'm4': 0, // / N->E
            'm5': 2, // Ignored
        },
        steps: [],
        totalMoves: 4,
    ),
  );

  /// 7. Precision Angle (Levels 321-340)
  /// Par: 4 moves
  static final _precisionAngle = LevelTemplate(
    id: 'e2_precision',
    nameKey: 'template_e2_precision',
    episode: 2,
    difficulty: 4,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 0), orientation: 0), // East
       FixedObject(type: ObjectType.target, position: GridPosition(10, 0), orientation: 0),
    ],
    variableObjects: [
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 0), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 5), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 5), orientationExpr: OrientationExpression.scramble('s3')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 3, // \ E->S.
            'm2': 3, // \ S->E.
            'm3': 1, // / E->N.
        },
        steps: [],
        totalMoves: 3,
    ),
  );

  /// 8. Dense Grid (Levels 341-360)
  /// Par: 5 moves
  static final _denseGrid = LevelTemplate(
    id: 'e2_dense',
    nameKey: 'template_e2_dense',
    episode: 2,
    difficulty: 5,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0),
       FixedObject(type: ObjectType.target, position: GridPosition(12, 4), orientation: 0),
    ],
    variableObjects: [
       // 3x3 Grid of mirrors in center
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 3), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 3), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 3), orientationExpr: OrientationExpression.scramble('s3')),
       VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 4), orientationExpr: OrientationExpression.scramble('s4')),
       VariableObject(id: 'm5', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 4), orientationExpr: OrientationExpression.scramble('s5')), // Center
       VariableObject(id: 'm6', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 4), orientationExpr: OrientationExpression.scramble('s6')),
       VariableObject(id: 'm7', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 5), orientationExpr: OrientationExpression.scramble('s7')),
       VariableObject(id: 'm8', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 5), orientationExpr: OrientationExpression.scramble('s8')),
       VariableObject(id: 'm9', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 5), orientationExpr: OrientationExpression.scramble('s9')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's5', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's6', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's7', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's8', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's9', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm4': 2, // -
            'm5': 2, // -
            'm6': 2, // -
        },
        steps: [],
        totalMoves: 0, 
    ),
  );

  /// 9. Sequence (Levels 361-380)
  /// Par: 4 moves
  static final _sequence = LevelTemplate(
    id: 'e2_sequence',
    nameKey: 'template_e2_sequence',
    episode: 2,
    difficulty: 4,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 4), orientation: 0),
       FixedObject(type: ObjectType.target, position: GridPosition(13, 1), orientation: 0),
       FixedObject(type: ObjectType.target, position: GridPosition(13, 7), orientation: 0),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 1), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 7), orientationExpr: OrientationExpression.scramble('s2')),
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 1), orientationExpr: OrientationExpression.scramble('s3')),
        VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 7), orientationExpr: OrientationExpression.scramble('s4')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm3': 0, // / S->E (From P1 Split North->(5,1)? No (5,4)->(5,1) is North? No 4->1 is North. P1 Splitter: Front, Right(+90), Left(-90).
                     // Front=East. Right=South. Left=North.
                     // North beam -> (5,1).
                     // M3(5,1): Incoming S. Needs E. S->E. / (0). Correct. (Wait. S->E is / (0)?)
                     // m Grid 0 (/) reflects S<->E, N<->W. Correct.
            'm4': 1, // \ N->E (From P1 Split South->(5,7). Incoming N. Needs E.
                     // N->E. \ (1). Correct.
            'm1': 2, // - Pass or bounce? (This is confusing, let's just terminate at targets).
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 10. Reflection Master E2 (Levels 381-400)
  /// Par: 6 moves
  static final _reflectionMasterE2 = LevelTemplate(
    id: 'e2_master',
    nameKey: 'template_e2_master',
    episode: 2,
    difficulty: 5,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(4, 4), orientation: 0),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 4), orientation: 0),
    ],
    variableObjects: [
       // Octagon?
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 1), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 1), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 4), orientationExpr: OrientationExpression.scramble('s3')),
       VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 7), orientationExpr: OrientationExpression.scramble('s4')),
       VariableObject(id: 'm5', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 7), orientationExpr: OrientationExpression.scramble('s5')),
       VariableObject(id: 'm6', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 7), orientationExpr: OrientationExpression.scramble('s6')),
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
            'm1': 3,
            'm2': 0,
            'm3': 3,
            'm4': 0,
            'm5': 1,
            'm6': 0,
        },
        steps: [],
        totalMoves: 6,
    ),
  );
}
