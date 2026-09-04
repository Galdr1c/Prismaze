class_name GridPosition
extends RefCounted

const BOARD_WIDTH: int = 6
const BOARD_HEIGHT: int = 12
const DIRECTION_SCRIPT: Script = preload("res://scripts/core/models/direction.gd")

var x: int
var y: int


func _init(new_x: int, new_y: int) -> void:
	x = new_x
	y = new_y


func is_valid() -> bool:
	return x >= 0 and x < BOARD_WIDTH and y >= 0 and y < BOARD_HEIGHT


func shift(delta_x: int, delta_y: int) -> GridPosition:
	return get_script().new(x + delta_x, y + delta_y)


func step(direction: int) -> GridPosition:
	var direction_rules: RefCounted = DIRECTION_SCRIPT.new()
	var delta: Vector2i = direction_rules.to_delta(direction)
	return get_script().new(x + delta.x, y + delta.y)
