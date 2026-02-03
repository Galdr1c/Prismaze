# Findings: PrismaZe Restructuring

## Project Goals
- 6x12 grid puzzle
- Endless generation
- Deterministic RayTracer
- Vertical-only design

## Architectural Notes
- **Core**: Shared models and immutable state
- **Generator**: Template-based procedural level generation
- **Engine**: Pure logic for light simulation
- **Game**: Flame-specific rendering logic
- **Cache**: Performance optimization for procedurally generated content

## External Dependencies
- flame: ^1.19.0
- shared_preferences: ^2.2.0
- flutter_riverpod: ^2.4.0
