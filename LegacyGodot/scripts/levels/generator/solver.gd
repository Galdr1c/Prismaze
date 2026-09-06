class_name Solver
extends RefCounted

const TRACER = preload("res://scripts/core/logic/ray_tracer.gd")
# Design 6.4: counting stops as soon as two solutions are known.
const MAX_SOLUTIONS := 2

# One move rotates a single rotatable object 90 degrees. Every candidate
# state is evaluated with the RayTracer, whose solved verdict is the
# WinChecker. Rotatable objects are restored to their initial orientations
# before returning.
func solve(objects: Array, board_size: Vector2i) -> Dictionary:
	var tracer := TRACER.new()
	var rotatable: Array = []
	var start: Dictionary = {}
	for index in objects.size():
		if objects[index].rotatable:
			rotatable.append(index)
			start[objects[index].id] = objects[index].orientation
	var initial := tracer.trace(objects, board_size)
	var result := {"solvable": initial.solved, "shortest_solution": 0, "solution_count": 1 if initial.solved else 0, "first_solution": [] as Array[String]}
	if initial.solved or rotatable.is_empty():
		return result
	var visited := {_state_key(objects, rotatable, start): true}
	var queue: Array = [{"orientations": start, "depth": 0, "path": [] as Array[String]}]
	var found_depth := -1
	while not queue.is_empty() and result.solution_count < MAX_SOLUTIONS:
		var node: Dictionary = queue.pop_front()
		if found_depth >= 0 and node.depth > found_depth:
			break
		_apply(objects, rotatable, node.orientations)
		for index in rotatable:
			var object = objects[index]
			var next: Dictionary = node.orientations.duplicate()
			next[object.id] = (next[object.id] + 1) % 4
			var key := _state_key(objects, rotatable, next)
			if visited.has(key):
				continue
			visited[key] = true
			_apply(objects, rotatable, next)
			var path: Array[String] = []
			path.append_array(node.path)
			path.append(object.id)
			var trace := tracer.trace(objects, board_size)
			if trace.solved:
				if result.solution_count < MAX_SOLUTIONS:
					result.solution_count += 1
				if found_depth < 0:
					found_depth = node.depth + 1
					result.solvable = true
					result.shortest_solution = found_depth
					result.first_solution = path
				if result.solution_count >= MAX_SOLUTIONS:
					break
			else:
				queue.append({"orientations": next, "depth": node.depth + 1, "path": path})
	_apply(objects, rotatable, start)
	return result

func _apply(objects: Array, rotatable: Array, orientations: Dictionary) -> void:
	for index in rotatable:
		objects[index].orientation = orientations[objects[index].id]

func _state_key(objects: Array, rotatable: Array, orientations: Dictionary) -> String:
	var key := ""
	for index in rotatable:
		key += "%s:%d," % [objects[index].id, orientations[objects[index].id]]
	return key
