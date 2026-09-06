extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, passed: bool) -> void:
	checks += 1
	if passed:
		print("PASS: " + label)
	else:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	var service: Node = load("res://scripts/platform/audio_service.gd").new()
	root.add_child(service)
	service.configure({"music": 0.65, "sfx": 0.65})
	service.set_context("menu")
	service.startup()
	check("Startup stinger plays without menu music", service.stinger.playing and not service.music.playing)
	service.set_context("game")
	check("Entering game stops and releases startup stinger", not service.stinger.playing and service.stinger.stream == null)
	check("Entering game plays gameplay music", service.music.playing and service.music.stream.resource_path.ends_with("gameplay.mp3"))
	service.startup()
	check("Startup stinger plays only once per session", not service.stinger.playing)
	service.suspend()
	service.sfx("click")
	check("Suspended app does not play effects", not service.effects.playing)
	service.resume()
	check("Resume unpauses background music", service.music.playing and not service.music.stream_paused)
	service.suspend()
	service.set_context("menu")
	service.resume()
	check("Resume applies context changed while suspended", service.music.stream.resource_path.ends_with("menu.mp3"))
	service.music.stop()
	service.resume()
	check("Resume restarts a stopped current track", service.music.playing)
	service.configure({"music": 0.0, "sfx": 0.0})
	service.sfx("click")
	check("Muted channels stop playback", not service.music.playing and not service.stinger.playing and not service.effects.playing)
	service.configure({"music": 0.65, "sfx": 0.65})
	check("Unmuting restores current background track", service.music.playing)
	service.sfx("click")
	var music_ref: WeakRef = weakref(service.music.stream)
	var effect_ref: WeakRef = weakref(service.effects.stream)
	service.queue_free()
	# Audio playback references are released by the mixer, not the render frame.
	var deadline := Time.get_ticks_msec() + 2000
	while (music_ref.get_ref() != null or effect_ref.get_ref() != null) and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	check("Removing AudioService releases music and effect resources", music_ref.get_ref() == null and effect_ref.get_ref() == null)
	print("Audio checks: %d, Failures: %d" % [checks, failures])
	quit(1 if failures else 0)
