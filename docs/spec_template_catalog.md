# Agent D: Template Catalog Specification

## Topology Standards
- **Grid Context**: 6x12 Portrait.
- **Rules**: No random walls. Use `WallPattern` presets only.
- **Solution**: Every template must define `solutionSteps` (correct rotation for each mirror/prism).

---

## 1. Vertical Corridor
*Long channel from North to South with a few deflections.*
- **V0 (Basic)**: Straight drop with 2 mirrors.
- **V1 (ZigZag)**: Hits side walls 3 times.
- **V2 (Obstacle)**: Center wall blocks the direct path, forcing a "U" turn.

## 2. Two-Chamber
*Grid split into Top (Generation) and Bottom (Reception) halves.*
- **V0 (Gate)**: One wall barrier at Y=6 with a single opening.
- **V1 (Offset)**: Two staggered wall barriers, forcing a "Z" path through the middle.
- **V2 (Locked)**: Top chamber has a Prism; Bottom has 2 Targets.

## 3. Staircase (Serpentine)
*Beam must travel side-to-side repeatedly to reach the bottom.*
- **V0 (Wide)**: 3 horizontal reaches.
- **V1 (Tight)**: 5 quick zig-zags.
- **V2 (Broken)**: Mid-flight collision with a fixed block requires a detour.

## 4. Side Channel
*Source is in one corner, Target in the opposite corner (diagonal flow).*
- **V0 (Direct)**: Source(0,0) -> Target(5,11).
- **V1 (Bypass)**: Central block forces beam to hug the perimeter.
- **V2 (Perimeter)**: Beam travels 0,0 -> 5,0 -> 5,11 -> 0,11.

## 5. Central Spine
*Fixed vertical wall in the center (X=2 or 3) acts as a mirror mounting point.*
- **V0 (Sym)**: Two beams, one left of spine, one right.
- **V1 (Switch)**: Beam crosses the spine twice.
- **V2 (Wraparound)**: Target is behind the source, requires circling the spine.

## 6. Loop Lite
*Path involves a 360-degree traversal but must be "broken" to reach the exit.*
- **V0 (Square)**: 4 mirrors forming a loop.
- **V1 (Diamond)**: 4 mirrors at 45-deg angles.
- **V2 (Double)**: Figure-8 loop.

## 7. Split Fanout
*Single prism splits light into 2 or 3 paths.*
- **V0 (Simple)**: 1 Source -> 1 Prism -> 2 Targets (Red/Blue).
- **V1 (Distant)**: Targets are at opposite ends of the grid.
- **V2 (Blocked)**: One of the fanout paths is obstructed, requiring extra mirrors.

## 8. Merge Gate (Logic)
*Two beams must hit the same prism or target setup to complete.*
- **V0 (Collinear)**: Red + Blue merge at (3,10) to form Magenta.
- **V1 (Async)**: Sources at top and bottom, merge in the center.
- **V2 (Key)**: One light beam must "clear" a blocker (moving target proxy) for the other.

## 9. Frame + Windows
*Grid perimeter is solid walls; only specific "windows" allow light across.*
- **V0 (X-Axis)**: Only central row is clear.
- **V1 (Checker)**: Staggered blocks create small corridors.
- **V2 (Maze)**: Single narrow path through the frames.

## 10. Blocker Pivot
*A fixed BlockerObject is placed at a critical intersection.*
- **V0 (Corner)**: Pivot at (2,2) forces a 90-deg turn.
- **V1 (Shield)**: Blocker protects a Target from the wrong color light.
- **V2 (Center)**: All beams must pass through the center 2x2 hole.

## 11. Dual-Zone
*Top 6x6 is Red puzzles; Bottom 6x6 is Blue puzzles.*
- **V0 (Separated)**: No interaction between zones.
- **V1 (Cross)**: Red beam must cross Blue territory.
- **V2 (Dependent)**: Blue target only opens after Red is lit.

## 12. Decoy Lane
*Contains interactive mirrors that are NOT part of the solution.*
- **V0 (Parallel)**: Two lanes, only one leads to Target.
- **V1 (Fake Exit)**: Path loops back to start if decoy is used.
- **V2 (Complexity)**: 5 Mirrors total, only 3 needed for the solution.
