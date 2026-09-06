extends RefCounted

const TRACER = preload("res://scripts/core/logic/ray_tracer.gd")
const STATE = preload("res://scripts/core/models/game_object_state.gd")
const CELL = preload("res://scripts/core/models/grid_position.gd")

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "Solver contract failed" if not ok else ""})

func run() -> Array[Dictionary]:
	var solver_path := "res://scripts/levels/generator/solver.gd"
	if not ResourceLoader.exists(solver_path):
		check(solver_path + " exists", false)
		return results
	var solver = load(solver_path).new()
	var catalog = load("res://scripts/levels/level_catalog.gd").new()
	var session = load("res://scripts/game/session/game_session.gd").new()

	for i in range(12):
		var definition = catalog.get_level(i)
		session.start(definition)
		var outcome: Dictionary = solver.solve(session.objects, definition.board_size)
		check("Level %d is solvable" % (i + 1), outcome.solvable and outcome.solution_count >= 1)
		var canonical := 0
		var starts: Dictionary = definition.initial_orientations()
		for id in definition.solution:
			canonical += posmod(int(definition.solution[id]) - int(starts[id]), 4)
		check("Level %d shortest is at most canonical" % (i + 1), outcome.shortest_solution <= canonical and outcome.shortest_solution > 0)
		check("Level %d path length matches shortest" % (i + 1), outcome.first_solution.size() == outcome.shortest_solution)
		var replay := 0
		for id in outcome.first_solution:
			if not session.result.solved and session.rotate(str(id)):
				replay += 1
		check("Level %d solver path replay wins" % (i + 1), session.result.solved and replay == outcome.shortest_solution)

	var first = catalog.get_level(0)
	session.start(first)
	var once: Dictionary = solver.solve(session.objects, first.board_size)
	check("First level solves in one move", once.shortest_solution == 1 and once.first_solution == ["m1"])
	var again: Dictionary = solver.solve(session.objects, first.board_size)
	check("Solver is deterministic across runs", again == once)

	var blocked: Array = first.create_states()
	blocked.append(STATE.new("w", 4, CELL.new(3, 5), 0, false, 7))
	var walled: Dictionary = solver.solve(blocked, first.board_size)
	check("Walled board reports no solution", not walled.solvable and walled.shortest_solution == 0 and walled.solution_count == 0 and walled.first_solution.is_empty())

	# Either mirror alone can light the target: both beams start absorbed and
	# each mirror's one-move reflection reaches t by a different route.
	var objects: Array = [
		STATE.new("s1", 0, CELL.new(0, 0), 1, false, 1),
		STATE.new("a", 1, CELL.new(2, 0), 2, true, 1),
		STATE.new("t", 3, CELL.new(2, 3), 0, false, 1),
		STATE.new("s2", 0, CELL.new(0, 6), 1, false, 1),
		STATE.new("b", 1, CELL.new(2, 6), 2, true, 1),
	]
	var twin: Dictionary = solver.solve(objects, Vector2i(6, 12))
	check("Twin mirrors yield two one-move solutions", twin.solvable and twin.shortest_solution == 1 and twin.solution_count == 2)
	return results
