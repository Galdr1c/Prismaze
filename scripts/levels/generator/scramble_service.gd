class_name ScrambleService
extends RefCounted

const TRACER = preload("res://scripts/core/logic/ray_tracer.gd")
# A layout whose targets are lit regardless of mirror orientation can never
# be scrambled; bail out instead of looping forever.
const MAX_ATTEMPTS := 64

# Converts a solved board into a scrambled start. Mutates the objects'
# orientations in place; the returned initial_orientations are what a caller
# should persist. The same seed always reproduces the same scramble, and
# every scramble keeps at least one rotatable different from the canonical
# orientations and never leaves the start already solved.
func scramble(objects: Array, board_size: Vector2i, seed_value: int) -> Dictionary:
	var canonical: Dictionary = {}
	for object in objects:
		if object.rotatable:
			canonical[object.id] = object.orientation
	var tracer := TRACER.new()
	var rng := RandomNumberGenerator.new()
	for attempt in range(MAX_ATTEMPTS):
		rng.seed = seed_value + attempt
		var initial: Dictionary = {}
		for object in objects:
			if object.rotatable:
				object.orientation = (canonical[object.id] + rng.randi_range(0, 3)) % 4
				initial[object.id] = object.orientation
		var differs := false
		for id in canonical:
			if initial[id] != canonical[id]:
				differs = true
				break
		if differs and not tracer.trace(objects, board_size).solved:
			return {"ok": true, "initial_orientations": initial, "attempts": attempt}
	return {"ok": false, "initial_orientations": {}, "attempts": MAX_ATTEMPTS}