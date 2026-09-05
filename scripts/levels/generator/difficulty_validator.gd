class_name DifficultyValidator
extends RefCounted

const SOLVER = preload("res://scripts/levels/generator/solver.gd")
const TRACER = preload("res://scripts/core/logic/ray_tracer.gd")

# Design 6.4 metrics. branch_count is the distinct solved states at the
# shortest depth (the solver's early-stopped solution_count signal). The
# score formula keeps the 6.4 weights; decision_points, prism_dependencies
# and misleading_rotations are not computed in generator v1 and contribute 0
# (documented in the implementation plan).
func evaluate(objects: Array, board_size: Vector2i) -> Dictionary:
	var result := {
		"solvable": false, "shortest_solution": 0, "solution_count": 0,
		"active_objects": 0, "irrelevant_objects": 0, "beam_length": 0.0,
		"beam_intersections": 0, "color_dependencies": 0, "branch_count": 0,
		"cycle_found": false, "difficulty_score": 0,
	}
	var solver := SOLVER.new()
	var outcome: Dictionary = solver.solve(objects, board_size)
	result.solvable = outcome.solvable
	result.shortest_solution = outcome.shortest_solution
	result.solution_count = outcome.solution_count
	result.branch_count = outcome.solution_count
	if not outcome.solvable:
		return result
	var moved: Dictionary = {}
	for id in outcome.first_solution:
		moved[id] = true
	for object in objects:
		if object.rotatable:
			if moved.has(object.id):
				result.active_objects += 1
			else:
				result.irrelevant_objects += 1
	var saved: Dictionary = {}
	for object in objects:
		if object.rotatable:
			saved[object.id] = object.orientation
	for id in outcome.first_solution:
		for object in objects:
			if object.id == id:
				object.orientation = (object.orientation + 1) % 4
				break
	var tracer := TRACER.new()
	var trace: Dictionary = tracer.trace(objects, board_size)
	result.beam_length = _beam_length(trace)
	result.beam_intersections = _intersections(trace)
	result.cycle_found = trace.loop_detected
	for object in objects:
		if object.rotatable:
			object.orientation = saved[object.id]
	result.color_dependencies = _color_dependencies(objects)
	var base: float = 0.30 * float(result.shortest_solution) + 0.20 * float(result.color_dependencies) + 0.10 * float(result.beam_intersections)
	result.difficulty_score = clampi(int(round(100.0 * base)) - 8 * int(result.irrelevant_objects), 0, 100)
	return result

func _beam_length(trace: Dictionary) -> float:
	var total := 0.0
	for segment in trace.get("segments", []):
		total += absf(segment.to.x - segment.from.x) + absf(segment.to.y - segment.from.y)
	return total

# Crossings between perpendicular beam segments, counted only at strictly
# interior points so same-beam corners and parallel overlaps stay out.
func _intersections(trace: Dictionary) -> int:
	var segments: Array = trace.get("segments", [])
	var count := 0
	for i in segments.size():
		for j in range(i + 1, segments.size()):
			if _crosses(segments[i], segments[j]):
				count += 1
	return count

func _crosses(a: Dictionary, b: Dictionary) -> bool:
	var a_horizontal: bool = a.from.y == a.to.y
	var b_horizontal: bool = b.from.y == b.to.y
	if a_horizontal == b_horizontal:
		return false
	var horizontal: Dictionary = a if a_horizontal else b
	var vertical: Dictionary = b if a_horizontal else a
	var hx1 := minf(horizontal.from.x, horizontal.to.x)
	var hx2 := maxf(horizontal.from.x, horizontal.to.x)
	var hy: float = horizontal.from.y
	var vx: float = vertical.from.x
	var vy1 := minf(vertical.from.y, vertical.to.y)
	var vy2 := maxf(vertical.from.y, vertical.to.y)
	return hx1 < vx and vx < hx2 and vy1 < hy and hy < vy2

func _color_dependencies(objects: Array) -> int:
	var count := 0
	for object in objects:
		if object.kind == 3:
			var bits := 0
			var mask: int = object.color
			for bit in [1, 2, 4]:
				if mask & bit:
					bits += 1
			if bits >= 2:
				count += 1
	return count