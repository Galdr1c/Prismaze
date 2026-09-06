class_name CatalogBuilder
extends RefCounted

const FACTORY = preload("res://scripts/levels/generator/generator_factory.gd")
const PROFILES := ["tutorial", "easy", "medium", "hard"]
const SEED_LIMIT := 100000

# Design 6.6: for each profile, scan seeds deterministically, push every
# candidate through the generator pipeline, and keep only accepted entries.
# Same count + base_seed always rebuilds the identical catalog.
func build(count_per_profile: int, base_seed: int = 1) -> Resource:
	var catalog = load("res://scripts/levels/generator/seed_catalog.gd").new()
	var generator = FACTORY.new().create(1)
	var level_index := 1
	for profile in PROFILES:
		var found := 0
		var seed_value := base_seed
		while found < count_per_profile and seed_value - base_seed < SEED_LIMIT:
			var outcome: Dictionary = generator.generate(profile, seed_value, level_index)
			if outcome.ok:
				catalog.entries.append({
					"generator_version": outcome.generator_version,
					"level_index": level_index,
					"seed": outcome.seed,
					"signature": outcome.signature,
					"difficulty_profile": profile,
					"difficulty_score": outcome.metrics.difficulty_score,
				})
				found += 1
				level_index += 1
			seed_value += 1
	return catalog