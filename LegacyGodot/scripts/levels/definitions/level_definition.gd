class_name LevelDefinition
extends Resource

const STATE = preload("res://scripts/core/models/game_object_state.gd")
const CELL = preload("res://scripts/core/models/grid_position.gd")

@export var id: int = 1
@export var title: String = ""
@export var lesson: String = ""
@export var board_size: Vector2i = Vector2i(6, 12)
@export var objects: Array[Dictionary] = []
@export var solution: Dictionary = {}
@export var par_moves: int = 1

func create_states() -> Array:
	var states: Array = []
	for item in objects:
		states.append(STATE.new(item.id, item.kind, CELL.new(item.x, item.y), item.get("orientation", 0), item.kind in [1, 2], item.get("color", 7)))
	return states

func initial_orientations() -> Dictionary:
	var result: Dictionary = {}
	for item in objects:
		if item.kind in [1, 2]:
			result[item.id] = item.get("orientation", 0)
	return result

func fingerprint() -> String:
	return JSON.stringify([id, board_size.x, board_size.y, objects, solution]).sha256_text()
