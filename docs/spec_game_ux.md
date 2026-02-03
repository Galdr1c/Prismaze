# Agent A: Game/UX Specification (Endless-Only)

## 1. Concept: "The Optical Weaver"
You are an engineer in the subterranean city of Prismaze, responsible for maintaining the "Optical Circuitry" that powers the city's life support systems. Pure energetic light must be directed through ancient crystalline relays to power up core receivers.

## 2. Core Gameplay Loop
1.  **Level Start**: A 6x12 grid appears with fixed objects (Sources, Targets, Blocks) and rotatable interactive objects (Mirrors, Prisms).
2.  **Interaction**: Player taps interactive objects to rotate them 90° clockwise.
3.  **Real-time Feedback**: Beams update instantly as objects rotate.
4.  **Verification**: The circuit is "Completed" when all Targets receive their required light frequency (color).
5.  **Progression**: `levelIndex` increments, and a new "Recipe" is fetched/generated for the next challenge.

## 3. Controls
- **Tap/Click**: Rotate object 90° clockwise.
- **Hold (Long Press)**: Show "Path Preview" (Optional UX polish).
- **Drag**: *Disabled in v1* (Placement is fixed by the template).

## 4. Win/Loss Conditions
- **Win**: All Targets are lit with the correct color.
- **Loss**: No "Loss" state exists in Endless mode. If stuck, the player can use a **Hint** (highlights a correct rotation) or **Reset** the level.

## 5. Game Flow (Continue-centric)
- **Launch**: Splash Screen -> Main Menu.
- **Main Menu**: Large "CONTINUE" button (jumps to the latest incomplete `levelIndex`). Small "Settings/Stats" buttons below.
- **Level Transition**: Smooth transition between levels. Next level pre-instantiated in the background.

## 6. Minimal UI Screens
### A. Main Menu
- **Title**: Prismaze
- **Primary Action**: `[CONTINUE LEVEL XXX]`
- **Secondary Actions**: 
  - `[Statistics]` (Records, time played).
  - `[Settings]` (Audio, Haptics, High Contrast, Reduced Glow).

### B. In-Game HUD
- **Top Bar**: Level Index, Back Button.
- **Bottom Bar**: Reset Button, Hint Button (if available), Settings Gear.

## 7. UX Guidelines (6x12 Grid)
- **Tutorial Buffer**: The first 20 levels of `v1` are restricted to "Structural Families" with 1-2 mirrors max.
- **Visual Hygiene**: 
  - Sources are always placed on the outer edge (Y=0 or Y=11 usually).
  - Targets must have at least 1 empty neighbor to ensure the beam can actually enter.
  - Beam crossing is visually distinct (subtle glow at intersection).
  - Max 40 total beam segments per level to avoid visual noise.
