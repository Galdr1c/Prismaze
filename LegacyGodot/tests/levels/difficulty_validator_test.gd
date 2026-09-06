extends RefCounted

const STATE = preload("res://scripts/core/models/game_object_state.gd")
const CELL = preload("res://scripts/core/models/grid_position.gd")
const BUILDER = preload("res://scripts/levels/generator/solved_board_builder.gd")
const SCRAMBLE = preload("res://scripts/levels/generator/scramble_service.gd")

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "DifficultyValidator contract failed" if not ok else ""})

func obj(id: String, kind: int, x: int, y: int, ori: int = 0, color: int = 7, rotatable: bool = false) -> RefCounted:
	return STATE.new(id, kind, CELL.new(x, y), ori, rotatable, color)

func run() -> Array[Dictionary]:
	var validator_path := "res://scripts/levels/generator/difficulty_validator.gd"
	if not ResourceLoader.exists(validator_path):
		check(validator_path + " exists", false)
		return results
	var validator = load(validator_path).new()

	var chain: Array = BUILDER.new().build([
		{"id": "s", "kind": 0, "x": 0, "y": 0, "orientation": 1, "color": 7},
		{"id": "a", "kind": 1, "x": 2, "y": 0},
		{"id": "b", "kind": 1, "x": 2, "y": 2},
		{"id": "t", "kind": 3, "x": 5, "y": 2},
	], Vector2i(6, 12)).objects
	# Deterministic scramble: both mirrors off canonical by three rotations.
	for object in chain:
		if object.id in ["a", "b"]:
			object.orientation = 0
	var chain_metrics: Dictionary = validator.evaluate(chain, Vector2i(6, 12))
	check("Chain board is solvable in six moves", chain_metrics.solvable and chain_metrics.shortest_solution == 6)
	check("Chain board keeps both mirrors active", chain_metrics.active_objects == 2 and chain_metrics.irrelevant_objects == 0)
	check("Chain board has no cycle and some beam", not chain_metrics.cycle_found and chain_metrics.beam_length > 0)
	check("Chain board scores within bounds", chain_metrics.difficulty_score >= 0 and chain_metrics.difficulty_score <= 100)
	check("Validator is deterministic", validator.evaluate(chain, Vector2i(6, 12)) == chain_metrics)

	var direct: Array = [obj("s", 0, 0, 0, 1, 1), obj("t", 3, 3, 0, 0, 1), obj("a", 1, 4, 5, 0, 1, true)]
	var direct_metrics: Dictionary = validator.evaluate(direct, Vector2i(6, 12))
	check("Always-solved board has one irrelevant mirror", direct_metrics.solvable and direct_metrics.shortest_solution == 0 and direct_metrics.active_objects == 0 and direct_metrics.irrelevant_objects == 1)
	check("Irrelevant mirror zeroes the score", direct_metrics.difficulty_score == 0)

	var blocked: Array = [obj("s", 0, 0, 0, 1, 7), obj("a", 1, 2, 0, 0, 7, true), obj("w", 4, 2, 1), obj("t", 3, 2, 3, 0, 7)]
	var blocked_metrics: Dictionary = validator.evaluate(blocked, Vector2i(6, 12))
	check("Unsolvable board reports zeros", not blocked_metrics.solvable and blocked_metrics.shortest_solution == 0 and blocked_metrics.active_objects == 0 and blocked_metrics.irrelevant_objects == 0 and blocked_metrics.difficulty_score == 0)

	# A yellow target no single beam can satisfy: red and green sources share
	# a row, so both are required for the exact R|G mask.
	var colored: Array = [obj("s1", 0, 0, 1, 1, 1), obj("s2", 0, 1, 1, 1, 2), obj("t", 3, 3, 1, 0, 3)]
	check("Yellow target counts as color dependency", validator.evaluate(colored, Vector2i(6, 12)).color_dependencies == 1)

	var loop: Array = [obj("s", 0, 2, 2, 1, 1), obj("m1", 1, 4, 2, 0, 1, true), obj("m2", 1, 0, 2, 0, 1, true), obj("t", 3, 3, 2, 0, 1)]
	var loop_metrics: Dictionary = validator.evaluate(loop, Vector2i(6, 12))
	check("Looping solved board reports the cycle", loop_metrics.solvable and loop_metrics.shortest_solution == 0 and loop_metrics.cycle_found)
	return results