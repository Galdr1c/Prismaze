# Agent B: Global Endless Contract & Persistence

## 1. The Global Contract (Model 1)
Every player in the world, regardless of their device, will play the exact same layout for a given level index.

- **The Formula**: `LevelSeed = SHA256(generatorVersion + ":" + levelIndex)`
- **The Result**: A deterministic `int` seed used to initialize the `DeterministicRNG`.
- **The Rule**: If two players have the same `generatorVersion` and `levelIndex`, their levels must be bitwise identical in terms of object type, position, and solution.

## 2. Persistence Layer (Local Storage)
Only the bare minimum is saved to ensure synchronization and state recovery:
1. `current_level_index` (int): The level the player is currently on.
2. `generator_version` (String): The version locked to this user's profile upon installation.
3. `best_score` / `moves` (Optional): Metadata for statistics.

## 3. Versioning Policy
To protect the Endless Contract, code changes must follow strict versioning:
- **Major Logic Change**: If a bug fix or new template family changes how a level is generated from a seed, the `generatorVersion` **MUST** be bumped (e.g., `v1` -> `v2`).
- **New Users**: Fresh installs always start with the `latestVersion`.
- **Legacy Users**: Existing users remain on their original `generator_version` to ensure their current level doesn't change mid-play. They can "opt-in" to a new version via a "Update Generator" button in settings, which will reset their current level to the start of the next sequence.

## 4. Cosmetic Diversity Seed
While the *layout* is global, the *visuals* can be personalized:
- **CosmeticSeed**: `Hash(uuid + ":" + levelIndex)`
- **Usage**: Selecting background colors, wall textures, or beam particles.
- **Restriction**: The `CosmeticSeed` **must never** be passed to the `GeneratorPipeline`. It is strictly for `View` layer components.

## 5. Migration Standard
When migrating to a new `generatorVersion`:
1. Check `userVersion` vs `latestVersion`.
2. If different, prompt the user for a "Season Update".
3. Maintain a backward-compatible `TemplateCatalog` where `v1` can still instantiate its specific historical templates.
