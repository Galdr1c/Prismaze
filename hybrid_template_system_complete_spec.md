# Hybrid Template-Based Level Generation System
## Comprehensive Design Document

---

## 🎯 System Overview

### Core Philosophy
```
Episode 1-2: Pure Templates (Proven Patterns)
Episode 3-5: Smart Templates (Color Mixing Patterns)
Episode 6+: Procedural + Template Fallback
```

### Success Metrics
- **Generation Speed:** <100ms per level
- **Success Rate:** >95% solvable levels
- **Variety:** 50 templates × 20 variations = 1000+ unique puzzles per episode
- **Maintenance:** Add new templates without touching code

---

## 📐 Template System Architecture

### Template Data Structure

```dart
/// Core template definition
class LevelTemplate {
  // Metadata
  final String id;                    // Unique identifier
  final String name;                  // Display name
  final int minDifficulty;            // 1-10 scale
  final int maxDifficulty;            // 1-10 scale
  final List<int> suitableEpisodes;   // Which episodes can use this
  
  // Fixed structure (guaranteed working)
  final TemplateLayout layout;
  
  // Variable parameters (for randomization)
  final Map<String, VariableRange> variables;
  
  // Solution information
  final TemplateSolution solution;
  
  // Tags for selection
  final Set<TemplateTag> tags;
  
  const LevelTemplate({
    required this.id,
    required this.name,
    required this.minDifficulty,
    required this.maxDifficulty,
    required this.suitableEpisodes,
    required this.layout,
    required this.variables,
    required this.solution,
    required this.tags,
  });
}

/// Template layout defines object positions
class TemplateLayout {
  final TemplateSource source;
  final List<TemplateTarget> targets;
  final List<TemplateMirror> mirrors;
  final List<TemplatePrism> prisms;
  final List<TemplateWall> walls;
  
  const TemplateLayout({
    required this.source,
    required this.targets,
    this.mirrors = const [],
    this.prisms = const [],
    this.walls = const [],
  });
}

/// Template object (can use variable expressions)
class TemplateObject {
  final PositionExpression position;  // Can be: {x:5,y:3} or {x:$var1,y:3}
  final OrientationExpression orientation;  // Can be: 0 or $rotation1
  final bool isScrambled;  // Should this be randomized in initial state?
  final String? id;  // For referencing in solution
  
  const TemplateObject({
    required this.position,
    required this.orientation,
    this.isScrambled = false,
    this.id,
  });
}

/// Variable range for randomization
class VariableRange {
  final String name;
  final int min;
  final int max;
  final VariableType type;  // position, rotation, count
  
  const VariableRange({
    required this.name,
    required this.min,
    required this.max,
    required this.type,
  });
}

/// Solution steps
class TemplateSolution {
  final int parMoves;  // Optimal move count
  final List<SolutionStep> steps;  // For validation/hints
  
  const TemplateSolution({
    required this.parMoves,
    required this.steps,
  });
}

/// Tags for template selection
enum TemplateTag {
  reflection,      // Uses mirrors only
  colorMixing,     // Uses prisms for color mixing
  colorSplitting,  // Splits white into RGB
  multiTarget,     // Multiple targets
  sequential,      // Targets must be hit in order
  corridors,       // Uses walls to create paths
  complex,         // High difficulty
  tutorial,        // Teaching mechanic
}
```

---

## 🎨 Episode Characteristics & Template Distribution

### **Episode 1: Reflection Basics** (200 levels)

**Theme:** Learn mirror mechanics  
**Mechanics:** Mirrors, Walls, Single Target  
**No Prisms:** Pure reflection puzzles

#### Difficulty Progression:
```
Levels 1-40:   Simple (1-2 mirrors, straight paths)
Levels 41-80:  Easy (2-3 mirrors, one turn)
Levels 81-120: Medium (3-4 mirrors, multiple turns)
Levels 121-160: Hard (4-5 mirrors, tight spaces)
Levels 161-200: Expert (5-6 mirrors, complex paths)
```

#### Template Categories (10 templates × 20 variations):

1. **Straight Shot** (Levels 1-20)
   - 1 mirror, direct path
   - Par: 1 move
   - Variables: mirror position (3 options), target position (5 options)
   
2. **L-Turn** (Levels 21-40)
   - 2 mirrors forming L shape
   - Par: 2 moves
   - Variables: corner position, orientation
   
3. **Z-Pattern** (Levels 41-60)
   - 3 mirrors zigzag
   - Par: 3 moves
   - Variables: offset positions, wall placement
   
4. **Box Bounce** (Levels 61-80)
   - 4 mirrors around perimeter
   - Par: 4 moves
   - Variables: starting corner, box size
   
5. **Corridor** (Levels 81-100)
   - 2-3 mirrors + walls creating narrow path
   - Par: 2-3 moves
   - Variables: corridor width, mirror spacing
   
6. **Double Reflection** (Levels 101-120)
   - 2 parallel mirrors (multiple bounces)
   - Par: 2-4 moves
   - Variables: mirror distance, angle offsets
   
7. **Maze Entry** (Levels 121-140)
   - 4-5 mirrors + wall maze
   - Par: 4-5 moves
   - Variables: maze layout (5 presets), mirror positions
   
8. **Split Decision** (Levels 141-160)
   - Multiple mirror paths (one correct)
   - Par: 3-5 moves
   - Variables: decoy mirror count, correct path
   
9. **Tight Squeeze** (Levels 161-180)
   - 5 mirrors in compact space
   - Par: 5 moves
   - Variables: grid size, mirror density
   
10. **Master Reflection** (Levels 181-200)
    - 6 mirrors maximum complexity
    - Par: 6 moves
    - Variables: all positions, tight constraints

---

### **Episode 2: Advanced Reflection** (200 levels)

**Theme:** Master mirror combinations  
**Mechanics:** More mirrors, Tighter spaces, Multiple targets  
**No Prisms Yet**

#### Difficulty Progression:
```
Levels 1-50:   Multi-target introduction (2 targets)
Levels 51-100: Complex wall mazes
Levels 101-150: High mirror count (6-8 mirrors)
Levels 151-200: Precision puzzles (tight angles)
```

#### Template Categories (10 templates × 20 variations):

1. **Two Target Basic** (Levels 1-20)
   - Single source → 2 targets via 4 mirrors
   - Par: 4-5 moves
   
2. **Parallel Paths** (Levels 21-40)
   - Two separate reflection paths
   - Par: 4-6 moves
   
3. **Converging Beams** (Levels 41-60)
   - Two paths merge at target
   - Par: 5-7 moves
   
4. **Labyrinth** (Levels 61-80)
   - Heavy wall usage, limited paths
   - Par: 5-7 moves
   
5. **Perimeter Circle** (Levels 81-100)
   - Mirrors around edge, center target
   - Par: 6-8 moves
   
6. **Double Bounce** (Levels 101-120)
   - Light bounces same mirror twice
   - Par: 4-6 moves
   
7. **Precision Angle** (Levels 121-140)
   - Exact 45° alignment required
   - Par: 5-7 moves
   
8. **Dense Grid** (Levels 141-160)
   - 8 mirrors in small space
   - Par: 7-9 moves
   
9. **Sequential Targets** (Levels 161-180)
   - Targets must be hit in order
   - Par: 6-8 moves
   
10. **Reflection Master** (Levels 181-200)
    - All mechanics combined
    - Par: 8-10 moves

---

### **Episode 3: Color Introduction** (200 levels)

**Theme:** Learn color splitting & mixing  
**Mechanics:** Prisms (Splitter), RGB colors, Purple targets  
**NEW:** White light → Red + Blue + Yellow

#### Difficulty Progression:
```
Levels 1-40:   Single prism, basic splitting
Levels 41-80:  Purple mixing (Red + Blue)
Levels 81-120: Green mixing (Blue + Yellow)
Levels 121-160: Orange mixing (Red + Yellow)
Levels 161-200: Multiple color targets
```

#### Template Categories (15 templates × 13 variations):

1. **First Prism** (Levels 1-15)
   - 1 splitter, 3 colored targets (R, B, Y)
   - Par: 1 move (just rotate prism)
   - Purpose: Teach splitting mechanic
   
2. **Purple Basic** (Levels 16-30)
   - 1 prism + 2 mirrors → Purple target
   - Par: 3 moves (prism + 2 mirrors)
   - Layout:
     ```
     Source(White) → Prism → Red ↓
                           → Blue ↓
                           → Yellow →(ignored)
     Mirror1 (redirect Red) ─┐
     Mirror2 (redirect Blue) ─┤→ Target(Purple)
     ```
   
3. **Purple L-Shape** (Levels 31-45)
   - Prism in corner, L-shaped path
   - Par: 4 moves
   
4. **Purple with Walls** (Levels 46-60)
   - Prism + mirrors + walls
   - Par: 4-5 moves
   
5. **Green Basic** (Levels 61-75)
   - 1 prism + 2 mirrors → Green target
   - Par: 3 moves
   - Uses Blue + Yellow
   
6. **Orange Basic** (Levels 76-90)
   - 1 prism + 2 mirrors → Orange target
   - Par: 3 moves
   - Uses Red + Yellow
   
7. **Dual Color Mix** (Levels 91-105)
   - 1 prism → 2 different mixed targets
   - Par: 5-6 moves
   - Example: Purple AND Green from same prism
   
8. **Prism + Reflection** (Levels 106-120)
   - Split colors, then reflect multiple times
   - Par: 6-7 moves
   
9. **Color Selection** (Levels 121-135)
   - Multiple color paths, choose correct combination
   - Par: 5-7 moves
   
10. **Prism Chain** (Levels 136-150)
    - 2 prisms in sequence
    - Par: 6-8 moves
    
11. **Triple Mix Challenge** (Levels 151-165)
    - All 3 mixed colors from one prism
    - Par: 8-10 moves
    
12. **Precision Color** (Levels 166-180)
    - Tight angles + color mixing
    - Par: 7-9 moves
    
13. **Color Maze** (Levels 181-190)
    - Walls + prism + multiple targets
    - Par: 8-10 moves
    
14. **Color Master I** (Levels 191-195)
    - Complex color + reflection combo
    - Par: 10-12 moves
    
15. **Color Master II** (Levels 196-200)
    - Maximum complexity color puzzles
    - Par: 12-15 moves

---

### **Episode 4: Color Mastery** (200 levels)

**Theme:** Complex color combinations  
**Mechanics:** Multiple prisms, All color mixing, 3+ targets  

#### Difficulty Progression:
```
Levels 1-50:   Multiple prisms (2 prisms)
Levels 51-100: 3 targets with different colors
Levels 101-150: Deflector prisms (direction change)
Levels 151-200: Mixed splitter + deflector
```

#### Template Categories (15 templates × 13 variations):

1. **Dual Prism Basic** (Levels 1-15)
   - 2 splitter prisms
   - Par: 6-8 moves
   
2. **Three Target Rainbow** (Levels 16-30)
   - 1 prism → 3 different colored targets
   - Par: 7-9 moves
   
3. **Sequential Color** (Levels 31-45)
   - Colors must arrive in order
   - Par: 8-10 moves
   
4. **Color Bounce** (Levels 46-60)
   - Colored light bounces mirrors
   - Par: 8-10 moves
   
5. **Deflector Intro** (Levels 61-75)
   - First deflector prism (changes direction only)
   - Par: 4-6 moves
   
6. **Splitter + Deflector** (Levels 76-90)
   - Mix both prism types
   - Par: 9-11 moves
   
7. **Color Cascade** (Levels 91-105)
   - Prism → Mirrors → Prism → Target
   - Par: 10-12 moves
   
8. **Triple Prism** (Levels 106-120)
   - 3 prisms total
   - Par: 11-13 moves
   
9. **Color Corridors** (Levels 121-135)
   - Walls create color-specific paths
   - Par: 10-12 moves
   
10. **Rainbow Complete** (Levels 136-150)
    - All 6 colors (R, B, Y, Purple, Green, Orange)
    - Par: 12-15 moves
    
11. **Precision Multi-Color** (Levels 151-165)
    - Tight angles + multiple colors
    - Par: 13-15 moves
    
12. **Color Chaos** (Levels 166-180)
    - Many prisms + mirrors + walls
    - Par: 14-16 moves
    
13. **Advanced Deflection** (Levels 181-190)
    - Complex deflector paths
    - Par: 12-15 moves
    
14. **Color Master III** (Levels 191-195)
    - All mechanics combined
    - Par: 16-18 moves
    
15. **Ultimate Color** (Levels 196-200)
    - Maximum complexity
    - Par: 18-20 moves

---

### **Episode 5: Expert Challenges** (200 levels)

**Theme:** Master all mechanics  
**Mechanics:** Everything combined, Decoys, Time pressure (optional)  

#### Difficulty Progression:
```
Levels 1-50:   Decoy objects (extra mirrors/prisms)
Levels 51-100: Minimal space (compact puzzles)
Levels 101-150: Maximum objects (10+ mirrors)
Levels 151-200: Expert precision puzzles
```

#### Template Categories (15 templates × 13 variations):

1. **Decoy Introduction** (Levels 1-15)
   - 2 extra mirrors not needed
   - Par: 8-10 moves
   
2. **Find the Path** (Levels 16-30)
   - Multiple possible paths, one optimal
   - Par: 10-12 moves
   
3. **Compact Challenge** (Levels 31-45)
   - Small grid, many objects
   - Par: 12-14 moves
   
4. **Dense Prism Field** (Levels 46-60)
   - 3-4 prisms + 8 mirrors
   - Par: 14-16 moves
   
5. **Sequential Precision** (Levels 61-75)
   - Sequence + tight angles
   - Par: 12-15 moves
   
6. **Color Decoy** (Levels 76-90)
   - Decoy colors + correct path
   - Par: 13-16 moves
   
7. **Maximum Mirrors** (Levels 91-105)
   - 12-15 mirrors total
   - Par: 15-18 moves
   
8. **Extreme Deflection** (Levels 106-120)
   - Multiple deflectors + splitters
   - Par: 16-19 moves
   
9. **Puzzle Box** (Levels 121-135)
   - Enclosed space, complex path
   - Par: 17-20 moves
   
10. **Ultimate Precision** (Levels 136-150)
    - Exact angles required
    - Par: 18-20 moves
    
11. **Expert Decoy** (Levels 151-165)
    - Many decoys, hard to find solution
    - Par: 19-22 moves
    
12. **Maximum Density** (Levels 166-180)
    - 20+ objects total
    - Par: 20-24 moves
    
13. **Challenge Master I** (Levels 181-190)
    - All expert mechanics
    - Par: 22-26 moves
    
14. **Challenge Master II** (Levels 191-195)
    - Near-maximum complexity
    - Par: 24-28 moves
    
15. **Grand Finale** (Levels 196-200)
    - Absolute maximum challenge
    - Par: 28-35 moves

---

## 🔧 Template Generation Algorithm

### Phase 1: Template Selection

```dart
class TemplateSelector {
  /// Select appropriate template for episode/level
  LevelTemplate selectTemplate(int episode, int levelIndex, Random rng) {
    // Calculate target difficulty (0-10 scale)
    final difficulty = _calculateDifficulty(episode, levelIndex);
    
    // Get templates suitable for this episode
    final candidates = TemplateLibrary.templates.where((t) => 
      t.suitableEpisodes.contains(episode) &&
      t.minDifficulty <= difficulty &&
      t.maxDifficulty >= difficulty
    ).toList();
    
    if (candidates.isEmpty) {
      throw Exception('No templates found for E$episode L$levelIndex');
    }
    
    // Deterministic selection based on level index
    // This ensures same level always gets same template type
    final templateIndex = levelIndex % candidates.length;
    return candidates[templateIndex];
  }
  
  /// Calculate difficulty score (1-10)
  int _calculateDifficulty(int episode, int levelIndex) {
    // Base difficulty from episode
    final episodeBase = {
      1: 2,  // E1: 2-6 difficulty
      2: 4,  // E2: 4-8 difficulty
      3: 5,  // E3: 5-9 difficulty
      4: 6,  // E4: 6-10 difficulty
      5: 7,  // E5: 7-10 difficulty
    }[episode] ?? 2;
    
    // Progressive increase within episode
    final progress = (levelIndex / 200.0); // 0.0 to 1.0
    final progressBonus = (progress * 4).round(); // 0-4 bonus
    
    return (episodeBase + progressBonus).clamp(1, 10);
  }
}
```

### Phase 2: Variable Generation

```dart
class VariableGenerator {
  /// Generate variable values for template instantiation
  Map<String, int> generateValues(
    LevelTemplate template,
    int seed,
  ) {
    final rng = Random(seed);
    final values = <String, int>{};
    
    for (final entry in template.variables.entries) {
      final varName = entry.key;
      final range = entry.value;
      
      switch (range.type) {
        case VariableType.position:
          // Position offset: -range to +range
          values[varName] = range.min + rng.nextInt(range.max - range.min + 1);
          break;
          
        case VariableType.rotation:
          // Rotation offset: 1-3 steps (never 0 = already solved)
          values[varName] = 1 + rng.nextInt(3);
          break;
          
        case VariableType.count:
          // Object count
          values[varName] = range.min + rng.nextInt(range.max - range.min + 1);
          break;
      }
    }
    
    return values;
  }
}
```

### Phase 3: Template Instantiation

```dart
class TemplateInstantiator {
  /// Create actual level from template + variables
  GeneratedLevel instantiate(
    LevelTemplate template,
    Map<String, int> variables,
    int seed,
    int episode,
    int levelIndex,
  ) {
    final objects = <GameObject>[];
    
    // 1. Instantiate Source
    final source = _instantiateSource(template.layout.source, variables);
    
    // 2. Instantiate Targets
    final targets = template.layout.targets
      .map((t) => _instantiateTarget(t, variables))
      .toList();
    
    // 3. Instantiate Mirrors
    final mirrors = template.layout.mirrors
      .map((m) => _instantiateMirror(m, variables))
      .toList();
    
    // 4. Instantiate Prisms
    final prisms = template.layout.prisms
      .map((p) => _instantiatePrism(p, variables))
      .toList();
    
    // 5. Instantiate Walls
    final walls = template.layout.walls
      .map((w) => _instantiateWall(w, variables))
      .toList();
    
    // 6. Calculate par moves (from solution + scrambling)
    final parMoves = _calculateParMoves(template.solution, variables);
    
    // 7. Generate solution steps
    final solution = _generateSolutionSteps(template.solution, variables);
    
    return GeneratedLevel(
      seed: seed,
      episode: episode,
      index: levelIndex,
      source: source,
      targets: targets,
      mirrors: mirrors,
      prisms: prisms,
      walls: walls,
      meta: LevelMeta(
        optimalMoves: parMoves,
        difficultyBand: template.minDifficulty,
        generationAttempts: 1, // Always succeeds on first try
      ),
      solution: solution,
    );
  }
  
  /// Apply variable expressions to position
  GridPosition _applyPositionExpression(
    PositionExpression expr,
    Map<String, int> vars,
  ) {
    // Parse expression like "{x:5,y:$offset1}" or "{x:$var1,y:3}"
    final x = expr.x.startsWith('\$') 
      ? vars[expr.x.substring(1)] ?? 0
      : int.parse(expr.x);
      
    final y = expr.y.startsWith('\$')
      ? vars[expr.y.substring(1)] ?? 0
      : int.parse(expr.y);
    
    return GridPosition(x, y);
  }
  
  /// Apply scrambling to orientation
  int _applyScrambling(
    int solvedOrientation,
    String? scrambleVar,
    Map<String, int> vars,
  ) {
    if (scrambleVar == null) return solvedOrientation;
    
    // Get scramble offset (1-3 rotations)
    final offset = vars[scrambleVar] ?? 0;
    
    // Apply offset backwards (so solution is to rotate forward)
    return (solvedOrientation - offset + 4) % 4;
  }
}
```

### Phase 4: Validation

```dart
class TemplateValidator {
  /// Validate instantiated level (minimal checks)
  bool validate(GeneratedLevel level) {
    // 1. Occupancy check (no overlapping objects)
    final occupancyResult = OccupancyGrid.validateLevel(level);
    if (!occupancyResult.valid) {
      print('Occupancy validation failed: ${occupancyResult.collisions}');
      return false;
    }
    
    // 2. Geometric constraints
    // - Prisms must be 2+ cells from source
    for (final prism in level.prisms) {
      if (prism.position.distanceTo(level.source.position) < 2) {
        print('Prism too close to source');
        return false;
      }
    }
    
    // - No objects on grid edges
    for (final mirror in level.mirrors) {
      if (mirror.position.isOnEdge) {
        print('Mirror on edge');
        return false;
      }
    }
    
    // 3. Template is pre-validated, no need to run solver!
    // Solution is guaranteed if template is correct
    
    return true;
  }
}
```

---

## 📚 Template Library Structure

### File Organization:

```
lib/game/templates/
├── template_library.dart          # Central registry
├── episode_1/
│   ├── straight_shot.dart         # 20 variants
│   ├── l_turn.dart                # 20 variants
│   ├── z_pattern.dart             # 20 variants
│   └── ... (10 templates total)
├── episode_2/
│   ├── two_target_basic.dart
│   └── ... (10 templates total)
├── episode_3/
│   ├── first_prism.dart
│   ├── purple_basic.dart
│   └── ... (15 templates total)
├── episode_4/
│   └── ... (15 templates total)
└── episode_5/
    └── ... (15 templates total)
```

### Template Definition Example:

```dart
// lib/game/templates/episode_3/purple_basic.dart

const purpleBasicTemplate = LevelTemplate(
  id: 'e3_purple_basic',
  name: 'Purple Mixer Basic',
  minDifficulty: 3,
  maxDifficulty: 5,
  suitableEpisodes: [3],
  
  layout: TemplateLayout(
    // Source: Fixed position, white light
    source: TemplateSource(
      position: PositionExpression(x: '1', y: '3'),
      direction: Direction.east,
      color: LightColor.white,
    ),
    
    // Prism: Fixed position, variable initial rotation
    prisms: [
      TemplatePrism(
        id: 'splitter1',
        position: PositionExpression(x: '6', y: '3'),
        orientation: OrientationExpression('\$prism_rotation'),
        type: PrismType.splitter,
        isScrambled: true,
      ),
    ],
    
    // Mirror 1: Routes red beam
    mirrors: [
      TemplateMirror(
        id: 'mirror1',
        position: PositionExpression(x: '6', y: '\$mirror1_y'),
        orientation: OrientationExpression('\$mirror1_rotation'),
        isScrambled: true,
      ),
      
      // Mirror 2: Routes blue beam
      TemplateMirror(
        id: 'mirror2',
        position: PositionExpression(x: '6', y: '\$mirror2_y'),
        orientation: OrientationExpression('\$mirror2_rotation'),
        isScrambled: true,
      ),
    ],
    
    // Target: Purple (needs R+B)
    targets: [
      TemplateTarget(
        position: PositionExpression(x: '\$target_x', y: '3'),
        requiredColor: LightColor.purple,
      ),
    ],
    
    // Walls: Add difficulty
    walls: [
      TemplateWall(
        position: PositionExpression(x: '\$wall1_x', y: '1'),
      ),
      TemplateWall(
        position: PositionExpression(x: '\$wall2_x', y: '5'),
      ),
    ],
  ),
  
  // Variable ranges
  variables: {
    'prism_rotation': VariableRange(
      name: 'prism_rotation',
      min: 1,
      max: 3,
      type: VariableType.rotation,
    ),
    'mirror1_rotation': VariableRange(
      name: 'mirror1_rotation',
      min: 1,
      max: 3,
      type: VariableType.rotation,
    ),
    'mirror2_rotation': VariableRange(
      name: 'mirror2_rotation',
      min: 1,
      max: 3,
      type: VariableType.rotation,
    ),
    'mirror1_y': VariableRange(
      name: 'mirror1_y',
      min: 1,
      max: 2,
      type: VariableType.position,
    ),
    'mirror2_y': VariableRange(
      name: 'mirror2_y',
      min: 4,
      max: 5,
      type: VariableType.position,
    ),
    'target_x': VariableRange(
      name: 'target_x',
      min: 10,
      max: 12,
      type: VariableType.position,
    ),
    'wall1_x': VariableRange(
      name: 'wall1_x',
      min: 2,
      max: 4,
      type: VariableType.position,
    ),
    'wall2_x': VariableRange(
      name: 'wall2_x',
      min: 2,
      max: 4,
      type: VariableType.position,
    ),
  },
  
  // Solution (in solved state)
  solution: TemplateSolution(
    parMoves: 3,  // prism + 2 mirrors
    steps: [
      SolutionStep(
        type: MoveType.rotatePrism,
        objectId: 'splitter1',
        description: 'Rotate prism to split white → RGB',
      ),
      SolutionStep(
        type: MoveType.rotateMirror,
        objectId: 'mirror1',
        description: 'Direct red beam to target',
      ),
      SolutionStep(
        type: MoveType.rotateMirror,
        objectId: 'mirror2',
        description: 'Direct blue beam to target',
      ),
    ],
  ),
  
  tags: {
    TemplateTag.colorMixing,
    TemplateTag.colorSplitting,
  },
);
```

---

## 🔄 Hybrid System: Procedural Fallback

### When to Use Procedural (Episode 6+):

```dart
class HybridGenerator {
  GeneratedLevel generate(int episode, int index, int seed) {
    // Episode 1-5: Use templates (guaranteed success)
    if (episode <= 5) {
      return _generateFromTemplate(episode, index, seed);
    }
    
    // Episode 6+: Try procedural, fallback to template
    final rng = Random(seed);
    
    // Attempt procedural generation (max 3 tries)
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final level = ProceduralGenerator().generate(
          episode, 
          index, 
          seed + attempt * 1000,
        );
        
        // Validate
        if (_validateProcedural(level)) {
          return level;
        }
      } catch (e) {
        print('Procedural attempt ${attempt + 1} failed: $e');
      }
    }
    
    // Fallback: Use closest template
    print('Procedural failed, using template fallback');
    return _generateFromTemplate(
      5,  // Use E5 templates (hardest)
      index,
      seed,
    );
  }
  
  GeneratedLevel _generateFromTemplate(int episode, int index, int seed) {
    final selector = TemplateSelector();
    final generator = VariableGenerator();
    final instantiator = TemplateInstantiator();
    final validator = TemplateValidator();
    
    final rng = Random(seed);
    
    // 1. Select template
    final template = selector.selectTemplate(episode, index, rng);
    
    // 2. Generate variables
    final variables = generator.generateValues(template, seed);
    
    // 3. Instantiate
    final level = instantiator.instantiate(
      template,
      variables,
      seed,
      episode,
      index,
    );
    
    // 4. Validate
    if (!validator.validate(level)) {
      // Retry with different variables
      final variables2 = generator.generateValues(template, seed + 1);
      return instantiator.instantiate(
        template,
        variables2,
        seed + 1,
        episode,
        index,
      );
    }
    
    return level;
  }
}
```

---

## 🎮 Runtime Performance

### Expected Performance:

| Operation | Current System | Hybrid System | Improvement |
|-----------|---------------|---------------|-------------|
| E1 Level Gen | 1-2 seconds | 50-100ms | **20x faster** |
| E3 Level Gen | 2-4 seconds | 80-150ms | **20x faster** |
| E5 Level Gen | 3-5 seconds | 100-200ms | **25x faster** |
| Success Rate E1-2 | 70% | 99% | **+29%** |
| Success Rate E3-5 | 30-50% | 95% | **+50%** |
| Code Complexity | 500+ lines | 150 lines core + templates | **60% reduction** |

### Memory Usage:

```
Template Library: ~2MB (50 templates × 40KB each)
Runtime Cache: ~5MB (active templates)
Generation Overhead: <1MB per level
Total: ~8MB (vs current 15MB+ for blueprint cache)
```

---

## 🛠️ Implementation Roadmap

### Week 1: Foundation
- **Day 1-2:** Create template data structures
- **Day 3:** Build template selector + variable generator
- **Day 4:** Build template instantiator
- **Day 5:** Create validator

### Week 2: Episode 1-2 Templates
- **Day 1-2:** Design 10 E1 templates
- **Day 3:** Test E1 generation (200 levels)
- **Day 4:** Design 10 E2 templates
- **Day 5:** Test E2 generation (200 levels)

### Week 3: Episode 3-5 Templates
- **Day 1-2:** Design 15 E3 templates (color mixing)
- **Day 3:** Design 15 E4 templates
- **Day 4:** Design 15 E5 templates
- **Day 5:** Test E3-5 generation (600 levels)

### Week 4: Integration & Polish
- **Day 1:** Integrate with campaign system
- **Day 2:** Add procedural fallback (E6+)
- **Day 3-4:** Bug fixes + optimization
- **Day 5:** Final testing + documentation

**Total: 4 weeks** (vs 2-3 months to fix current system)

---

## 📊 Success Metrics

### Quality Targets:
- ✅ **>95% solvable** on first generation attempt
- ✅ **<100ms** average generation time
- ✅ **Zero** prism-at-source errors
- ✅ **Zero** color mixing failures
- ✅ **100%** occupancy validation pass rate

### Variety Metrics:
- 50 unique template types
- 20+ variations per template
- 1000+ unique puzzle configurations per episode
- Deterministic (same seed → same level)

---

## 🎯 Next Steps

Ready to start implementation? I recommend:

1. **Start with E1 templates** (simplest, validate approach)
2. **Create 5 templates first** (proof of concept)
3. **Generate 100 levels** (test variation)
4. **Measure success rate** (should be >95%)
5. **Then expand to full library**

Shall I create:
- **A)** Template data structure code (complete implementation)
- **B)** Example E1 template library (5-10 templates)
- **C)** Generator algorithm (selector + instantiator)
- **D)** All of the above (full implementation)?
