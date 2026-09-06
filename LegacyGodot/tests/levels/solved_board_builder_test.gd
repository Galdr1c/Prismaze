extends RefCounted

const TRACER = preload("res://scripts/core/logic/ray_tracer.gd")
const SOLVER = preload("res://scripts/levels/generator/solver.gd")

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "SolvedBoardBuilder contract failed" if not ok else ""})

func run() -> Array[Dictionary]:
	var builder_path := "res://scripts/levels/generator/solved_board_builder.gd"
	if not ResourceLoader.exists(builder_path):
		check(builder_path + " exists", false)
		return results
	var builder = load(builder_path).new()
	var tracer := TRACER.new()

	var simple: Dictionary = builder.build([
		{"id": "s", "kind": 0, "x": 0, "y": 4, "orientation": 1, "color": 7},
		{"id": "m1", "kind": 1, "x": 3, "y": 4},
		{"id": "t", "kind": 3, "x": 3, "y": 9},
	], Vector2i(6, 12))
	check("Simple layout builds", simple.ok and simple.canonical_solution == {"m1": 3} and simple.target_colors == {"t": 7})
	var simple_trace: Dictionary = tracer.trace(simple.objects, Vector2i(6, 12))
	check("Built board is solved", simple.ok and simple_trace.solved)
	var simple_solver: Dictionary = SOLVER.new().solve(simple.objects, Vector2i(6, 12))
	check("Built board wins immediately for the solver", simple_solver.solvable and simple_solver.shortest_solution == 0 and simple_solver.solution_count == 1)

	var chain: Dictionary = builder.build([
		{"id": "s", "kind": 0, "x": 0, "y": 0, "orientation": 1, "color": 7},
		{"id": "a", "kind": 1, "x": 2, "y": 0},
		{"id": "b", "kind": 1, "x": 2, "y": 2},
		{"id": "t", "kind": 3, "x": 5, "y": 2},
	], Vector2i(6, 12))
	check("Two-mirror chain has a unique canonical", chain.ok and chain.canonical_solution == {"a": 3, "b": 3})

	var prism: Dictionary = builder.build([
		{"id": "s", "kind": 0, "x": 0, "y": 0, "orientation": 1, "color": 7},
		{"id": "p", "kind": 2, "x": 2, "y": 0},
		{"id": "t1", "kind": 3, "x": 5, "y": 0},
		{"id": "t2", "kind": 3, "x": 2, "y": 11},
	], Vector2i(6, 12))
	check("Prism split gets canonical orientation", prism.ok and prism.canonical_solution == {"p": 1})
	check("Target colors follow delivered masks", prism.ok and prism.target_colors == {"t1": 1, "t2": 2})
	check("Prism board traces solved", prism.ok and tracer.trace(prism.objects, Vector2i(6, 12)).solved)

	var blocked: Dictionary = builder.build([
		{"id": "s", "kind": 0, "x": 0, "y": 0, "orientation": 1, "color": 7},
		{"id": "a", "kind": 1, "x": 2, "y": 0},
		{"id": "w", "kind": 4, "x": 2, "y": 1},
		{"id": "t", "kind": 3, "x": 2, "y": 3},
	], Vector2i(6, 12))
	check("Blocked layout reports no build", not blocked.ok and blocked.objects.is_empty() and blocked.canonical_solution.is_empty())

	var repeated: Dictionary = builder.build([
		{"id": "s", "kind": 0, "x": 0, "y": 0, "orientation": 1, "color": 7},
		{"id": "a", "kind": 1, "x": 2, "y": 0},
		{"id": "b", "kind": 1, "x": 2, "y": 2},
		{"id": "t", "kind": 3, "x": 5, "y": 2},
	], Vector2i(6, 12))
	check("Builder is deterministic", repeated.canonical_solution == chain.canonical_solution and repeated.target_colors == chain.target_colors)
	return results
