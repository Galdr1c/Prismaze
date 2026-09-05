class_name SolvedBoardBuilder
extends RefCounted

const TRACER = preload("res://scripts/core/logic/ray_tracer.gd")
const STATE = preload("res://scripts/core/models/game_object_state.gd")
const CELL = preload("res://scripts/core/models/grid_position.gd")
const ORIENTATION_ORDER := [3, 0, 1, 2]

# Builds the valid light path for a layout: assigns each mirror/prism an
# orientation so every source beam reaches every target, then fixes target
# colors from the masks the built path delivers. Rotatables are searched in
# placement order with ascending orientations, so the first found assignment
# is deterministic. Returns:
#   ok, objects (solved GameObjectState array), canonical_solution
#   (id -> orientation), target_colors (id -> mask).
func build(placements: Array, board_size: Vector2i) -> Dictionary:
	var rotatables: Array = []
	for item in placements:
		if item.kind in [1, 2]:
			rotatables.append(item)
	var tracer := TRACER.new()
	var assignment: Dictionary = {}
	if not _assign(placements, board_size, tracer, rotatables, 0, assignment):
		return {"ok": false, "objects": [], "canonical_solution": {}, "target_colors": {}}
	var objects := _materialize(placements, assignment)
	var trace := tracer.trace(objects, board_size)
	var colors: Dictionary = {}
	for object in objects:
		if object.kind == 3:
			colors[object.id] = trace.hits[object.id]
			object.color = colors[object.id]
	return {"ok": true, "objects": objects, "canonical_solution": assignment, "target_colors": colors}

func _assign(placements: Array, board_size: Vector2i, tracer: RefCounted, rotatables: Array, index: int, assignment: Dictionary) -> bool:
	if index == rotatables.size():
		var objects := _materialize(placements, assignment)
		var trace: Dictionary = tracer.trace(objects, board_size)
		if not trace.valid:
			return false
		var lit := true
		for object in objects:
			if object.kind == 3:
				# A dead target would be "satisfied" by the zero mask; every
				# target must actually receive light.
				var mask: int = trace.hits[object.id]
				if mask == 0:
					lit = false
					break
				object.color = mask
		if not lit:
			return false
		return tracer.trace(objects, board_size).solved
	# v1 algorithm: try canonical-friendly orientations first so staircase
	# templates (all mirrors at 3) resolve on the first leaf.
	for orientation in ORIENTATION_ORDER:
		assignment[rotatables[index].id] = orientation
		if _assign(placements, board_size, tracer, rotatables, index + 1, assignment):
			return true
	assignment.erase(rotatables[index].id)
	return false

func _materialize(placements: Array, assignment: Dictionary) -> Array:
	var objects: Array = []
	for item in placements:
		var cell := CELL.new(item.x, item.y)
		var rotatable: bool = item.kind in [1, 2]
		var orientation: int = assignment[item.id] if rotatable else item.get("orientation", 0)
		objects.append(STATE.new(item.id, item.kind, cell, orientation, rotatable, item.get("color", 7)))
	return objects