# Prismaze Design Master Plan (Global Endless Contract)

## 0) Core Philosophy: Global Endless
- **Contract**: Same `generatorVersion` + same `levelIndex` ⇒ Identical level for all users on all platforms.
- **Recipe**: Derived via `Hash(version + ":" + levelIndex)`.
- **Determinism**: Zero tolerance for floating point drift (Fixed-Point only) or non-deterministic iteration orders.

## 1) Game Concept: Optical Circuits
- **Fantasy**: Repairing "Optical Circuits" by directing light energy using mirrors and prisms.
- **Controls**: Rotation only (90° steps). No placement in v1.
- **Core Loop**: Split (Prism) -> Direct (Mirror) -> Merge (Lenses/Targets).

## 2) Grid Standards (6x12)
- **Bounds**: X: 0..5, Y: 0..11.
- **Readability**: Source buffer (2-3 cells), Target buffer (1 cell), Beam crossing limits.
- **Performance**: Max ray segments/bounces limits.

## 3) Persistence
- `currentLevelIndex`: Track player progress.
- `generatorVersion`: Lock user to a specific generator logic version.
- `CosmeticSeed`: `Hash(installId + ":" + levelIndex)` for user-specific visuals without affecting gameplay.

## 4) Template System
- **12 Topology Families**: Vertical Corridor, Two-Chamber, Staircase, Side Channel, Central Spine, Loop Lite, Split Fanout, Merge Gate, Frame, Blocker Pivot, Dual-Zone, Decoy Lane.
- **Variants**: Every family must have at least 3 variants with `solutionSteps`.

## 5) Pipeline: Construct & Verify
1. **Derive Seed**
2. **Select Template**
3. **Instantiate**
4. **Validate** (Geometry -> Replay -> Performance)
5. **Fallback** (Swap Preset -> Simplify -> Emergency Template)

## 6) Versioning Policy
- `generatorVersion` is sacred. Never change template logic, catalog, or selector weights within the same version.
- Update `latestVersion` for major changes; existing users stay on their original version.
