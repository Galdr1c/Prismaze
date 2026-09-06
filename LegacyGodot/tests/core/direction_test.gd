extends RefCounted

const DIRECTION_PATH := "res://scripts/core/models/direction.gd"


func run() -> Array[Dictionary]:
	return [
		_test_rotate_right_turns_north_to_east(),
		_test_to_delta_returns_north_vector(),
		_test_to_delta_maps_remaining_cardinal_vectors(),
	]


func _test_rotate_right_turns_north_to_east() -> Dictionary:
	const test_name := "Direction rotate_right turns north to east"

	if not ResourceLoader.exists(DIRECTION_PATH):
		return _failure(test_name, "Direction production script is missing")

	var direction_script: Script = load(DIRECTION_PATH)
	var direction_rules: RefCounted = direction_script.new()

	if not direction_rules.has_method("rotate_right"):
		return _failure(test_name, "Direction.rotate_right is missing")

	if direction_rules.call("rotate_right", 0) != 1:
		return _failure(test_name, "Expected north (0) to rotate to east (1)")

	return _success(test_name)


func _test_to_delta_returns_north_vector() -> Dictionary:
	const test_name := "Direction to_delta returns the north vector"

	var direction_script: Script = load(DIRECTION_PATH)
	var direction_rules: RefCounted = direction_script.new()

	if not direction_rules.has_method("to_delta"):
		return _failure(test_name, "Direction.to_delta is missing")

	if direction_rules.call("to_delta", 0) != Vector2i(0, -1):
		return _failure(test_name, "Expected north (0) to map to Vector2i(0, -1)")

	return _success(test_name)


func _test_to_delta_maps_remaining_cardinal_vectors() -> Dictionary:
	const test_name := "Direction to_delta maps east south and west"

	var direction_script: Script = load(DIRECTION_PATH)
	var direction_rules: RefCounted = direction_script.new()
	var passed: bool = (
		direction_rules.call("to_delta", 1) == Vector2i(1, 0)
		and direction_rules.call("to_delta", 2) == Vector2i(0, 1)
		and direction_rules.call("to_delta", 3) == Vector2i(-1, 0)
	)

	if not passed:
		return _failure(test_name, "Expected east, south and west unit vectors")

	return _success(test_name)


func _success(test_name: String) -> Dictionary:
	return {
		"name": test_name,
		"passed": true,
		"message": "",
	}


func _failure(test_name: String, message: String) -> Dictionary:
	return {
		"name": test_name,
		"passed": false,
		"message": message,
	}
