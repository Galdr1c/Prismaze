extends RefCounted

const GRID_POSITION_PATH := "res://scripts/core/models/grid_position.gd"


func run() -> Array[Dictionary]:
	return [
		_test_constructs_with_requested_coordinates(),
		_test_reports_inside_board_as_valid(),
		_test_shift_returns_offset_position(),
		_test_step_moves_one_cell_in_direction(),
	]


func _test_constructs_with_requested_coordinates() -> Dictionary:
	const test_name := "GridPosition constructs with requested coordinates"

	if not ResourceLoader.exists(GRID_POSITION_PATH):
		return _failure(test_name, "GridPosition production script is missing")

	var grid_position_script: Script = load(GRID_POSITION_PATH)
	var position: RefCounted = grid_position_script.new(2, 3)
	var passed: bool = position.get("x") == 2 and position.get("y") == 3

	if not passed:
		return _failure(test_name, "Expected x=2 and y=3")

	return _success(test_name)


func _test_reports_inside_board_as_valid() -> Dictionary:
	const test_name := "GridPosition reports an inside board cell as valid"

	var grid_position_script: Script = load(GRID_POSITION_PATH)
	var position: RefCounted = grid_position_script.new(5, 11)

	if not position.has_method("is_valid"):
		return _failure(test_name, "GridPosition.is_valid is missing")

	if not position.call("is_valid"):
		return _failure(test_name, "Expected (5, 11) to be inside the 6x12 board")

	return _success(test_name)


func _test_shift_returns_offset_position() -> Dictionary:
	const test_name := "GridPosition shift returns an offset position"

	var grid_position_script: Script = load(GRID_POSITION_PATH)
	var start: RefCounted = grid_position_script.new(2, 3)

	if not start.has_method("shift"):
		return _failure(test_name, "GridPosition.shift is missing")

	var shifted: RefCounted = start.call("shift", -1, 4)
	var passed: bool = shifted.get("x") == 1 and shifted.get("y") == 7

	if not passed:
		return _failure(test_name, "Expected shifted position (1, 7)")

	return _success(test_name)


func _test_step_moves_one_cell_in_direction() -> Dictionary:
	const test_name := "GridPosition step moves one cell in a direction"

	var grid_position_script: Script = load(GRID_POSITION_PATH)
	var start: RefCounted = grid_position_script.new(2, 3)

	if not start.has_method("step"):
		return _failure(test_name, "GridPosition.step is missing")

	var stepped: RefCounted = start.call("step", 0)
	var passed: bool = stepped.get("x") == 2 and stepped.get("y") == 2

	if not passed:
		return _failure(test_name, "Expected north step from (2, 3) to (2, 2)")

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
