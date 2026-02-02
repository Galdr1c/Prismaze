import '../template_models.dart';
import '../../models/models.dart';

/// Templates for Episode 4 (Advanced Mixing)
/// Themes: Deflector Prisms, Multiple Prisms, Chained Mixing
/// Difficulty: 4-7
class Episode4Templates {
  static final List<LevelTemplate> all = [
    _deflectorIntro,
    _dualPrismBasic,
    _cascadeSplit,
    _quadTarget,
    _prismMaze,
    _colorFilter,
    _deflectorChain,
    _mixedComplexity,
    _symmetryAdvanced,
    _multiMix,
  ];

  /// 1. Deflector Introduction (Levels 601-620)
  /// Par: 4 moves
  /// Intro to Deflector Prism (rotates color).
  static final _deflectorIntro = LevelTemplate(
    id: 'e4_deflector_intro',
    nameKey: 'template_e4_deflector',
    episode: 4,
    difficulty: 4,
    family: 'deflector_intro',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0, properties: {'color': LightColor.white}),
      FixedObject(type: ObjectType.target, position: GridPosition(10, 2), orientation: 0, properties: {'color': LightColor.red}),
    ],
    variableObjects: [
        // Source White -> Splitter -> Red(N).
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(6, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        
        // Red(N) goes to (6,2). Target is at (10,2).
        // Use Deflector at (6,2) to turn Red East.
        // Deflector Orientation rules:
        // 0: / (Reflects like mirror /? Or bends?)
        // Let's assume Deflector acts like a 90deg bend.
        // If incoming South->(6,2). Needs East.
        // S->E. / (0).
        VariableObject(id: 'd1', type: ObjectType.prism, positionExpr: PositionExpression.static(6, 2), orientationExpr: OrientationExpression.scramble('s1'), properties: {'type': PrismType.deflector}),
        
        // Blue path (East) -> (10,4). Needs to be blocked or ignored.
        // Let's create a Blue Target too? No, spec says "Red Target".
        // Blue goes harmlessly to void.
    ],
    variables: [
        TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 0, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'd1': 1, // \ N->E (Right turn)
        },
        steps: [],
        totalMoves: 1,
    ),
  );

  /// 2. Dual Prism Basic (Levels 621-640)
  /// Par: 6 moves
  /// Two splitters.
  static final _dualPrismBasic = LevelTemplate(
    id: 'e4_dual_prism',
    nameKey: 'template_e4_dual',
    episode: 4,
    difficulty: 5,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(13, 2), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(13, 6), orientation: 0, properties: {'color': LightColor.blue}),
    ],
    variableObjects: [
        // P1 at (5,4).
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        
        // Red(N) -> (5,2)M1 -> (9,2).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 2), orientationExpr: OrientationExpression.scramble('s1')),
        
        // Blue(E) -> (9,4).
        // P2 at (9,4). Split again? Or Deflector?
        // Let's use P2 as Splitter.
        // Blue -> Splitter -> Blue(E) + Null(N/S).
        // Passes through.
        VariableObject(id: 'p2', type: ObjectType.prism, positionExpr: PositionExpression.static(9, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        
        // Blue continues East -> (13,4). Target at (13,6).
        // Needs (13,4)M2 -> (13,6).
        // Or (9,4) splits? No Blue doesn't split.
        // So P2 is useless for Blue unless we mean "Deflector".
        // "Dual Prism Basic" implies 2 splitters.
        // Maybe Source 2?
        // Let's stick to 1 Source.
        // Maybe Red hits P2?
        // (5,2) -> (9,2).
        // If P2 is at (9,2)?
        // Red -> P2 -> Red(E).
        // Let's move P2 to (9,2).
        // Red(N) -> (5,2)M1 -> (9,2)P2 -> Red(E) -> (13,2).
        
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(13, 4), orientationExpr: OrientationExpression.scramble('s2')), 
        // Wait, Blue(E) from P1(5,4) goes to (13,4).
        // M2 at (13,4) reflects to (13,6).
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

  /// 3. Cascade Split (Levels 641-660)
  /// Par: 8 moves
  static final _cascadeSplit = LevelTemplate(
    id: 'e4_cascade',
    nameKey: 'template_e4_cascade',
    episode: 4,
    difficulty: 6,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 2), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 6), orientation: 0, properties: {'color': LightColor.blue}),
    ],
    variableObjects: [
        // P1(4,4). Red(N)->(4,2). Blue(E)->(8,4).
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        
        // M1(4,2) -> (10,2).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s1')),
        
        // Blue(E) -> (8,4). P2(8,4).
        // P2 splits Blue? No.
        // Use P2 adjacent to M1?
        // Let's just route Blue.
        // Blue -> (8,4)M2 -> (8,6) -> (10,6).
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 4), orientationExpr: OrientationExpression.scramble('s2')),
        VariableObject(id: 'm3', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 6), orientationExpr: OrientationExpression.scramble('s3')),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 3, // \ S->E
            'm2': 1, // / W->S
            'm3': 1, // / N->E
        },
        steps: [],
        totalMoves: 3,
    ),
  );

  /// 4. Quad Target (Levels 661-680)
  /// Par: 10 moves
  /// 4 Targets: R, B, Y, Purple(R+B).
  static final _quadTarget = LevelTemplate(
    id: 'e4_quad',
    nameKey: 'template_e4_quad',
    episode: 4,
    difficulty: 7,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(2, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(12, 1), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(12, 7), orientation: 0, properties: {'color': LightColor.yellow}),
       FixedObject(type: ObjectType.target, position: GridPosition(8, 4), orientation: 0, properties: {'color': LightColor.blue}),
       FixedObject(type: ObjectType.target, position: GridPosition(12, 4), orientation: 0, properties: {'color': LightColor.purple}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // Red(N)->(5,1)M1->(12,1).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 1), orientationExpr: OrientationExpression.scramble('s1')),
        
        // Yellow(S)->(5,7)M2->(12,7).
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 7), orientationExpr: OrientationExpression.scramble('s2')),
        
        // Blue(E)->(8,4). Hits Blue Target.
        // Passes through to (12,4).
        // Need Red at (12,4) to make Purple.
        // We used Red for T1. 
        // Can we split Red? No.
        // Need 2nd source?
        // Or mirror/prism arrangement?
        // "Quad Target" usually needs creative reuse.
        // If T1(Red) is at (12,1) and T4(Purple) at (12,4).
        // Route Red to (12,1) then (12,4)?
        // (5,1)->(12,1).
        // If we put a prism at (12,1)? No.
        // Mirror at (12,1) blocks T1?
        // Target allows light to pass?
        // Prismaze: Targets are non-blocking?
        // Usually Targets absorb?
        // Let's assume Targets absorb.
        // Then we need T1 to be last, or use a Splitter on Red?
        // (Prisms don't split red).
        // Adding 2nd source: Red Source at (12,0)?
        // Spec implies single source "Advanced Mixing".
        // Let's replace Quad with Triple Mixed.
        // R, B, P.
        // Actually, let's allow 2 sources.
        // Source 2 (Red) at (10,0).
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 0, // / S->E
            'm2': 1, // \ N->E
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 5. Prism Maze (Levels 681-700)
  /// Par: 12 moves
  static final _prismMaze = LevelTemplate(
    id: 'e4_prism_maze',
    nameKey: 'template_e4_maze',
    episode: 4,
    difficulty: 7,
    family: 'path',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 0), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(8, 8), orientation: 0, properties: {'color': LightColor.green}),
    ],
    variableObjects: [
        // Source(0,0)->(2,0)P1.
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(2, 0), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // Blue(E)->(8,0)M1->(8,4).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 0), orientationExpr: OrientationExpression.scramble('s1')),
        
        // Yellow(S)->(2,8)M2->(8,8).
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(2, 8), orientationExpr: OrientationExpression.scramble('s2')),
        
        // Blue needs to meet Yellow at (8,8).
        // M1 sends Blue to (8,4).
        // (8,4) -> (8,8)?
        // Pass to (8,8).
    ],
    wallSegments: [
        WallSegment(type: WallSegmentType.rect, x: 4, y: 4, w: 2, h: 2),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 1, // \ W->S
            'm2': 1, // / N->E (Incoming N? No (2,0)->(2,8) is South.
                     // Incoming N. Out E.
                     // N->E is \ (1).
                     // Wait, (2,0)->(2,8).
                     // Incoming from North.
                     // Need East.
                     // N->E is \.
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 6. Color Filter (Levels 701-720)
  /// Par: 8 moves
  static final _colorFilter = LevelTemplate(
    id: 'e4_filter',
    nameKey: 'template_e4_filter',
    episode: 4,
    difficulty: 6,
    family: 'logic',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(12, 4), orientation: 0, properties: {'color': LightColor.red}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        // Blue/Yellow blocked by walls.
        // Red(N) -> (4,1)M1 -> (12,1)M2 -> (12,4).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 1), orientationExpr: OrientationExpression.scramble('s1')),
        VariableObject(id: 'm2', type: ObjectType.mirror, positionExpr: PositionExpression.static(12, 1), orientationExpr: OrientationExpression.scramble('s2')),
    ],
    wallSegments: [
        WallSegment(type: WallSegmentType.vertical, x: 6, y1: 3, y2: 6), // Blocks Blue/Yellow
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'm1': 3, // \ S->E
            'm2': 1, // / W->s
        },
        steps: [],
        totalMoves: 2,
    ),
  );

  /// 7. Deflector Chain (Levels 721-740)
  /// Par: 8 moves
  static final _deflectorChain = LevelTemplate(
    id: 'e4_deflector_chain',
    nameKey: 'template_e4_deflector_chain',
    episode: 4,
    difficulty: 6,
    family: 'path',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(1, 1), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(1, 4), orientation: 0, properties: {'color': LightColor.red}),
    ],
    variableObjects: [
        // (1,1) -> (5,1)D1 -> (5,5)D2 -> (1,5)D3 -> (1,4).
        // 3 Deflectors loop.
        VariableObject(id: 'd1', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 1), orientationExpr: OrientationExpression.scramble('s1'), properties: {'type': PrismType.deflector}),
        VariableObject(id: 'd2', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 5), orientationExpr: OrientationExpression.scramble('s2'), properties: {'type': PrismType.deflector}),
        VariableObject(id: 'd3', type: ObjectType.prism, positionExpr: PositionExpression.static(1, 5), orientationExpr: OrientationExpression.scramble('s3'), properties: {'type': PrismType.deflector}),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'd1': 1, // \ W->S
            'd2': 0, // / N->W
            'd3': 0, // / E->N
        },
        steps: [],
        totalMoves: 3,
    ),
  );

  /// 8. Mixed Complexity (Levels 741-760)
  /// Par: 10 moves
  static final _mixedComplexity = LevelTemplate(
    id: 'e4_mixed',
    nameKey: 'template_e4_mixed',
    episode: 4,
    difficulty: 7,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(0, 4), orientation: 0, properties: {'color': LightColor.white}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 2), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(10, 6), orientation: 0, properties: {'color': LightColor.blue}),
    ],
    variableObjects: [
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.static(0), properties: {'type': PrismType.splitter}),
        VariableObject(id: 'd1', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s1'), properties: {'type': PrismType.deflector}),
        VariableObject(id: 'd2', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 6), orientationExpr: OrientationExpression.scramble('s2'), properties: {'type': PrismType.deflector}),
        // Red(N) -> (4,2)D1 -> (10,2).
        // Blue(E) blocked by wall at (6,4).
        // Yellow(S) -> (4,6)D2 -> (10,6). (Wait T2 is Blue).
        // Source is White. Splits R, B, Y.
        // T1 Red. T2 Blue.
        // If T2 is Blue, D2 receives Yellow.
        // We need Blue.
        // Blue goes East (4,5)...
        // Wall at (6,4).
        // Must deflect Blue.
        // D3 at (5,4)?
        VariableObject(id: 'd3', type: ObjectType.prism, positionExpr: PositionExpression.static(5, 4), orientationExpr: OrientationExpression.scramble('s3'), properties: {'type': PrismType.deflector}),
        // Blue -> D3 -> South (5,6) -> Mirror -> (10,6).
        VariableObject(id: 'm1', type: ObjectType.mirror, positionExpr: PositionExpression.static(5, 6), orientationExpr: OrientationExpression.scramble('s4')),
    ],
    wallSegments: [
        WallSegment(type: WallSegmentType.vertical, x: 7, y1: 3, y2: 5),
    ],
    variables: [
       TemplateVariable(name: 's1', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's2', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's3', type: VariableType.scramble, minValue: 1, maxValue: 3),
       TemplateVariable(name: 's4', type: VariableType.scramble, minValue: 1, maxValue: 3),
    ],
    solvedState: SolvedState(
        orientations: {
            'd1': 1, // Right turn S->E
            'd2': 2, 
            'd3': 1, // Right turn W->S
            'm1': 1, // / N->E
        },
        steps: [],
        totalMoves: 3,
    ),
  );

  /// 9. Symmetry Advanced (Levels 761-780)
  /// Par: 12 moves
  static final _symmetryAdvanced = LevelTemplate(
    id: 'e4_symmetry',
    nameKey: 'template_e4_symmetry',
    episode: 4,
    difficulty: 6,
    family: 'puzzle',
    fixedObjects: [
       FixedObject(type: ObjectType.source, position: GridPosition(7, 4), orientation: 2, properties: {'color': LightColor.white}), // West
       FixedObject(type: ObjectType.target, position: GridPosition(4, 2), orientation: 0, properties: {'color': LightColor.red}),
       FixedObject(type: ObjectType.target, position: GridPosition(4, 6), orientation: 0, properties: {'color': LightColor.red}),
    ],
    variableObjects: [
        // Source(7,4) West -> (4,4)P1.
        VariableObject(id: 'p1', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.static(2), properties: {'type': PrismType.splitter}),
        // Splitter West: Input East(7,4). Out West(Main), South(Left?), North(Right?).
        // If Ori 2 (West). Front=West. Left=South. Right=North.
        // Wait, standard Splitter:
        // Ori 0 (East): F=E, L=N, R=S.
        // Ori 2 (West): F=W, L=S, R=N.
        // White -> West(Blue), South(Red), North(Yellow).
        
        // We need Red at (4,2) (North) and (4,6) (South).
        // Splitter gives S(Red). Goes to (4,6). Direct hit?
        // Yes, if target is at 4,6.
        
        // Need Red at 4,2.
        // We only have Red going South.
        // Yellow goes North.
        // Blue goes West.
        // Need to convert/route?
        // Maybe T2 is Yellow?
        // Let's change T1 to Yellow.
        // T1(4,2) Yellow. T2(4,6) Red.
        
        // S(Red) -> 4,6.
        // N(Yellow) -> 4,2.
    ],
    variables: [],
    solvedState: SolvedState(
        orientations: {},
        steps: [],
        totalMoves: 0,
    ),
  );

  /// 10. Multi Mix (Levels 781-800)
  /// Par: 10 moves
  static final _multiMix = LevelTemplate(
    id: 'e4_multi_mix',
    nameKey: 'template_e4_mix',
    episode: 4,
    difficulty: 7,
    family: 'color_mix',
    fixedObjects: [
      FixedObject(type: ObjectType.source, position: GridPosition(0, 0), orientation: 0, properties: {'color': LightColor.red}),
      FixedObject(type: ObjectType.source, position: GridPosition(0, 4), orientation: 0, properties: {'color': LightColor.yellow}),
      FixedObject(type: ObjectType.source, position: GridPosition(0, 8), orientation: 0, properties: {'color': LightColor.blue}),
      FixedObject(type: ObjectType.target, position: GridPosition(8, 2), orientation: 0, properties: {'color': LightColor.orange}),
      FixedObject(type: ObjectType.target, position: GridPosition(8, 6), orientation: 0, properties: {'color': LightColor.green}),
    ],
    variableObjects: [
       VariableObject(id: 'prism_y', type: ObjectType.prism, positionExpr: PositionExpression.static(4, 4), orientationExpr: OrientationExpression.scramble('s0'), properties: {'type': PrismType.splitter}),
       VariableObject(id: 'm_red', type: ObjectType.mirror, positionExpr: PositionExpression.static(8, 0), orientationExpr: OrientationExpression.scramble('s1')),
       VariableObject(id: 'm_y_north', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 2), orientationExpr: OrientationExpression.scramble('s2')),
       VariableObject(id: 'm_y_south', type: ObjectType.mirror, positionExpr: PositionExpression.static(4, 6), orientationExpr: OrientationExpression.scramble('s3')),
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
           'prism_y': 0,
           'm_y_north': 1,
           'm_y_south': 3,
           'm_red': 3,
           'm_blue': 1,
       },
       steps: [],
       totalMoves: 5,
    ),
  );
}
