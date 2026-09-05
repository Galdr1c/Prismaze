extends RefCounted

var results: Array[Dictionary] = []

func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "Audio lifecycle contract failed" if not ok else ""})


func run() -> Array[Dictionary]:
	var path := "res://scripts/platform/audio_service.gd"
	if not ResourceLoader.exists(path):
		check("AudioService exists", false)
		return results

	var service: Node = load(path).new()
	service._ready()
	check("AudioService exposes shutdown contract", service.has_method("shutdown"))
	if service.has_method("shutdown"):
		service.music.stream = AudioStreamGenerator.new()
		service.effects.stream = AudioStreamGenerator.new()
		service.stinger.stream = AudioStreamGenerator.new()
		service.shutdown()
		check("Shutdown stops music playback", not service.music.playing)
		check("Shutdown releases music stream", service.music.stream == null)
		check("Shutdown releases effects stream", service.effects.stream == null)
		check("Shutdown releases stinger stream", service.stinger.stream == null)
	service.free()
	return results
