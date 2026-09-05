extends SceneTree

const SUITES: Array[String] = [
	"res://tests/core/grid_position_test.gd",
	"res://tests/core/direction_test.gd",
	"res://tests/core/light_color_test.gd",
	"res://tests/core/game_object_state_test.gd",
	"res://tests/core/optics_test.gd",
	"res://tests/core/session_test.gd",
	"res://tests/core/solver_test.gd",
	"res://tests/levels/solved_board_builder_test.gd",
	"res://tests/levels/scramble_service_test.gd",
	"res://tests/levels/difficulty_validator_test.gd",
	"res://tests/core/save_test.gd",
	"res://tests/core/audio_service_test.gd",
	"res://tests/core/test_save_directory_test.gd",
]


func _init() -> void:
	var checks: int = 0
	var failures: int = 0

	for suite_path: String in SUITES:
		var suite_script: Script = load(suite_path)
		var suite: RefCounted = suite_script.new()
		var results: Array[Dictionary] = suite.run()

		for result: Dictionary in results:
			checks += 1
			if result["passed"]:
				print("PASS: %s" % result["name"])
			else:
				failures += 1
				printerr("FAIL: %s — %s" % [result["name"], result["message"]])

	print("Checks: %d, Failures: %d" % [checks, failures])
	quit(failures)
