# PrisMaze Tuning Iterations Log

## Summary

After 3 iterations, we achieved stable level generation with high acceptance rates.
Current focus: Simple mirror-only configs for reliable baseline, then add complexity.

---

## Iteration 3 (CURRENT - Working Baseline)

### Changes
Simplified ALL episodes to mirror-only configs:
- No prisms, no walls, no decoys
- 2-6 moves range
- 3-4 mirrors, all rotatable
- Single target

### Results (n=20/episode)
| Ep | Accept% | Avg | p50 | Trivial | Notes |
|----|---------|-----|-----|---------|-------|
| 1  | **85%** | 2.2 | 2   | 64.7%   | ✓ Excellent |
| 2  | **65%** | 2.4 | 2   | 61.5%   | ✓ Good |
| 3  | **65%** | 2.7 | 3   | 46.2%   | ✓ Good |
| 4  | **80%** | 2.8 | 2   | 56.3%   | ✓ Excellent |
| 5  | **45%** | 2.4 | 2   | 66.7%   | Needs work |

### Analysis
- Generation is now fast (~50ms/level) and reliable
- All episodes have >45% acceptance
- Trivial wins are high (expected with simple configs)
- Solve times are 0ms (very fast)

---

## Previous Iterations

### Iteration 2 (Failed)
- Removed prisms to simplify
- E3 acceptance dropped to 10%
- Too restrictive

### Iteration 1
- Lower thresholds from original
- E4-5: 0% → 20-35%
- E3: 15% → 60%
- Working but trivial wins high

### Iteration 0 (Performance Fix)
- Reduced maxAttempts: 200 → 50
- Reduced solverBudget: 50000 → 10000
- Generation time: minutes → milliseconds

---

## Next Steps

To increase difficulty while maintaining acceptance:

1. **Increase minMoves gradually** (2 → 3 → 4)
2. **Add walls sparingly** (1-2 per level)
3. **Re-introduce prisms** (1 per level for E3+)
4. **Add colored targets** (E3+)

Goal: Maintain >60% acceptance while reducing trivial wins to <30%.

---

## Current Episode Config

```dart
// All episodes similar for now:
minMoves: 1-2, maxMoves: 4-6
mirrors: 2-4, prisms: 0
rotatable: 2-4, targets: 1
walls: 0, decoys: 0
```

Generation is working reliably. Ready for gradual difficulty increase.
