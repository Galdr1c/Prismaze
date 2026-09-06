extends RefCounted

const BUILDER = preload("res://scripts/levels/generator/solved_board_builder.gd")

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "LayoutGenerator contract failed" if not ok else ""})

func run() -> Array[Dictionary]:
	var path := "res://scripts/levels/generator/layout_generator.gd"
	if not ResourceLoader.exists(path):
		check(path + " exists", false)
		return results
	var generator = load(path).new()
	var builder := BUILDER.new()
	var profiles := {"tutorial": [1, 2], "easy": [2, 4], "medium": [3, 7], "hard": [5, 7]}
	for profile in profiles:
		var counts: Dictionary = {}
		for seed_value in range(1, 31):
			var layout: Dictionary = generator.generate(profile, seed_value)
			var mirrors := 0
			var kinds := {}
			var cells := {}
			var in_bounds := true
			for item in layout.placements:
				kinds[item.kind] = kinds.get(item.kind, 0) + 1
				if item.kind == 1:
					mirrors += 1
				var key := "%d,%d" % [item.x, item.y]
				cells[key] = cells.get(key, 0) + 1
				if item.x < 0 or item.y < 0 or item.x >= layout.board_size.x or item.y >= layout.board_size.y:
					in_bounds = false
			check("%s seed %d mirror count in range" % [profile, seed_value], mirrors >= profiles[profile][0] and mirrors <= profiles[profile][1])
			check("%s seed %d one source one target" % [profile, seed_value], kinds.get(0, 0) == 1 and kinds.get(3, 0) == 1 and kinds.get(1, 0) == mirrors)
			check("%s seed %d cells inside board" % [profile, seed_value], in_bounds)
			check("%s seed %d cells unique" % [profile, seed_value], cells.values().all(func(v): return v == 1))
			check("%s seed %d layout builds" % [profile, seed_value], builder.build(layout.placements, layout.board_size).ok)
			counts[mirrors] = counts.get(mirrors, 0) + 1
		check("%s hits every allowed mirror count" % [profile], counts.size() == profiles[profile][1] - profiles[profile][0] + 1)
	var a: Dictionary = generator.generate("easy", 42)
	var b: Dictionary = generator.generate("easy", 42)
	check("Generator is deterministic", a.placements == b.placements)
	var distinct := {}
	for seed_value in range(1, 21):
		distinct[generator.generate("hard", seed_value).placements] = true
	check("Different seeds produce different layouts", distinct.size() >= 5)
	return results