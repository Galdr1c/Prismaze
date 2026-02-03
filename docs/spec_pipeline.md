# Agent F: Construct & Verify Pipeline

## 1. Overview
The Prismaze generator uses a "Construct & Verify" approach. It does **not** solve levels at runtime; it builds them based on pre-solved templates and then validates that the specific instantiation is stable.

## 2. Pipeline Sequence
1. **Derive Recipe**:
   - Input: `levelIndex`, `generatorVersion`.
   - Output: `baseSeed`.
2. **Select Template**:
   - `TemplateSelector` picks the `Family` (history-aware) and `VariantID`.
3. **Resolve (The Fallback Loop)**:
   - Starts with `attemptIndex = 0`.
   - **Max Attempts**: 12–25.
   - For each attempt:
     a. **Instantiate**:
        - Pick `WallPreset`.
        - Inject `VariableSlots`.
        - Place `Anchors`.
     b. **Validate V0 (Geometry)**:
        - Check for overlaps and bounds.
        - If fail: increment `attemptIndex` and retry (different `attemptSeed`).
     c. **Validate V1 (Replay)**:
        - Apply `Template.solutionSteps`.
        - Run `HeadlessRayTracer` (Fixed-Point).
        - If `targets.allLit == false`: Reject.
     d. **Validate V2 (Performance)**:
        - Check `raySegments < 100`, `bounces < 20`.
        - If fail: Reject.
4. **Final Step**: If all attempts fail, default to the **Emergency Template** (Vertical Corridor V0 - Basic).

## 3. Fail Reason Matrix
| Reason | Action |
| :--- | :--- |
| Geometry Overlap | Swap `WallPreset` or pick different `VariableSlot` values. |
| Replay Fail | Downgrade to "Basic" version of the same family. |
| Performance Fail | Simplify (reduce `VariableSlot` probability). |
| MaxAttempts Reached | Instantiate `VerticalCorridor.v0_basic` (guaranteed solvable). |

## 4. Key Constraint: No Runtime Solver
Traditional "Generate & Search" solvers are too expensive (2000ms+). By using the **Replay Validator** (50ms) against pre-defined `solutionSteps`, the pipeline remains extremely fast and optimized for mobile devices.
