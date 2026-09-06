class_name GridDirection
extends RefCounted

enum Value {
	NORTH = 0,
	EAST = 1,
	SOUTH = 2,
	WEST = 3,
}


func rotate_right(direction: int) -> int:
	return posmod(direction + 1, Value.size())


func to_delta(direction: int) -> Vector2i:
	match direction:
		Value.NORTH:
			return Vector2i(0, -1)
		Value.EAST:
			return Vector2i(1, 0)
		Value.SOUTH:
			return Vector2i(0, 1)
		Value.WEST:
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO
