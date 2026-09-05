extends RefCounted

const TRACER = preload("res://scripts/core/logic/ray_tracer.gd")

var definition: Resource
var objects: Array = []
var result: Dictionary = {}
var moves: int = 0
var elapsed: float = 0.0
var _tracer := TRACER.new()

func start(level: Resource) -> void:
	definition = level
	reset()

func reset() -> void:
	objects = definition.create_states()
	moves = 0
	elapsed = 0.0
	_retrace()

func rotate(id: String) -> bool:
	if result.get("solved", false):
		return false
	for object in objects:
		if object.id == id and object.rotatable:
			object.orientation = (object.orientation + 1) % 4
			moves += 1
			_retrace()
			return true
	return false

func orientation_of(id: String) -> int:
	for object in objects:
		if object.id == id:
			return object.orientation
	return -1

func hint() -> Dictionary:
	if result.get("solved", false):
		return {}
	for id in definition.solution:
		if orientation_of(id) != definition.solution[id]:
			return {"id": id, "orientation": definition.solution[id]}
	return {}

func snapshot() -> Dictionary:
	var orientations: Dictionary = {}
	for object in objects:
		if object.rotatable:
			orientations[object.id] = object.orientation
	return {"level_id": definition.id, "fingerprint": definition.fingerprint(), "orientations": orientations, "moves": moves, "elapsed": elapsed}

func restore(data: Dictionary) -> bool:
	if data.get("level_id") != definition.id or data.get("fingerprint") != definition.fingerprint():
		return false
	var angles = data.get("orientations")
	if not angles is Dictionary or angles.size() != definition.initial_orientations().size():
		return false
	for id in definition.initial_orientations():
		var value = angles.get(id)
		if not (value is int or value is float) or value != int(value) or value < 0 or value > 3:
			return false
	var saved_moves = data.get("moves")
	var saved_time = data.get("elapsed")
	if not (saved_moves is int or saved_moves is float) or saved_moves < 0 or saved_moves != int(saved_moves):
		return false
	if not (saved_time is int or saved_time is float) or not is_finite(float(saved_time)) or saved_time < 0:
		return false
	for object in objects:
		if object.rotatable:
			object.orientation = int(angles[object.id])
	moves = int(saved_moves)
	elapsed = float(saved_time)
	_retrace()
	return true

func _retrace() -> void:
	result = _tracer.trace(objects, definition.board_size)
