extends SceneTree

var checks := 0
var failures := 0
var app: Control

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
	else:
		print("PASS: " + label)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("res://artifacts/" + name + ".png")

func click_object(id: String) -> void:
	var point: Vector2 = app.board.get_global_transform_with_canvas() * app.board.point_for(id)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func _run() -> void:
	if not load("res://tests/test_save_directory.gd").validate_args():
		quit(1)
		return
	root.size = Vector2i(720, 1280)
	app = load("res://scenes/boot/boot.tscn").instantiate()
	root.add_child(app)
	await settle()
	check("Boot displays main menu", app.screen == "menu")
	await capture("menu")
	app.open_level(0, false, true)
	await settle()
	check("First level has guided hand", app.board.tutorial)
	await capture("tutorial")
	await click_object("m1")
	await create_timer(0.5).timeout
	check("Real mouse input solves tutorial", app.session.result.solved and app.session.moves == 1)
	check("Result overlay opens", app.screen == "result" and is_instance_valid(app.overlay))
	check("Next level unlocks and persists", app.profile.unlocked >= 2 and app.profile.tutorial_done)
	await capture("result")
	app.open_level(1, false)
	await settle()
	await click_object("m1")
	check("Second level remains unsolved after one tap", app.session.moves == 1 and not app.session.result.solved)
	app.pause_game()
	check("Pause disables board input", app.screen == "paused" and not app.board.enabled)
	var moves: int = app.session.moves
	await click_object("m1")
	check("Modal prevents hidden board tap", app.session.moves == moves)
	app.resume_game()
	app.show_hint()
	check("Hint highlights an object", not app.board.hint_id.is_empty())
	app.persist()
	var snapshot: Dictionary = app.session.snapshot()
	app.show_menu()
	app.open_level(1)
	await settle()
	check("Continue restores current rotations", app.session.moves == snapshot.moves and app.session.snapshot().orientations == snapshot.orientations)
	app.profile.unlocked = 12
	app.open_level(11, false)
	await settle()
	await capture("prism")
	for viewport in [Vector2i(360,640), Vector2i(360,800), Vector2i(412,915)]:
		root.size = viewport
		await settle()
		check("Board fits viewport %s" % viewport, app.board.get_global_rect().end.y <= app.size.y and app.content.size.y <= app.size.y)
	await capture("compact")
	app.show_settings(app.show_menu)
	await settle()
	check("Settings screen opens", app.screen == "settings")
	await capture("settings")
	app.show_levels()
	await settle()
	check("Level selector opens", app.screen == "levels")
	var playing: Array[WeakRef] = []
	for player in [app.audio.music, app.audio.effects, app.audio.stinger]:
		if player.stream != null:
			playing.append(weakref(player.stream))
	app.queue_free()
	await settle()
	# Let the audio mixer retire stopped playback before quitting the engine.
	var deadline := Time.get_ticks_msec() + 2000
	while playing.any(func(reference: WeakRef): return reference.get_ref() != null) and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	check("UI teardown releases playing audio", playing.all(func(reference: WeakRef): return reference.get_ref() == null))
	print("UI checks: %d, Failures: %d" % [checks, failures])
	quit(1 if failures else 0)
