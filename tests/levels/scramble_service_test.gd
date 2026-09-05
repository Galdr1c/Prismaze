extends RefCounted

const SOLVER = preload("res://scripts/levels/generator/solver.gd")

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "ScrambleService contract failed" if not ok else ""})

func _differs(initial: Dictionary, canonical: Dictionary) -> bool:
	for id in canonical:
		if initial[id] != canonical[id]:
			return true
	return false

func _built_board() -> Array:
	var builder = load("res://scripts/levels/generator/solved_board_builder.gd").new()
	var outcome: Dictionary = builder.build([
		{"id": "s", "kind": 0, "x": 0, "y": 0, "orientation": 1, "color": 7},
		{"id": "a", "kind": 1, "x": 2, "y": 0},
		{"id": "b", "kind": 1, "x": 2, "y": 2},
		{"id": "t", "kind": 3, "x": 5, "y": 2},
	], Vector2i(6, 12))
	return outcome.objects

func run() -> Array[Dictionary]:
	var service_path := "res://scripts/levels/generator/scramble_service.gd"
	if not ResourceLoader.exists(service_path):
		check(service_path + " exists", false)
		return results
	var service = load(service_path).new()
	var solver := SOLVER.new()

	var objects := _built_board()
	var canonical: Dictionary = {}
	for object in objects:
		if object.rotatable:
			canonical[object.id] = object.orientation

	var first: Dictionary = service.scramble(objects, Vector2i(6, 12), 20260904)
	check("Scramble reports success", first.ok)
	check("Scramble changes at least one orientation", _differs(first.initial_orientations, canonical))
	var fresh := _built_board()
	service.scramble(fresh, Vector2i(6, 12), 20260904)
	check("Scrambled start is not solved", not solver.solve(fresh, Vector2i(6, 12)).solvable == false and not solver.solve(fresh, Vector2i(6, 12)).shortest_solution == 0)
	var replay: Dictionary = solver.solve(fresh, Vector2i(6, 12))
	check("Scrambled board remains solvable", replay.solvable and replay.shortest_solution >= 1)
	check("Canonical is reachable from the scrambled start", replay.shortest_solution <= 4 * canonical.size())

	var second_objects := _built_board()
	var second: Dictionary = service.scramble(second_objects, Vector2i(6, 12), 20260904)
	check("Same seed reproduces the same scramble", second == first)

	var distinct := {}
	for seed_value in range(1, 21):
		var outcome: Dictionary = service.scramble(_built_board(), Vector2i(6, 12), seed_value)
		if outcome.ok:
			distinct[outcome.initial_orientations] = true
	check("Different seeds produce different scrambles", distinct.size() >= 2)

	var state_script = load("res://scripts/core/models/game_object_state.gd")
	var cell_script = load("res://scripts/core/models/grid_position.gd")
	var direct: Array = [
		state_script.new("s", 0, cell_script.new(0, 0), 1, false, 1),
		state_script.new("t", 3, cell_script.new(3, 0), 0, false, 1),
		state_script.new("a", 1, cell_script.new(4, 5), 0, true, 1),
	]
	var stuck: Dictionary = service.scramble(direct, Vector2i(6, 12), 7)
	check("Always-solved board fails instead of looping", not stuck.ok and stuck.initial_orientations.is_empty())
	return results