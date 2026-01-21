You are refactoring/optimizing a Flutter/Dart puzzle game “PrisMaze” to support scalable procedural generation of 1000–2000 solvable levels with a sharp difficulty ramp. We are standardizing mirrors to a 4-state discrete orientation system and building a deterministic generator + solver + hint pipeline.

CORE PLAYER INTERACTION (Method A)
- Episode levels use FIXED object positions (no free placement).
- Player can rotate certain objects by TAP only.
- One tap = one move. Rotation cycles to next discrete orientation.
- Mirrors have EXACTLY 4 states (cycle order fixed):
  0: "_"  (horizontal reflector)
  1: "/"  (slash reflector)
  2: "|"  (vertical reflector)
  3: "\"  (backslash reflector)
- Prisms (if rotatable) also have discrete states (define count based on existing logic; keep small, e.g. 4 states).

GOAL
- Build a robust, deterministic, and scalable system capable of generating 1000–2000 levels per “episode set” with:
  - guaranteed solvability
  - controlled difficulty bands (minimum moves)
  - non-trivial puzzles from Episode 3 onward
  - decoy objects that look useful but are traps
  - more walls/maze-like routing while staying readable and fair
  - color system and prisms integrated deterministically
  - solver provides minimum moves + explicit move sequence for star rating and hints
  - hint re-solves from CURRENT state (not only from initial)

GRID / COORDINATES
- Grid is 22x9 (W=22, H=9), cell-based.
- Direction set must match the existing codebase:
  - If current rays are 4-direction (E,N,W,S), keep it.
  - If 8-direction is already implemented, keep it.
DO NOT introduce continuous angles. Everything must remain discrete and deterministic.

LIGHT / COLOR SYSTEM (deterministic, puzzle-friendly)
- enum LightColor: White, Red, Blue, Yellow, Purple, Orange, Green
- Base: Red, Blue, Yellow
- Mix rules (two-base mix):
  - R+B => Purple
  - R+Y => Orange
  - B+Y => Green
- Mixing MUST NOT rely on “free-space line intersection” (ambiguous).
Use “Target-cell accumulation” mixing:
  - During ray tracing, accumulate arriving base components at each TARGET cell:
    - Track which of {R,B,Y} reached that cell (ignore duplicates).
    - If target requires a mixed color, it is satisfied only if exactly the required base set arrives.
    - If target requires a base color, it is satisfied if that base arrives.
    - If target requires White, it is satisfied only by White arriving (do not let White auto-satisfy everything).
  - Define behavior for >2 bases arriving:
    - Option A (recommended): treat as “invalid mix” for mixed targets (target not satisfied unless it explicitly allows “any”).
Keep the rule strict and deterministic.

OBJECTS / MODELS (Dart)
Implement/standardize:
- class Source {int x,y; Direction dir; LightColor color = White;}
- class Target {int x,y; LightColor required;}
- class Wall {int x,y;}
- class Mirror {int x,y; int orientation; bool rotatable;}
  - orientation in [0..3] for 4 mirror states
- class Prism {int x,y; int orientation; bool rotatable; PrismType type;}
- class Level {
    int seed;
    int episode;
    int index;
    Source source;
    List<Target> targets;
    Set<Wall> walls;
    List<Mirror> mirrors;
    List<Prism> prisms;
    LevelMeta meta; // optimalMoves, difficultyBand, etc.
  }
- class GameState {Uint8List mirrorOrientations; Uint8List prismOrientations;}
- JSON serialization for all.

RAY TRACER (multi-ray, safe, deterministic)
Implement RayTracer.trace(Level level, GameState state) -> TraceResult:
- A ray has (x,y,dir,color).
- Step:
  1) move to next cell
  2) stop if out-of-bounds or wall
  3) if mirror at cell: reflect dir using MIRROR_REFLECT_TABLE[inDir][mirrorOrientation]; continue
  4) if prism at cell: apply PRISM_TABLE[(inDir,inColor,prismOrientation,prismType)] -> list of outgoing rays; continue
  5) if target at cell: record arrival color for mixing at that target cell; continue (ray does not have to stop unless design says so; choose one consistent rule and document it; recommended: ray continues through target cell)
- Loop control:
  - visited per ray: (x,y,dir,color) -> if repeats, terminate that ray
  - global maxSteps ~ 2000, maxRays ~ 32
- Output:
  - per-ray polyline segments for rendering
  - for each target: satisfied or not, plus arrival components info

MIRROR REFLECTION: CONST LOOKUP TABLE (critical)
Because mirrors are discrete 4-state, implement a const mapping:
outDir = MIRROR_REFLECT[inDir][mirrorOrientation]
- Build the mapping consistent with existing reflection behavior.
- Add unit tests covering all inDir x orientation cases.
- No floating-point math.

PRISM BEHAVIOR: CONST LOOKUP TABLE
Implement prism mapping as deterministic tables. Keep ray count bounded.
Two recommended prism types:
- PrismType.SPLITTER (white -> base colors)
- PrismType.DEFLECTOR (deflects direction slightly but keeps color)
Mapping guidance (adapt to your existing prism logic):
- SPLITTER:
  - White in => split into 3 rays: Red, Blue, Yellow with deterministic directions (e.g., straight + left + right within the allowed direction set)
  - Non-white in => pass-through with deterministic deflection (or just pass-through unchanged; decide and document)
- DEFLECTOR:
  - Any color in => direction rotates by +1 or -1 step depending on orientation; color preserved
Add tests for prism behavior and ensure total ray explosion is prevented.

SOLVER (minimum moves + explicit move list)
Implement Solver.solve(Level level, GameState start, {budget}) -> Solution?:
- State = orientations for all rotatable mirrors/prisms.
- Action:
  - rotate mirror i: ori = (ori+1) mod 4
  - rotate prism j: ori = (ori+1) mod PRISM_ORI_COUNT
- Goal: all targets satisfied via RayTracer.trace
- Use BFS for correctness. Add A* optionally for speed:
  - heuristic h = number of unsatisfied targets (safe, simple)
- Must return:
  - minMoves
  - move sequence: list of (objectKind, index, taps=1)
Performance constraints:
- Control number of rotatable objects:
  - Episode 1: 3–6
  - Episode 2: 6–9
  - Episode 3: 9–13
  - Episode 4: 12–16
  - Episode 5: 14–18
If higher, A* and budgets are required.

HINT ENGINE (re-solve from CURRENT state)
HintEngine.getHint(Level, currentState, hintType) -> Hint:
- Always attempt Solver.solve(level, currentState) within budget.
- Light hint: return first move’s object index to highlight.
- Medium hint: next 3 moves for animation.
- Full: full move list for animation and step-through.
- If solver fails within budget, fallback to:
  - smaller hint (highlight a “critical” object), or
  - baseline solution stored from initial (optional), but warn/avoid misleading.

STAR SYSTEM
- optimalMoves = solver minMoves from initial state.
- 3 stars: movesUsed <= optimal
- 2 stars: movesUsed <= ceil(1.5*optimal)
- 1 star: completed

LEVEL GENERATOR (scalable constructive generation; strict rejection; Episode 3+ hard)
We need a generator that can produce 1000–2000 levels reliably.
Do NOT use random scatter + brute force. Use constructive generation:

Generator.generate(episode, index, seed) -> Level
- Deterministic: same seed produces same level.
- Use a bounded attempt loop: try up to 200 attempts; if fail, increment seed and retry.

Difficulty bands by episode (adjustable but must exist):
- Episode 1: minMoves target 1–6 (tutorial; allow trivial sometimes)
- Episode 2: 4–10
- Episode 3: 10–18 (non-trivial starts; must reject easy wins aggressively)
- Episode 4: 16–26
- Episode 5: 22–35

CONSTRUCTIVE PIPELINE
1) Choose parameters for this episode:
   - targetCount
   - mirrorCountTotal = critical + decoy
   - prismCountTotal = critical + decoy
   - wallDensity (higher from Episode 3+)
   - requiredColorTargets ratio (Episode 1 mostly white, Episode 3+ mostly colored with at least 1 mixed target often)
2) Place Source on edge pointing inward.
3) Place Targets with spacing constraints.
4) Construct the intended solution path(s):
   - Build a discrete routing plan where rays must visit a sequence of object cells to reach targets.
   - Place CRITICAL mirrors/prisms on those cells.
   - Determine the REQUIRED orientation for each critical object such that the ray(s) satisfy all targets with required colors using the chosen mixing rule.
   - Ensure “cheap alternatives” are unlikely by design (use walls later too).
5) Initialize orientations to enforce difficulty:
   - For each critical object, set initial orientation K steps away from required (K in 0..3 for mirrors; choose distribution to hit target minMoves).
   - For Episode 3+, ensure multiple critical objects require changes (avoid single-object solve).
6) Add DECOY objects that appear plausible but are traps:
   Decoy strategies (must implement several):
   - Leads ray into a wall pocket (dead-end)
   - Produces almost-correct color (e.g., reaches target with Blue instead of Purple)
   - Creates a loop that terminates by loop detector
   - Satisfies one target but blocks others (trade-off)
Place decoys near the main corridor to be tempting.
7) Add WALLS (dense but readable; Episode 3+ heavier):
   Wall algorithm requirements:
   - Reserve a protected corridor around the intended correct ray paths (do not place walls on those cells).
   - Place blocker segments to break:
     - direct source->target (LOS) solutions
     - 1-2 object shortcut routes
   - Use short segments/clusters (2–6 cells) rather than filling whole maze.
   - Keep the board readable; avoid sealing targets in tiny enclosed pockets unless intended.
8) Validate with solver:
   - Must be solvable from initial state.
   - Reject if minMoves < episodeMinMoves (Episode 3+: strict).
   - Reject if a “single tap anywhere” solves all targets (except Episode 1 tutorial).
   - Reject if too many solutions exist near optimal (puzzle is too loose):
     - e.g., detect a second distinct solution within optimal+2; if found often, reject.
   - Reject if solver exceeds time/budget (level too complex for runtime hint).
9) Persist to JSON:
   - include seed, episode, index
   - include meta.optimalMoves
   - include meta.difficultyBand and rejection reason logging in debug builds

BATCH VALIDATION TOOLING (must deliver)
Add a dev/debug tool that:
- Generates N levels for a given episode (e.g., N=200)
- Runs solver on each and reports:
  - acceptance rate
  - distribution of minMoves
  - average solve time
  - top rejection reasons
We need this to tune parameters for 1000–2000 levels.

UI/DEBUG FEATURES (must add)
- Buttons:
  - Generate (episode, seed)
  - Solve (shows minMoves and animates solution taps)
  - Toggle rays (render polyline)
  - Step trace
  - Batch validate report

DELIVERABLES (file-level)
Implement/refactor cleanly:
- models.dart (+ JSON)
- reflection_tables.dart (+ unit tests)
- prism_tables.dart (+ unit tests)
- ray_tracer.dart (+ tests for loop + mixing)
- solver.dart (+ tests)
- level_generator.dart (+ batch validation harness)
- hint_engine.dart

IMPORTANT DESIGN PRINCIPLES
- Determinism > realism. Discrete tables everywhere.
- Episode 3+ must “hurt” but remain fair:
  - enforce minMoves thresholds
  - require multi-step color reasoning
  - use decoys that teach, not randomize
  - ensure runtime hints can re-solve within a budget
- Keep rotatable count bounded to avoid solver blow-ups.

Now inspect the existing codebase, align Direction set and current ray logic, implement the 4-state mirror system, and refactor generator+solver+hint accordingly. Provide clear code comments and tests. Do not break UI; add debug utilities for tuning generation.
