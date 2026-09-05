class_name RayTracer
extends RefCounted

const DELTAS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
# Rows: | / - \\ ; columns: travelling N E S W; -1 absorbs.
const REFLECTIONS := [[-1, 3, -1, 1], [1, 0, 3, 2], [2, -1, 0, -1], [3, 2, 1, 0]]

func reflect(travel: int, orientation: int) -> int:
	return REFLECTIONS[posmod(orientation, 4)][travel]

func trace(objects: Array, board_size: Vector2i) -> Dictionary:
	var output := {"segments": [], "hits": {}, "solved": false, "loop_detected": false, "valid": true}
	var grid: Dictionary = {}
	var targets: Array = []
	var queue: Array = []
	var ids: Dictionary = {}
	for object in objects:
		var cell := Vector2i(object.position.x, object.position.y)
		if not _inside(cell, board_size) or grid.has(cell) or ids.has(object.id):
			output.valid = false
			return output
		grid[cell] = object
		ids[object.id] = true
		if object.kind == 0:
			queue.append({"cell": cell, "direction": object.orientation, "color": object.color, "path": {}})
		elif object.kind == 3:
			targets.append(object)
			output.hits[object.id] = 0
	var processed: Dictionary = {}
	var index := 0
	while index < queue.size():
		var ray: Dictionary = queue[index]
		index += 1
		var cell: Vector2i = ray.cell
		var direction: int = ray.direction
		var color: int = ray.color
		var segment_start := Vector2(cell) + Vector2(0.5, 0.5)
		var path: Dictionary = ray.path
		while true:
			var key := "%d,%d,%d,%d" % [cell.x, cell.y, direction, color]
			if path.has(key):
				output.loop_detected = true
				break
			if processed.has(key):
				break
			path[key] = true
			processed[key] = true
			var next: Vector2i = cell + DELTAS[direction]
			var end := Vector2(next) + Vector2(0.5, 0.5)
			if not _inside(next, board_size):
				end = Vector2(cell) + Vector2(0.5, 0.5) + Vector2(DELTAS[direction]) * 0.5
				_segment(output, segment_start, end, color)
				break
			var object = grid.get(next)
			if object == null or object.kind == 0:
				cell = next
				continue
			if object.kind == 3:
				output.hits[object.id] |= color
				cell = next
				continue
			_segment(output, segment_start, end, color)
			if object.kind == 4:
				break
			if object.kind == 1:
				var outgoing := reflect(direction, object.orientation)
				if outgoing >= 0:
					queue.append({"cell": next, "direction": outgoing, "color": color, "path": path.duplicate()})
			elif object.kind == 2:
				if color == 7:
					for port in [[0, 1], [1, 2], [3, 4]]:
						queue.append({"cell": next, "direction": (port[0] + object.orientation) % 4, "color": port[1], "path": path.duplicate()})
				else:
					queue.append({"cell": next, "direction": direction, "color": color, "path": path.duplicate()})
			break
	output.solved = not targets.is_empty()
	for target in targets:
		if output.hits[target.id] != target.color:
			output.solved = false
	return output

func _inside(cell: Vector2i, size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y

func _segment(output: Dictionary, start: Vector2, end: Vector2, color: int) -> void:
	if start != end:
		output.segments.append({"from": start, "to": end, "color": color})
