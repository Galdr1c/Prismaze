# Agent C: Determinism & RNG Rules

## 1. Floating Point Avoidance (HATA 1)
Floating point numbers (`double`) behave differently across architectures (ARM vs. x86) and compilers (Web/JS vs. Native Dart).
- **Rule**: All generation logic, collision detection, and physics simulation must use **Fixed-Point Integer Math**.
- **Scale**: Use 10,000 as the scale factor (e.g., `1.0 units = 10,000`).
- **Implementation**: `HeadlessRayTracer` uses integer coordinate systems for all intersection tests.

## 2. Canonical Ordering (HATA 2)
Maps and Sets in many languages (including Dart's default `LinkedHashMap`) can have non-deterministic iteration order if items are added based on async events or transient state.
- **Rule**: Never iterate over raw `Map.values` or `Set` during generation.
- **Fix**: Convert to a `List` and **Sort** by a stable property (like `position.hashCode` or `id`) before iteration.
- **Enforcement**: `Instantiator.instantiate` sorts the final object list.

## 3. RNG Drift Protection (HATA 3)
In "Generate & Verify" loops, using a single shared RNG instance causes "Retrial Drift." If attempt #1 fails, attempt #2's output depends on how many times `rng.nextInt()` was called during the failed attempt #1.
- **Rule**: Every generation attempt must be independent.
- **Implementation**: `attemptSeed = baseSeed + (attemptIndex * magicPrime)`. Create a fresh `DeterministicRNG` for every attempt.

## 4. Deterministic Hashing
Use a platform-agnostic hashing algorithm.
- **Choice**: SHA-256 for seeds, and a simple rolling xor/prime-multiply for transient structure hashes.
- **Avoid**: `Object.hashCode` is memory-address dependent in some runtimes and must never be used for persistable seeds. Use `GridPosition.hashCode` which is calculated as `calculatedOffset`.

## 5. Test Plan for Determinism
1. **The 100x10 Test**: Generate level $X$, 10 times in a row. Compare memory signatures.
2. **Cross-Platform Check**: Run tests in `flutter test` (VM) vs. `flutter test --platform chrome` (JS).
3. **Audit Tool**: `tool/version_guard.dart` monitors template file hashes to ensure logic is locked.
