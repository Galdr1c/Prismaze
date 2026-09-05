class_name GeneratorV1
extends RefCounted

const LAYOUT = preload("res://scripts/levels/generator/layout_generator.gd")
const BUILDER = preload("res://scripts/levels/generator/solved_board_builder.gd")
const SCRAMBLE = preload("res://scripts/levels/generator/scramble_service.gd")
const VALIDATOR = preload("res://scripts/levels/generator/difficulty_validator.gd")
const DEFINITION = preload("res://scripts/levels/definitions/level_definition.gd")

const VERSION := 1
const MAX_ATTEMPTS := 200
# Design 6.5 target solution behavior; thresholds are fixed for generator v1.
const PROFILES := {
	"tutorial": {"moves": [1, 3], "max_irrelevant": 0},
	"easy": {"moves": [2, 5], "max_irrelevant": 1},
	"medium": {"moves": [5, 9], "max_irrelevant": 2},
	"hard": {"moves": [8, 14], "max_irrelevant": 2},
}

# Full solved-state -> scramble -> solver -> difficulty pipeline (design 6.6).
# Retries are deterministic: attempt n uses seed_value + n, so a fixed seed
# always regenerates the same accepted level. Returns ok, generator_version,
# profile, seed, attempts, definition (a playable LevelDefinition),
# metrics (validator output) and signature (definition fingerprint).
func generate(profile: String, seed_value: int, level_index: int = 1) -> Dictionary:
	var layout_generator := LAYOUT.new()
	var builder := BUILDER.new()
	var scramble := SCRAMBLE.new()
	var validator := VALIDATOR.new()
	for attempt in range(MAX_ATTEMPTS):
		var seed := seed_value + attempt
		var layout: Dictionary = layout_generator.generate(profile, seed)
		var built: Dictionary = builder.build(layout.placements, layout.board_size)
		if not built.ok:
			continue
		var scrambled: Dictionary = scramble.scramble(built.objects, layout.board_size, seed)
		if not scrambled.ok:
			continue
		var metrics: Dictionary = validator.evaluate(built.objects, layout.board_size)
		if not _accepts(profile, metrics):
			continue
		var definition := _definition(level_index, profile, layout, built, metrics)
		return {"ok": true, "generator_version": VERSION, "profile": profile, "seed": seed, "attempts": attempt + 1, "definition": definition, "metrics": metrics, "signature": definition.fingerprint()}
	return {"ok": false, "generator_version": VERSION, "profile": profile, "attempts": MAX_ATTEMPTS}

func _accepts(profile: String, metrics: Dictionary) -> bool:
	var spec: Dictionary = PROFILES.get(profile, PROFILES["easy"])
	if not metrics.solvable or metrics.cycle_found:
		return false
	if metrics.shortest_solution < spec.moves[0] or metrics.shortest_solution > spec.moves[1]:
		return false
	return metrics.irrelevant_objects <= spec.max_irrelevant

func _definition(level_index: int, profile: String, layout: Dictionary, built: Dictionary, metrics: Dictionary) -> Resource:
	var definition := DEFINITION.new()
	definition.id = level_index
	definition.title = "Endless · %s" % profile.capitalize()
	definition.lesson = "Işığı %d hamlede hedefe ulaştır." % metrics.shortest_solution
	definition.board_size = layout.board_size
	definition.par_moves = metrics.shortest_solution
	definition.solution = built.canonical_solution
	var objects: Array[Dictionary] = []
	for state in built.objects:
		objects.append({"id": state.id, "kind": state.kind, "x": state.position.x, "y": state.position.y, "orientation": state.orientation, "color": state.color})
	definition.objects = objects
	return definition