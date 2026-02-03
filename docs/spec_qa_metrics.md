# Agent H: QA/CI & Metrics Plan

## 1. Determinism Audit (The Golden Rule)
- **Target**: Same Seed = Same Level Output.
- **Test**: Run `determinism_test.dart` generating 100 levels across Native VM and Web (Chrome).
- **Verification**: Byte-for-byte matching of the computed `LevelSignature`.

## 2. Replay Validation Suite
- **Sample**: Random selection of 50-100 levels.
- **Check**: Run `ReplayValidator` (Fixed-Point Integer). 
- **Requirement**: **100% Solvability**. Any failure triggers a CI block.

## 3. Diversity & Pacing Metrics
| Metric | Description | Target |
| :--- | :--- | :--- |
| **Family Spread** | Percentage of each Structural Family over 1000 levels. | ~8% per family. |
| **Unique Ratio** | Number of unique `LevelSignatures` over 1000 seeds. | 1.0 (Zero collisions). |
| **Cooldown Violations** | Number of times a family repeats within 6 levels. | 0. |

## 4. Performance Guardrails
- **Max Ray Count**: 50.
- **Max Bounces**: 20.
- **Max Generation Latency**: 500ms (95th percentile).
- **Validation**: Enforced by `test/qa/performance_test.dart`.

## 5. Build-Time Reports
Every PR must generate a `qa_report.json` with the following format:
```json
{
  "version": "v1",
  "template_hash": "ef577ec4",
  "determinism_pass": true,
  "solvability": 1.0,
  "p95_latency_ms": 12,
  "family_distribution": {
    "verticalCorridor": 0.12,
    "twoChamber": 0.09,
    ...
  }
}
```

## 6. Version Guard Integration
Fail the CI if `generatorVersion` is `v1` but `lib/generator/templates` has a different hash than the one recorded in `tool/template_version.lock`.
