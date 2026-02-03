# Task Plan: PrismaZe Restructuring (Phase 0)

## Goal
Clean the existing Flutter project and initialize the new architecture for a vertical endless puzzle game as requested.

## Current Phase
Phase 0

## Phases

### Phase 0: Project Prep
- [x] Create planning files (task_plan.md, findings.md, progress.md)
- [ ] Update `pubspec.yaml` with requested dependencies
- [ ] Restructure `lib/` directory and create subfolders
- [ ] Create empty barrel files in each subfolder
- [ ] Create README.md with project description
- [x] Initialize `main.dart` with basic Flutter boilerplate
- **Status:** complete

### Phase 1: Core Framework Implementation
- [ ] Implement game constants and colors
- [ ] Implement basic models (GridPosition, GameObject, LightColor, Direction)
- [ ] Implement deterministic utilities (Hash, RNG)
- **Status:** pending

### Phase 2: Engine Development
- [ ] Implement RayTracer (deterministic)
- [ ] Implement ColorMixer logic
- [ ] Implement StateManager and WinChecker
- **Status:** pending

### Phase 3: Generator Pipeline
- [ ] Implement Template models and Family definitions
- [ ] Create Template Catalog
- [ ] Implement Selector and Instantiator
- [ ] Implement Generator Pipeline orchestrator
- **Status:** pending

### Phase 4: Game & UI Layer
- [ ] Implement GameBoard renderer
- [ ] Implement Game Components (Mirror, Prism, etc.)
- [ ] Implement InputHandler (Tap-to-rotate)
- [ ] Build Screens (Main Menu, Game, Loading)
- **Status:** pending

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Fresh start in 6x12 grid | Simplified gameplay and vertical screen optimization |
| Deterministic Engine | Critical for cross-platform consistency and recipe-based levels |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |
