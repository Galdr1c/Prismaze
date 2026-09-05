extends RefCounted

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "Session contract failed" if not ok else ""})

func run() -> Array[Dictionary]:
	var paths := ["res://scripts/levels/level_catalog.gd", "res://scripts/game/session/game_session.gd"]
	for path in paths:
		if not ResourceLoader.exists(path):
			check(path + " exists", false)
			return results
	var catalog = load(paths[0]).new()
	var session = load(paths[1]).new()
	check("Campaign contains twelve levels", catalog.count() == 12)
	for i in range(12):
		var definition = catalog.get_level(i)
		session.start(definition)
		check("Level %d starts unsolved" % (i + 1), not session.result.solved)
		var start_orientations: Dictionary = session.snapshot().orientations.duplicate()
		var hint = session.hint()
		check("Level %d has a hint" % (i + 1), not hint.is_empty())
		var taps := 0
		for id in definition.solution:
			while session.orientation_of(id) != definition.solution[id] and taps < 200 and not session.result.solved:
				session.rotate(id)
				taps += 1
		check("Level %d canonical replay wins" % (i + 1), session.result.solved)
		check("Level %d definition unchanged" % (i + 1), definition.initial_orientations() == start_orientations)
		var won_moves: int = session.moves
		session.rotate("m1")
		check("Completed level rejects input", session.moves == won_moves)
		session.reset()
		check("Reset restores original board and counter", not session.result.solved and session.moves == 0 and session.snapshot().orientations == start_orientations)
	session.start(catalog.get_level(0))
	var snapshot: Dictionary = session.snapshot()
	session.rotate("does-not-exist")
	session.rotate("s")
	check("Fixed and missing objects are not moves", session.snapshot() == snapshot)
	session.rotate("m1")
	check("First level solves in one tap", session.result.solved and session.moves == 1)
	check("Victory hides canonical hint", session.hint().is_empty())
	session.start(catalog.get_level(3))
	session.rotate("m1")
	var saved: Dictionary = session.snapshot()
	var restored = load(paths[1]).new()
	restored.start(catalog.get_level(3))
	check("Snapshot restoration accepted", restored.restore(saved))
	check("Snapshot restores moves and orientation", restored.snapshot() == saved)
	var corrupt := saved.duplicate(true)
	corrupt.orientations["m1"] = 999
	check("Corrupt snapshot rejected atomically", not restored.restore(corrupt) and restored.snapshot() == saved)
	return results
