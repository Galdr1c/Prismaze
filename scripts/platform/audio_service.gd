extends Node

var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var stinger: AudioStreamPlayer
var preferences: Dictionary = {}
var _started := false
var _context := "menu"

func _ready() -> void:
	music = AudioStreamPlayer.new()
	effects = AudioStreamPlayer.new()
	stinger = AudioStreamPlayer.new()
	for player in [music, effects, stinger]:
		add_child(player)
	stinger.finished.connect(func(): set_context(_context))

func configure(settings: Dictionary) -> void:
	preferences = settings
	music.volume_db = linear_to_db(maxf(0.0001, float(settings.get("music", 0.65)) * 0.4))
	stinger.volume_db = linear_to_db(maxf(0.0001, float(settings.get("music", 0.65)) * 0.5))
	effects.volume_db = linear_to_db(maxf(0.0001, float(settings.get("sfx", 0.65)) * 0.65))

func startup() -> void:
	if _started:
		return
	_started = true
	if preferences.get("music", 0.65) > 0:
		stinger.stream = load("res://assets/audio/stingers/starting_sound.mp3")
		stinger.play()
	else:
		set_context("menu")

func set_context(context: String) -> void:
	_context = context
	if stinger.playing and context == "menu":
		return
	if stinger.playing:
		stinger.stop()
	var path := "res://assets/audio/runtime/menu.mp3" if context == "menu" else "res://assets/audio/runtime/gameplay.mp3"
	if music.stream and music.stream.resource_path == path:
		return
	var stream := load(path) as AudioStreamMP3
	if stream:
		stream.loop = true
		music.stream = stream
		music.play()

func sfx(event: String) -> void:
	if preferences.get("sfx", 0.65) <= 0:
		return
	effects.stream = load("res://assets/audio/runtime/" + event + ".mp3")
	if effects.stream:
		effects.play()

func suspend() -> void:
	stinger.stop()
	effects.stop()
	music.stream_paused = true

func resume() -> void:
	music.stream_paused = false
	if not music.playing:
		set_context(_context)
