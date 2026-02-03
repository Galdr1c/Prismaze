# Agent E: Selector Specification (v1)

## 1. Pacing Model: Buckets
To ensure a gradual progression of difficulty, levels are grouped into buckets.

- **Bucket Size**: 20 levels.
- **Bucket Index**: `levelIndex // 20`.
- **Tutorial Band**: 0-200 levels (Buckets 0-10) prioritize simpler families.

## 2. Weight Distribution (Tutorial Phase 0-200)
| Family | Weight (Bucket 0-5) | Weight (Bucket 6-10) |
| :--- | :--- | :--- |
| Vertical Corridor | 50 | 30 |
| Two-Chamber | 30 | 20 |
| Staircase | 15 | 20 |
| Side Channel | 5 | 15 |
| Others | 0 | 15 (Spread) |

## 3. Cooldown Logic
To avoid visual repetition, a "History Window" prevents recently used families from appearing too soon.

- **Window Size**: 6 levels.
- **Rule**: If a `TemplateFamily` was selected in the last 6 levels, its weight is reduced to **0**.
- **Edge Case (eligible == 0)**: If all families are on cooldown, the window is halved (3 levels).
- **Edge Case (eligible == 1)**: If only one family remains, force a `variantId` change or `WallPreset` shuffle to maintain variety.

## 4. Deterministic Weighted Pick
1. Get `stepSeed = Hash(version : levelIndex)`.
2. Get Weights based on `levelIndex`.
3. Filter out families in the Cooldown History.
4. **Sort** the remaining eligible families by `index` (Canonical Order).
5. Perform a weighted random roll using `DeterministicRNG(stepSeed)`.

## 5. Progression Curve (500+)
After level 500, logic-heavy families (Merge Gate, Decoy Lane, Blocker Pivot) reach their peak weights (~15% each), while "Vertical Corridor" drops to a background frequency (~5%).
