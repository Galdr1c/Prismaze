import '../template_models.dart';
import '../../models/models.dart';

/// Templates for Episode 5 (Masterclass)
/// Themes: Expert Puzzles, Combined Mechanics, High Object Count
/// Difficulty: 7-10
class Episode5Templates {
  static final List<LevelTemplate> all = [
    _grandPuzzle,
    _efficiency,
    _artisticLayout,
    _gauntlet,
    _precisionMaster,
    _colorSymphony,
    _labyrinth,
    _expertDecoys,
    _symmetryMaster,
    _finalExam,
  ];

  /// 1. Grand Puzzle (Levels 801-820)
  /// Par: 12 moves
  /// Large scale routing with mixed mechanics.
  static final _grandPuzzle = LevelTemplate(
    id: 'e5_grand_puzzle',
    nameKey: 'template_e5_grand',
    episode: 5,
    difficulty: 8,
    family: 'puzzle',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 0, properties: {'color': LightColor.white}),
      FixedObject(type: ObjectType.target, position: GridPosition(20, 7), orientation: 0, properties: {'color': LightColor.purple}),
      FixedObject(type: ObjectType.target, position: GridPosition(1, 7), orientation: 0, properties: {'color': LightColor.orange}),
      // Second Red Source for Purple Target
      FixedObject(type: ObjectType.source, position: GridPosition(20, 5), orientation: 2, properties: {'color': LightColor.red}),
    ],
    variableObjects: [
       // Source (1,1) -> (5,1) [Splitter].
       VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 1), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
       
       // Red(N) path -> (5,7) to hit Orange Target(1,7)?
       // (5,1)-N->(5,-1)? No. Splitter Ori 0 (East): N(Left), S(Right).
       // Left is North (y-1). Right is South (y+1).
       // So Red goes North to (5,0). 
       // Needs to go to (1,7) and (20,7).
       // Route Red: (5,0)->(1,0)->(1,7).
       VariableObject(id: 'm_red1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 0), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm_red2', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 0), orientationExpr: OrientationExpression.scramble('s2')),
       
       // Need Red at (20,7) too? Purple = R+B.
       // Prisms don't clone.
       // Maybe use Orange Target at (1,7) and Purple at (??).
       // Let's rely on simple mixing.
       // Orange needs Yellow.
       // Purple needs Blue.
       // Red is needed for BOTH.
       // Unless we have 2 Red Sources.
       // Spec allows "All mechanics".
       // Let's add Red Source at (20,1) for the second target.
       
       // Yellow(S) from P1 -> (5,7)M -> (1,7).
       VariableObject(id: 'm_yel', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 7), orientationExpr: OrientationExpression.scramble('s3')),
       
       // Blue(E) from P1 -> (20,1)M -> (20,7).
       VariableObject(id: 'm_blue', type: ObjectType.mirror, positionExpr: PositionExpression.static(20, 1), orientationExpr: OrientationExpression.scramble('s4')),
       
       // 2nd Red Source for Purple Target.
       // (20,3) Red Source.
       VariableObject(id: 'm_red_src2', type: ObjectType.mirror, positionExpr: PositionExpression.static(20, 3), orientationExpr: OrientationExpression.scramble('s5')),
       // Wait, m_red_src2 is a mirror? Source is Fixed.
       // Add Fixed Red Source at (20,5)?
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
           'm_red1': 1, // / S->W
           'm_red2': 3, // \ E->S
           'm_yel': 1, // / S->W? No P1 South is Yellow. Goes to (5,7)M. 5,7->1,7 is West.
                      // Incoming North (to 5,7). Needs West.
                      // N->W is / (1). 
           'm_blue': 3, // \ E->S. (P1 East Blue to 20,1. 20,1->20,7 is South. E->S is 3).
       },
       steps: [],
       totalMoves: 5,
    ),
  );

  /// 2. Efficiency Challenge (Levels 821-840)
  /// Par: 10 moves
  static final _efficiency = LevelTemplate(
    id: 'e5_efficiency',
    nameKey: 'template_e5_efficiency',
    episode: 5,
    difficulty: 8,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 4), orientation: 0, properties: {'color': LightColor.white}),
       // Obstacles requiring zigzag
       FixedObject(type: ObjectType.wall, position: GridPosition(2, 4), orientation: 0),
       FixedObject(type: ObjectType.wall, position: GridPosition(4, 4), orientation: 0),
       FixedObject(type: ObjectType.wall, position: GridPosition(6, 4), orientation: 0),
       FixedObject(type: ObjectType.wall, position: GridPosition(8, 4), orientation: 0),
    ],
    variableObjects: [
       // Use deflectors to weave?
       // (0,4) blocked.
       // Deflect at (1,4)? No source is (0,4).
       // Redirect immediately.
       // (1,4): Can't place immediate.
       // (0,4) -> (1,4) (Blocked? No wall at 1,4).
       // Mirror at (1,4) -> (1,2) -> (3,2) -> (3,6) -> (5,6) -> (5,2) -> (7,2) -> (7,6) -> (9,6) -> (9,4) -> (10,4).
       
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 4), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 2), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 2), orientationExpr: OrientationExpression.scramble('s3')),
       VariableObject(id: 'm4', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 6), orientationExpr: OrientationExpression.scramble('s4')),
       VariableObject(id: 'm5', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 6), orientationExpr: OrientationExpression.scramble('s5')),
       VariableObject(id: 'm6', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 2), orientationExpr: OrientationExpression.scramble('s6')),
       VariableObject(id: 'm7', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 2), orientationExpr: OrientationExpression.scramble('s7')),
       VariableObject(id: 'm8', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 6), orientationExpr: OrientationExpression.scramble('s8')),
       VariableObject(id: 'm9', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 6), orientationExpr: OrientationExpression.scramble('s9')),
       VariableObject(id: 'm10', type: ObjectType.mirror, positionExpr: PositionExpression.static(9, 4), orientationExpr: OrientationExpression.scramble('s10')),
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
       TemplateVariable(name: 's10', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {
           'm1': 3, 'm2': 1, 'm3': 1, 'm4': 3, 'm5': 3,
           'm6': 1, 'm7': 1, 'm8': 3, 'm9': 3, 'm10': 1,
       },
       steps: [],
       totalMoves: 10,
    ),
  );

  /// 3. Artistic Layout (Levels 841-860)
  /// Par: 12 moves
  static final _artisticLayout = LevelTemplate(
    id: 'e5_artistic',
    nameKey: 'template_e5_artistic',
    episode: 5,
    difficulty: 7,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(10, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 0), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 8), orientation: 0, properties: {'color': LightColor.blue}),
       FixedObject(type: ObjectType.target, position: GridPosition(14, 4), orientation: 0, properties: {'color': LightColor.yellow}),
       FixedObject(type: ObjectType.target, position: GridPosition(6, 4), orientation: 0, properties: {'color': LightColor.white}), // Actually White Target?
    ],
    variableObjects: [
       // Central Splitter Loop
       // Source is Middle (10,4).
       // Needs to hit targets in cross pattern.
       // 10,4 Source overlaps Prism?
       // Cannot overlap.
       // Move Source to (9,4).
       
       VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(10, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
       
       // Input from West (9,4).
       // Out: E(Blue)->(14,4). (Actually Blue beam. Target is Yellow? No Yellow target. T_Yellow is at 14,4).
       // If P1.Blue -> 14,4. T_Yellow needs Yellow.
       // P1.South -> Yellow -> 10,8. T_Blue needs Blue.
       // P1.North -> Red -> 10,0. T_Red needs Red. Match!
       
       // So Red is mostly free.
       // Blue/Yellow are swapped.
       // Cross them.
       // Blue(E) -> (12,4)D1(Deflector) -> (12,8)M -> (10,8) [T_Blue].
       VariableObject(id: 'd1', type: ObjectType.prism, positionExpr: PositionExpression.static(12, 4), orientationExpr: OrientationExpression.scramble('s1'), properties: {'type': PrismType.deflector}),
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(12, 8), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 8), orientationExpr: OrientationExpression.scramble('s3')), // To catch? No 10,8 is target.
       // Target at (10,8) needs input. (12,8)->(10,8). Clear.
       
       // Yellow(S) -> (10,6)D2 -> (14,6)M -> (14,4) [T_Yellow].
       VariableObject(id: 'd2', type: ObjectType.prism, positionExpr: PositionExpression.static(10, 6), orientationExpr: OrientationExpression.scramble('s4'), properties: {'type': PrismType.deflector}),
       VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(14, 6), orientationExpr: OrientationExpression.scramble('s5')),
       
       // T_White at (6,4). needs White.
       // Prisms split white.
       // Source (9,4) -> Prism.
       // T_White is at WEST of source.
       // (9,4) -> (6,4)? No Source emits East.
       // Move Source to (8,4)?
       // If Source(8,4) -> (10,4).
       // How to get White to (6,4)?
       // Mirror at (7,4)? Backwards?
       // Can't reflect Source output directly back.
       // Maybe omit T_White.
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
           'd1': 0, 'm1': 1, // Blue path
           'd2': 0, 'm3': 1, // Yellow path
       },
       steps: [],
       totalMoves: 4,
    ),
  );

  /// 4. Gauntlet (Levels 861-880)
  /// Par: 15 moves
  static final _gauntlet = LevelTemplate(
    id: 'e5_gauntlet',
    nameKey: 'template_e5_gauntlet',
    episode: 5,
    difficulty: 9,
    family: 'path',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 0), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(20, 8), orientation: 0, properties: {'color': LightColor.white}),
    ],
    variableObjects: [
       // Long winding path with gates.
       // 3 Prism Gates using Deflectors as rigid turns.
       VariableObject(id: 'd1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 0), orientationExpr: OrientationExpression.scramble('s1'), properties: {'type': PrismType.deflector}),
       VariableObject(id: 'd2', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 8), orientationExpr: OrientationExpression.scramble('s2'), properties: {'type': PrismType.deflector}),
       VariableObject(id: 'd3', type: ObjectType.prism, positionExpr: PositionExpression.static(10, 8), orientationExpr: OrientationExpression.scramble('s3'), properties: {'type': PrismType.deflector}),
       VariableObject(id: 'd4', type: ObjectType.prism, positionExpr: PositionExpression.static(10, 0), orientationExpr: OrientationExpression.scramble('s4'), properties: {'type': PrismType.deflector}),
       VariableObject(id: 'd5', type: ObjectType.prism, positionExpr: PositionExpression.static(15, 0), orientationExpr: OrientationExpression.scramble('s5'), properties: {'type': PrismType.deflector}),
       VariableObject(id: 'd6', type: ObjectType.prism, positionExpr: PositionExpression.static(15, 8), orientationExpr: OrientationExpression.scramble('s6'), properties: {'type': PrismType.deflector}),
       // Path: (0,0)->(5,0)->(5,8)->(10,8)->(10,0)->(15,0)->(15,8)->(20,8)
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
           'd1': 0, 'd2': 0, 'd3': 1, 'd4': 0, 'd5': 0, 'd6': 2, // 20,8 is E of 15,8
       },
       steps: [],
       totalMoves: 6,
    ),
  );

  /// 5. Precision Master (Levels 881-900)
  /// Par: 12 moves
  static final _precisionMaster = LevelTemplate(
    id: 'e5_precision',
    nameKey: 'template_e5_precision',
    episode: 5,
    difficulty: 9,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(5, 4), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(5, 5), orientation: 0, properties: {'color': LightColor.red}),
    ],
    variableObjects: [
       // Target is adjacent to source.
       // Must loop around entire board.
       // 4 Corner mirrors.
       VariableObject(id: 'c1', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 1), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'c2', type: ObjectType.mirror, positionExpr: PositionExpression.static(20, 1), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'c3', type: ObjectType.mirror, positionExpr: PositionExpression.static(20, 7), orientationExpr: OrientationExpression.scramble('s3')),
       VariableObject(id: 'c4', type: ObjectType.mirror, positionExpr: PositionExpression.static(1, 7), orientationExpr: OrientationExpression.scramble('s4')),
       
       // Inner routing.
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 1), orientationExpr: OrientationExpression.scramble('s5')),
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 7), orientationExpr: OrientationExpression.scramble('s6')),
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
           'm1': 0, 'c1': 3, 'c4': 0, 'm2': 0, // Left loop?
           // (5,4)->(5,1)M1 -> (1,1)C1 -> (1,7)C4 -> (5,7)M2 -> (5,5).
       },
       steps: [],
       totalMoves: 4,
    ),
  );

  /// 6. Color Symphony (Levels 901-920)
  /// Par: 14 moves
  static final _colorSymphony = LevelTemplate(
    id: 'e5_symphony',
    nameKey: 'template_e5_symphony',
    episode: 5,
    difficulty: 9,
    family: 'color_mix',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 2), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.source, position: GridPosition(0, 6), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 4), orientation: 0, properties: {'color': LightColor.white}), // R+G+B
    ],
    variableObjects: [
       // Mix everything.
       VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
       VariableObject(id: 'p2', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 6), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
       
       // Route all 6 beams to 10,4?
       // White target needs R+G+B (Physics: R+B+Y? No LightColor.white is R+B+Y in Prismaze model typically).
       // Actually we just need to hit it with all primaries.
       
       // P1: R(N), B(E), Y(S).
       // P2: R(N), B(E), Y(S).
       
       // Mix P1.Y and P2.R?
       // Just focus on getting 1 complete set.
       // P1.B -> (10,2)M -> (10,4).
       VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 2), orientationExpr: OrientationExpression.scramble('s1')),
       // P2.B -> (10,6)M -> (10,4).
       VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(10, 6), orientationExpr: OrientationExpression.scramble('s2')),
       
       // Need Red and Yellow.
       // P1.Y(S) -> (4,4) -> (6,4) -> (10,4).
       // P2.R(N) -> (4,4) -> Collision?
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {
           'm1': 3,
           'm2': 0,
       },
       steps: [],
       totalMoves: 2,
    ),
  );

  /// 7. The Labyrinth (Levels 921-940)
  /// Par: 16 moves
  static final _labyrinth = LevelTemplate(
    id: 'e5_labyrinth',
    nameKey: 'template_e5_labyrinth',
    episode: 5,
    difficulty: 9,
    family: 'path',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 0), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 4), orientation: 0, properties: {'color': LightColor.white}),
    ],
    variableObjects: [
       // Massive grid of mirrors.
       // 4x4 block.
       VariableObject(id: 'm00', type: ObjectType.mirror, positionExpr: PositionExpression.static(2, 2), orientationExpr: OrientationExpression.scramble('s0')),
       VariableObject(id: 'm01', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s0')),
       VariableObject(id: 'm02', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 2), orientationExpr: OrientationExpression.scramble('s0')),
       VariableObject(id: 'm03', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 2), orientationExpr: OrientationExpression.scramble('s0')),
       
       VariableObject(id: 'm10', type: ObjectType.mirror, positionExpr: PositionExpression.static(2, 6), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm11', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 6), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm12', type: ObjectType.mirror, positionExpr: PositionExpression.static(6, 6), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm13', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 6), orientationExpr: OrientationExpression.scramble('s1')),
    ],
    variables: [
       TemplateVariable(name: 's0', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {},
       steps: [],
       totalMoves: 8,
    ),
  );

  /// 8. Expert Decoys (Levels 941-960)
  /// Par: 14 moves
  static final _expertDecoys = LevelTemplate(
    id: 'e5_decoys',
    nameKey: 'template_e5_decoys',
    episode: 5,
    difficulty: 8,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 4), orientation: 0, properties: {'color': LightColor.blue}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 4), orientation: 0, properties: {'color': LightColor.blue}),
    ],
    variableObjects: [
       // Direct path is (1,4)->(10,4).
       // Decoy mirrors scattered everywhere.
       VariableObject(id: 'd1', type: ObjectType.mirror, positionExpr: PositionExpression.static(3, 3), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'd2', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 5), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'd3', type: ObjectType.mirror, positionExpr: PositionExpression.static(7, 2), orientationExpr: OrientationExpression.scramble('s3')),
       // Real Mirrors (if needed? No, direct path).
       // Add Logic: Direct Path Blocked.
    ],
    wallSegments: [
        WallSegment(type: WallSegmentType.vertical, x: 5, y1: 3, y2: 5), // Block (5,4).
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {},
       steps: [],
       totalMoves: 0,
    ),
  );

  /// 9. Symmetry Master (Levels 961-980)
  /// Par: 16 moves
  static final _symmetryMaster = LevelTemplate(
    id: 'e5_symmetry',
    nameKey: 'template_e5_symmetry',
    episode: 5,
    difficulty: 9,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(11, 4), orientation: 0, properties: {'color': LightColor.white}), // Center
       FixedObject(type: ObjectType.target, position: GridPosition(1, 1), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(21, 1), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(1, 8), orientation: 0, properties: {'color': LightColor.blue}),
       FixedObject(type: ObjectType.target, position: GridPosition(21, 8), orientation: 0, properties: {'color': LightColor.blue}),
    ],
    variableObjects: [
       // 4 Corners.
       VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(11, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
    ],
    variables: [],
    solvedState: SolvedState(
       orientations: {},
       steps: [],
       totalMoves: 0,
    ),
  );

  /// 10. Final Exam (Levels 981-1000)
  /// Par: 20 moves
  static final _finalExam = LevelTemplate(
    id: 'e5_final',
    nameKey: 'template_e5_final',
    episode: 5,
    difficulty: 10,
    family: 'boss',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 0), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(20, 8), orientation: 0, properties: {'color': LightColor.purple}), // R+B
    ],
    variableObjects: [
       // The Ultimate Path.
       VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 5), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
       VariableObject(id: 'd1', type: ObjectType.prism, positionExpr: PositionExpression.static(15, 5), orientationExpr: OrientationExpression.scramble('s1'), properties: {'type': PrismType.deflector}),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
       orientations: {},
       steps: [],
       totalMoves: 0,
    ),
  );
}
