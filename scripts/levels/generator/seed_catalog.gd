class_name SeedCatalog
extends Resource

const FACTORY = preload("res://scripts/levels/generator/generator_factory.gd")

# Design 6.6: each entry carries generator_version, level_index, seed,
# signature, difficulty_profile and difficulty_score. Runtime never rolls a
# fresh seed; it regenerates an entry and verifies its signature.
@export var entries: Array[Dictionary] = []

func next(profile: String, index: int) -> Dictionary:
	var pool: Array = []
	for entry in entries:
		if entry.difficulty_profile == profile:
			pool.append(entry)
	if pool.is_empty():
		return {}
	return pool[posmod(index, pool.size())]

func regenerate(entry: Dictionary) -> Dictionary:
	var generator = FACTORY.new().create(int(entry.generator_version))
	if generator == null:
		return {"ok": false}
	var outcome: Dictionary = generator.generate(entry.difficulty_profile, int(entry.seed), int(entry.level_index))
	if not outcome.ok or outcome.signature != entry.signature:
		return {"ok": false}
	return {"ok": true, "definition": outcome.definition}

# Design 6.6: on a signature mismatch fall back to a pre-validated entry from
# the same catalog instead of generating anything new at runtime.
func emergency() -> Dictionary:
	for entry in entries:
		var result := regenerate(entry)
		if result.ok:
			return result
	return {"ok": false}