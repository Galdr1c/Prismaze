extends RefCounted

const STATE = preload("res://scripts/core/models/game_object_state.gd")
const CELL = preload("res://scripts/core/models/grid_position.gd")
var results: Array[Dictionary] = []

func check(label: String, passed: bool) -> void:
	results.append({"name": label, "passed": passed, "message": "Optical contract failed" if not passed else ""})

func obj(id: String, kind: int, x: int, y: int, ori: int = 0, color: int = 7) -> RefCounted:
	return STATE.new(id, kind, CELL.new(x, y), ori, kind in [1, 2], color)

func run() -> Array[Dictionary]:
	var path := "res://scripts/core/logic/ray_tracer.gd"
	if not ResourceLoader.exists(path):
		check("RayTracer is available", false)
		return results
	var tracer = load(path).new()
	var source = obj("s", 0, 0, 2, 1, 1)
	var target = obj("t", 3, 4, 2, 0, 1)
	check("Straight red beam satisfies target", tracer.trace([source, target], Vector2i(6, 12)).solved)
	check("No targets is not a win", not tracer.trace([source], Vector2i(6, 12)).solved)
	check("Wall blocks target", not tracer.trace([source, obj("w", 4, 2, 2), target], Vector2i(6, 12)).solved)
	check("Target passes light onward", tracer.trace([source, target, obj("t2", 3, 5, 2, 0, 1)], Vector2i(6, 12)).solved)
	var expected := [[-1, 3, -1, 1], [1, 0, 3, 2], [2, -1, 0, -1], [3, 2, 1, 0]]
	for ori in range(4):
		for incoming in range(4):
			check("Mirror %d travel direction %d" % [ori, incoming], tracer.reflect(incoming, ori) == expected[ori][incoming])
	check("Reflection routes east to north", tracer.trace([source, obj("m", 1, 4, 2, 1), obj("t", 3, 4, 0, 0, 1)], Vector2i(6, 12)).solved)
	var mix_objects := [source, obj("b", 0, 4, 0, 2, 4), obj("t", 3, 4, 2, 0, 5)]
	check("Two rays combine only at target", tracer.trace(mix_objects, Vector2i(6, 12)).solved)
	mix_objects.append(obj("g", 0, 5, 2, 3, 2))
	check("Extra green rejects purple target", not tracer.trace(mix_objects, Vector2i(6, 12)).solved)
	check("Crossings do not recolor rays", tracer.trace([source, obj("b", 0, 2, 0, 2, 4), target, obj("bt", 3, 2, 5, 0, 4)], Vector2i(6, 12)).solved)
	check("White splits into RGB ports", tracer.trace([obj("s", 0, 2, 0, 2), obj("p", 2, 2, 4, 2), obj("r", 3, 2, 8, 0, 1), obj("g", 3, 0, 4, 0, 2), obj("b", 3, 5, 4, 0, 4)], Vector2i(6, 12)).solved)
	for mask in [1, 2, 3, 4, 5, 6]:
		check("Prism passes mask %d unchanged" % mask, tracer.trace([obj("s", 0, 0, 2, 1, mask), obj("p", 2, 2, 2), obj("t", 3, 5, 2, 0, mask)], Vector2i(6, 12)).solved)
	var loop = tracer.trace([source, obj("m1", 1, 4, 2), obj("m2", 1, 0, 2)], Vector2i(6, 12))
	# A source inside two opposing mirrors: no overlapping fixture.
	loop = tracer.trace([obj("s", 0, 2, 2, 1, 1), obj("m1", 1, 4, 2), obj("m2", 1, 0, 2)], Vector2i(6, 12))
	check("Mirror loop terminates", loop.loop_detected and loop.segments.size() < 100)
	var overlap = tracer.trace([source, obj("duplicate", 4, 0, 2), target], Vector2i(6, 12))
	check("Overlapping objects rejected", not overlap.valid and not overlap.solved)
	return results
