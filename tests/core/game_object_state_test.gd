extends RefCounted

const GRID_POSITION_PATH := "res://scripts/core/models/grid_position.gd"
const GAME_OBJECT_STATE_PATH := "res://scripts/core/models/game_object_state.gd"


func run() -> Array[Dictionary]:
	return [
		_test_constructs_a_mirror_state(),
	]


func _test_constructs_a_mirror_state() -> Dictionary:
	const test_name := "GameObjectState constructs a mirror state"

	if not ResourceLoader.exists(GAME_OBJECT_STATE_PATH):
		return _failure(test_name, "GameObjectState production script is missing")

	var grid_position_script: Script = load(GRID_POSITION_PATH)
	var position: RefCounted = grid_position_script.new(2, 5)
	var state_script: Script = load(GAME_OBJECT_STATE_PATH)
	var mirror: RefCounted = state_script.new("mirror_2_5", 1, position, 0, true)
	var passed: bool = (
		mirror.get("id") == "mirror_2_5"
		and mirror.get("kind") == 1
		and mirror.get("position") == position
		and mirror.get("orientation") == 0
		and mirror.get("rotatable") == true
	)

	if not passed:
		return _failure(test_name, "Mirror state fields did not match constructor input")

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
