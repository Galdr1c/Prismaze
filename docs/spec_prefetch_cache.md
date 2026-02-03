# Agent G: Prefetch/Cache Runtime Plan

## 1. Goal
Provide a zero-latency "Continue" experience. The next puzzle should be ready to display the moment the current one is completed.

## 2. The Cache Strategy
- **Buffer Size**: 
  - `targetPrefetch`: 5 levels.
  - `minReady`: 3 levels.
- **Eviction**: LRU (Least Recently Used), though typically we only move forward in `levelIndex`.

## 3. Background Processing
- All level generation (`deriveSeed`, `instantiate`, `validate`) must occur on a background thread (or via asynchronous `Isolate` in Flutter).
- **Triggers**:
  - **Cold Start**: Main Menu launch triggers prefetch for `currentLevelIndex` to `currentLevelIndex + 5`.
  - **Completion**: Completing `Level X` triggers prefetch for `Level X + 6`.

## 4. Save & Crash-Safe Behavior
- **Index Update**: The `currentLevelIndex` in persistence is ONLY incremented when the "Level Complete" animation finishes and the user clicks "Continue".
- **State Recovery**:
  1. On launch, check `currentLevelIndex`.
  2. Instantiate from `v1:currentLevelIndex`.
  3. If same, restore the level as it was.
- **Atomic Writes**: Save the index before clearing the "current level" from the prefetch cache.

## 5. UI Thread Interaction
- Use a `LoadingNotifier` to prevent the "Start" button from being clickable until `minReady` is met (usually < 100ms).
- If the background thread is lagging, show a themed "Building Optical Circuit..." spinner.

## 6. Memory Management
Generated `Level` objects are small (~2-5KB). Storing 10 in memory is negligible (~50KB). Only heavy assets (textures) should be managed via a separate LRU cache.
