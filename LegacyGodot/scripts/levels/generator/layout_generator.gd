class_name LayoutGenerator
extends RefCounted

const BOARD_SIZE := Vector2i(6, 12)
# Design 6.5 content limits. v1 uses mirror-chain templates only: walls and
# prisms arrive with generator v2 templates. Hard is capped at 7 mirrors
# because the staircase consumes one board column per two mirrors.
const PROFILES := {
	"tutorial": [1, 2],
	"easy": [2, 4],
	"medium": [3, 7],
	"hard": [5, 7],
}

# Seeded staircase template: a source shoots east into a diagonal mirror
# chain; every mirror reflects E->S or S->E (all canonical orientations 3),
# and the final run reaches the target. Same seed always reproduces the same
# placements.
func generate(profile: String, seed_value: int) -> Dictionary:
	var spec: Array = PROFILES.get(profile, PROFILES["easy"])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mirror_count := rng.randi_range(spec[0], spec[1])
	var target_offset: int = mirror_count / 2 if mirror_count % 2 == 0 else (mirror_count + 1) / 2 + 1
	var y0 := rng.randi_range(0, maxi(0, 11 - target_offset))
	var placements: Array = []
	placements.append({"id": "s", "kind": 0, "x": 0, "y": y0, "orientation": 1, "color": 7})
	for i in range(mirror_count):
		placements.append({"id": "m%d" % i, "kind": 1, "x": 2 + i / 2, "y": y0 + (i + 1) / 2})
	if mirror_count % 2 == 0:
		placements.append({"id": "t", "kind": 3, "x": 5, "y": y0 + mirror_count / 2})
	else:
		placements.append({"id": "t", "kind": 3, "x": 2 + (mirror_count - 1) / 2, "y": y0 + (mirror_count + 1) / 2 + 1})
	return {"placements": placements, "board_size": BOARD_SIZE, "profile": profile, "mirror_count": mirror_count}