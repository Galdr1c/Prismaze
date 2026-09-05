extends SceneTree

var checks := 0
var failures := 0
var app: Control

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, passed: bool) -> void:
	checks += 1
	if passed:
		print("PASS: " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func touch(point: Vector2, pressed: bool, index: int = 0, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * point
	event.index = index
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	await settle()

func board_point(id: String) -> Vector2:
	return app.board.get_global_transform_with_canvas() * app.board.point_for(id)

func _run() -> void:
	if not load("res://tests/test_save_directory.gd").validate_args():
		quit(1)
		return
	root.size = Vector2i(720, 1280)
	app = load("res://scenes/boot/boot.tscn").instantiate()
	root.add_child(app)
	await settle()
	var start_button: Button
	for button: Button in app.find_children("*", "Button", true, false):
		if button.text == "Başla":
			start_button = button
	check("Fresh profile displays Start", is_instance_valid(start_button))
	if is_instance_valid(start_button):
		var point := start_button.get_global_rect().get_center()
		await touch(point, true)
		await touch(point, false)
	check("Touch activates menu button", app.screen == "playing")
	app.profile.unlocked = 4
	app.open_level(3, false)
	await settle()
	var point := board_point("m1")
	await touch(point, true)
	await touch(point, false)
	check("A finger tap rotates exactly once", app.session.moves == 1)
	app.open_level(3, false)
	await settle()
	point = board_point("m1")
	await touch(point, true)
	await touch(point, false, 0, true)
	check("Canceled touch does not rotate mirror", app.session.moves == 0)
	app.open_level(3, false)
	await settle()
	point = board_point("m1")
	await touch(point, true, 0)
	await touch(point, true, 1)
	await touch(point, false, 1)
	check("Second finger cannot rotate held board", app.session.moves == 0)
	await touch(point, false, 0)
	check("First finger completes one move", app.session.moves == 1)
	app.open_level(3, false)
	await settle()
	point = board_point("m1")
	await touch(point, true, 0)
	app.pause_game()
	await touch(point, false, 0)
	app.resume_game()
	await touch(point, true, 1)
	await touch(point, false, 1)
	check("Pause clears held pointer so a new finger works", app.session.moves == 1)
	app.queue_free()
	await create_timer(0.15).timeout
	print("Touch checks: %d, Failures: %d" % [checks, failures])
	quit(1 if failures else 0)
