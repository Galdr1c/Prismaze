extends RefCounted

const LIGHT_COLOR_PATH := "res://scripts/core/models/light_color.gd"


func run() -> Array[Dictionary]:
	return [
		_test_mix_red_and_blue_returns_purple(),
		_test_satisfies_requires_an_exact_mask(),
	]


func _test_mix_red_and_blue_returns_purple() -> Dictionary:
	const test_name := "LightColor mixes red and blue into purple"

	if not ResourceLoader.exists(LIGHT_COLOR_PATH):
		return _failure(test_name, "LightColor production script is missing")

	var light_color_script: Script = load(LIGHT_COLOR_PATH)
	var light_color: RefCounted = light_color_script.new()

	if not light_color.has_method("mix"):
		return _failure(test_name, "LightColor.mix is missing")

	if light_color.call("mix", 1, 4) != 5:
		return _failure(test_name, "Expected red (1) plus blue (4) to equal purple (5)")

	return _success(test_name)


func _test_satisfies_requires_an_exact_mask() -> Dictionary:
	const test_name := "LightColor satisfies requires an exact mask"

	var light_color_script: Script = load(LIGHT_COLOR_PATH)
	var light_color: RefCounted = light_color_script.new()

	if not light_color.has_method("satisfies"):
		return _failure(test_name, "LightColor.satisfies is missing")

	var exact_match: bool = light_color.call("satisfies", 5, 5)
	var extra_color_rejected: bool = not light_color.call("satisfies", 7, 5)

	if not exact_match or not extra_color_rejected:
		return _failure(test_name, "Purple must accept 5 and reject white 7")

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
