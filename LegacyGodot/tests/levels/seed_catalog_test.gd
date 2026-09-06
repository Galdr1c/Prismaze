extends RefCounted

const SESSION = preload("res://scripts/game/session/game_session.gd")

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "SeedCatalog contract failed" if not ok else ""})

func run() -> Array[Dictionary]:
	var catalog_path := "res://scripts/levels/generator/seed_catalog.gd"
	if not ResourceLoader.exists(catalog_path):
		check(catalog_path + " exists", false)
		return results
	var builder = load("res://scripts/tools/catalog_builder.gd").new()
	var catalog_script = load(catalog_path)

	var catalog: Resource = builder.build(3, 1000)
	check("Small catalog covers all profiles", catalog.entries.size() == 12)
	var required := ["generator_version", "level_index", "seed", "signature", "difficulty_profile", "difficulty_score"]
	var fields_ok := true
	var profiles := {}
	var indices := {}
	for entry in catalog.entries:
		for field in required:
			if not entry.has(field):
				fields_ok = false
		profiles[entry.difficulty_profile] = true
		indices[entry.level_index] = true
	check("Entries carry the design 6.6 fields", fields_ok)
	check("Every profile appears", profiles.size() == 4)
	check("Level indices are unique", indices.size() == catalog.entries.size())
	var rebuilt: Resource = builder.build(3, 1000)
	check("Catalog builder is deterministic", rebuilt.entries == catalog.entries)

	var pick: Dictionary = catalog.next("easy", 0)
	check("next picks the requested profile", not pick.is_empty() and pick.difficulty_profile == "easy")
	check("next rotates through the pool", catalog.next("easy", 3) == pick)
	check("next refuses unknown profiles", catalog.next("missing", 0).is_empty())

	var result: Dictionary = catalog.regenerate(pick)
	check("Regeneration matches the stored signature", result.ok and result.definition.fingerprint() == pick.signature)
	var session := SESSION.new()
	session.start(result.definition)
	var taps := 0
	for id in result.definition.solution:
		while session.orientation_of(id) != result.definition.solution[id] and taps < 200 and not session.result.solved:
			session.rotate(id)
			taps += 1
	check("Regenerated level replays to a win", session.result.solved)

	var corrupt: Dictionary = pick.duplicate()
	corrupt.signature = "deadbeef"
	check("Tampered signature is rejected", not catalog.regenerate(corrupt).ok)
	check("Emergency entry still works", catalog.emergency().ok)

	var real_path := "res://data/catalogs/endless_seed_catalog_v1.tres"
	check("Real v1 catalog file exists", ResourceLoader.exists(real_path))
	if ResourceLoader.exists(real_path):
		var real: Resource = load(real_path)
		check("Real catalog loads with entries", real.get_script() == catalog_script and real.entries.size() >= 4)
		var profiles_ok := true
		for profile in ["tutorial", "easy", "medium", "hard"]:
			var entry: Dictionary = real.next(profile, 0)
			var check_result: Dictionary = real.regenerate(entry)
			if not check_result.ok:
				profiles_ok = false
		check("Real catalog regenerates every profile", profiles_ok)
	return results