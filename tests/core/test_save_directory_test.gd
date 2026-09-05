extends RefCounted

func run() -> Array[Dictionary]:
	var guard = load("res://tests/test_save_directory.gd")
	var results: Array[Dictionary] = []
	var cases := {
		"": false,
		"user://": false,
		ProjectSettings.globalize_path("user://"): false,
		"res://artifacts/tests/../../../": false,
		"res://artifacts/tests": false,
		"res://artifacts/tests/../player_save": false,
		"res://artifacts/tests/new_%d" % Time.get_ticks_usec(): true,
	}
	for path in cases:
		results.append({"name": "Test save isolation: " + path, "passed": guard.is_safe(path) == cases[path], "message": "Unsafe test directory accepted"})
	return results
