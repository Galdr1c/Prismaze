/// Procedural level generation system.
///
/// This library provides deterministic procedural level generation
/// for the PrisMaze puzzle game.
///
/// Key components:
/// - Models: Direction, LightColor, game objects, level structure
/// - Tables: Mirror reflection and prism behavior lookup tables
/// - RayTracer: Deterministic cell-based ray tracing
/// - RayTracerAdapter: Grid-to-pixel segment conversion
/// - Solver: BFS/A* optimal solution finder
/// - LevelGenerator: Constructive level generation pipeline
/// - LevelProvider: Abstraction for level loading and generation
/// - HintEngine: Current-state hint generation
/// - BatchValidator: Tuning and validation tools
library;

export 'models/models.dart';
export 'tables/tables.dart';
export 'ray_tracer.dart';
export 'ray_tracer_adapter.dart';
export 'solver.dart';
export 'episode_config.dart';
export 'level_generator.dart';
export 'hint_engine.dart';
export 'batch_validator.dart';
export 'campaign_loader.dart';
export 'occupancy_grid.dart';

