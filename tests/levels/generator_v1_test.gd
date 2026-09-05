extends RefCounted

const SESSION = preload("res://scripts/game/session/game_session.gd")

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "GeneratorV1 contract failed" if not ok else ""})

func run() -> Array[Dictionary]:
	var path := "res://scripts/levels/generator/generator_v1.gd"
	if not ResourceLoader.exists(path):
		check(path + " exists", false)
		return results
	var generator = load(path).new()
	# Design 6.5: moves range and max irrelevant objects per profile.
	var profiles := {"tutorial": [1, 3, 0, 901], "easy": [2, 5, 1, 902], "medium": [5, 9, 2, 903], "hard": [8, 14, 2, 904]}
	for profile in profiles:
		var outcome := {}
		for seed_value in range(1, 31):
			var candidate: Dictionary = generator.generate(profile, seed_value, profiles[profile][3])
			if candidate.ok:
				outcome = candidate
				break
		check("%s generates an accepted level" % [profile], not outcome.is_empty())
		if outcome.is_empty():
			continue
		var definition = outcome.definition
		check("%s definition carries metadata" % [profile], definition.id == profiles[profile][3] and definition.solution.size() > 0 and definition.par_moves == outcome.metrics.shortest_solution)
		check("%s signature matches fingerprint" % [profile], outcome.signature == definition.fingerprint())
		check("%s moves within profile" % [profile], outcome.metrics.shortest_solution >= profiles[profile][0] and outcome.metrics.shortest_solution <= profiles[profile][1])
		check("%s no cycle and few irrelevant objects" % [profile], not outcome.metrics.cycle_found and outcome.metrics.irrelevant_objects <= profiles[profile][2])
		var session := SESSION.new()
		session.start(definition)
		var taps := 0
		for id in definition.solution:
			while session.orientation_of(id) != definition.solution[id] and taps < 200 and not session.result.solved:
				session.rotate(id)
				taps += 1
		check("%s canonical replay wins" % [profile], session.result.solved)
		var again: Dictionary = generator.generate(profile, outcome.seed, profiles[profile][3])
		check("%s regenerates identically" % [profile], again.ok and again.definition.fingerprint() == definition.fingerprint() and again.metrics == outcome.metrics)
	return results