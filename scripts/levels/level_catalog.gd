extends RefCounted

const LEVEL_COUNT := 12

func count() -> int:
	return LEVEL_COUNT

func get_level(index: int) -> Resource:
	if index < 0 or index >= LEVEL_COUNT:
		return null
	return load("res://data/levels/level_%03d.tres" % (index + 1))
